import vscode, {TextDocument} from "vscode";

/*async function openFileResult(res: ParserResult<{lang: string, content: string}>): Promise<TextDocument | undefined> {
    const error = formatErrors(res.errors)
    const file = res.result
    if (file) {
        error && vscode.window.showWarningMessage(error)
        return await openFile(file.lang, file.content)
    } else {
        error && vscode.window.showErrorMessage(error)
    }
}*/

export async function openFile(language: string, content: string): Promise<TextDocument> {
    const doc: TextDocument = await vscode.workspace.openTextDocument({language, content})
    await vscode.window.showTextDocument(doc)
    return doc
}

/*function formatErrors(errors: ParserError[] | undefined): string | undefined {
    if (errors && errors.length > 1) {
        return `Got ${errors.length} AML parsing issues:${errors.map(e => `\n- ${formatErrorLevel(e.level)} ${e.message}`).join('')}`
    } else if (errors && errors.length === 1) {
        const error = errors[0]
        return `AML parsing ${error.level}: ${error.message}`
    } else {
        return undefined
    }
}

function formatErrorLevel(level: ParserErrorLevel): string {
    switch (level) {
        case 'error': return '[ERR] '
        case 'warning': return '[WARN]'
        case 'info': return '[INFO]'
        case 'hint': return '[HINT]'
        default: return '[ERR] '
    }
}*/

type Timeout = ReturnType<typeof setTimeout>
export function debounce<F extends (...args: Parameters<F>) => ReturnType<F>>(
    func: F,
    delay: number
): (...args: Parameters<F>) => void {
    let timeout: Timeout
    return (...args: Parameters<F>): void => {
        clearTimeout(timeout)
        timeout = setTimeout(() => func(...args), delay)
    }
}
