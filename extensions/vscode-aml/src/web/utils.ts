import vscode, {Position, Range, TextDocument} from "vscode";
import {Database, EditorPosition, ParserError, ParserErrorLevel, ParserResult, TokenEditor} from "@azimutt/models";

export async function openFileResult(res: ParserResult<Database>, transform: (db: Database) => Promise<{lang: string, content: string}>): Promise<TextDocument | undefined> {
    const error = formatErrors(res.errors)
    const db = res.result
    if (db) {
        error && vscode.window.showWarningMessage(error)
        const file = await transform(db)
        return await openFile(file.lang, file.content)
    } else {
        error && vscode.window.showErrorMessage(error)
    }
}

export async function openFile(language: string, content: string): Promise<TextDocument> {
    const doc: TextDocument = await vscode.workspace.openTextDocument({language, content})
    await vscode.window.showTextDocument(doc)
    return doc
}

export function formatErrors(errors: ParserError[] | undefined): string | undefined {
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
}

// convert types

export function positionToAml(position: Position): EditorPosition {
    return {line: position.line + 1, column: position.character + 1}
}
export function tokenToRange(position: TokenEditor): Range {
    return new Range(position.start.line - 1, position.start.column - 1, position.end.line - 1, position.end.column)
}

// utils

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
