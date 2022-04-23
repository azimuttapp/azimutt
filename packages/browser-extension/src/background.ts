import browser = require('webextension-polyfill')

browser.action.onClicked.addListener(() => browser.tabs.create({ url: 'https://azimutt.app/projects/last' }))
