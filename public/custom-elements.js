// polyfills: https://github.com/webcomponents/polyfills/tree/master/packages/webcomponentsjs
// tuto: https://korban.net/posts/elm/2018-09-17-introduction-custom-elements-shadow-dom/
window.addEventListener('load', function() {
    customElements.define('az-editor', class extends HTMLElement {
        editor = null

        constructor() {
            super()
        }
        static get observedAttributes() { return ['value', 'language', 'theme'] }
        attributeChangedCallback(name, oldValue, newValue) {
            if (this.editor) {
                if (name === 'value' && newValue !== this.value) { this.value = newValue }
            }
        }

        connectedCallback() {
            const value = this.hasAttribute('value') ? this.getAttribute('value') : ''
            const language = this.hasAttribute('language') ? this.getAttribute('language') : ''
            const theme = this.hasAttribute('theme') ? this.getAttribute('theme') : ''

            const shadowRoot = this.attachShadow({mode: 'open'})
            shadowRoot.innerHTML = `<div class="monaco-editor" style="width: 800px; height: 300px; border: 1px solid grey; position: relative"></div>`
            const editor = this.shadowRoot.querySelector(".monaco-editor")

            require.config({ paths: { vs: '/assets/vs' } })
            require(['vs/editor/editor.main'], () => {
                this.editor = monaco.editor.create(editor, { value, language })
                this.editor.getModel().onDidChangeContent(e => {
                    this.dispatchEvent(new CustomEvent('input', {detail: this.value}))
                })
            })
        }

        get value() { return this.editor ? this.editor.value : '' }
        set value(val) { this.editor.setValue(val) }
    })

    customElements.define('az-editor-1', class extends HTMLElement {
        constructor() {
            super()
            let shadowRoot = this.attachShadow({mode: 'open'})
            const value = this.hasAttribute('value') ? this.getAttribute('value') : ''
            const language = this.hasAttribute('language') ? this.getAttribute('language') : ''
            const theme = this.hasAttribute('theme') ? this.getAttribute('theme') : ''

            shadowRoot.innerHTML = `
                <style>
                    :host {
                        border: 2px solid #2f4858; border-radius: 3px;
                        background-color: #f0fff0;
                        display: block;
                        padding: 3px;
                        margin: 10px;
                    }
                    .toolbar { height: 20px; border-bottom: 1px solid #2f4858 }
                    .content { color: #33658a; padding-top: 3px; }
                </style>
                <div class="toolbar">
                    <strong>B</strong>&nbsp;
                    <em>I</em>&nbsp;
                    <span style="text-decoration: underline">U</span>
                </div>
                <textarea class="content" rows="5" cols="33">${value}</textarea>`
            this.textarea = this.shadowRoot.querySelector("textarea")
            this.textarea.addEventListener('input', () => this.dispatchEvent(new CustomEvent('input', {detail: this.value})))
        }
        static get observedAttributes() { return ['value', 'language', 'theme'] }
        attributeChangedCallback(name, oldValue, newValue) {
            if (name === 'value' && newValue !== this.value) { this.value = newValue }
        }

        get value() { return this.textarea.value }
        set value(val) { this.textarea.value = val }
    })
})
