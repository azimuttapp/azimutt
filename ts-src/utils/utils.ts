import {Env, HtmlId} from "../types/basics";
import confetti from "canvas-confetti";

export const Utils = {
    getEnv(): Env {
        return window.location.hostname === 'localhost' ? 'dev' :
            window.location.hostname === 'azimutt.app' ? 'prod' :
                'staging'
    },
    randomUID() {
        return window.uuidv4()
    },
    getElementById(id: HtmlId): HTMLElement {
        const elem = document.getElementById(id)
        if (elem) {
            return elem
        } else {
            throw new Error(`Can't find element with id '${id}'`)
        }
    },
    maybeElementById(id: HtmlId): HTMLElement[] {
        const elem = document.getElementById(id)
        return elem ? [elem] : []
    },
    getParents(elt: HTMLElement): HTMLElement[] {
        const parents = [elt]
        let parent = elt.parentElement
        while (parent) {
            parents.push(parent)
            parent = parent.parentElement
        }
        return parents
    },
    findParent(elt: HTMLElement, predicate: (e: HTMLElement) => boolean): HTMLElement | undefined {
        if (predicate(elt)) {
            return elt
        } else if (elt.parentElement) {
            return Utils.findParent(elt.parentElement, predicate)
        } else {
            return undefined
        }
    },
    fullscreen(id: HtmlId | undefined) {
        const element = id ? Utils.getElementById(id) : document.body
        const result = element.requestFullscreen ? element.requestFullscreen() : Promise.reject(new Error('requestFullscreen not available'))
        result.catch(_ => window.open(window.location.href, '_blank')?.focus()) // if full-screen is denied, open in a new tab
    },
    downloadFile(filename: string, content: string) {
        const element = document.createElement('a')
        element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(content))
        element.setAttribute('download', filename)

        element.style.display = 'none'
        document.body.appendChild(element)

        element.click()

        document.body.removeChild(element)
    },
    launchConfetti(id: string): void {
        const elt = document.getElementById(id) as HTMLElement
        if (!elt) {
            console.warn(`Didn't found ${id} to launch confetti`)
            return
        }

        const rect = elt.getBoundingClientRect()
        const left = (rect.left + rect.right) / 2
        const top = 50 + (rect.top + rect.bottom) / 2
        confetti({
            particleCount: 100,
            spread: 70,
            origin: {x: left / window.innerWidth, y: top / window.innerHeight},
            disableForReducedMotion: true
        });
    },
    launchConfettiPride(): void {
        const end = Date.now() + (3 * 1000);
        const colors = ['#28BEC9', '#0C4F9C'];

        (function frame() {
            confetti({
                particleCount: 2,
                angle: 60,
                spread: 55,
                origin: { x: 0 },
                colors: colors,
                zIndex: 20000
            });
            confetti({
                particleCount: 2,
                angle: 120,
                spread: 55,
                origin: { x: 1 },
                colors: colors,
                zIndex: 20000
            });

            if (Date.now() < end) {
                requestAnimationFrame(frame);
            }
        }());
    }
}
