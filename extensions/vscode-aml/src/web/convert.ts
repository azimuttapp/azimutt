import vscode, {TextEditor} from "vscode";

export async function convertJsonToAml(editor: TextEditor): Promise<void> {
    if (editor.document.languageId !== 'json') {
        vscode.window.showErrorMessage('Needs JSON file to convert it to AML.')
        return
    }

    vscode.window.showInformationMessage('JSON to AML conversion not implemented yet, work in progress...')
    // FIXME: await openFileResult(parseJsonDatabase(editor.document.getText()).map((db: Database) => ({lang: 'aml', content: generateAml(db)})))
}

export async function convertSqlToAml(editor: TextEditor): Promise<void> {
    if (editor.document.languageId !== 'sql') {
        vscode.window.showErrorMessage('Needs SQL file to convert it to AML.')
        return
    }

    const dialects = ['PostgreSQL']
    const dialect = await vscode.window.showQuickPick(dialects, {placeHolder: 'Select target'})
    if (dialect === 'PostgreSQL') {
        vscode.window.showInformationMessage('SQL to AML conversion not implemented yet, work in progress...')
        // FIXME: await openFileResult(parseSql(editor.document.getText(), 'postgres').map((db: Database) => ({lang: 'aml', content: generateAml(db)})))
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
    vscode.window.showInformationMessage(`AML to ${dialect} conversion not implemented yet, work in progress...`)
    /* FIXME: const res = parseAml(editor.document.getText())
    const error = formatErrors(res.errors)
    const db = res.result

    if (db) {
        error && vscode.window.showWarningMessage(error)
        if (dialect === 'JSON') {
            await openFile('json', generateJsonDatabase(db))
        } else if (dialect === 'DOT') {
            await openFile('dot', generateDot(db))
        } else if (dialect === 'Mermaid') {
            await openFile('mermaid', generateMermaid(db))
        } else if (dialect === 'Markdown') {
            await openFile('markdown', generateMarkdown(db))
        } else if (dialect === 'PostgreSQL') {
            await openFile('sql', generateSql(db, 'postgres'))
        } else {
            vscode.window.showWarningMessage(`Unable to convert AML to ${dialect}: unsupported dialect.`)
        }
    } else {
        error && vscode.window.showErrorMessage(error)
    }*/
}
