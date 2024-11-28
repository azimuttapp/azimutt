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

const SQL_DIALECTS = ['PostgreSQL'] as const
type SQLDialect = typeof SQL_DIALECTS[number]

export async function convertSqlToAml(editor: TextEditor): Promise<void> {
    if (editor.document.languageId !== 'sql') {
        vscode.window.showErrorMessage('Needs SQL file to convert it to AML.')
        return
    }

    const dialect = await vscode.window.showQuickPick(SQL_DIALECTS, {placeHolder: 'Select source language'}) as SQLDialect
    if (dialect === 'PostgreSQL') {
        await openFileResult(await parsePostgres(editor.document.getText()), async db => ({lang: 'aml', content: await generateAml(db)}))
    } else {
        vscode.window.showWarningMessage(`Unable to convert SQL to AML: unsupported ${dialect} dialect.`)
    }
}

const EXPORT_DIALECTS = ['PostgreSQL', 'JSON', 'DOT', 'Mermaid', 'Markdown'] as const
type ExportDialect = typeof EXPORT_DIALECTS[number]

export async function convertAmlToDialect(editor: TextEditor): Promise<void> {
    if (editor.document.languageId !== 'aml') {
        vscode.window.showErrorMessage('Needs AML file to convert AML to another language.')
        return
    }

    const dialect = await vscode.window.showQuickPick(EXPORT_DIALECTS, {placeHolder: 'Select target format'}) as ExportDialect
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
