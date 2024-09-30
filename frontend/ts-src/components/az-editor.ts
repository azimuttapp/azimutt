// https://github.com/elm-community/js-integration-examples/blob/master/more/webcomponents/README.md

export function loadAzEditor(): void {
    customElements.define('az-editor', AzEditor)
}

class AzEditor extends HTMLElement {
    private textarea: HTMLTextAreaElement
    private counter: HTMLSpanElement

    constructor() {
        super()
        this.attachShadow({ mode: 'open' })

        const style = document.createElement('style')
        style.textContent = `
            :host {
                display: inline-block;
            }
            textarea {
                width: 100%;
                resize: vertical;
            }
            .counter {
                display: block;
                text-align: right;
                font-size: 0.8em;
                color: #666;
            }
        `

        this.textarea = document.createElement('textarea')
        this.counter = document.createElement('span')
        this.counter.className = 'counter'

        this.shadowRoot?.appendChild(style)
        this.shadowRoot?.appendChild(this.textarea)
        this.shadowRoot?.appendChild(this.counter)
    }

    connectedCallback() { // component added to the DOM
        console.log('AzEditor.connectedCallback')
        this.updateCounter()
        this.textarea.addEventListener('input', this.updateCounter.bind(this))
    }

    disconnectedCallback() { // component removed from the DOM
        console.log('AzEditor.disconnectedCallback')
        this.textarea.removeEventListener('input', this.updateCounter.bind(this))
    }

    static get observedAttributes() {
        // id, class
        return ['value', 'readonly', 'disabled']
    }

    attributeChangedCallback(name: string, oldValue: string, newValue: string) {
        if (name === 'value') {
            this.textarea.value = newValue
            this.updateCounter()
        } else {
            this.textarea.setAttribute(name, newValue)
        }
    }

    private updateCounter() {
        this.counter.textContent = `${this.textarea.value.length}`
    }
}
