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
export type StatementAst = AlterTableStatementAst | CommentStatementAst | CreateExtensionStatementAst | CreateIndexStatementAst | CreateTableStatementAst
    | CreateTypeStatementAst | CreateViewStatementAst | DropStatementAst | InsertIntoStatementAst | SelectStatementAst | SetStatementAst
export type AlterTableStatementAst = { kind: 'AlterTable', ifExists?: TokenInfo, only?: TokenInfo, schema?: IdentifierAst, table: IdentifierAst, action: AlterTableActionAst } & TokenInfo
export type CommentStatementAst = { kind: 'Comment', object: { kind: CommentObject } & TokenInfo, schema?: IdentifierAst, parent?: IdentifierAst, entity: IdentifierAst, comment: StringAst | NullAst } & TokenInfo
export type CreateExtensionStatementAst = { kind: 'CreateExtension', ifNotExists?: TokenInfo, name: IdentifierAst, with?: TokenInfo, schema?: {name: IdentifierAst} & TokenInfo, version?: {number: StringAst | IdentifierAst} & TokenInfo, cascade?: TokenInfo } & TokenInfo
export type CreateIndexStatementAst = { kind: 'CreateIndex', unique?: TokenInfo, concurrently?: TokenInfo, ifNotExists?: TokenInfo, index?: IdentifierAst, only?: TokenInfo, schema?: IdentifierAst, table: IdentifierAst, using?: {method: IdentifierAst} & TokenInfo, columns: IndexColumnAst[], include?: {columns: IdentifierAst[]} & TokenInfo, where?: {predicate: ExpressionAst} & TokenInfo } & TokenInfo
export type CreateTableStatementAst = { kind: 'CreateTable', schema?: IdentifierAst, table: IdentifierAst, columns: TableColumnAst[], constraints?: TableConstraintAst[] } & TokenInfo
export type CreateTypeStatementAst = { kind: 'CreateType', schema?: IdentifierAst, type: IdentifierAst, struct?: {attrs: TypeColumnAst[]} & TokenInfo, enum?: {values: StringAst[]} & TokenInfo, base?: {name: IdentifierAst, value: ExpressionAst}[] } & TokenInfo
export type CreateViewStatementAst = { kind: 'CreateView', replace?: TokenInfo, temporary?: TokenInfo, recursive?: TokenInfo, schema?: IdentifierAst, view: IdentifierAst, columns?: IdentifierAst[], query: SelectStatementInnerAst } & TokenInfo
export type DropStatementAst = { kind: 'Drop', object: { kind: DropObject } & TokenInfo, entities: ObjectNameAst[], concurrently?: TokenInfo, ifExists?: TokenInfo, mode?: { kind: DropMode } & TokenInfo } & TokenInfo
export type InsertIntoStatementAst = { kind: 'InsertInto', schema?: IdentifierAst, table: IdentifierAst, columns?: IdentifierAst[], values: (ExpressionAst | { kind: 'Default' } & TokenInfo)[][], returning?: SelectClauseAst } & TokenInfo
export type SelectStatementAst = { kind: 'Select' } & SelectStatementInnerAst & TokenInfo
export type SetStatementAst = { kind: 'Set', scope?: { kind: SetScope } & TokenInfo, parameter: IdentifierAst, equal: { kind: SetAssign } & TokenInfo, value: SetValueAst } & TokenInfo

// clauses
export type SelectStatementInnerAst = { select: SelectClauseAst, from?: FromClauseAst, where?: WhereClauseAst }
export type SelectClauseAst = { columns: SelectClauseExprAst[] } & TokenInfo
export type SelectClauseExprAst = ExpressionAst & { alias?: AliasAst }
export type FromClauseAst = { table: IdentifierAst, alias?: AliasAst } & TokenInfo
export type WhereClauseAst = { predicate: ExpressionAst } & TokenInfo
export type AlterTableActionAst = AddColumnAst | AddConstraintAst | DropColumnAst | DropConstraintAst
export type AddColumnAst = { kind: 'AddColumn', ifNotExists?: TokenInfo, column: TableColumnAst } & TokenInfo
export type AddConstraintAst = { kind: 'AddConstraint', constraint: TableConstraintAst } & TokenInfo
export type DropColumnAst = { kind: 'DropColumn', ifExists?: TokenInfo, column: IdentifierAst } & TokenInfo
export type DropConstraintAst = { kind: 'DropConstraint', ifExists?: TokenInfo, constraint: IdentifierAst } & TokenInfo
export type TypeColumnAst = { name: IdentifierAst, type: ColumnTypeAst, collation?: {name: IdentifierAst} & TokenInfo }
export type IndexColumnAst = ExpressionAst & {collation?: {name: IdentifierAst} & TokenInfo, order?: {kind: SortOrder} & TokenInfo, nulls?: {kind: SortNulls} & TokenInfo}
export type TableColumnAst = { name: IdentifierAst, type: ColumnTypeAst, constraints?: TableColumnConstraintAst[] }
export type TableColumnConstraintAst = TableColumnNullableAst | TableColumnDefaultAst | TableColumnPkAst | TableColumnUniqueAst | TableColumnCheckAst | TableColumnFkAst
export type TableColumnNullableAst = { kind: 'Nullable', value: boolean } & ConstraintCommonAst
export type TableColumnDefaultAst = { kind: 'Default', expression: ExpressionAst } & ConstraintCommonAst
export type TableColumnPkAst = { kind: 'PrimaryKey' } & ConstraintCommonAst
export type TableColumnUniqueAst = { kind: 'Unique' } & ConstraintCommonAst
export type TableColumnCheckAst = { kind: 'Check', predicate: ExpressionAst } & ConstraintCommonAst
export type TableColumnFkAst = { kind: 'ForeignKey', schema?: IdentifierAst, table: IdentifierAst, column?: IdentifierAst, onUpdate?: ForeignKeyActionAst & TokenInfo, onDelete?: ForeignKeyActionAst & TokenInfo } & ConstraintCommonAst
export type TableConstraintAst = TablePkAst | TableUniqueAst | TableCheckAst | TableFkAst
export type TablePkAst = { kind: 'PrimaryKey', columns: IdentifierAst[] } & ConstraintCommonAst
export type TableUniqueAst = { kind: 'Unique', columns: IdentifierAst[] } & ConstraintCommonAst
export type TableCheckAst = { kind: 'Check', predicate: ExpressionAst } & ConstraintCommonAst
export type TableFkAst = { kind: 'ForeignKey', columns: IdentifierAst[], ref: {schema?: IdentifierAst, table: IdentifierAst, columns?: IdentifierAst[]} & TokenInfo, onUpdate?: ForeignKeyActionAst & TokenInfo, onDelete?: ForeignKeyActionAst & TokenInfo } & ConstraintCommonAst
export type ConstraintCommonAst = { constraint?: ConstraintNameAst } & TokenInfo
export type ConstraintNameAst = { name: IdentifierAst } & TokenInfo
export type ColumnTypeAst = {schema?: IdentifierAst, name: {value: string} & TokenInfo, args?: IntegerAst[], array?: TokenInfo} & TokenInfo
export type ForeignKeyActionAst = {action: {kind: ForeignKeyAction} & TokenInfo, columns?: IdentifierAst[]}
export type SetValueAst = IdentifierAst | LiteralAst | (IdentifierAst | LiteralAst)[] | { kind: 'Default' } & TokenInfo

// basic parts
export type AliasAst = { name: IdentifierAst } & TokenInfo
export type ObjectNameAst = { schema?: IdentifierAst, name: IdentifierAst }
export type ExpressionAst = (LiteralAst | ParameterAst | ColumnAst | WildcardAst | FunctionAst | GroupAst | OperationAst | ListAst) & { cast?: { type: ColumnTypeAst } & TokenInfo }
export type LiteralAst = StringAst | IntegerAst | DecimalAst | BooleanAst | NullAst
export type ColumnAst = { kind: 'Column', schema?: IdentifierAst, table?: IdentifierAst, column: IdentifierAst, json?: ColumnJsonAst[] }
export type ColumnJsonAst = { kind: JsonOp, field: StringAst } & TokenInfo
export type FunctionAst = { kind: 'Function', schema?: IdentifierAst, function: IdentifierAst, parameters: ExpressionAst[] }
export type GroupAst = { kind: 'Group', expression: ExpressionAst }
export type WildcardAst = { kind: 'Wildcard', schema?: IdentifierAst, table?: IdentifierAst } & TokenInfo
export type OperationAst = { kind: 'Operation', left: ExpressionAst, op: OperatorAst, right: ExpressionAst }
export type OperatorAst = { kind: Operator } & TokenInfo
export type ListAst = { kind: 'List', items: LiteralAst[] }

// elements
export type ParameterAst = { kind: 'Parameter', value: string, index?: number } & TokenInfo
export type IdentifierAst = { kind: 'Identifier', value: string, quoted?: boolean } & TokenInfo
export type StringAst = { kind: 'String', value: string, escaped?: boolean } & TokenInfo
export type DecimalAst = { kind: 'Decimal', value: number } & TokenInfo
export type IntegerAst = { kind: 'Integer', value: number } & TokenInfo
export type BooleanAst = { kind: 'Boolean', value: boolean } & TokenInfo
export type NullAst = { kind: 'Null' } & TokenInfo
export type CommentAst = { kind: CommentKind, value: string } & TokenInfo // special case

// enums
export type Operator = '+' | '-' | '*' | '/' | '%' | '^' | '&' | '|' | '#' | '<<' | '>>' | '=' | '<' | '>' | '<=' | '>=' | '<>' | '!=' | '||' | '~' | '~*' | '!~' | '!~*' | 'Like' | 'NotLike' | 'In' | 'NotIn' | 'Or' | 'And'
export type JsonOp = '->' | '->>'
export type ForeignKeyAction = 'NoAction' | 'Restrict' | 'Cascade' | 'SetNull' | 'SetDefault'
export type DropObject = 'Table' | 'View' | 'MaterializedView' | 'Index' | 'Type'
export type DropMode = 'Cascade' | 'Restrict'
export type CommentObject = 'Column' | 'Constraint' | 'Database' | 'Extension' | 'Index' | 'MaterializedView' | 'Schema' | 'Table' | 'Type' | 'View'
export type SortOrder = 'Asc' | 'Desc'
export type SortNulls = 'First' | 'Last'
export type SetScope = 'Session' | 'Local'
export type SetAssign = '=' | 'To'
export type CommentKind = 'line' | 'block' | 'doc'

// helpers
export type TokenInfo = TokenPosition & { issues?: TokenIssue[] }
export type TokenIssue = { message: string, kind: string, level: ParserErrorLevel }
