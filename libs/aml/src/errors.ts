import {ParserError, TokenPosition} from "@azimutt/models";
import {TokenIssue} from "./ast";

export const legacy = (message: string): TokenIssue => ({name: 'LegacySyntax', kind: 'warning', message})

export const duplicated = (name: string, line: number | undefined, position: TokenPosition): ParserError =>
    ({name: 'Duplicated', kind: 'warning', message: `${name} already defined${line !== undefined ? ` at line ${line}` : ''}`, offset: position.offset, position: position.position})
