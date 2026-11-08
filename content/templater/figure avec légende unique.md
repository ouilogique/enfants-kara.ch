<%*
let src = await tp.system.prompt("Chemin de l'image (ex: images/photo.jpg)");
let legende = await tp.system.prompt("Légende à utiliser pour cette photo");

tR += '<figure class="gallery-item">\n';
tR += '  <img src="' + src + '" alt="' + legende + '" title="' + legende + '">\n';
tR += '  <figcaption>' + legende + '</figcaption>\n';
tR += '</figure>';
%>
