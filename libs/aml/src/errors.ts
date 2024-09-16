import {ParserError, TokenPosition} from "@azimutt/models";
import {TokenIssue} from "./ast";

export const legacy = (message: string): TokenIssue => ({name: 'LegacySyntax', kind: 'warning', message})

export const duplicated = (name: string, definedAtLine: number | undefined, position: TokenPosition): ParserError =>
    ({name: 'Duplicated', kind: 'warning', message: `${name} already defined${definedAtLine !== undefined ? ` at line ${definedAtLine}` : ''}`, offset: position.offset, position: position.position})

export const badIndent = (expectedDepth: number, actualDepth: number): TokenIssue =>
    ({name: 'WrongIndentation', kind: 'error', message: `Expecting indentation of ${expectedDepth} but got ${actualDepth}`})
