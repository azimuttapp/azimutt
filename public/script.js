window.addEventListener('load', function() {
    const isDev = window.location.hostname === 'localhost'
    const isProd = window.location.hostname === 'azimutt.app'
    const skipAnalytics = !!JSON.parse(localStorage.getItem('skip-analytics'))
    const analytics = initAnalytics(isProd && !skipAnalytics)
    const errorTracking = initErrorTracking(isProd)
    const app = Elm.Main.init()


    /* PWA service worker */

    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.register("/service-worker.js")
            // .then(reg => console.log('service-worker registered!', reg))
            // .catch(err => console.log('service-worker failed to register!', err))
    }


    /* Elm ports */

    function sendToElm(msg) {
        // console.log('js message', msg)
        app.ports.jsToElm.send(msg)
    }
    app.ports && app.ports.elmToJs.subscribe(msg => {
        // setTimeout: a ugly hack to wait for Elm to render the model changes before running the commands :(
        setTimeout(() => {
            // console.log('elm message', msg)
            switch (msg.kind) {
                case 'Click':         click(msg.id); break;
                case 'ShowModal':     showModal(msg.id); break;
                case 'HideModal':     hideModal(msg.id); break;
                case 'HideOffcanvas': hideOffcanvas(msg.id); break;
                case 'ActivateTooltipsAndPopovers': activateTooltipsAndPopovers(); break;
                case 'ShowToast':     showToast(msg.toast); break;
                case 'LoadProjects':  loadProjects(); break;
                case 'SaveProject':   saveProject(msg.project); break;
                case 'DropProject':   dropProject(msg.project); break;
                case 'GetLocalFile':  getLocalFile(msg.project, msg.source, msg.file); break;
                case 'GetRemoteFile': getRemoteFile(msg.project, msg.source, msg.url, msg.sample); break;
                case 'ObserveSizes':  observeSizes(msg.ids); break;
                case 'ListenKeys':    listenHotkeys(msg.keys); break;
                case 'TrackPage':     analytics.then(a => a.trackPage(msg.name)); break;
                case 'TrackEvent':    analytics.then(a => a.trackEvent(msg.name, msg.details)); break;
                case 'TrackError':    analytics.then(a => a.trackError(msg.name, msg.details)); errorTracking.then(e => e.trackError(msg.name, msg.details)); break;
                default: console.error('Unsupported Elm message', msg); break;
            }
        }, 100)
    })

    function click(id) {
        getElementById(id).click()
    }
    function showModal(id) {
        bootstrap.Modal.getOrCreateInstance(getElementById(id)).show()
    }
    function hideModal(id) {
        bootstrap.Modal.getOrCreateInstance(getElementById(id)).hide()
    }
    function hideOffcanvas(id) {
        bootstrap.Offcanvas.getOrCreateInstance(getElementById(id)).hide()
    }
    function activateTooltipsAndPopovers() {
        bootstrap && document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(e => bootstrap.Tooltip.getOrCreateInstance(e))
        bootstrap && document.querySelectorAll('[data-bs-toggle="popover"]').forEach(e => bootstrap.Popover.getOrCreateInstance(e))
    }

    let toastCpt = 0
    function showToast(toast) {
        const toastContainer = document.getElementById('toast-container')
        if (toastContainer) {
            const toastNo = toastCpt += 1
            const toastId = 'toast-' + toastNo
            let bgColor = ''
            let btnColor = ''
            let autoHide = true
            switch (toast.kind) {
                case 'info':
                    break
                case 'warning':
                    bgColor = 'bg-warning'
                    break
                case 'error':
                    bgColor = 'bg-danger text-white'
                    btnColor = 'btn-close-white'
                    autoHide = false
                    break
                default:
                    break
            }
            let html =
                '<div class="toast align-items-center ' + bgColor + '" id="' + toastId + '" role="status" aria-live="polite" aria-atomic="true"' + (autoHide ? '' : ' data-bs-autohide="false"') + '>\n' +
                '  <div class="d-flex">\n' +
                '    <div class="toast-body">\n' +
                '      ' + toast.message + '\n' +
                '    </div>\n' +
                '    <button type="button" class="btn-close ' + btnColor + ' me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>\n' +
                '  </div>\n' +
                '</div>'
            toastContainer.insertAdjacentHTML('beforeend', html)
            bootstrap.Toast.getOrCreateInstance(getElementById(toastId)).show()
        } else {
            console.warn("Can't show toast, container not present", toast)
        }
    }

    const projectPrefix = 'project-'
    function loadProjects() {
        const values = Object.keys(localStorage)
            .filter(key => key.startsWith(projectPrefix))
            .map(key => [key.replace(projectPrefix, ''), JSON.parse(localStorage.getItem(key))])
        sendToElm({kind: 'GotProjects', projects: values})
    }
    function saveProject(project) {
        const key = projectPrefix + project.id
        // setting dates should be done in Elm but can't find how to run a Task before calling a Port
        const now = Date.now()
        project.updatedAt = now
        if (localStorage.getItem(key) === null) { project.createdAt = now }
        try {
            localStorage.setItem(key, JSON.stringify(project))
        } catch (e) {
            if (e.code === DOMException.QUOTA_EXCEEDED_ERR) {
                showToast({kind: 'error', message: "Can't save project, storage quota exceeded. Use a smaller schema or clean unused projects."})
            } else {
                showToast({kind: 'error', message: "Can't save project: " + e.message})
            }
            const name = 'local-storage'
            const details = {error: e.name, message: e.message}
            analytics.then(a => a.trackError(name, details)); errorTracking.then(e => e.track(name, details));
        }
    }
    function dropProject(project) {
        localStorage.removeItem(projectPrefix + project.id)
    }

    function getLocalFile(maybeProjectId, maybeSourceId, file) {
        const reader = new FileReader()
        reader.onload = e => sendToElm({
            kind: 'GotLocalFile',
            now: Date.now(),
            projectId: maybeProjectId || randomUID(),
            sourceId: maybeSourceId || randomUID(),
            file, content: e.target.result
        })
        reader.readAsText(file)
    }

    function getRemoteFile(maybeProjectId, maybeSourceId, url, sample) {
        fetch(url)
            .then(res => res.text())
            .then(content => sendToElm({
                kind: 'GotRemoteFile',
                now: Date.now(),
                projectId: maybeProjectId || randomUID(),
                sourceId: maybeSourceId || randomUID(),
                url,
                content,
                sample
            }))
            .catch(err => showToast({kind: 'error', message: err}))
    }

    const resizeObserver = new ResizeObserver(entries => {
        const sizes = entries.map(entry => ({
            id: entry.target.id,
            position: {
                left: entry.target.offsetLeft,
                top: entry.target.offsetTop
            },
            size: {
                width: entry.contentRect.width,
                height: entry.contentRect.height
            }
        }))
        sendToElm({kind: 'GotSizes', sizes: sizes})
    })
    function observeSizes(ids) {
        ids.flatMap(maybeElementById).forEach(elt => resizeObserver.observe(elt))
    }

    const hotkeys = {}
    // keydown is needed for preventDefault, also can't use Elm Browser.Events.onKeyUp because of it
    document.addEventListener('keydown', e => {
        Object.entries(hotkeys).forEach(([id, alternatives]) => {
            alternatives.forEach(hotkey => {
                if ((!hotkey.key || hotkey.key === e.key) &&
                    (!hotkey.ctrl || e.ctrlKey) &&
                    (!hotkey.shift || e.shiftKey) &&
                    (!hotkey.alt || e.altKey) &&
                    (!hotkey.meta || e.metaKey) &&
                    ((!hotkey.target && (hotkey.onInput || e.target.localName !== 'input')) || (hotkey.target &&
                        (!hotkey.target.id || hotkey.target.id === e.target.id) &&
                        (!hotkey.target.class || e.target.className.split(' ').includes(hotkey.target.class)) &&
                        (!hotkey.target.tag || hotkey.target.tag === e.target.localName)))) {
                    if (hotkey.preventDefault) {
                        e.preventDefault()
                    }
                    sendToElm({kind: 'GotHotkey', id: id})
                }
            })
        })
    })
    function listenHotkeys(keys) {
        Object.assign(hotkeys, keys)
    }

    // listen at every click to handle tracked events
    document.addEventListener('click', event => {
        const tracked = findParent(event.target, e => e.getAttribute('data-track-event'))
        if (tracked) {
            const eventName = tracked.getAttribute('data-track-event')
            const details = {label: tracked.textContent.trim()}
            for (const attr of event.target.attributes) {
                if (attr.name.startsWith('data-track-event-')) {
                    details[attr.name.replace('data-track-event-', '')] = attr.value
                }
            }
            analytics.then(a => a.trackEvent(eventName, details))
        }
    })


    /* Tracking */

    function initAnalytics(shouldTrack) {
        if (shouldTrack) {
            const waitSplitbee = (resolve, reject, timeout) => {
                if (timeout <= 0) {
                    reject()
                } else if (splitbee) {
                    resolve({
                        trackPage: name => { /* automatically tracked, do nothing */ },
                        trackEvent: (name, details) => { splitbee.track(name, details) },
                        trackError: (name, details) => { /* don't track errors in splitbee */ }
                    })
                } else {
                    setTimeout(() => {
                        waitSplitbee(resolve, reject, timeout - 100)
                    }, 100)
                }
            }
            return new Promise((resolve, reject) => waitSplitbee(resolve, reject, 3000))
        } else {
            return Promise.resolve({
                trackPage: name => console.log('analytics.page', name),
                trackEvent: (name, details) => console.log('analytics.event', name, details),
                trackError: (name, details) => console.log('analytics.error', name, details)
            })
        }
    }

    function initErrorTracking(shouldTrack) {
        if (shouldTrack) {
            // see https://sentry.io
            // initial: https://js.sentry-cdn.com/268b122ecafb4f20b6316b87246e509c.min.js
            return loadScript('/assets/sentry-268b122ecafb4f20b6316b87246e509c.min.js').then(() => ({
                trackError: (name, details) => Sentry.captureException(new Error(JSON.stringify({name, ...details})))
            }))
        } else {
            return Promise.resolve({
                trackError: (name, details) => console.log('error.track', name, details)
            })
        }
    }


    /* Bootstrap helpers */

    // hide tooltip on click (avoid orphan tooltips when element is removed)
    // cf https://getbootstrap.com/docs/5.0/components/tooltips/: "Tooltips must be hidden before their corresponding elements have been removed from the DOM."
    let currentTooltip = null
    window.addEventListener('show.bs.tooltip', e => {
        currentTooltip = e.target
    })
    window.addEventListener('click', () => {
        currentTooltip && bootstrap && bootstrap.Tooltip.getOrCreateInstance(currentTooltip).hide()
    })
    // autofocus element in modal that require it (not done automatically)
    // cd https://getbootstrap.com/docs/5.0/components/modal/: "Due to how HTML5 defines its semantics, the autofocus HTML attribute has no effect in Bootstrap modals."
    window.addEventListener('shown.bs.modal', e => {
        const input = e.target.querySelector('[autofocus]')
        input && input.focus()
        activateTooltipsAndPopovers()
    })
    window.addEventListener('hidden.bs.toast', e => {
        const toast = getElementById(e.target.id)
        toast.parentNode.removeChild(toast)
    })


    /* Autocomplete hacks, this is more than ugly and also very fragile, should find better ways to handle autocomplete!!! */

    // when the search is focused, the dropdown should be open:
    //  - prevent closing it if search input is still active
    //  - open it when search input is focused
    //  - close it when search input is blurred
    window.addEventListener('hide.bs.dropdown', e => {
        if(e.target.id === 'search' && e.target === document.activeElement) {
            e.preventDefault()
        }
    })
    window.addEventListener('focusin', e => {
        if (e.target.id === 'search') { bootstrap && setTimeout(() => bootstrap.Dropdown.getOrCreateInstance(e.target).show(), 10) }
    })
    window.addEventListener('focusout', e => {
        if (e.target.id === 'search') { bootstrap && setTimeout(() => bootstrap.Dropdown.getOrCreateInstance(e.target).hide(), 10) }
    })
    // search input parent is the dropdown element, on mousedown it's blurred but we want that only on click
    window.addEventListener('mousedown', e => {
        const parents = getParents(e.target)
        const dropdown = parents.find(e => e.className === 'dropdown')
        const search = Array.from(dropdown?.children || []).find(e => e.id === 'search')
        if (search) {
            setTimeout(() => search.focus(), 10)
        }
    })
    // the second node inside the dropdown element is the dropdown menu, we want to blur the search on click
    window.addEventListener('click', e => {
        const parents = getParents(e.target)
        const dropdown = parents.find(e => e.className === 'dropdown')
        const search = Array.from(dropdown?.children || []).find(e => e.id === 'search')
        if (search && parents.find(e => e.className && e.className.includes('dropdown-menu'))) {
            search.blur()
        }
    })
    // blur search when esc key is pressed, doesn't work :(
    window.addEventListener('keydown', e => {
        const parents = getParents(e.target)
        const dropdown = parents.find(e => e.className === 'dropdown')
        const search = Array.from(dropdown?.children || []).find(e => e.id === 'search')
        if (search && e.keyCode === 27) {
            search.blur()
        }
    })
    // do not submit search form on enter
    window.addEventListener('submit', e => {
        if (e.target[0].id === 'search') {
            e.preventDefault()
        }
    })


    /* Libs */

    function getElementById(id) {
        const elem = document.getElementById(id)
        if (elem) {
            return elem
        } else {
            throw new Error(`Can't find element with id '${id}'`)
        }
    }

    function maybeElementById(id) {
        const elem = document.getElementById(id)
        return elem ? [elem] : []
    }

    function getParents(elt) {
        const parents = [elt]
        let parent = elt.parentElement
        while (parent) {
            parents.push(parent)
            parent = parent.parentElement
        }
        return parents
    }

    function findParent(elt, predicate) {
        if (predicate(elt)) {
            return elt
        } else if (elt.parentElement) {
            return findParent(elt.parentElement, predicate)
        } else {
            return undefined
        }
    }

    function randomUID() {
        return uuidv4() // TODO replace with https://github.com/ai/nanoid
    }

    function loadScript(url) {
        return new Promise((resolve, reject) => {
            const script = document.createElement('script')
            script.src = url
            script.type='text/javascript'
            script.addEventListener('load', resolve)
            script.addEventListener('error', reject)
            document.getElementsByTagName('head')[0].appendChild(script)
        })
    }

    /* polyfills */

    // https://developer.mozilla.org/fr/docs/Web/JavaScript/Reference/Global_Objects/String/includes
    if (!String.prototype.includes) {
        String.prototype.includes = function(search, start) {
            'use strict';
            if (search instanceof RegExp) {
                throw TypeError('first argument must not be a RegExp');
            }
            if (start === undefined) { start = 0; }
            return this.indexOf(search, start) !== -1;
        };
    }
})
