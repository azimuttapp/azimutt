/*import * as monaco from "monaco-editor";

// https://github.com/elm-community/js-integration-examples/blob/master/more/webcomponents/README.md

export function loadElmMonaco(): void {
    customElements.define('elm-monaco', ElmMonaco)
}

class ElmMonaco extends HTMLElement {
    private container: HTMLDivElement
    private editor: monaco.editor.IStandaloneCodeEditor | undefined

    constructor() {
        super()
        this.attachShadow({ mode: 'open' })

        this.container = document.createElement('div')
        this.container.style.width = '100%'
        this.container.style.height = '500px'

        this.shadowRoot?.appendChild(this.container)
    }

    connectedCallback() { // component added to the DOM
        console.log('ElmMonaco.connectedCallback')
        console.log('create monaco editor')
        this.editor = monaco.editor.create(this.container, {
            automaticLayout: true,
            language: 'html',
            value: `<div>Hello World</div>`,
        });
        (window as any).editor = this.editor
        console.log('monaco editor created')
    }

    disconnectedCallback() { // component removed from the DOM
        console.log('ElmMonaco.disconnectedCallback')
        this.editor?.dispose()
    }

    static get observedAttributes() {
        // id, class
        return ['value', 'readonly', 'disabled']
    }

    attributeChangedCallback(name: string, oldValue: string, newValue: string) {
        console.log('ElmMonaco.attributeChangedCallback', name, newValue)
    }
}
*/
