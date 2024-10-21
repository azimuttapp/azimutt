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
export type StatementAst = (AlterTableStatementAst | CommentOnStatementAst | CreateExtensionStatementAst | CreateIndexStatementAst | CreateTableStatementAst
    | CreateTypeStatementAst | CreateViewStatementAst | DeleteStatementAst | DropStatementAst | InsertIntoStatementAst | SelectStatementAst | SetStatementAst) & { meta: TokenInfo }
export type AlterTableStatementAst = { kind: 'AlterTable', token: TokenInfo, ifExists?: TokenInfo, only?: TokenInfo, schema?: IdentifierAst, table: IdentifierAst, action: AlterTableActionAst }
export type CommentOnStatementAst = { kind: 'CommentOn', token: TokenInfo, object: { token: TokenInfo, kind: CommentObject }, schema?: IdentifierAst, parent?: IdentifierAst, entity: IdentifierAst, comment: StringAst | NullAst }
export type CreateExtensionStatementAst = { kind: 'CreateExtension', token: TokenInfo, ifNotExists?: TokenInfo, name: IdentifierAst, with?: TokenInfo, schema?: { token: TokenInfo, name: IdentifierAst }, version?: { token: TokenInfo, number: StringAst | IdentifierAst }, cascade?: TokenInfo }
export type CreateIndexStatementAst = { kind: 'CreateIndex', token: TokenInfo, unique?: TokenInfo, concurrently?: TokenInfo, ifNotExists?: TokenInfo, index?: IdentifierAst, only?: TokenInfo, schema?: IdentifierAst, table: IdentifierAst, using?: { token: TokenInfo, method: IdentifierAst }, columns: IndexColumnAst[], include?: { token: TokenInfo, columns: IdentifierAst[] }, where?: WhereClauseAst }
export type CreateTableStatementAst = { kind: 'CreateTable', token: TokenInfo, mode?: CreateTableModeAst, ifNotExists?: TokenInfo, schema?: IdentifierAst, table: IdentifierAst, columns: TableColumnAst[], constraints?: TableConstraintAst[] }
export type CreateTypeStatementAst = { kind: 'CreateType', token: TokenInfo, schema?: IdentifierAst, type: IdentifierAst, struct?: { token: TokenInfo, attrs: TypeColumnAst[] }, enum?: { token: TokenInfo, values: StringAst[] }, base?: { name: IdentifierAst, value: ExpressionAst }[] }
export type CreateViewStatementAst = { kind: 'CreateView', token: TokenInfo, replace?: TokenInfo, temporary?: TokenInfo, recursive?: TokenInfo, schema?: IdentifierAst, view: IdentifierAst, columns?: IdentifierAst[], query: SelectStatementInnerAst }
export type DeleteStatementAst = { kind: 'Delete', token: TokenInfo, only?: TokenInfo, schema?: IdentifierAst, table: IdentifierAst, descendants?: TokenInfo, alias?: AliasAst, using?: FromItemAst & { token: TokenInfo }, where?: WhereClauseAst, returning?: SelectClauseAst }
export type DropStatementAst = { kind: 'Drop', token: TokenInfo, object: DropObject, entities: ObjectNameAst[], concurrently?: TokenInfo, ifExists?: TokenInfo, mode?: { kind: DropMode, token: TokenInfo } }
export type InsertIntoStatementAst = { kind: 'InsertInto', token: TokenInfo, schema?: IdentifierAst, table: IdentifierAst, columns?: IdentifierAst[], values: (ExpressionAst | { kind: 'Default', token: TokenInfo })[][], returning?: SelectClauseAst }
export type SelectStatementAst = { kind: 'Select' } & SelectStatementInnerAst
export type SetStatementAst = { kind: 'Set', token: TokenInfo, scope?: { kind: SetScope, token: TokenInfo }, parameter: IdentifierAst, equal?: { kind: SetAssign, token: TokenInfo }, value: SetValueAst }

// clauses
export type CreateTableModeAst = ({ kind: 'Unlogged', token: TokenInfo }) | ({ kind: 'Temporary', token: TokenInfo, scope?: { kind: 'Local' | 'Global', token: TokenInfo } })
export type SelectStatementInnerAst = SelectStatementMainAst & SelectStatementResultAst
export type SelectStatementMainAst = SelectClauseAst & { from?: FromClauseAst, where?: WhereClauseAst, groupBy?: GroupByClauseAst, having?: HavingClauseAst }
export type SelectStatementResultAst = { union?: UnionClauseAst, orderBy?: OrderByClauseAst, limit?: LimitClauseAst, offset?: OffsetClauseAst, fetch?: FetchClauseAst }
export type SelectClauseAst = { token: TokenInfo, columns: SelectClauseExprAst[] }
export type SelectClauseExprAst = ExpressionAst & { alias?: AliasAst }
export type FromClauseAst = FromItemAst & { token: TokenInfo, joins?: FromJoinAst[] }
export type FromItemAst = (FromTableAst | FromQueryAst) & { alias?: AliasAst }
export type FromTableAst = { kind: 'Table', schema?: IdentifierAst, table: IdentifierAst }
export type FromQueryAst = { kind: 'Select', select: SelectStatementInnerAst }
export type FromJoinAst = { kind: JoinKind, token: TokenInfo, from: FromItemAst, on: FromJoinOnAst | FromJoinUsingAst | FromJoinNaturalAst, alias?: AliasAst }
export type FromJoinOnAst = { kind: 'On', token: TokenInfo, predicate: ExpressionAst }
export type FromJoinUsingAst = { kind: 'Using', token: TokenInfo, columns: IdentifierAst[] }
export type FromJoinNaturalAst = { kind: 'Natural', token: TokenInfo }
export type WhereClauseAst = { token: TokenInfo, predicate: ExpressionAst }
export type GroupByClauseAst = { token: TokenInfo, mode: { kind: 'All' | 'Distinct', token: TokenInfo }, expressions: ExpressionAst[] }
export type HavingClauseAst = { token: TokenInfo, predicate: ExpressionAst }
export type UnionClauseAst = { kind: 'Union' | 'Intersect' | 'Except', token: TokenInfo, mode: { kind: 'All' | 'Distinct', token: TokenInfo }, select: SelectStatementInnerAst } // TODO: VALUES also allowed
export type OrderByClauseAst = { token: TokenInfo, expressions: (ExpressionAst & { order?: SortOrderAst, nulls?: SortNullsAst })[] }
export type LimitClauseAst = { token: TokenInfo, value: IntegerAst | ParameterAst | ({ kind: 'All', token: TokenInfo }) }
export type OffsetClauseAst = { token: TokenInfo, value: IntegerAst | ParameterAst, rows?: { kind: 'Rows' | 'Row', token: TokenInfo } }
export type FetchClauseAst = { token: TokenInfo, first: { kind: 'First' | 'Next', token: TokenInfo }, value: IntegerAst | ParameterAst, rows: { kind: 'Rows' | 'Row', token: TokenInfo }, mode: { kind: 'Only' | 'WithTies', token: TokenInfo } }
export type AlterTableActionAst = AddColumnAst | AddConstraintAst | DropColumnAst | DropConstraintAst
export type AddColumnAst = { kind: 'AddColumn', token: TokenInfo, ifNotExists?: TokenInfo, column: TableColumnAst }
export type AddConstraintAst = { kind: 'AddConstraint', token: TokenInfo, constraint: TableConstraintAst }
export type DropColumnAst = { kind: 'DropColumn', token: TokenInfo, ifExists?: TokenInfo, column: IdentifierAst }
export type DropConstraintAst = { kind: 'DropConstraint', token: TokenInfo, ifExists?: TokenInfo, constraint: IdentifierAst }
export type TypeColumnAst = { name: IdentifierAst, type: ColumnTypeAst, collation?: { token: TokenInfo, name: IdentifierAst } }
export type IndexColumnAst = ExpressionAst & { collation?: { token: TokenInfo, name: IdentifierAst }, order?: SortOrderAst, nulls?: SortNullsAst }
export type TableColumnAst = { name: IdentifierAst, type: ColumnTypeAst, constraints?: TableColumnConstraintAst[] }
export type TableColumnConstraintAst = TableColumnNullableAst | TableColumnDefaultAst | TableColumnPkAst | TableColumnUniqueAst | TableColumnCheckAst | TableColumnFkAst
export type TableColumnNullableAst = { kind: 'Nullable', value: boolean } & ConstraintCommonAst
export type TableColumnDefaultAst = { kind: 'Default', expression: ExpressionAst } & ConstraintCommonAst
export type TableColumnPkAst = { kind: 'PrimaryKey' } & ConstraintCommonAst
export type TableColumnUniqueAst = { kind: 'Unique' } & ConstraintCommonAst
export type TableColumnCheckAst = { kind: 'Check', predicate: ExpressionAst } & ConstraintCommonAst
export type TableColumnFkAst = { kind: 'ForeignKey', schema?: IdentifierAst, table: IdentifierAst, column?: IdentifierAst, onUpdate?: ForeignKeyActionAst & {token: TokenInfo}, onDelete?: ForeignKeyActionAst & {token: TokenInfo} } & ConstraintCommonAst
export type TableConstraintAst = TablePkAst | TableUniqueAst | TableCheckAst | TableFkAst
export type TablePkAst = { kind: 'PrimaryKey', columns: IdentifierAst[] } & ConstraintCommonAst
export type TableUniqueAst = { kind: 'Unique', columns: IdentifierAst[] } & ConstraintCommonAst
export type TableCheckAst = { kind: 'Check', predicate: ExpressionAst } & ConstraintCommonAst
export type TableFkAst = { kind: 'ForeignKey', columns: IdentifierAst[], ref: { token: TokenInfo, schema?: IdentifierAst, table: IdentifierAst, columns?: IdentifierAst[] }, onUpdate?: ForeignKeyActionAst & {token: TokenInfo}, onDelete?: ForeignKeyActionAst & {token: TokenInfo} } & ConstraintCommonAst
export type ConstraintCommonAst = { token: TokenInfo, constraint?: ConstraintNameAst }
export type ConstraintNameAst = { token: TokenInfo, name: IdentifierAst }
export type ColumnTypeAst = { token: TokenInfo, schema?: IdentifierAst, name: { token: TokenInfo, value: string }, args?: IntegerAst[], array?: TokenInfo }
export type ForeignKeyActionAst = { action: { kind: ForeignKeyAction, token: TokenInfo }, columns?: IdentifierAst[] }
export type SetValueAst = IdentifierAst | LiteralAst | (IdentifierAst | LiteralAst)[] | { kind: 'Default', token: TokenInfo }

// basic parts
export type AliasAst = { token?: TokenInfo, name: IdentifierAst }
export type ObjectNameAst = { schema?: IdentifierAst, name: IdentifierAst }
export type ExpressionAst = (LiteralAst | ParameterAst | ColumnAst | WildcardAst | FunctionAst | GroupAst | OperationAst | OperationLeftAst | OperationRightAst | ListAst) & { cast?: { token: TokenInfo, type: ColumnTypeAst } }
export type LiteralAst = StringAst | IntegerAst | DecimalAst | BooleanAst | NullAst
export type ColumnAst = { kind: 'Column', schema?: IdentifierAst, table?: IdentifierAst, column: IdentifierAst, json?: ColumnJsonAst[] }
export type ColumnJsonAst = { kind: JsonOp, token: TokenInfo, field: StringAst }
export type FunctionAst = { kind: 'Function', schema?: IdentifierAst, function: IdentifierAst, parameters: ExpressionAst[] }
export type GroupAst = { kind: 'Group', expression: ExpressionAst }
export type WildcardAst = { kind: 'Wildcard', token: TokenInfo, schema?: IdentifierAst, table?: IdentifierAst }
export type OperationAst = { kind: 'Operation', left: ExpressionAst, op: OperatorAst, right: ExpressionAst }
export type OperatorAst = { kind: Operator, token: TokenInfo }
export type OperationLeftAst = { kind: 'OperationLeft', op: OperatorLeftAst, right: ExpressionAst }
export type OperatorLeftAst = { kind: OperatorLeft, token: TokenInfo }
export type OperationRightAst = { kind: 'OperationRight', left: ExpressionAst, op: OperatorRightAst }
export type OperatorRightAst = { kind: OperatorRight, token: TokenInfo }
export type ListAst = { kind: 'List', items: LiteralAst[] }
export type SortOrderAst = { kind: SortOrder, token: TokenInfo }
export type SortNullsAst = { kind: SortNulls, token: TokenInfo }

// elements
export type ParameterAst = { kind: 'Parameter', token: TokenInfo, value: string, index?: number }
export type IdentifierAst = { kind: 'Identifier', token: TokenInfo, value: string, quoted?: boolean }
export type StringAst = { kind: 'String', token: TokenInfo, value: string, escaped?: boolean }
export type DecimalAst = { kind: 'Decimal', token: TokenInfo, value: number }
export type IntegerAst = { kind: 'Integer', token: TokenInfo, value: number }
export type BooleanAst = { kind: 'Boolean', token: TokenInfo, value: boolean }
export type NullAst = { kind: 'Null', token: TokenInfo }
export type CommentAst = { kind: CommentKind, token: TokenInfo, value: string } // special case

// enums
export type Operator = '+' | '-' | '*' | '/' | '%' | '^' | '&' | '|' | '#' | '<<' | '>>' | '=' | '<' | '>' | '<=' | '>=' | '<>' | '!=' | '||' | '~' | '~*' | '!~' | '!~*' | 'Is' | 'Like' | 'NotLike' | 'In' | 'NotIn' | 'Or' | 'And'
export type OperatorLeft = 'Not' | '~'
export type OperatorRight = 'IsNull' | 'NotNull'
export type JsonOp = '->' | '->>'
export type ForeignKeyAction = 'NoAction' | 'Restrict' | 'Cascade' | 'SetNull' | 'SetDefault'
export type DropObject = 'Table' | 'View' | 'MaterializedView' | 'Index' | 'Type'
export type DropMode = 'Cascade' | 'Restrict'
export type CommentObject = 'Column' | 'Constraint' | 'Database' | 'Extension' | 'Index' | 'MaterializedView' | 'Schema' | 'Table' | 'Type' | 'View'
export type JoinKind = 'Inner' | 'Left' | 'Right' | 'Full' | 'Cross'
export type SortOrder = 'Asc' | 'Desc'
export type SortNulls = 'First' | 'Last'
export type SetScope = 'Session' | 'Local'
export type SetAssign = '=' | 'To'
export type CommentKind = 'line' | 'block' | 'doc'

// helpers
export type TokenInfo = TokenPosition & { issues?: TokenIssue[] }
export type TokenIssue = { message: string, kind: string, level: ParserErrorLevel }
