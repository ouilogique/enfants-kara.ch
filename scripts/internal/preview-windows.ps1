# Run Hugo in a Windows job that kills its processes when this launcher exits,
# including when the terminal window is closed rather than Ctrl+C being sent.
param(
    [Parameter(Mandatory = $true)][string] $HugoPath,
    [Parameter(Mandatory = $true)][string] $ProjectDir,
    [Parameter(ValueFromRemainingArguments = $true)][string[]] $HugoArguments
)

$ErrorActionPreference = 'Stop'

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class PreviewJob {
    [StructLayout(LayoutKind.Sequential)]
    public struct BasicLimitInformation {
        public long PerProcessUserTimeLimit;
        public long PerJobUserTimeLimit;
        public uint LimitFlags;
        public UIntPtr MinimumWorkingSetSize;
        public UIntPtr MaximumWorkingSetSize;
        public uint ActiveProcessLimit;
        public UIntPtr Affinity;
        public uint PriorityClass;
        public uint SchedulingClass;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct IoCounters {
        public ulong ReadOperationCount;
        public ulong WriteOperationCount;
        public ulong OtherOperationCount;
        public ulong ReadTransferCount;
        public ulong WriteTransferCount;
        public ulong OtherTransferCount;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct ExtendedLimitInformation {
        public BasicLimitInformation BasicLimitInformation;
        public IoCounters IoInfo;
        public UIntPtr ProcessMemoryLimit;
        public UIntPtr JobMemoryLimit;
        public UIntPtr PeakProcessMemoryUsed;
        public UIntPtr PeakJobMemoryUsed;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr CreateJobObject(IntPtr attributes, string name);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool SetInformationJobObject(IntPtr job, int infoClass,
        ref ExtendedLimitInformation info, uint length);

    public static IntPtr CreateKillOnCloseJob() {
        IntPtr job = CreateJobObject(IntPtr.Zero, null);
        if (job == IntPtr.Zero) throw new System.ComponentModel.Win32Exception();
        var info = new ExtendedLimitInformation();
        info.BasicLimitInformation.LimitFlags = 0x2000; // JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
        if (!SetInformationJobObject(job, 9, ref info,
            (uint)Marshal.SizeOf(typeof(ExtendedLimitInformation)))) {
            var error = new System.ComponentModel.Win32Exception();
            CloseHandle(job);
            throw error;
        }
        return job;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool CloseHandle(IntPtr handle);
}
'@

$jobType = [PreviewJob]

$job = $jobType::CreateKillOnCloseJob()

$process = $null
try {
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $HugoPath
    $startInfo.WorkingDirectory = $ProjectDir
    $startInfo.UseShellExecute = $false
    $startInfo.Arguments = $HugoArguments -join ' '
    $process = [System.Diagnostics.Process]::Start($startInfo)
    if (-not $jobType::AssignProcessToJobObject($job, $process.Handle)) {
        throw "AssignProcessToJobObject failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    }

    $process.WaitForExit()
    exit $process.ExitCode
} finally {
    [void] $jobType::CloseHandle($job)
    if ($null -ne $process) { $process.Dispose() }
}
