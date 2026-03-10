

function isImageHref(href) {
    return /\.(avif|gif|jpe?g|png|svg|webp)(?:[?#].*)?$/i.test(href || "");
}

function getDirectElementChild(parent, selector) {
    return Array.from(parent.children).find((child) => child.matches(selector)) || null;
}

function getStandaloneMedia(node) {
    if (node.childElementCount !== 1) return null;

    const directImage = getDirectElementChild(node, "img");
    if (directImage) return { img: directImage, anchor: null };

    const directAnchor = getDirectElementChild(node, "a[href]");
    if (!directAnchor || directAnchor.childElementCount !== 1 || !isImageHref(directAnchor.getAttribute("href"))) {
        return null;
    }

    const linkedImage = getDirectElementChild(directAnchor, "img");
    if (!linkedImage) return null;

    return { img: linkedImage, anchor: directAnchor };
}

function enhanceContentMedia() {
    const contents = document.querySelectorAll(".content");

    contents.forEach((content) => {
        const lists = content.querySelectorAll("ul, ol");
        lists.forEach((list) => {
            const items = Array.from(list.children).filter((child) => child.tagName === "LI");
            if (items.length < 2) return;

            const mediaItems = items.map((item) => getStandaloneMedia(item));
            if (mediaItems.some((item) => !item)) return;

            list.classList.add("image-gallery");
            items.forEach((item, index) => {
                item.classList.add("gallery-item");
                item.dataset.galleryIndex = String(index);

                const media = mediaItems[index];
                media.img.classList.add("gallery-image");
                if (media.anchor) media.anchor.classList.add("gallery-link");
            });
        });

        Array.from(content.children).forEach((child) => {
            const media = getStandaloneMedia(child);
            if (!media) return;

            child.classList.add("media-block");
            media.img.classList.add("gallery-image");
            if (media.anchor) media.anchor.classList.add("gallery-link");
        });
    });
}

const lightboxState = {
    root: null,
    image: null,
    caption: null,
    close: null,
    prev: null,
    next: null,
    count: null,
    opener: null,
    items: [],
    index: 0,
    isOpen: false
};

function getLightboxItems(trigger) {
    const gallery = trigger.closest(".image-gallery");
    const scope = gallery ? gallery.querySelectorAll(".gallery-image") : [trigger];

    return Array.from(scope).map((img) => {
        const anchor = img.closest("a[href]");
        const src = anchor && isImageHref(anchor.getAttribute("href")) ? anchor.href : (img.currentSrc || img.src);
        const caption = img.getAttribute("alt") || "";
        return { img, src, caption };
    });
}

function updateLightbox() {
    const item = lightboxState.items[lightboxState.index];
    if (!item) return;

    lightboxState.image.src = item.src;
    lightboxState.image.alt = item.caption;
    lightboxState.caption.textContent = item.caption;
    lightboxState.caption.hidden = !item.caption;
    lightboxState.count.textContent = lightboxState.items.length > 1
        ? item.caption
            ? `${lightboxState.index + 1} / ${lightboxState.items.length}`
            : `${lightboxState.index + 1} / ${lightboxState.items.length}`
        : "";
    lightboxState.count.hidden = lightboxState.items.length <= 1;
    lightboxState.prev.hidden = lightboxState.items.length <= 1;
    lightboxState.next.hidden = lightboxState.items.length <= 1;
}

function openLightbox(trigger) {
    lightboxState.items = getLightboxItems(trigger);
    lightboxState.index = lightboxState.items.findIndex((item) => item.img === trigger);
    lightboxState.opener = trigger;

    if (lightboxState.index < 0) lightboxState.index = 0;

    updateLightbox();
    lightboxState.root.hidden = false;
    document.body.classList.add("has-lightbox");
    lightboxState.isOpen = true;
    lightboxState.close.focus();
}

function closeLightbox() {
    if (!lightboxState.isOpen) return;

    lightboxState.root.hidden = true;
    lightboxState.image.removeAttribute("src");
    lightboxState.caption.textContent = "";
    lightboxState.count.textContent = "";
    document.body.classList.remove("has-lightbox");
    lightboxState.isOpen = false;

    if (lightboxState.opener) {
        lightboxState.opener.focus();
    }
}

function stepLightbox(delta) {
    if (!lightboxState.isOpen || lightboxState.items.length <= 1) return;

    lightboxState.index = (lightboxState.index + delta + lightboxState.items.length) % lightboxState.items.length;
    updateLightbox();
}

function setupLightbox() {
    lightboxState.root = document.getElementById("site-lightbox");
    if (!lightboxState.root) return;

    const mediaHost = lightboxState.root.querySelector(".lightbox-media");
    const image = document.createElement("img");
    image.className = "lightbox-image";
    image.alt = "";
    mediaHost.appendChild(image);

    lightboxState.image = image;
    lightboxState.caption = lightboxState.root.querySelector(".lightbox-caption");
    lightboxState.close = lightboxState.root.querySelector(".lightbox-close");
    lightboxState.prev = lightboxState.root.querySelector(".lightbox-prev");
    lightboxState.next = lightboxState.root.querySelector(".lightbox-next");
    lightboxState.count = lightboxState.root.querySelector(".lightbox-count");

    const images = document.querySelectorAll(".content .gallery-image");
    images.forEach((img) => {
        const anchor = img.closest("a[href]");
        img.classList.add("is-lightboxable");
        img.setAttribute("tabindex", "0");
        img.setAttribute("role", "button");
        img.setAttribute("aria-label", "Agrandir l'image");

        img.addEventListener("click", () => openLightbox(img));
        img.addEventListener("keydown", (event) => {
            if (event.key === "Enter" || event.key === " ") {
                event.preventDefault();
                openLightbox(img);
            }
        });

        if (anchor && isImageHref(anchor.getAttribute("href"))) {
            anchor.addEventListener("click", (event) => {
                event.preventDefault();
                openLightbox(img);
            });
        }
    });

    lightboxState.close.addEventListener("click", closeLightbox);
    lightboxState.prev.addEventListener("click", () => stepLightbox(-1));
    lightboxState.next.addEventListener("click", () => stepLightbox(1));
    lightboxState.root.addEventListener("click", (event) => {
        if (event.target === lightboxState.root) closeLightbox();
    });
}

enhanceContentMedia();
setupLightbox();

// Navigation au clavier entre pages.
let isNavigating = false;

function getHomeHref() {
    const brandLink = document.querySelector(".brand[href]");
    if (brandLink) return brandLink.getAttribute("href");
    return "/";
}

function isHomePage() {
    const homePath = new URL(getHomeHref(), window.location.href).pathname.replace(/\/$/, "");
    return window.location.pathname.replace(/\/$/, "") === homePath;
}

function replayLogoAnimation() {
    const logoTargets = document.querySelectorAll(".cls-site-logo, .spin");
    logoTargets.forEach((el) => {
        el.style.animation = "none";
        void el.offsetWidth;
        el.style.animation = "";
    });
}

function smoothScrollToTop() {
    window.scrollTo({ top: 0, behavior: "smooth" });
}

function setupPageNavigation() {
    document.querySelectorAll('.page-nav-link[href]').forEach((link) => {
        link.addEventListener('click', (e) => {
            if (isNavigating) return;
            e.preventDefault();
            isNavigating = true;
            sessionStorage.setItem('ek-nav', '1');
            window.location.href = link.href;
        });
    });
}

setupPageNavigation();

document.addEventListener("keydown", (event) => {
    if (lightboxState.isOpen) {
        if (event.key === "Escape") {
            event.preventDefault();
            closeLightbox();
        } else if (event.key === "ArrowLeft") {
            event.preventDefault();
            stepLightbox(-1);
        } else if (event.key === "ArrowRight") {
            event.preventDefault();
            stepLightbox(1);
        }
        return;
    }

    if (isNavigating) return;

    const tag = (event.target.tagName || "").toLowerCase();
    if (tag === "input" || tag === "textarea" || event.target.isContentEditable) return;

    if (event.key === "Escape") {
        event.preventDefault();
        if (isHomePage()) {
            smoothScrollToTop();
            replayLogoAnimation();
            return;
        }
        isNavigating = true;
        sessionStorage.setItem('ek-nav', '1');
        window.location.href = getHomeHref();
    } else if (event.key === "ArrowLeft") {
        const prevHref = document.querySelector('[data-page-nav="prev"]')?.href;
        if (!prevHref) return;
        event.preventDefault();
        isNavigating = true;
        sessionStorage.setItem('ek-nav', '1');
        window.location.href = prevHref;
    } else if (event.key === "ArrowRight") {
        const nextHref = document.querySelector('[data-page-nav="next"]')?.href;
        if (!nextHref) return;
        event.preventDefault();
        isNavigating = true;
        sessionStorage.setItem('ek-nav', '1');
        window.location.href = nextHref;
    }
});
