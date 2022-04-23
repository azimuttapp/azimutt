(() => {
    addAzimuttButton()
})()

function addAzimuttButton() {
    const pageUrl = document.location.href
    const btnGroup = document.querySelector('.Box-header .BtnGroup')
    const azimuttBtn = document.getElementById('azimutt-btn')
    if (pageUrl.endsWith('.sql') && btnGroup && !azimuttBtn) {
        const rawUrl = document.getElementById('raw-url').getAttribute('href')
        fetch(rawUrl).then(res => { // to get url with eventual redirections and tokens
            const azimuttUrl = `https://azimutt.app/embed?source-url=${encodeURIComponent(res.url)}&mode=full`
            // use a logo hosted in Github as the extension one is blocked by CSP
            const logoUrl = 'https://raw.githubusercontent.com/azimuttapp/azimutt/main/public/favicon-16x16.png'
            const btn = document.createElement('a')
            btn.id = 'azimutt-btn'
            btn.href = azimuttUrl
            btn.target = '_blank'
            btn.className = 'btn-sm btn BtnGroup-item'
            btn.innerHTML = `<img src="${logoUrl}" alt="" style="height: 16px; margin-bottom: -3px; margin-left: -3px"/> Open in Azimutt`
            fetch(logoUrl).then(() => btnGroup.prepend(btn)) // load image first so it doesn't blink
        })
    }

    // continuously try to add the button if needed
    // this is ugly but the only way I found to make it work as Github does not reload pages but replace them
    // PS: even if added, you can navigate away and come back, so we need to keep trying
    setTimeout(addAzimuttButton, 1000)
}
