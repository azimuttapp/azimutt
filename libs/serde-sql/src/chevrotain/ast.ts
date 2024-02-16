export type SqlScriptAst = StatementAst[]
export type StatementAst = SelectAst

export type SelectAst = {command: 'SELECT', result: SelectResultAst, from: SelectFromAst, where?: SelectWhereAst}
export type SelectResultAst = {columns: SelectColumnAst[]}
export type SelectColumnAst = (ColumnRefAst | SelectColumnWildcardAst) & {alias?: IdentifierAst}
export type SelectColumnWildcardAst = {column: WildcardAst, table?: IdentifierAst, schema?: IdentifierAst}
export type SelectFromAst = TableRefAst & {alias?: IdentifierAst}
export type SelectWhereAst = ConditionAst

export type IntegerAst = {value: number, parser: TokenInfo}
export type StringAst = {value: string, parser: TokenInfo}
export type BooleanAst = {value: boolean, parser: TokenInfo}
export type IdentifierAst = {identifier: string, parser: TokenInfo}
export type TableRefAst = {table: IdentifierAst, schema?: IdentifierAst}
export type ColumnRefAst = {column: IdentifierAst, table?: IdentifierAst, schema?: IdentifierAst}
export type WildcardAst = {wildcard: '*', parser: TokenInfo}
export type ConditionOpAst = {operator: '=' | '!=' | '<' | '>', parser: TokenInfo}
export type ConditionElemAst = IntegerAst | StringAst | BooleanAst | ColumnRefAst
export type ConditionAst = {left: ConditionElemAst, operation: ConditionOpAst, right?: ConditionElemAst}
export type BooleanOperationAst = {left: ConditionAst, rights: {operation: 'AND' | 'OR', condition: ConditionAst}[]}

export type TokenInfo = {token: string, offset: Position, line: Position, column: Position}
export type ParserResult<T> = {
    result?: T
    errors?: ParserError[]
    warnings?: ParserError[]
}
export type ParserError = {kind: string, message: string, offset: Position, line: Position, column: Position}
export type Position = [number, number]
