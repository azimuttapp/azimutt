import {ParserErrorLevel, TokenPosition} from "@azimutt/models";

/**
 * Conventions:
 * - use `kind` attribute for discriminated unions or enum values
 * - use `value` attribute for the actual source value
 * - keep all token positions
 * - statement positions are start/end, all other positions are the specific token
 */

// statements
export type StatementsAst = { statements: StatementAst[] }
export type StatementAst = SelectStatementAst | CreateTableStatementAst | DropStatementAst
export type SelectStatementAst = { statement: 'Select', select: SelectClauseAst, from?: FromClauseAst, where?: WhereClauseAst } & TokenInfo
export type CreateTableStatementAst = { statement: 'CreateTable', name: TableAst, columns: TableColumnAst[], constraints?: TableConstraintAst[] }
export type DropStatementAst = { statement: 'Drop', kind: { kind: 'Table' | 'View' | 'MaterializedView' | 'Index' | 'Type' } & TokenInfo, entities: TableAst[], concurrently?: TokenInfo, ifExists?: TokenInfo, mode?: { kind: 'Cascade' | 'Restrict' } & TokenInfo } & TokenInfo
export type SetStatementAst = { statement: 'Set', scope?: { kind: 'Session' | 'Local' } & TokenInfo, parameter: IdentifierAst, equal: { kind: '=' | 'To' } & TokenInfo, value: SetValueAst } & TokenInfo

// clauses
export type SelectClauseAst = { expressions: SelectClauseExprAst[] } & TokenInfo
export type SelectClauseExprAst = ExpressionAst & { alias?: AliasAst }
export type FromClauseAst = { table: IdentifierAst, alias?: AliasAst } & TokenInfo
export type WhereClauseAst = { condition: ConditionAst } & TokenInfo
export type TableColumnAst = { name: IdentifierAst, type: IdentifierAst, constraints?: TableColumnConstraintAst[] }
export type TableColumnConstraintAst = TableColumnNullableAst | TableColumnDefaultAst | TableColumnPkAst | TableColumnUniqueAst | TableColumnCheckAst | TableColumnFkAst
export type TableColumnNullableAst = { kind: 'Nullable', value: boolean } & ConstraintCommonAst
export type TableColumnDefaultAst = { kind: 'Default', expression: ExpressionAst } & ConstraintCommonAst
export type TableColumnPkAst = { kind: 'PrimaryKey' } & ConstraintCommonAst
export type TableColumnUniqueAst = { kind: 'Unique' } & ConstraintCommonAst
export type TableColumnCheckAst = { kind: 'Check', predicate: ConditionAst } & ConstraintCommonAst
export type TableColumnFkAst = { kind: 'ForeignKey', schema?: IdentifierAst, table: IdentifierAst, column?: IdentifierAst, onUpdate?: ForeignKeyActionAst & TokenInfo, onDelete?: ForeignKeyActionAst & TokenInfo } & ConstraintCommonAst
export type TableConstraintAst = TablePkAst | TableUniqueAst | TableCheckAst | TableFkAst
export type TablePkAst = { kind: 'PrimaryKey', columns: IdentifierAst[] } & ConstraintCommonAst
export type TableUniqueAst = { kind: 'Unique', columns: IdentifierAst[] } & ConstraintCommonAst
export type TableCheckAst = { kind: 'Check', predicate: ConditionAst } & ConstraintCommonAst
export type TableFkAst = { kind: 'ForeignKey', columns: IdentifierAst[], ref: {schema?: IdentifierAst, table: IdentifierAst, columns?: IdentifierAst[]} & TokenInfo, onUpdate?: ForeignKeyActionAst & TokenInfo, onDelete?: ForeignKeyActionAst & TokenInfo } & ConstraintCommonAst
export type ConstraintCommonAst = { constraint?: ConstraintNameAst } & TokenInfo
export type ConstraintNameAst = { name: IdentifierAst } & TokenInfo
export type ForeignKeyActionAst = {action: {kind: 'NoAction' | 'Restrict' | 'Cascade' | 'SetNull' | 'SetDefault'} & TokenInfo, columns?: IdentifierAst[]}
export type SetValueAst = IdentifierAst | LiteralAst | (IdentifierAst | LiteralAst)[] | { kind: 'Default' } & TokenInfo

// basic parts
export type AliasAst = { name: IdentifierAst } & TokenInfo
export type ConditionAst = { left: ExpressionAst, operator: OperatorAst, right: ExpressionAst }
export type OperatorAst = { kind: '=' | '<' | '>' | 'Like' } & TokenInfo
export type ExpressionAst = LiteralAst | ColumnAst
export type TableAst = {table: IdentifierAst, schema?: IdentifierAst}
export type ColumnAst = {column: IdentifierAst, table?: IdentifierAst, schema?: IdentifierAst}
export type LiteralAst = StringAst | IntegerAst | DecimalAst | BooleanAst

// elements
export type IdentifierAst = { kind: 'Identifier', value: string, quoted?: boolean } & TokenInfo
export type StringAst = { kind: 'String', value: string } & TokenInfo
export type DecimalAst = { kind: 'Decimal', value: number } & TokenInfo
export type IntegerAst = { kind: 'Integer', value: number } & TokenInfo
export type BooleanAst = { kind: 'Boolean', value: boolean } & TokenInfo
export type CommentAst = { kind: 'line' | 'block' | 'doc', value: string } & TokenInfo // special case

// helpers
export type TokenInfo = TokenPosition & { issues?: TokenIssue[] }
export type TokenIssue = { message: string, kind: string, level: ParserErrorLevel }
