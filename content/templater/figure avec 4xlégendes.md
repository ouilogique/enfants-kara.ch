<%*
let src = await tp.system.prompt("Chemin de l'image (ex: images/photo.jpg)");
let alt = await tp.system.prompt("Texte alternatif pour l'accessibilité");
let titreSurvol = await tp.system.prompt("Légende à afficher au survol de la souris");
let legende = await tp.system.prompt("Légende visible sous la photo");

tR += '<figure class="gallery-item">\n';
tR += '  <img src="' + src + '" alt="' + alt + '" title="' + titreSurvol + '">\n';
tR += '  <figcaption>' + legende + '</figcaption>\n';
tR += '</figure>';
%>