import {ParserError, ParserErrorLevel, TokenPosition} from "@azimutt/models";
import {TokenIssue} from "./amlAst";

export const legacy = (message: string): TokenIssue => ({message, kind: 'LegacySyntax', level: ParserErrorLevel.enum.warning})

export const duplicated = (name: string, definedAtLine: number | undefined, position: TokenPosition): ParserError =>
    ({message: `${name} already defined${definedAtLine !== undefined ? ` at line ${definedAtLine}` : ''}`, kind: 'Duplicated', level: ParserErrorLevel.enum.warning, offset: position.offset, position: position.position})

export const badIndent = (expectedDepth: number, actualDepth: number): TokenIssue =>
    ({message: `Expecting indentation of ${expectedDepth} but got ${actualDepth}`, kind: 'WrongIndentation', level: ParserErrorLevel.enum.error})
