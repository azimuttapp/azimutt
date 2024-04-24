import {ParserPosition} from "@azimutt/models";

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

export type UnaryOperatorAst = {operator: 'NOT'}
export type UnaryExpressionAst = {operator: UnaryOperatorAst, expression: ExpressionAst}
export type BinaryOperatorAst = {operator: 'AND' | 'OR'}
export type BinaryExpressionAst = {left: ExpressionAst, operator: BinaryOperatorAst, right: ExpressionAst}
export type GroupExpressionAst = {group: ExpressionAst}
export type ExpressionAst = ConditionAst | BinaryExpressionAst | UnaryExpressionAst | GroupExpressionAst

export type TokenInfo = {token: string, offset: ParserPosition, line: ParserPosition, column: ParserPosition}
