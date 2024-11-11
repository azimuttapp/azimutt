import {ParserErrorLevel, TokenPosition} from "@azimutt/models";

/**
 * Conventions:
 * - use `kind` attribute for discriminated unions or enum values
 * - use `value` attribute for the actual source value
 * - keep all token positions
 * - statement positions are start/end, all other positions are the specific token
 */

// statements
export type PostgresAst = StatementsAst & { comments?: CommentAst[] }
export type PostgresStatementAst = StatementAst & { comments?: CommentAst[] }
export type StatementsAst = { statements: StatementAst[] }
export type StatementAst = { meta: TokenInfo } & (AlterFunctionStatementAst | AlterMaterializedViewStatementAst | AlterSchemaStatementAst |
    AlterSequenceStatementAst | AlterTableStatementAst | AlterTypeStatementAst | AlterViewStatementAst | BeginStatementAst |
    CommentOnStatementAst | CommitStatementAst | CreateExtensionStatementAst | CreateFunctionStatementAst | CreateIndexStatementAst |
    CreateMaterializedViewStatementAst | CreateSchemaStatementAst | CreateSequenceStatementAst | CreateTableStatementAst |
    CreateTriggerStatementAst | CreateTypeStatementAst | CreateViewStatementAst | DeleteStatementAst | DropStatementAst |
    InsertIntoStatementAst | SelectStatementAst | SetStatementAst | ShowStatementAst | UpdateStatementAst)
export type AlterFunctionStatementAst = { kind: 'AlterFunction', token: TokenInfo, schema?: IdentifierAst, name: IdentifierAst, args: FunctionArgumentAst[], actions: AlterFunctionActionAst[] }
export type AlterMaterializedViewStatementAst = { kind: 'AlterMaterializedView', token: TokenInfo, ifExists?: TokenAst, schema?: IdentifierAst, name: IdentifierAst, actions: AlterMaterializedViewActionAst[] }
export type AlterSchemaStatementAst = { kind: 'AlterSchema', token: TokenInfo, schema: IdentifierAst, actions: AlterSchemaActionAst[] }
export type AlterSequenceStatementAst = { kind: 'AlterSequence', token: TokenInfo, ifExists?: TokenAst, schema?: IdentifierAst, name: IdentifierAst, as?: SequenceTypeAst, start?: SequenceParamAst, increment?: SequenceParamAst, minValue?: SequenceParamOptAst, maxValue?: SequenceParamOptAst, cache?: SequenceParamAst, ownedBy?: SequenceOwnedByAst }
export type AlterTableStatementAst = { kind: 'AlterTable', token: TokenInfo, ifExists?: TokenAst, only?: TokenAst, schema?: IdentifierAst, name: IdentifierAst, actions: AlterTableActionAst[] }
export type AlterTypeStatementAst = { kind: 'AlterType', token: TokenInfo, schema?: IdentifierAst, name: IdentifierAst, actions: AlterTypeActionAst[] }
export type AlterViewStatementAst = { kind: 'AlterView', token: TokenInfo, ifExists?: TokenAst, schema?: IdentifierAst, name: IdentifierAst, actions: AlterViewActionAst[] }
export type BeginStatementAst = { kind: 'Begin', token: TokenInfo, object?: TransactionObjectAst, modes?: TransactionModeAst[] }
export type CommentOnStatementAst = { kind: 'CommentOn', token: TokenInfo, object: CommentObjectAst, schema?: IdentifierAst, parent?: IdentifierAst, entity: IdentifierAst, comment: StringAst | NullAst }
export type CommitStatementAst = { kind: 'Commit', token: TokenInfo, object?: TransactionObjectAst, chain?: TransactionChainAst }
export type CreateExtensionStatementAst = { kind: 'CreateExtension', token: TokenInfo, ifNotExists?: TokenAst, name: IdentifierAst, with?: TokenAst, schema?: NameAst, version?: ExtensionVersionAst, cascade?: TokenAst }
export type CreateFunctionStatementAst = { kind: 'CreateFunction', token: TokenInfo, replace?: TokenAst, schema?: IdentifierAst, name: IdentifierAst, args: FunctionArgumentAst[], returns?: FunctionReturnsAst, language?: NameAst, behavior?: FunctionBehaviorAst, nullBehavior?: FunctionNullBehaviorAst, definition?: FunctionDefinitionAst, return?: FunctionReturnAst }
export type CreateIndexStatementAst = { kind: 'CreateIndex', token: TokenInfo, unique?: TokenAst, concurrently?: TokenAst, ifNotExists?: TokenAst, name?: IdentifierAst, only?: TokenAst, schema?: IdentifierAst, table: IdentifierAst, using?: IndexUsingAst, columns: IndexColumnAst[], include?: IndexIncludeAst, where?: WhereClauseAst }
export type CreateMaterializedViewStatementAst = { kind: 'CreateMaterializedView', token: TokenInfo, ifNotExists?: TokenAst, schema?: IdentifierAst, name: IdentifierAst, columns?: IdentifierAst[], query: SelectInnerAst, withData?: ViewMaterializedDataAst }
export type CreateSchemaStatementAst = { kind: 'CreateSchema', token: TokenInfo, ifNotExists?: TokenAst, schema?: IdentifierAst, authorization?: SchemaAuthorizationAst }
export type CreateSequenceStatementAst = { kind: 'CreateSequence', token: TokenInfo, mode?: SequenceModeAst, ifNotExists?: TokenAst, schema?: IdentifierAst, name: IdentifierAst, as?: SequenceTypeAst, start?: SequenceParamAst, increment?: SequenceParamAst, minValue?: SequenceParamOptAst, maxValue?: SequenceParamOptAst, cache?: SequenceParamAst, ownedBy?: SequenceOwnedByAst }
export type CreateTableStatementAst = { kind: 'CreateTable', token: TokenInfo, mode?: TableCreateModeAst, ifNotExists?: TokenAst, schema?: IdentifierAst, name: IdentifierAst, columns?: TableColumnAst[], constraints?: TableConstraintAst[] }
export type CreateTriggerStatementAst = { kind: 'CreateTrigger', token: TokenInfo, replace?: TokenAst, constraint?: TokenAst, name: IdentifierAst, timing: TriggerTimingAst, events?: TriggerEventAst[], schema?: IdentifierAst, table: IdentifierAst, from?: TriggerFromAst, deferrable?: TriggerDeferrableAst, referencing?: TriggerReferencingAst, target?: TriggerTargetAst, when?: FilterAst, execute: TriggerExecuteAst }
export type CreateTypeStatementAst = { kind: 'CreateType', token: TokenInfo, schema?: IdentifierAst, name: IdentifierAst, struct?: TypeStructAst, enum?: TypeEnumAst, base?: TypeBaseAttrAst[] }
export type CreateViewStatementAst = { kind: 'CreateView', token: TokenInfo, replace?: TokenAst, temporary?: TokenAst, recursive?: TokenAst, schema?: IdentifierAst, name: IdentifierAst, columns?: IdentifierAst[], query: SelectInnerAst }
export type DeleteStatementAst = { kind: 'Delete', token: TokenInfo, only?: TokenAst, schema?: IdentifierAst, table: IdentifierAst, descendants?: TokenAst, alias?: AliasAst, using?: FromClauseItemAst & TokenAst, where?: WhereClauseAst, returning?: SelectClauseAst }
export type DropStatementAst = { kind: 'Drop', token: TokenInfo, object: DropObject, entities: ObjectNameAst[], concurrently?: TokenAst, ifExists?: TokenAst, mode?: DropModeAst }
export type InsertIntoStatementAst = { kind: 'InsertInto', token: TokenInfo, schema?: IdentifierAst, table: IdentifierAst, columns?: IdentifierAst[], values: InsertValueAst[][], onConflict?: OnConflictClauseAst, returning?: SelectClauseAst }
export type SelectStatementAst = { kind: 'Select' } & SelectInnerAst
export type SetStatementAst = { kind: 'Set', token: TokenInfo, scope?: SetModeAst, parameter: IdentifierAst, equal?: SetAssignAst, value: SetValueAst }
export type ShowStatementAst = { kind: 'Show', token: TokenInfo, name: IdentifierAst }
export type UpdateStatementAst = { kind: 'Update', token: TokenInfo, only?: TokenAst, schema?: IdentifierAst, table: IdentifierAst, descendants?: TokenAst, alias?: AliasAst, columns: ColumnUpdateAst[], where?: WhereClauseAst, returning?: SelectClauseAst }

// select clauses
export type SelectInnerAst = SelectMainAst & SelectResultAst
export type SelectMainAst = SelectClauseAst & { from?: FromClauseAst, where?: WhereClauseAst, groupBy?: GroupByClauseAst, having?: HavingClauseAst, window?: WindowClauseAst[] }
export type SelectResultAst = { union?: UnionClauseAst, orderBy?: OrderByClauseAst, limit?: LimitClauseAst, offset?: OffsetClauseAst, fetch?: FetchClauseAst }
export type SelectClauseAst = { token: TokenInfo, distinct?: { token: TokenInfo, on?: { token: TokenInfo, columns: ExpressionAst[] } }, columns: SelectClauseColumnAst[] }
export type SelectClauseColumnAst = ExpressionAst & { filter?: { token: TokenInfo, where: WhereClauseAst }, over?: TokenAst & ({ name: IdentifierAst } | WindowClauseContentAst), alias?: AliasAst }
export type FromClauseAst = FromClauseItemAst & { token: TokenInfo, joins?: FromClauseJoinAst[] }
export type FromClauseItemAst = (FromClauseTableAst | FromClauseQueryAst) & { alias?: AliasAst }
export type FromClauseTableAst = { kind: 'Table', schema?: IdentifierAst, table: IdentifierAst }
export type FromClauseQueryAst = { kind: 'Select', select: SelectInnerAst }
export type FromClauseJoinAst = { kind: JoinKind, token: TokenInfo, from: FromClauseItemAst, on: JoinOnAst | JoinUsingAst | JoinNaturalAst, alias?: AliasAst }
export type JoinOnAst = { kind: 'On', token: TokenInfo, predicate: ExpressionAst }
export type JoinUsingAst = { kind: 'Using', token: TokenInfo, columns: IdentifierAst[] }
export type JoinNaturalAst = { kind: 'Natural', token: TokenInfo }
export type WhereClauseAst = { token: TokenInfo, predicate: ExpressionAst }
export type GroupByClauseAst = { token: TokenInfo, mode: { kind: 'All' | 'Distinct', token: TokenInfo }, expressions: ExpressionAst[] }
export type HavingClauseAst = { token: TokenInfo, predicate: ExpressionAst }
export type WindowClauseAst = NameAst & WindowClauseContentAst
export type WindowClauseContentAst = { partitionBy?: { token: TokenInfo, columns: ExpressionAst[] }, orderBy?: OrderByClauseAst }
export type UnionClauseAst = { kind: 'Union' | 'Intersect' | 'Except', token: TokenInfo, mode: { kind: 'All' | 'Distinct', token: TokenInfo }, select: SelectInnerAst } // TODO: VALUES also allowed
export type OrderByClauseAst = { token: TokenInfo, expressions: (ExpressionAst & { order?: SortOrderAst, nulls?: SortNullsAst })[] }
export type LimitClauseAst = { token: TokenInfo, value: IntegerAst | ParameterAst | ({ kind: 'All', token: TokenInfo }) }
export type OffsetClauseAst = { token: TokenInfo, value: IntegerAst | ParameterAst, rows?: { kind: 'Rows' | 'Row', token: TokenInfo } }
export type FetchClauseAst = { token: TokenInfo, first: { kind: 'First' | 'Next', token: TokenInfo }, value: IntegerAst | ParameterAst, rows: { kind: 'Rows' | 'Row', token: TokenInfo }, mode: { kind: 'Only' | 'WithTies', token: TokenInfo } }

// other clauses
export type AlterFunctionActionAst = AlterRenameAst | AlterSetOwnerAst | AlterSetSchemaAst
export type AlterMaterializedViewActionAst = AlterRenameAst | AlterSetOwnerAst | AlterSetSchemaAst
export type AlterSchemaActionAst = AlterRenameAst | AlterSetOwnerAst
export type AlterTableActionAst = AlterAddColumnAst | AlterAddConstraintAst | AlterTableColumnAst | AlterDropColumnAst | AlterDropConstraintAst | AlterSetOwnerAst
export type AlterTypeActionAst = AlterRenameAst | AlterSetOwnerAst | AlterSetSchemaAst
export type AlterViewActionAst = AlterRenameAst | AlterSetOwnerAst | AlterSetSchemaAst
export type AlterAddColumnAst = { kind: 'AddColumn', token: TokenInfo, ifNotExists?: TokenAst, column: TableColumnAst }
export type AlterAddConstraintAst = { kind: 'AddConstraint', token: TokenInfo, constraint: TableConstraintAst, notValid?: TokenAst }
export type AlterTableColumnAst = { kind: 'AlterColumn', token: TokenInfo, column: IdentifierAst, action: ColumnAlterActionAst }
export type AlterDropColumnAst = { kind: 'DropColumn', token: TokenInfo, ifExists?: TokenAst, column: IdentifierAst }
export type AlterDropConstraintAst = { kind: 'DropConstraint', token: TokenInfo, ifExists?: TokenAst, constraint: IdentifierAst }
export type AlterRenameAst = { kind: 'Rename', token: TokenInfo, name: IdentifierAst }
export type AlterSetOwnerAst = { kind: 'SetOwner', token: TokenInfo, owner: OwnerAst }
export type AlterSetSchemaAst = { kind: 'SetSchema', token: TokenInfo, schema: IdentifierAst }
export type ColumnAlterActionAst = ColumnAlterDefaultAst | ColumnAlterNotNullAst
export type ColumnAlterDefaultAst = { kind: 'Default', action: { kind: 'Set' | 'Drop', token: TokenInfo }, token: TokenInfo, expression?: ExpressionAst }
export type ColumnAlterNotNullAst = { kind: 'NotNull', action: { kind: 'Set' | 'Drop', token: TokenInfo }, token: TokenInfo }
export type ColumnTypeAst = { token: TokenInfo, schema?: IdentifierAst, name: IdentifierAst, args?: IntegerAst[], array?: TokenAst }
export type ColumnUpdateAst = { column: IdentifierAst, value: InsertValueAst }
export type CommentObjectAst = { kind: CommentObject, token: TokenInfo }
export type DropModeAst = { kind: DropMode, token: TokenInfo }
export type ExtensionVersionAst = { token: TokenInfo, number: StringAst | IdentifierAst }
export type ForeignKeyActionAst = { action: { kind: ForeignKeyAction, token: TokenInfo }, columns?: IdentifierAst[] }
export type FunctionArgumentAst = { mode?: { kind: 'In' | 'Out' | 'InOut' | 'Variadic', token: TokenInfo }, name?: IdentifierAst, type: ColumnTypeAst }
export type FunctionBehaviorAst = { kind: 'Immutable' | 'Stable' | 'Volatile', token: TokenInfo }
export type FunctionDefinitionAst = { token: TokenInfo, value: StringAst }
export type FunctionNullBehaviorAst = { kind: 'Called' | 'ReturnsNull' | 'Strict', token: TokenInfo }
export type FunctionReturnAst = { token: TokenInfo, expression: ExpressionAst }
export type FunctionReturnsAst = { kind: 'Type', token: TokenInfo, setOf?: TokenAst, type: ColumnTypeAst } | { kind: 'Table', token: TokenInfo, columns: { name: IdentifierAst, type: ColumnTypeAst }[] }
export type IndexColumnAst = ExpressionAst & { collation?: NameAst, order?: SortOrderAst, nulls?: SortNullsAst }
export type IndexIncludeAst = { token: TokenInfo, columns: IdentifierAst[] }
export type IndexUsingAst = { token: TokenInfo, method: IdentifierAst }
export type InsertValueAst = ExpressionAst | { kind: 'Default', token: TokenInfo }
export type OnConflictClauseAst = { token: TokenInfo, target?: OnConflictColumnsAst | OnConflictConstraintAst, action: OnConflictNothingAst | OnConflictUpdateAst }
export type OnConflictColumnsAst = { kind: 'Columns', columns: IdentifierAst[], where?: WhereClauseAst }
export type OnConflictConstraintAst = { kind: 'Constraint', token: TokenInfo, name: IdentifierAst }
export type OnConflictNothingAst = { kind: 'Nothing', token: TokenInfo }
export type OnConflictUpdateAst = { kind: 'Update', columns: ColumnUpdateAst[], where?: WhereClauseAst }
export type SchemaAuthorizationAst = { token: TokenInfo, owner: OwnerAst }
export type SequenceModeAst = { kind: 'Unlogged' | 'Temporary', token: TokenInfo }
export type SequenceOwnedByAst = { token: TokenInfo, owner: { kind: 'None', token: TokenInfo } | { kind: 'Column', schema?: IdentifierAst, table: IdentifierAst, column: IdentifierAst } }
export type SequenceParamAst = { token: TokenInfo, value: IntegerAst }
export type SequenceParamOptAst = { token: TokenInfo, value?: IntegerAst }
export type SequenceTypeAst = { token: TokenInfo, type: IdentifierAst }
export type SetAssignAst = { kind: SetAssign, token: TokenInfo }
export type SetModeAst = { kind: SetScope, token: TokenInfo }
export type SetValueAst = IdentifierAst | LiteralAst | (IdentifierAst | LiteralAst)[] | { kind: 'Default', token: TokenInfo }
export type TableColumnAst = { name: IdentifierAst, type: ColumnTypeAst, constraints?: TableColumnConstraintAst[] }
export type TableColumnConstraintAst = TableColumnNullableAst | TableColumnDefaultAst | TableColumnPkAst | TableColumnUniqueAst | TableColumnCheckAst | TableColumnFkAst
export type TableColumnNullableAst = { kind: 'Nullable', value: boolean } & TableConstraintCommonAst
export type TableColumnDefaultAst = { kind: 'Default', expression: ExpressionAst } & TableConstraintCommonAst
export type TableColumnPkAst = { kind: 'PrimaryKey' } & TableConstraintCommonAst
export type TableColumnUniqueAst = { kind: 'Unique' } & TableConstraintCommonAst
export type TableColumnCheckAst = { kind: 'Check', predicate: ExpressionAst } & TableConstraintCommonAst
export type TableColumnFkAst = { kind: 'ForeignKey', schema?: IdentifierAst, table: IdentifierAst, column?: IdentifierAst, onUpdate?: ForeignKeyActionAst & {token: TokenInfo}, onDelete?: ForeignKeyActionAst & {token: TokenInfo} } & TableConstraintCommonAst
export type TableConstraintAst = TablePkAst | TableUniqueAst | TableCheckAst | TableFkAst
export type TablePkAst = { kind: 'PrimaryKey', columns: IdentifierAst[] } & TableConstraintCommonAst
export type TableUniqueAst = { kind: 'Unique', columns: IdentifierAst[] } & TableConstraintCommonAst
export type TableCheckAst = { kind: 'Check', predicate: ExpressionAst } & TableConstraintCommonAst
export type TableFkAst = { kind: 'ForeignKey', columns: IdentifierAst[], ref: { token: TokenInfo, schema?: IdentifierAst, table: IdentifierAst, columns?: IdentifierAst[] }, onUpdate?: ForeignKeyActionAst & {token: TokenInfo}, onDelete?: ForeignKeyActionAst & {token: TokenInfo} } & TableConstraintCommonAst
export type TableConstraintCommonAst = { token: TokenInfo, constraint?: NameAst }
export type TableCreateModeAst = ({ kind: 'Unlogged', token: TokenInfo }) | ({ kind: 'Temporary', token: TokenInfo, scope?: { kind: 'Local' | 'Global', token: TokenInfo } })
export type TransactionChainAst = { token: TokenInfo, no?: TokenAst }
export type TransactionModeAst = { kind: 'IsolationLevel', token: TokenInfo, level: { kind: 'Serializable' | 'RepeatableRead' | 'ReadCommitted' | 'ReadUncommitted', token: TokenInfo } } | { kind: 'ReadWrite' | 'ReadOnly', token: TokenInfo } | { kind: 'Deferrable', token: TokenInfo, not?: TokenAst }
export type TransactionObjectAst = { kind: 'Work' | 'Transaction', token: TokenInfo }
export type TriggerDeferrableAst = { kind: 'Deferrable' | 'NotDeferrable', token: TokenInfo, initially?: { kind: 'Immediate' | 'Deferred', token: TokenInfo } }
export type TriggerEventAst = { kind: 'Insert' | 'Update' | 'Delete' | 'Truncate', token: TokenInfo, columns?: IdentifierAst }
export type TriggerExecuteAst = { token: TokenInfo, schema?: IdentifierAst, function: IdentifierAst, arguments: ExpressionAst[] }
export type TriggerFromAst = { token: TokenInfo, schema?: IdentifierAst, table: IdentifierAst }
export type TriggerReferencingAst = { token: TokenInfo, old?: NameAst, new?: NameAst }
export type TriggerTargetAst = { kind: 'Row' | 'Statement', token: TokenInfo }
export type TriggerTimingAst = { kind: 'Before' | 'After' | 'InsteadOf', token: TokenInfo }
export type TypeBaseAttrAst = { name: IdentifierAst, value: ExpressionAst }
export type TypeColumnAst = { name: IdentifierAst, type: ColumnTypeAst, collation?: NameAst }
export type TypeEnumAst = { token: TokenInfo, values: StringAst[] }
export type TypeStructAst = { token: TokenInfo, attrs: TypeColumnAst[] }
export type ViewMaterializedDataAst = { token: TokenInfo, no?: TokenAst }

// basic parts
export type AliasAst = { token?: TokenInfo, name: IdentifierAst }
export type NameAst = { token: TokenInfo, name: IdentifierAst }
export type FilterAst = { token: TokenInfo, condition: ExpressionAst }
export type ObjectNameAst = { schema?: IdentifierAst, name: IdentifierAst }
export type OwnerAst = { kind: 'User', name: IdentifierAst } | { kind: 'CurrentRole' | 'CurrentUser' | 'SessionUser', token: TokenInfo }
export type ExpressionAst = (LiteralAst | ParameterAst | ColumnAst | WildcardAst | FunctionAst | GroupAst | OperationAst | OperationLeftAst | OperationRightAst | ArrayAst | ListAst) & { cast?: { token: TokenInfo, type: ColumnTypeAst } }
export type LiteralAst = StringAst | IntegerAst | DecimalAst | BooleanAst | NullAst
export type ColumnAst = { kind: 'Column', schema?: IdentifierAst, table?: IdentifierAst, column: IdentifierAst, json?: ColumnJsonAst[] }
export type ColumnJsonAst = { kind: JsonOp, token: TokenInfo, field: StringAst | ParameterAst }
export type FunctionAst = { kind: 'Function', schema?: IdentifierAst, function: IdentifierAst, distinct?: TokenAst, parameters: ExpressionAst[] }
export type GroupAst = { kind: 'Group', expression: ExpressionAst }
export type WildcardAst = { kind: 'Wildcard', token: TokenInfo, schema?: IdentifierAst, table?: IdentifierAst }
export type OperationAst = { kind: 'Operation', left: ExpressionAst, op: OperatorAst, right: ExpressionAst }
export type OperatorAst = { kind: Operator, token: TokenInfo }
export type OperationLeftAst = { kind: 'OperationLeft', op: OperatorLeftAst, right: ExpressionAst }
export type OperatorLeftAst = { kind: OperatorLeft, token: TokenInfo }
export type OperationRightAst = { kind: 'OperationRight', left: ExpressionAst, op: OperatorRightAst }
export type OperatorRightAst = { kind: OperatorRight, token: TokenInfo }
export type ArrayAst = { kind: 'Array', token: TokenInfo, items: ExpressionAst[] }
export type ListAst = { kind: 'List', items: LiteralAst[] }
export type SortOrderAst = { kind: SortOrder, token: TokenInfo }
export type SortNullsAst = { kind: SortNulls, token: TokenInfo }

// elements
export type ParameterAst = { kind: 'Parameter', token: TokenInfo, value: string, index?: number }
export type IdentifierAst = { kind: 'Identifier', token: TokenInfo, value: string, quoted?: boolean }
export type StringAst = { kind: 'String', token: TokenInfo, value: string, escaped?: boolean, dollar?: string }
export type DecimalAst = { kind: 'Decimal', token: TokenInfo, value: number }
export type IntegerAst = { kind: 'Integer', token: TokenInfo, value: number }
export type BooleanAst = { kind: 'Boolean', token: TokenInfo, value: boolean }
export type NullAst = { kind: 'Null', token: TokenInfo }
export type CommentAst = { kind: CommentKind, token: TokenInfo, value: string } // special case
export type TokenAst = { token: TokenInfo }

// enums
export type Operator = '+' | '-' | '*' | '/' | '%' | '^' | '&' | '|' | '#' | '<<' | '>>' | '=' | '<' | '>' | '<=' | '>=' | '<>' | '!=' | '||' | '~' | '~*' | '!~' | '!~*' | 'Is' | 'IsNot' | 'Like' | 'NotLike' | 'In' | 'NotIn' | 'DistinctFrom' | 'NotDistinctFrom' | 'Or' | 'And'
export type OperatorLeft = 'Not' | 'Interval' | '~'
export type OperatorRight = 'IsNull' | 'NotNull'
export type JsonOp = '->' | '->>' | '#>' | '#>>'
export type ForeignKeyAction = 'NoAction' | 'Restrict' | 'Cascade' | 'SetNull' | 'SetDefault'
export type DropObject = 'Index' | 'MaterializedView' | 'Sequence' | 'Table' | 'Type' | 'View'
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
