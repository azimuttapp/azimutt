// https://github.com/elm-community/js-integration-examples/blob/master/more/webcomponents/README.md

export function loadElmTextarea(): void {
    customElements.define('elm-textarea', ElmTextarea)
}

class ElmTextarea extends HTMLElement {
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
        console.log('ElmTextarea.connectedCallback')
        const value = this.getAttribute('value') || ''
        console.log('connectedCallback.value', value)
        this.textarea.value = value // value is empty here, not sure why as it should have a value from the start (cf frontend/src/PagesComponents/Organization_/Project_/Components/AmlSidebar.elm:308)
        this.updateCounter()
        this.textarea.addEventListener('input', this.updateCounter.bind(this))
    }

    disconnectedCallback() { // component removed from the DOM
        console.log('ElmTextarea.disconnectedCallback')
        this.textarea.removeEventListener('input', this.updateCounter.bind(this))
    }

    static get observedAttributes() {
        // id, class
        return ['value', 'readonly', 'disabled']
    }

    attributeChangedCallback(name: string, oldValue: string, newValue: string) { // can't see this function triggered :/
        console.log('ElmTextarea.attributeChangedCallback', name, newValue, this.getAttribute('value') || '')
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
