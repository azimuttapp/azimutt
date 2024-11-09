import {ParserError, ParserErrorLevel, TokenPosition} from "@azimutt/models";

export const duplicated = (name: string, definedAtLine: number | undefined, position: TokenPosition): ParserError =>
    ({message: `${name} already defined${definedAtLine !== undefined ? ` at line ${definedAtLine}` : ''}`, kind: 'Duplicated', level: ParserErrorLevel.enum.warning, offset: position.offset, position: position.position})
