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
export type StatementAst = CommentStatementAst | CreateExtensionStatementAst | CreateTableStatementAst | DropStatementAst | SelectStatementAst | SetStatementAst
export type CommentStatementAst = { statement: 'Comment', object: { kind: CommentObject } & TokenInfo, schema?: IdentifierAst, parent?: IdentifierAst, entity: IdentifierAst, comment: StringAst | NullAst } & TokenInfo
export type CreateExtensionStatementAst = { statement: 'CreateExtension', ifNotExists?: TokenInfo, name: IdentifierAst, with?: TokenInfo, schema?: {name: IdentifierAst} & TokenInfo, version?: {number: StringAst | IdentifierAst} & TokenInfo, cascade?: TokenInfo } & TokenInfo
export type CreateTableStatementAst = { statement: 'CreateTable', schema?: IdentifierAst, table: IdentifierAst, columns: TableColumnAst[], constraints?: TableConstraintAst[] } & TokenInfo
export type CreateTypeStatementAst = { statement: 'CreateType', schema?: IdentifierAst, type: IdentifierAst, struct?: {attrs: TypeColumnAst[]} & TokenInfo, enum?: {values: StringAst[]} & TokenInfo } & TokenInfo
export type DropStatementAst = { statement: 'Drop', object: { kind: DropObject } & TokenInfo, entities: TableAst[], concurrently?: TokenInfo, ifExists?: TokenInfo, mode?: { kind: DropMode } & TokenInfo } & TokenInfo
export type SelectStatementAst = { statement: 'Select', select: SelectClauseAst, from?: FromClauseAst, where?: WhereClauseAst } & TokenInfo
export type SetStatementAst = { statement: 'Set', scope?: { kind: SetScope } & TokenInfo, parameter: IdentifierAst, equal: { kind: SetAssign } & TokenInfo, value: SetValueAst } & TokenInfo

// clauses
export type SelectClauseAst = { expressions: SelectClauseExprAst[] } & TokenInfo
export type SelectClauseExprAst = ExpressionAst & { alias?: AliasAst }
export type FromClauseAst = { table: IdentifierAst, alias?: AliasAst } & TokenInfo
export type WhereClauseAst = { condition: ConditionAst } & TokenInfo
export type TypeColumnAst = { name: IdentifierAst, type: ColumnTypeAst, collation?: {name: IdentifierAst} & TokenInfo }
export type TableColumnAst = { name: IdentifierAst, type: ColumnTypeAst, constraints?: TableColumnConstraintAst[] }
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
export type ColumnTypeAst = {schema?: IdentifierAst, name: {value: string} & TokenInfo, args?: IntegerAst[]} & TokenInfo
export type ForeignKeyActionAst = {action: {kind: ForeignKeyAction} & TokenInfo, columns?: IdentifierAst[]}
export type SetValueAst = IdentifierAst | LiteralAst | (IdentifierAst | LiteralAst)[] | { kind: 'Default' } & TokenInfo

// basic parts
export type AliasAst = { name: IdentifierAst } & TokenInfo
export type ConditionAst = { left: ExpressionAst, operator: OperatorAst, right: ExpressionAst }
export type OperatorAst = { kind: Operator } & TokenInfo
export type ExpressionAst = (LiteralAst | ColumnAst | FunctionAst) & { cast?: { type: ColumnTypeAst } & TokenInfo }
export type LiteralAst = StringAst | IntegerAst | DecimalAst | BooleanAst | NullAst
export type TableAst = {schema?: IdentifierAst, table: IdentifierAst}
export type ColumnAst = {schema?: IdentifierAst, table?: IdentifierAst, column: IdentifierAst}
export type ColumnWithTableAst = {schema?: IdentifierAst, table: IdentifierAst, column: IdentifierAst}
export type FunctionAst = {schema?: IdentifierAst, function: IdentifierAst, parameters: ExpressionAst[]}

// elements
export type IdentifierAst = { kind: 'Identifier', value: string, quoted?: boolean } & TokenInfo
export type StringAst = { kind: 'String', value: string } & TokenInfo
export type DecimalAst = { kind: 'Decimal', value: number } & TokenInfo
export type IntegerAst = { kind: 'Integer', value: number } & TokenInfo
export type BooleanAst = { kind: 'Boolean', value: boolean } & TokenInfo
export type NullAst = { kind: 'Null' } & TokenInfo
export type CommentAst = { kind: CommentKind, value: string } & TokenInfo // special case

// enums
export type Operator = '=' | '<' | '>' | 'Like'
export type ForeignKeyAction = 'NoAction' | 'Restrict' | 'Cascade' | 'SetNull' | 'SetDefault'
export type DropObject = 'Table' | 'View' | 'MaterializedView' | 'Index' | 'Type'
export type DropMode = 'Cascade' | 'Restrict'
export type CommentObject = 'Column' | 'Constraint' | 'Database' | 'Extension' | 'Index' | 'MaterializedView' | 'Schema' | 'Table' | 'Type' | 'View'
export type SetScope = 'Session' | 'Local'
export type SetAssign = '=' | 'To'
export type CommentKind = 'line' | 'block' | 'doc'

// helpers
export type TokenInfo = TokenPosition & { issues?: TokenIssue[] }
export type TokenIssue = { message: string, kind: string, level: ParserErrorLevel }
