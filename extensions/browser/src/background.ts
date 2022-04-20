import browser = require('webextension-polyfill');

const openAzimutt = () => browser.tabs.create({ url: 'https://azimutt.app/pwa-start' })

browser.action.onClicked.addListener(openAzimutt);
