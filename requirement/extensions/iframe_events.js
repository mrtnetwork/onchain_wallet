window.addEventListener("message", (e) => {
    if (e.origin !== location.origin) return;

    if (e.data?.source !== "wallet") return;
    if (e.data?.message !== "close_iframe") return;

    window.close();
});