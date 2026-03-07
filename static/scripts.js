function targetBlank() {
    const _a = document.getElementsByTagName("a");
    const _siteHost = location.host.replace(/^www\./i, "");
    const internalRegex = new RegExp(_siteHost, "i");

    for (let i = 0; i < _a.length; i++) {
        let href = _a[i].href;
        let isExternal = false;

        if (/^mailto:/i.test(href)) {
            // Si le lien commence par mailto: il est forcement externe
            isExternal = true;
        } else if (location.protocol === "file:") {
            // Si on est en protocole file://
            // tous les liens http/https et protocol-relative sont externes
            isExternal = /^(https?:)?\/\//i.test(href);
        } else {
            // Logique normale pour http/https
            // Un lien est externe s'il a un host et que ce host ne correspond pas au site actuel
            let linkHost = _a[i].host;
            isExternal = linkHost && !internalRegex.test(linkHost);
        }

        if (isExternal) {
            // Attribue `_blank` a l'attribut `target`.
            _a[i].setAttribute("target", "_blank");

            // Ajoute `noopener` a l'attribut `rel`.
            const rel = (_a[i].getAttribute("rel") || "").trim();
            const relParts = rel ? rel.split(/\s+/) : [];
            if (!relParts.includes("noopener")) relParts.push("noopener");
            _a[i].setAttribute("rel", relParts.join(" ").trim());
        }
        // console.log(`${String(isExternal).padEnd(5)} ${_siteHost} ${href}`);
    }
}
targetBlank();

// Navigation au clavier entre pages.
let isNavigating = false;

function getHomeHref() {
    const footerHomeLink = document.querySelector(".nav-footer-center a.nav-link[href]");
    if (footerHomeLink) return footerHomeLink.getAttribute("href");
    return "/";
}

function normalizePath(pathname) {
    return pathname.replace(/\/index\.html$/, "/");
}

function isHomePage() {
    const currentPath = normalizePath(window.location.pathname);
    const homePath = normalizePath(new URL(getHomeHref(), window.location.href).pathname);
    return currentPath === homePath;
}

function replayLogoAnimation() {
    const logoTargets = document.querySelectorAll(".cls-site-logo, .spin");
    logoTargets.forEach((el) => {
        el.style.animation = "none";
        // Force reflow to restart CSS animation.
        void el.offsetWidth;
        el.style.animation = "";
    });
}

function smoothScrollToTop() {
    window.scrollTo({ top: 0, behavior: "smooth" });
}

document.addEventListener("keydown", (event) => {
    if (isNavigating) return;

    // Leave if user is typing in an editable area.
    const tag = (event.target.tagName || "").toLowerCase();
    if (tag === "input" || tag === "textarea" || event.target.isContentEditable) return;

    // Otherwise assign keyboard shortcuts to prev-next buttons.
    const prevKeys = ["ArrowLeft"];
    const nextKeys = ["ArrowRight"];
    const homeKeys = ["Escape"];

    const prevLink = document.querySelector(".nav-page-home .pagination-link");
    const nextLink = document.querySelector(".nav-page-next .pagination-link");

    if (homeKeys.includes(event.key)) {
        event.preventDefault();
        if (isHomePage()) {
            smoothScrollToTop();
            replayLogoAnimation();
            return;
        }
        isNavigating = true;
        window.location.href = getHomeHref();
        return;
    }
    else if (prevKeys.includes(event.key) && prevLink && prevLink.getAttribute("href")) {
        event.preventDefault();
        isNavigating = true;
        window.location.href = prevLink.getAttribute("href");
        return;
    }
    else if (nextKeys.includes(event.key) && nextLink && nextLink.getAttribute("href")) {
        event.preventDefault();
        isNavigating = true;
        window.location.href = nextLink.getAttribute("href");
        return;
    }
});
