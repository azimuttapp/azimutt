// import browser = require('webextension-polyfill');
(() => {
    const pageUrl = document.location.href
    const btnGroup = document.querySelector('.Box-header .BtnGroup')
    if (btnGroup) {
        const rawUrl = pageUrl.replace('/blob', '').replace('github.com', 'raw.githubusercontent.com')
        const azimuttUrl = `https://azimutt.app/embed?source-url=${rawUrl}&mode=full`
        // TODO: logo in extension is blocked by github csp :(
        const logoUrl = 'https://raw.githubusercontent.com/azimuttapp/azimutt/main/public/favicon-16x16.png' // browser.runtime.getURL("azimutt_16.png");
        const link = document.createElement('a')
        link.href = azimuttUrl
        link.target = '_blank'
        link.className = 'btn-sm btn BtnGroup-item'
        link.innerHTML = `<img src="${logoUrl}" alt="" style="height: 16px; margin-bottom: -3px; margin-left: -3px"/> Open in Azimutt`
        btnGroup.prepend(link)
    }
})();
