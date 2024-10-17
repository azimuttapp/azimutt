import {
    createToken,
    EmbeddedActionsParser,
    ILexingError,
    IRecognitionException,
    IToken,
    Lexer,
    TokenType
} from "chevrotain";
import {isNotUndefined, removeEmpty, removeUndefined} from "@azimutt/utils";
import {mergePositions, ParserError, ParserErrorLevel, ParserResult, TokenPosition} from "@azimutt/models";
import {
    AliasAst,
    BooleanAst,
    ColumnAst,
    CommentAst,
    ConditionAst,
    ConstraintNameAst,
    CreateTableStatementAst,
    DecimalAst,
    DropStatementAst,
    ExpressionAst,
    ForeignKeyActionAst,
    FromClauseAst,
    IdentifierAst,
    IntegerAst,
    LiteralAst,
    OperatorAst,
    SelectClauseAst,
    SelectClauseExprAst,
    SelectStatementAst,
    SetStatementAst,
    StatementAst,
    StatementsAst,
    StringAst,
    TableAst,
    TableColumnAst,
    TableColumnCheckAst,
    TableColumnConstraintAst,
    TableColumnDefaultAst,
    TableColumnFkAst,
    TableColumnNullableAst,
    TableColumnPkAst,
    TableColumnUniqueAst,
    TableConstraintAst,
    TableFkAst,
    TablePkAst,
    TableUniqueAst,
    TokenInfo,
    TokenIssue,
    WhereClauseAst
} from "./postgresAst";

const LineComment = createToken({name: 'LineComment', pattern: /--.*/, group: 'comments'})
const BlockComment = createToken({name: 'BlockComment', pattern: /\/\*[^]*?\*\//, line_breaks: true, group: 'comments'})
const WhiteSpace = createToken({name: 'WhiteSpace', pattern: /\s+/, group: Lexer.SKIPPED})

const Identifier = createToken({name: 'Identifier', pattern: /\b[a-zA-Z_]\w*\b|"([^\\"]|\\\\|\\")+"/})
const String = createToken({name: 'String', pattern: /'([^\\']|'')+'/})
const Decimal = createToken({name: 'Decimal', pattern: /\d+\.\d+/})
const Integer = createToken({name: 'Integer', pattern: /0|[1-9]\d*/, longer_alt: Decimal})
const valueTokens: TokenType[] = [Integer, Decimal, String, Identifier, LineComment, BlockComment]

const And = createToken({name: 'And', pattern: /\bAND\b/i, longer_alt: Identifier})
const As = createToken({name: 'As', pattern: /\bAS\b/i, longer_alt: Identifier})
const Cascade = createToken({name: 'Cascade', pattern: /\bCASCADE\b/i, longer_alt: Identifier})
const Check = createToken({name: 'Check', pattern: /\bCHECK\b/i, longer_alt: Identifier})
const Concurrently = createToken({name: 'Concurrently', pattern: /\bCONCURRENTLY\b/i, longer_alt: Identifier})
const Constraint = createToken({name: 'Constraint', pattern: /\bCONSTRAINT\b/i, longer_alt: Identifier})
const Create = createToken({name: 'Create', pattern: /\bCREATE\b/i, longer_alt: Identifier})
const Default = createToken({name: 'Default', pattern: /\bDEFAULT\b/i, longer_alt: Identifier})
const Delete = createToken({name: 'Delete', pattern: /\bDELETE\b/i, longer_alt: Identifier})
const Distinct = createToken({name: 'Distinct', pattern: /\bDISTINCT\b/i, longer_alt: Identifier})
const Drop = createToken({name: 'Drop', pattern: /\bDROP\b/i, longer_alt: Identifier})
const False = createToken({name: 'False', pattern: /\bFALSE\b/i, longer_alt: Identifier})
const Fetch = createToken({name: 'Fetch', pattern: /\bFETCH\b/i, longer_alt: Identifier})
const ForeignKey = createToken({name: 'ForeignKey', pattern: /\bFOREIGN\s+KEY\b/i})
const From = createToken({name: 'From', pattern: /\bFROM\b/i, longer_alt: Identifier})
const GroupBy = createToken({name: 'GroupBy', pattern: /\bGROUP\s+BY\b/i})
const Having = createToken({name: 'Having', pattern: /\bHAVING\b/i, longer_alt: Identifier})
const IfExists = createToken({name: 'IfExists', pattern: /\bIF\s+EXISTS\b/i})
const Index = createToken({name: 'Index', pattern: /\bINDEX\b/i, longer_alt: Identifier})
const Join = createToken({name: 'Join', pattern: /\bJOIN\b/i, longer_alt: Identifier})
const Like = createToken({name: 'Like', pattern: /\bLIKE\b/i, longer_alt: Identifier})
const Limit = createToken({name: 'Limit', pattern: /\bLIMIT\b/i, longer_alt: Identifier})
const Local = createToken({name: 'Local', pattern: /\bLOCAL\b/i, longer_alt: Identifier})
const MaterializedView = createToken({name: 'MaterializedView', pattern: /\bMATERIALIZED\s+VIEW\b/i})
const NoAction = createToken({name: 'NoAction', pattern: /\bNO\s+ACTION\b/i})
const Not = createToken({name: 'Not', pattern: /\bNOT\b/i, longer_alt: Identifier})
const Null = createToken({name: 'Null', pattern: /\bNULL\b/i, longer_alt: Identifier})
const Offset = createToken({name: 'Offset', pattern: /\bOFFSET\b/i, longer_alt: Identifier})
const On = createToken({name: 'On', pattern: /\bON\b/i, longer_alt: Identifier})
const Or = createToken({name: 'Or', pattern: /\bOR\b/i, longer_alt: Identifier})
const OrderBy = createToken({name: 'OrderBy', pattern: /\bORDER\s+BY\b/i})
const PrimaryKey = createToken({name: 'PrimaryKey', pattern: /\bPRIMARY\s+KEY\b/i})
const References = createToken({name: 'References', pattern: /\bREFERENCES\b/i, longer_alt: Identifier})
const Restrict = createToken({name: 'Restrict', pattern: /\bRESTRICT\b/i, longer_alt: Identifier})
const Select = createToken({name: 'Select', pattern: /\bSELECT\b/i, longer_alt: Identifier})
const Session = createToken({name: 'Session', pattern: /\bSESSION\b/i, longer_alt: Identifier})
const SetDefault = createToken({name: 'SetDefault', pattern: /\bSET\s+DEFAULT\b/i})
const SetNull = createToken({name: 'SetNull', pattern: /\bSET\s+NULL\b/i})
const Set = createToken({name: 'Set', pattern: /\bSET\b/i, longer_alt: Identifier})
const Table = createToken({name: 'Table', pattern: /\bTABLE\b/i, longer_alt: Identifier})
const To = createToken({name: 'To', pattern: /\bTO\b/i, longer_alt: Identifier})
const True = createToken({name: 'True', pattern: /\bTRUE\b/i, longer_alt: Identifier})
const Type = createToken({name: 'Type', pattern: /\bTYPE\b/i, longer_alt: Identifier})
const Union = createToken({name: 'Union', pattern: /\bUNION\b/i, longer_alt: Identifier})
const Unique = createToken({name: 'Unique', pattern: /\bUNIQUE\b/i, longer_alt: Identifier})
const Update = createToken({name: 'Update', pattern: /\bUPDATE\b/i, longer_alt: Identifier})
const View = createToken({name: 'View', pattern: /\bVIEW\b/i, longer_alt: Identifier})
const Where = createToken({name: 'Where', pattern: /\bWHERE\b/i, longer_alt: Identifier})
const Window = createToken({name: 'Window', pattern: /\bWINDOW\b/i, longer_alt: Identifier})
const keywordTokens: TokenType[] = [
    And, As, Cascade, Check, Concurrently, Constraint, Create, Default, Delete, Distinct, Drop, False, Fetch, ForeignKey, From, GroupBy, Having,
    IfExists, Index, Join, Like, Limit, Local, MaterializedView, NoAction, Not, Null, Offset, On, Or, OrderBy, PrimaryKey, References, Restrict,
    Select, Session, SetDefault, SetNull, Set, Table, To, True, Type, Union, Unique, Update, View, Where, Window
]

const Asterisk = createToken({ name: 'Asterisk', pattern: /\*/ })
const BracketLeft = createToken({ name: 'BracketLeft', pattern: /\[/ })
const BracketRight = createToken({ name: 'BracketRight', pattern: /]/ })
const Comma = createToken({name: 'Comma', pattern: /,/})
const CurlyLeft = createToken({ name: 'CurlyLeft', pattern: /\{/ })
const CurlyRight = createToken({ name: 'CurlyRight', pattern: /}/ })
const Dot = createToken({name: 'Dot', pattern: /\./})
const Equal = createToken({name: 'Equal', pattern: /=/})
const GreaterThan = createToken({name: 'GreaterThan', pattern: />/})
const LowerThan = createToken({name: 'LowerThan', pattern: /</})
const ParenLeft = createToken({ name: 'ParenLeft', pattern: /\(/ })
const ParenRight = createToken({ name: 'ParenRight', pattern: /\)/ })
const Semicolon = createToken({name: 'Semicolon', pattern: /;/})
const charTokens: TokenType[] = [Asterisk, BracketLeft, BracketRight, Comma, CurlyLeft, CurlyRight, Dot, Equal, GreaterThan, LowerThan, ParenLeft, ParenRight, Semicolon]

const allTokens: TokenType[] = [WhiteSpace, ...keywordTokens, ...charTokens, ...valueTokens]

const defaultPos: number = -1 // used when error position is undefined

class PostgresParser extends EmbeddedActionsParser {
    // top level
    statementsRule: () => StatementsAst
    // statements
    statementRule: () => StatementAst
    selectStatementRule: () => SelectStatementAst
    createTableStatementRule: () => CreateTableStatementAst
    dropStatementRule: () => DropStatementAst
    setStatementRule: () => SetStatementAst
    // clauses
    selectClauseRule: () => SelectClauseAst
    fromClauseRule: () => FromClauseAst
    whereClauseRule: () => WhereClauseAst
    tableColumnRule: () => TableColumnAst
    tableConstraintRule: () => TableConstraintAst
    // basic parts
    aliasRule: () => AliasAst
    conditionRule: () => ConditionAst
    operatorRule: () => OperatorAst
    expressionRule: () => ExpressionAst
    tableRule: () => TableAst
    columnRule: () => ColumnAst
    literalRule: () => LiteralAst
    // elements
    identifierRule: () => IdentifierAst
    stringRule: () => StringAst
    integerRule: () => IntegerAst
    decimalRule: () => DecimalAst
    booleanRule: () => BooleanAst

    constructor(tokens: TokenType[], recovery: boolean) {
        super(tokens, {recoveryEnabled: recovery})
        const $ = this

        // statements

        this.statementsRule = $.RULE<() => StatementsAst>('statementsRule', () => {
            const statements: StatementAst[] = []
            $.MANY(() => {
                const stmt = $.SUBRULE($.statementRule)
                stmt && statements.push(stmt) // `stmt` can be undefined on invalid input
            })
            return {statements}
        })

        this.statementRule = $.RULE<() => StatementAst>('statementRule', () => $.OR([
            { ALT: () => $.SUBRULE($.selectStatementRule) },
            { ALT: () => $.SUBRULE($.createTableStatementRule) },
            { ALT: () => $.SUBRULE($.dropStatementRule) },
            { ALT: () => $.SUBRULE($.setStatementRule) },
        ]))

        // https://www.postgresql.org/docs/current/sql-select.html
        this.selectStatementRule = $.RULE<() => SelectStatementAst>('selectStatementRule', () => {
            const select = $.SUBRULE($.selectClauseRule)
            const from = $.OPTION(() => $.SUBRULE($.fromClauseRule))
            const where = $.OPTION2(() => $.SUBRULE($.whereClauseRule))
            const token = $.CONSUME(Semicolon)
            return removeUndefined({statement: 'Select' as const, select, from, where, ...mergePositions([select, tokenInfo(token)])})
        })

        this.createTableStatementRule = $.RULE<() => CreateTableStatementAst>('createTableStatementRule', () => {
            const create = $.CONSUME(Create)
            $.CONSUME(Table)
            const name = $.SUBRULE($.tableRule)
            $.CONSUME(ParenLeft)
            const columns: TableColumnAst[] = []
            const constraints: TableConstraintAst[] = []
            $.MANY_SEP({SEP: Comma, DEF: () => $.OR([
                { ALT: () => columns.push($.SUBRULE($.tableColumnRule)) },
                { ALT: () => constraints.push($.SUBRULE($.tableConstraintRule)) },
            ])})
            $.CONSUME(ParenRight)
            const token = $.CONSUME(Semicolon)
            return removeEmpty({ statement: 'CreateTable' as const, name, columns: columns.filter(isNotUndefined), constraints: constraints.filter(isNotUndefined), ...tokensInfo(create, token) })
        })

        this.dropStatementRule = $.RULE<() => DropStatementAst>('dropStatementRule', () => {
            const drop = $.CONSUME(Drop)
            const kind = $.OR([
                {ALT: () => ({kind: 'Table' as const, ...tokensInfo(drop, $.CONSUME(Table))})}, // https://www.postgresql.org/docs/current/sql-droptable.html
                {ALT: () => ({kind: 'View' as const, ...tokensInfo(drop, $.CONSUME(View))})}, // https://www.postgresql.org/docs/current/sql-dropview.html
                {ALT: () => ({kind: 'MaterializedView' as const, ...tokensInfo(drop, $.CONSUME(MaterializedView))})}, // https://www.postgresql.org/docs/current/sql-dropmaterializedview.html
                {ALT: () => ({kind: 'Index' as const, ...tokensInfo(drop, $.CONSUME(Index))})}, // https://www.postgresql.org/docs/current/sql-dropindex.html
                {ALT: () => ({kind: 'Type' as const, ...tokensInfo(drop, $.CONSUME(Type))})}, // https://www.postgresql.org/docs/current/sql-droptype.html
            ])
            const concurrently = $.OPTION(() => tokenInfo($.CONSUME(Concurrently)))
            const ifExists = $.OPTION2(() => tokenInfo($.CONSUME(IfExists)))
            const entities: TableAst[] = []
            $.AT_LEAST_ONE_SEP({
                SEP: Comma,
                DEF: () => {
                    const entity = $.SUBRULE($.tableRule)
                    entity && entities.push(entity)
                }
            })
            const mode = $.OPTION3(() => $.OR2([
                {ALT: () => ({kind: 'Cascade' as const, ...tokenInfo($.CONSUME(Cascade))})},
                {ALT: () => ({kind: 'Restrict' as const, ...tokenInfo($.CONSUME(Restrict))})},
            ]))
            const token = $.CONSUME(Semicolon)
            return removeUndefined({statement: 'Drop' as const, kind, entities, concurrently, ifExists, mode, ...tokensInfo(drop, token)})
        })

        this.setStatementRule = $.RULE<() => SetStatementAst>('setStatementRule', () => {
            const set = $.CONSUME(Set)
            const scope = $.OPTION(() => $.OR([
                {ALT: () => ({kind: 'Session' as const, ...tokenInfo($.CONSUME(Session))})},
                {ALT: () => ({kind: 'Local' as const, ...tokenInfo($.CONSUME(Local))})},
            ]))
            const parameter = $.SUBRULE($.identifierRule)
            const equal = $.OR2([
                {ALT: () => ({kind: '=' as const, ...tokenInfo($.CONSUME(Equal))})},
                {ALT: () => ({kind: 'To' as const, ...tokenInfo($.CONSUME(To))})},
            ])
            const value = $.OR3([
                {ALT: () => ({kind: 'Default' as const, ...tokenInfo($.CONSUME(Default))})},
                {ALT: () => {
                    const values: (IdentifierAst | LiteralAst)[] = []
                    $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => values.push($.OR4([
                        {ALT: () => $.SUBRULE2($.literalRule)},
                        {ALT: () => $.SUBRULE3($.identifierRule)},
                        {ALT: () => {const on = $.CONSUME(On); return {kind: 'Identifier', value: on.image, ...tokenInfo(on)}}}, // special case
                    ]))})
                    return values.length === 1 ? values[0] : values
                }},
            ])
            const token = $.CONSUME(Semicolon)
            return removeUndefined({statement: 'Set' as const, scope, parameter, equal, value, ...tokensInfo(set, token)})
        })

        // clauses

        this.selectClauseRule = $.RULE<() => SelectClauseAst>('selectClauseRule', () => {
            const token = $.CONSUME(Select)
            const expressions: SelectClauseExprAst[] = []
            $.AT_LEAST_ONE_SEP({
                SEP: Comma,
                DEF: () => {
                    const expression = $.SUBRULE($.expressionRule)
                    const alias = $.OPTION(() => $.SUBRULE($.aliasRule))
                    expression && expressions.push(removeUndefined({...expression, alias}))
                }
            })
            return {...tokenInfo(token), expressions}
        })

        this.fromClauseRule = $.RULE<() => FromClauseAst>('fromClauseRule', () => {
            const token = $.CONSUME(From)
            const table = $.SUBRULE($.identifierRule)
            const alias = $.OPTION(() => $.SUBRULE($.aliasRule))
            return removeUndefined({...tokenInfo(token), table, alias})
        })

        this.whereClauseRule = $.RULE<() => WhereClauseAst>('whereClauseRule', () => {
            const token = $.CONSUME(Where)
            return {...tokenInfo(token), condition: $.SUBRULE($.conditionRule)}
        })

        this.tableColumnRule = $.RULE<() => TableColumnAst>('tableColumnRule', () => {
            const name = $.SUBRULE($.identifierRule)
            const type = $.SUBRULE2($.identifierRule) // TODO: handle types with space (timestamp without time zone), numbers (character varying(255)) and schema (public.citext)
            const constraints: TableColumnConstraintAst[] = []
            $.MANY(() => constraints.push($.SUBRULE(tableColumnConstraintRule)))
            return removeEmpty({name, type, constraints: constraints.filter(isNotUndefined)})
        })
        const tableColumnConstraintRule = $.RULE<() => TableColumnConstraintAst>('tableColumnConstraintRule', () => $.OR([
            { ALT: () => $.SUBRULE(tableColumnNullableRule) },
            { ALT: () => $.SUBRULE(tableColumnDefaultRule) },
            { ALT: () => $.SUBRULE(tableColumnPkRule) },
            { ALT: () => $.SUBRULE(tableColumnUniqueRule) },
            { ALT: () => $.SUBRULE(tableColumnCheckRule) },
            { ALT: () => $.SUBRULE(tableColumnFkRule) },
        ]))
        const tableColumnNullableRule = $.RULE<() => TableColumnNullableAst>('tableColumnNullableRule', () => {
            const constraint = $.OPTION(() => $.SUBRULE(constraintNameRule))
            const not = $.OPTION2(() => $.CONSUME(Not))
            const nullable = $.CONSUME(Null)
            const value = !not
            const token = not ? tokensInfo(not, nullable) : tokenInfo(nullable)
            return removeUndefined({kind: 'Nullable' as const, value, constraint, ...token})
        })
        const tableColumnDefaultRule = $.RULE<() => TableColumnDefaultAst>('tableColumnDefaultRule', () => {
            const constraint = $.OPTION(() => $.SUBRULE(constraintNameRule))
            const token = $.CONSUME(Default)
            const expression = $.SUBRULE($.expressionRule) // TODO: handle type conversion (DEFAULT 'none'::character varying)
            return removeUndefined({kind: 'Default' as const, expression, constraint, ...tokenInfo(token)})
        })
        const tableColumnPkRule = $.RULE<() => TableColumnPkAst>('tableColumnPkRule', () => {
            const constraint = $.OPTION(() => $.SUBRULE(constraintNameRule))
            const token = $.CONSUME(PrimaryKey)
            return removeUndefined({kind: 'PrimaryKey' as const, constraint, ...tokenInfo(token)})
        })
        const tableColumnUniqueRule = $.RULE<() => TableColumnUniqueAst>('tableColumnUniqueRule', () => {
            const constraint = $.OPTION(() => $.SUBRULE(constraintNameRule))
            const token = $.CONSUME(Unique)
            return removeUndefined({kind: 'Unique' as const, constraint, ...tokenInfo(token)})
        })
        const tableColumnCheckRule = $.RULE<() => TableColumnCheckAst>('tableColumnCheckRule', () => {
            const constraint = $.OPTION(() => $.SUBRULE(constraintNameRule))
            const token = $.CONSUME(Check)
            $.CONSUME(ParenLeft)
            const predicate = $.SUBRULE($.conditionRule)
            $.CONSUME(ParenRight)
            return removeUndefined({kind: 'Check' as const, constraint, ...tokenInfo(token), predicate})
        })
        const tableColumnFkRule = $.RULE<() => TableColumnFkAst>('tableColumnFkRule', () => {
            const constraint = $.OPTION(() => $.SUBRULE(constraintNameRule))
            const token = $.CONSUME(References)
            const table = $.SUBRULE($.tableRule)
            const column = $.OPTION2(() => {
                $.CONSUME(ParenLeft)
                const column = $.SUBRULE($.identifierRule)
                $.CONSUME(ParenRight)
                return column
            })
            const onUpdate = $.OPTION3(() => ({...tokensInfo($.CONSUME(On), $.CONSUME(Update)), ...$.SUBRULE(foreignKeyActionsRule)}))
            const onDelete = $.OPTION4(() => ({...tokensInfo($.CONSUME2(On), $.CONSUME(Delete)), ...$.SUBRULE2(foreignKeyActionsRule)}))
            return removeUndefined({kind: 'ForeignKey' as const, ...table, column, onUpdate, onDelete, constraint, ...tokenInfo(token)})
        })

        this.tableConstraintRule = $.RULE<() => TableConstraintAst>('tableConstraintRule', () => $.OR([
            { ALT: () => $.SUBRULE(tablePkRule) },
            { ALT: () => $.SUBRULE(tableUniqueRule) },
            { ALT: () => $.SUBRULE(tableCheckRule) },
            { ALT: () => $.SUBRULE(tableFkRule) },
        ]))
        const tablePkRule = $.RULE<() => TablePkAst>('tablePkRule', () => {
            const constraint = $.OPTION(() => $.SUBRULE(constraintNameRule))
            const token = $.CONSUME(PrimaryKey)
            const columns = $.SUBRULE(columnNamesRule)
            return removeUndefined({kind: 'PrimaryKey' as const, constraint, ...tokenInfo(token), columns})
        })
        const tableUniqueRule = $.RULE<() => TableUniqueAst>('tableUniqueRule', () => {
            const constraint = $.OPTION(() => $.SUBRULE(constraintNameRule))
            const token = $.CONSUME(Unique)
            const columns = $.SUBRULE(columnNamesRule)
            return removeUndefined({kind: 'Unique' as const, constraint, ...tokenInfo(token), columns})
        })
        const tableCheckRule = tableColumnCheckRule // exactly the same ^^
        const tableFkRule = $.RULE<() => TableFkAst>('tableFkRule', () => {
            const constraint = $.OPTION(() => $.SUBRULE(constraintNameRule))
            const token = $.CONSUME(ForeignKey)
            const columns = $.SUBRULE(columnNamesRule)
            const refToken = $.CONSUME(References)
            const refTable = $.SUBRULE($.tableRule)
            const refColumns = $.OPTION2(() => $.SUBRULE2(columnNamesRule))
            const onUpdate = $.OPTION3(() => ({...tokensInfo($.CONSUME(On), $.CONSUME(Update)), ...$.SUBRULE(foreignKeyActionsRule)}))
            const onDelete = $.OPTION4(() => ({...tokensInfo($.CONSUME2(On), $.CONSUME(Delete)), ...$.SUBRULE2(foreignKeyActionsRule)}))
            const ref = {...tokenInfo(refToken), ...refTable, columns: refColumns}
            return removeUndefined({kind: 'ForeignKey' as const, ...tokenInfo(token), columns, ref, onUpdate, onDelete, constraint})
        })

        const constraintNameRule = $.RULE<() => ConstraintNameAst>('constraintNameRule', () => {
            const token = $.CONSUME(Constraint)
            const name = $.SUBRULE($.identifierRule)
            return {...tokenInfo(token), name}
        })
        const foreignKeyActionsRule = $.RULE<() => ForeignKeyActionAst>('foreignKeyActionsRule', () => {
            const res = $.OR([
                { ALT: () => ({action: {kind: 'NoAction' as const, ...tokenInfo($.CONSUME(NoAction))}}) },
                { ALT: () => ({action: {kind: 'Restrict' as const, ...tokenInfo($.CONSUME(Restrict))}}) },
                { ALT: () => ({action: {kind: 'Cascade' as const, ...tokenInfo($.CONSUME(Cascade))}}) },
                { ALT: () => ({action: {kind: 'SetNull' as const, ...tokenInfo($.CONSUME(SetNull))}}) },
                { ALT: () => ({action: {kind: 'SetDefault' as const, ...tokenInfo($.CONSUME(SetDefault))}}) },
            ])
            const columns = $.OPTION(() => $.SUBRULE(columnNamesRule))
            return removeEmpty({...res, columns})
        })
        const columnNamesRule = $.RULE<() => IdentifierAst[]>('columnNamesRule', () => {
            $.CONSUME(ParenLeft)
            const columns: IdentifierAst[] = []
            $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => columns.push($.SUBRULE($.identifierRule))})
            $.CONSUME(ParenRight)
            return columns.filter(isNotUndefined)
        })

        // basic parts

        this.aliasRule = $.RULE<() => AliasAst>('aliasRule', () => {
            const token = $.CONSUME(As)
            const name = $.SUBRULE($.identifierRule)
            return {...tokenInfo(token), name}
        })

        this.conditionRule = $.RULE<() => ConditionAst>('conditionRule', () => {
            const left = $.SUBRULE($.expressionRule)
            const operator = $.SUBRULE($.operatorRule)
            const right = $.SUBRULE2($.expressionRule)
            return {left, operator, right}
        })

        this.operatorRule = $.RULE<() => OperatorAst>('operatorRule', () => $.OR([
            {ALT: () => ({kind: '=' as const, ...tokenInfo($.CONSUME(Equal))})},
            {ALT: () => ({kind: '<' as const, ...tokenInfo($.CONSUME(LowerThan))})},
            {ALT: () => ({kind: '>' as const, ...tokenInfo($.CONSUME(GreaterThan))})},
            {ALT: () => ({kind: 'Like' as const, ...tokenInfo($.CONSUME(Like))})},
        ]))

        this.expressionRule = $.RULE<() => ExpressionAst>('expressionRule', () => $.OR([
            { ALT: () => $.SUBRULE($.columnRule) },
            { ALT: () => $.SUBRULE($.literalRule) },
        ]))

        this.tableRule = $.RULE<() => TableAst>('tableRule', () => {
            const first = $.SUBRULE($.identifierRule)
            const second = $.OPTION(() => {
                $.CONSUME(Dot)
                return $.SUBRULE2($.identifierRule)
            })
            const [table, schema] = [second, first].filter(isNotUndefined)
            return removeUndefined({table, schema})
        })

        this.columnRule = $.RULE<() => ColumnAst>('columnRule', () => {
            const first = $.SUBRULE($.identifierRule)
            const second = $.OPTION(() => {
                $.CONSUME(Dot)
                return $.SUBRULE2($.identifierRule)
            })
            const third = $.OPTION2(() => {
                $.CONSUME2(Dot)
                return $.SUBRULE3($.identifierRule)
            })
            const [column, table, schema] = [third, second, first].filter(isNotUndefined)
            return removeUndefined({column, table, schema})
        })

        this.literalRule = $.RULE<() => LiteralAst>('literalRule', () => $.OR([
            { ALT: () => $.SUBRULE($.stringRule) },
            { ALT: () => $.SUBRULE($.decimalRule) },
            { ALT: () => $.SUBRULE($.integerRule) },
            { ALT: () => $.SUBRULE($.booleanRule) },
        ]))

        // elements

        this.identifierRule = $.RULE<() => IdentifierAst>('identifierRule', () => {
            const token = $.CONSUME(Identifier)
            if (token.image.startsWith('"') && token.image.endsWith('"')) {
                return {kind: 'Identifier', value: token.image.slice(1, -1).replaceAll(/\\"/g, '"'), quoted: true, ...tokenInfo(token)}
            } else {
                return {kind: 'Identifier', value: token.image, ...tokenInfo(token)}
            }
        })

        this.stringRule = $.RULE<() => StringAst>('stringRule', () => {
            const token = $.CONSUME(String)
            return {kind: 'String', value: token.image.slice(1, -1).replaceAll(/''/g, "'"), ...tokenInfo(token)}
        })

        this.integerRule = $.RULE<() => IntegerAst>('integerRule', () => {
            const token = $.CONSUME(Integer)
            return {kind: 'Integer', value: parseInt(token.image), ...tokenInfo(token)}
        })

        this.decimalRule = $.RULE<() => DecimalAst>('decimalRule', () => {
            const token = $.CONSUME(Decimal)
            return {kind: 'Decimal', value: parseFloat(token.image), ...tokenInfo(token)}
        })

        this.booleanRule = $.RULE<() => BooleanAst>('booleanRule', () => $.OR([
            { ALT: () => ({kind: 'Boolean', value: true, ...tokenInfo($.CONSUME(True))}) },
            { ALT: () => ({kind: 'Boolean', value: false, ...tokenInfo($.CONSUME(False))}) },
        ]))

        this.performSelfAnalysis()
    }
}

const lexer = new Lexer(allTokens)
const parserStrict = new PostgresParser(allTokens, false)
const parserWithRecovery = new PostgresParser(allTokens, true)

// exported only for tests, use the `parse` function instead
export function parseRule<T extends object>(parse: (p: PostgresParser) => T, input: string, strict: boolean = false): ParserResult<T & { comments?: CommentAst[] }> {
    const lexingResult = lexer.tokenize(input)
    const parser = strict ? parserStrict : parserWithRecovery
    parser.input = lexingResult.tokens // "input" is a setter which will reset the parser's state.
    const res = parse(parser)
    const errors = lexingResult.errors.map(formatLexerError).concat(parser.errors.map(formatParserError))
    const comments = lexingResult.groups.comments.map(buildComment)
    return new ParserResult(comments.length > 0 ? {...res, comments} : res, errors)
}

export function parsePostgresAst(input: string, opts: { strict?: boolean } = {strict: false}): ParserResult<StatementsAst & { comments?: CommentAst[] }> {
    return parseRule(p => p.statementsRule(), input, opts.strict || false)
}

function buildComment(token: IToken): CommentAst {
    if (token.tokenType.name === 'LineComment') {
        return {kind: 'line', value: token.image.slice(2).trim(), ...tokenInfo(token)}
    } else if (token.image.startsWith('/*\n *') && token.image.endsWith('\n */')) {
        return {kind: 'doc', value: token.image.slice(3, -4).split('\n').map(line => line.startsWith(' *') ? line.slice(2).trim() : line.trim()).join('\n'), ...tokenInfo(token)}
    } else {
        return {kind: 'block', value: token.image.slice(2, -2).trim(), ...tokenInfo(token)}
    }
}

function formatLexerError(err: ILexingError): ParserError {
    return {
        message: err.message,
        kind: 'LexingError',
        level: ParserErrorLevel.enum.error,
        offset: {start: err.offset, end: err.offset + err.length},
        position: {
            start: {line: err.line || defaultPos, column: err.column || defaultPos},
            end: {line: err.line || defaultPos, column: (err.column || defaultPos) + err.length}
        }
    }
}

function formatParserError(err: IRecognitionException): ParserError {
    return {message: err.message, kind: err.name, level: ParserErrorLevel.enum.error, ...tokenInfo(err.token)}
}

function tokenInfo(token: IToken, issues?: TokenIssue[]): TokenInfo {
    return removeEmpty({...tokenPosition(token), issues})
}

function tokensInfo(start: IToken, end: IToken, issues?: TokenIssue[]): TokenInfo {
    return removeEmpty({...mergePositions([tokenPosition(start), tokenPosition(end)]), issues})
}

function tokenPosition(token: IToken): TokenPosition {
    return {
        offset: {start: pos(token.startOffset), end: pos(token.endOffset)},
        position: {
            start: {line: pos(token.startLine), column: pos(token.startColumn)},
            end: {line: pos(token.endLine), column: pos(token.endColumn)}
        }
    }
}

function pos(value: number | undefined): number {
    return value !== undefined && !isNaN(value) ? value : defaultPos
}