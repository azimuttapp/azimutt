import vscode, {TextEditor} from "vscode";
import {
    generateAml,
    generateDot,
    generateJson,
    generateMarkdown,
    generateMermaid,
    generatePostgres,
    parseAml,
    parseJson,
    parsePostgres
} from "./aml";
import {formatErrors, openFile, openFileResult} from "./utils";

export async function convertJsonToAml(editor: TextEditor): Promise<void> {
    if (editor.document.languageId !== 'json') {
        vscode.window.showErrorMessage('Needs JSON file to convert it to AML.')
        return
    }

    await openFileResult(await parseJson(editor.document.getText()), async db => ({lang: 'aml', content: await generateAml(db)}))
}

export async function convertSqlToAml(editor: TextEditor): Promise<void> {
    if (editor.document.languageId !== 'sql') {
        vscode.window.showErrorMessage('Needs SQL file to convert it to AML.')
        return
    }

    const dialects = ['PostgreSQL']
    const dialect = await vscode.window.showQuickPick(dialects, {placeHolder: 'Select target'})
    if (dialect === 'PostgreSQL') {
        await openFileResult(await parsePostgres(editor.document.getText()), async db => ({lang: 'aml', content: await generateAml(db)}))
    } else {
        vscode.window.showWarningMessage(`Unable to convert SQL to AML: unsupported ${dialect} dialect.`)
    }
}

export async function convertAmlToDialect(editor: TextEditor): Promise<void> {
    if (editor.document.languageId !== 'aml') {
        vscode.window.showErrorMessage('Needs AML file to convert AML to another language.')
        return
    }

    const dialects = ['PostgreSQL', 'JSON', 'DOT', 'Mermaid', 'Markdown']
    const dialect = await vscode.window.showQuickPick(dialects, {placeHolder: 'Select target'})
    const res = await parseAml(editor.document.getText())
    const error = formatErrors(res.errors)
    const db = res.result

    if (db) {
        error && vscode.window.showWarningMessage(error)
        if (dialect === 'JSON') {
            await openFile('json', await generateJson(db))
        } else if (dialect === 'DOT') {
            await openFile('dot', await generateDot(db))
        } else if (dialect === 'Mermaid') {
            await openFile('mermaid', await generateMermaid(db))
        } else if (dialect === 'Markdown') {
            await openFile('markdown', await generateMarkdown(db))
        } else if (dialect === 'PostgreSQL') {
            await openFile('sql', await generatePostgres(db))
        } else {
            vscode.window.showWarningMessage(`Unable to convert AML to ${dialect}: unsupported dialect.`)
        }
    } else {
        error && vscode.window.showErrorMessage(error)
    }
}
