// import "monaco-editor/esm/vs/editor/standalone/browser/...";
// import "monaco-editor/esm/vs/basic-languages/sql/sql.contribution.js";
// export * from "monaco-editor/esm/vs/editor/editor.api";

import "monaco-editor/esm/vs/editor/editor.all";

import "monaco-editor/esm/vs/editor/standalone/browser/inspectTokens/inspectTokens";
import "monaco-editor/esm/vs/editor/standalone/browser/iPadShowKeyboard/iPadShowKeyboard";
import "monaco-editor/esm/vs/editor/standalone/browser/quickAccess/standaloneCommandsQuickAccess";
import "monaco-editor/esm/vs/editor/standalone/browser/quickAccess/standaloneGotoLineQuickAccess";
import "monaco-editor/esm/vs/editor/standalone/browser/quickAccess/standaloneGotoSymbolQuickAccess";
import "monaco-editor/esm/vs/editor/standalone/browser/quickAccess/standaloneHelpQuickAccess";
import "monaco-editor/esm/vs/editor/standalone/browser/referenceSearch/standaloneReferenceSearch";

import "monaco-editor/esm/vs/basic-languages/mysql/mysql.contribution";
import "monaco-editor/esm/vs/basic-languages/pgsql/pgsql.contribution";
import "monaco-editor/esm/vs/basic-languages/sql/sql.contribution";

import * as monaco from "monaco-editor/esm/vs/editor/editor.api";

// examples: https://microsoft.github.io/monaco-editor/playground.html?source=v0.47.0#example-creating-the-editor-hello-world
export class AzimuttEditor extends HTMLElement {
    constructor() {
        super();
        const shadow = this.attachShadow({mode: 'open'})
        const container = document.createElement("div");
        container.style.height = "60dvh";
        shadow.appendChild(container);

        monaco.editor.create(container, {
            value: "SELECT * FROM toto",
            language: "sql",
            theme: "vs-dark",
            automaticLayout: true,
            lineNumbersMinChars: 3,
            mouseWheelZoom: true,
        });
    }
}
customElements.define("azimutt-editor", AzimuttEditor);
