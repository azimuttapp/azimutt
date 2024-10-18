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
    ColumnTypeAst,
    ColumnWithTableAst,
    CommentAst,
    CommentStatementAst,
    ConditionAst,
    ConstraintNameAst,
    CreateExtensionStatementAst,
    CreateTableStatementAst,
    CreateTypeStatementAst,
    DecimalAst,
    DropStatementAst,
    ExpressionAst,
    ForeignKeyActionAst,
    FromClauseAst,
    FunctionAst,
    IdentifierAst,
    IntegerAst,
    LiteralAst,
    NullAst,
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
    TypeColumnAst,
    WhereClauseAst
} from "./postgresAst";

const LineComment = createToken({name: 'LineComment', pattern: /--.*/, group: 'comments'})
const BlockComment = createToken({name: 'BlockComment', pattern: /\/\*[^]*?\*\//, line_breaks: true, group: 'comments'})
const WhiteSpace = createToken({name: 'WhiteSpace', pattern: /\s+/, group: Lexer.SKIPPED})

const Identifier = createToken({name: 'Identifier', pattern: /\b[a-zA-Z_]\w*\b|"([^\\"]|\\\\|\\")+"/})
const String = createToken({name: 'String', pattern: /'([^\\']|'')*'/})
const Decimal = createToken({name: 'Decimal', pattern: /\d+\.\d+/})
const Integer = createToken({name: 'Integer', pattern: /0|[1-9]\d*/, longer_alt: Decimal})
const valueTokens: TokenType[] = [Integer, Decimal, String, Identifier, LineComment, BlockComment]

const And = createToken({name: 'And', pattern: /\bAND\b/i, longer_alt: Identifier})
const As = createToken({name: 'As', pattern: /\bAS\b/i, longer_alt: Identifier})
const Cascade = createToken({name: 'Cascade', pattern: /\bCASCADE\b/i, longer_alt: Identifier})
const Check = createToken({name: 'Check', pattern: /\bCHECK\b/i, longer_alt: Identifier})
const Collate = createToken({name: 'Collate', pattern: /\bCOLLATE\b/i, longer_alt: Identifier})
const Column = createToken({name: 'Column', pattern: /\bCOLUMN\b/i, longer_alt: Identifier})
const Comment = createToken({name: 'Comment', pattern: /\bCOMMENT\b/i, longer_alt: Identifier})
const Concurrently = createToken({name: 'Concurrently', pattern: /\bCONCURRENTLY\b/i, longer_alt: Identifier})
const Constraint = createToken({name: 'Constraint', pattern: /\bCONSTRAINT\b/i, longer_alt: Identifier})
const Create = createToken({name: 'Create', pattern: /\bCREATE\b/i, longer_alt: Identifier})
const Database = createToken({name: 'Database', pattern: /\bDATABASE\b/i, longer_alt: Identifier})
const Default = createToken({name: 'Default', pattern: /\bDEFAULT\b/i, longer_alt: Identifier})
const Delete = createToken({name: 'Delete', pattern: /\bDELETE\b/i, longer_alt: Identifier})
const Distinct = createToken({name: 'Distinct', pattern: /\bDISTINCT\b/i, longer_alt: Identifier})
const Domain = createToken({name: 'Domain', pattern: /\bDOMAIN\b/i, longer_alt: Identifier})
const Drop = createToken({name: 'Drop', pattern: /\bDROP\b/i, longer_alt: Identifier})
const Enum = createToken({name: 'Enum', pattern: /\bENUM\b/i, longer_alt: Identifier})
const Exists = createToken({name: 'Exists', pattern: /\bEXISTS\b/i, longer_alt: Identifier})
const Extension = createToken({name: 'Extension', pattern: /\bEXTENSION\b/i, longer_alt: Identifier})
const False = createToken({name: 'False', pattern: /\bFALSE\b/i, longer_alt: Identifier})
const Fetch = createToken({name: 'Fetch', pattern: /\bFETCH\b/i, longer_alt: Identifier})
const ForeignKey = createToken({name: 'ForeignKey', pattern: /\bFOREIGN\s+KEY\b/i})
const From = createToken({name: 'From', pattern: /\bFROM\b/i, longer_alt: Identifier})
const GroupBy = createToken({name: 'GroupBy', pattern: /\bGROUP\s+BY\b/i})
const Having = createToken({name: 'Having', pattern: /\bHAVING\b/i, longer_alt: Identifier})
const If = createToken({name: 'If', pattern: /\bIF\b/i, longer_alt: Identifier})
const Is = createToken({name: 'Is', pattern: /\bIS\b/i, longer_alt: Identifier})
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
const Schema = createToken({name: 'Schema', pattern: /\bSCHEMA\b/i, longer_alt: Identifier})
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
const Version = createToken({name: 'Version', pattern: /\bVERSION\b/i, longer_alt: Identifier})
const View = createToken({name: 'View', pattern: /\bVIEW\b/i, longer_alt: Identifier})
const Where = createToken({name: 'Where', pattern: /\bWHERE\b/i, longer_alt: Identifier})
const Window = createToken({name: 'Window', pattern: /\bWINDOW\b/i, longer_alt: Identifier})
const With = createToken({name: 'With', pattern: /\bWITH\b/i, longer_alt: Identifier})
const keywordTokens: TokenType[] = [
    And, As, Cascade, Check, Collate, Column, Comment, Concurrently, Constraint, Create, Default, Database, Delete, Distinct, Domain, Drop, Enum, Exists, Extension,
    False, Fetch, ForeignKey, From, GroupBy, Having, If, Is, Index, Join, Like, Limit, Local, MaterializedView, NoAction, Not, Null, Offset, On, Or, OrderBy,
    PrimaryKey, References, Restrict, Schema, Select, Session, SetDefault, SetNull, Set, Table, To, True, Type, Union, Unique, Update, Version, View, Where, Window, With
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
    commentStatementRule: () => CommentStatementAst
    createExtensionStatementRule: () => CreateExtensionStatementAst
    createTableStatementRule: () => CreateTableStatementAst
    createTypeStatementRule: () => CreateTypeStatementAst
    dropStatementRule: () => DropStatementAst
    selectStatementRule: () => SelectStatementAst
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
    functionRule: () => FunctionAst
    tableRule: () => TableAst
    columnRule: () => ColumnAst
    columnWithTableRule: () => ColumnWithTableAst
    columnTypeRule: () => ColumnTypeAst
    literalRule: () => LiteralAst
    // elements
    identifierRule: () => IdentifierAst
    stringRule: () => StringAst
    integerRule: () => IntegerAst
    decimalRule: () => DecimalAst
    booleanRule: () => BooleanAst
    nullRule: () => NullAst

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
            { ALT: () => $.SUBRULE($.commentStatementRule) },
            { ALT: () => $.SUBRULE($.createExtensionStatementRule) },
            { ALT: () => $.SUBRULE($.createTableStatementRule) },
            { ALT: () => $.SUBRULE($.createTypeStatementRule) },
            { ALT: () => $.SUBRULE($.dropStatementRule) },
            { ALT: () => $.SUBRULE($.selectStatementRule) },
            { ALT: () => $.SUBRULE($.setStatementRule) },
        ]))

        this.commentStatementRule = $.RULE<() => CommentStatementAst>('commentStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-comment.html
            const start = $.CONSUME(Comment)
            $.CONSUME(On)
            const {object, schema, parent, entity} = $.OR([
                {ALT: () => ({object: {kind: 'Column' as const, ...tokenInfo2(start, $.CONSUME(Column))}, ...$.SUBRULE(commentColumnRule)})},
                {ALT: () => ({object: {kind: 'Constraint' as const, ...tokenInfo2(start, $.CONSUME(Constraint))}, ...$.SUBRULE(commentConstraintRule)})},
                {ALT: () => ({object: {kind: 'Database' as const, ...tokenInfo2(start, $.CONSUME(Database))}, ...$.SUBRULE(commentObjectDefaultRule)})},
                {ALT: () => ({object: {kind: 'Extension' as const, ...tokenInfo2(start, $.CONSUME(Extension))}, ...$.SUBRULE2(commentObjectDefaultRule)})},
                {ALT: () => ({object: {kind: 'Index' as const, ...tokenInfo2(start, $.CONSUME(Index))}, ...$.SUBRULE3(commentObjectDefaultRule)})},
                {ALT: () => ({object: {kind: 'MaterializedView' as const, ...tokenInfo2(start, $.CONSUME(MaterializedView))}, ...$.SUBRULE4(commentObjectDefaultRule)})},
                {ALT: () => ({object: {kind: 'Schema' as const, ...tokenInfo2(start, $.CONSUME(Schema))}, ...$.SUBRULE5(commentObjectDefaultRule)})},
                {ALT: () => ({object: {kind: 'Table' as const, ...tokenInfo2(start, $.CONSUME(Table))}, ...$.SUBRULE6(commentObjectDefaultRule)})},
                {ALT: () => ({object: {kind: 'Type' as const, ...tokenInfo2(start, $.CONSUME(Type))}, ...$.SUBRULE7(commentObjectDefaultRule)})},
                {ALT: () => ({object: {kind: 'View' as const, ...tokenInfo2(start, $.CONSUME(View))}, ...$.SUBRULE8(commentObjectDefaultRule)})},
            ])
            $.CONSUME(Is)
            const comment = $.OR2([
                {ALT: () => $.SUBRULE($.stringRule)},
                {ALT: () => $.SUBRULE($.nullRule)},
            ])
            const end = $.CONSUME(Semicolon)
            return removeUndefined({statement: 'Comment' as const, object, schema, parent, entity, comment, ...tokenInfo2(start, end)})
        })
        const commentObjectDefaultRule = $.RULE<() => {schema?: IdentifierAst, entity: IdentifierAst}>('commentObjectDefaultRule', () => {
            const table = $.SUBRULE($.tableRule)
            return removeUndefined({schema: table.schema, entity: table.table})
        })
        const commentColumnRule = $.RULE<() => {schema?: IdentifierAst, parent: IdentifierAst, entity: IdentifierAst}>('commentColumnRule', () => {
            const column = $.SUBRULE($.columnWithTableRule)
            return removeUndefined({schema: column.schema, parent: column.table, entity: column.column})
        })
        const commentConstraintRule = $.RULE<() => {schema?: IdentifierAst, parent: IdentifierAst, entity: IdentifierAst}>('commentConstraintRule', () => {
            const entity = $.SUBRULE($.identifierRule)
            $.CONSUME(On)
            $.OPTION(() => $.CONSUME(Domain))
            const parent = $.SUBRULE($.tableRule)
            return {entity, schema: parent.schema, parent: parent.table}
        })

        this.createExtensionStatementRule = $.RULE<() => CreateExtensionStatementAst>('createExtensionStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-createextension.html
            const start = $.CONSUME(Create)
            $.CONSUME(Extension)
            const ifNotExists = $.OPTION(() => tokenInfo3($.CONSUME(If), $.CONSUME(Not), $.CONSUME(Exists)))
            const name = $.SUBRULE($.identifierRule)
            const withh = $.OPTION2(() => tokenInfo($.CONSUME(With)))
            const schema = $.OPTION3(() => ({...tokenInfo($.CONSUME(Schema)), name: $.SUBRULE2($.identifierRule)}))
            const version = $.OPTION4(() => ({...tokenInfo($.CONSUME(Version)), number: $.OR([{ALT: () => $.SUBRULE($.stringRule)}, {ALT: () => $.SUBRULE3($.identifierRule)}])}))
            const cascade = $.OPTION5(() => tokenInfo($.CONSUME(Cascade)))
            const end = $.CONSUME(Semicolon)
            return removeUndefined({statement: 'CreateExtension' as const, ifNotExists, name, with: withh, schema, version, cascade, ...tokenInfo2(start, end)})
        })

        this.createTableStatementRule = $.RULE<() => CreateTableStatementAst>('createTableStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-createtable.html
            const start = $.CONSUME(Create)
            $.CONSUME(Table)
            const table = $.SUBRULE($.tableRule)
            $.CONSUME(ParenLeft)
            const columns: TableColumnAst[] = []
            const constraints: TableConstraintAst[] = []
            $.MANY_SEP({SEP: Comma, DEF: () => $.OR([
                { ALT: () => columns.push($.SUBRULE($.tableColumnRule)) },
                { ALT: () => constraints.push($.SUBRULE($.tableConstraintRule)) },
            ])})
            $.CONSUME(ParenRight)
            const end = $.CONSUME(Semicolon)
            return removeEmpty({statement: 'CreateTable' as const, ...table, columns: columns.filter(isNotUndefined), constraints: constraints.filter(isNotUndefined), ...tokenInfo2(start, end)})
        })

        this.createTypeStatementRule = $.RULE<() => CreateTypeStatementAst>('createTypeStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-createtype.html
            const start = $.CONSUME(Create)
            $.CONSUME(Type)
            const table = $.SUBRULE($.tableRule)
            const content = $.OPTION(() => {
                const as = $.CONSUME(As)
                return $.OR([
                    {ALT: () => {
                        $.CONSUME(ParenLeft)
                        const attrs: TypeColumnAst[] = []
                        $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => attrs.push(removeUndefined({
                            name: $.SUBRULE($.identifierRule),
                            type: $.SUBRULE($.columnTypeRule),
                            collation: $.OPTION2(() => ({...tokenInfo($.CONSUME(Collate)), name: $.SUBRULE2($.identifierRule)}))
                        }))})
                        $.CONSUME(ParenRight)
                        return {struct: {...tokenInfo(as), attrs: attrs.filter(isNotUndefined)}}
                    }},
                    {ALT: () => {
                        const token = tokenInfo2(as, $.CONSUME(Enum))
                        $.CONSUME2(ParenLeft)
                        const values: StringAst[] = []
                        $.AT_LEAST_ONE_SEP2({SEP: Comma, DEF: () => values.push($.SUBRULE($.stringRule))})
                        $.CONSUME2(ParenRight)
                        return {enum: {...token, values: values.filter(isNotUndefined)}}
                    }},
                    // TODO: RANGE
                    // TODO: function
                ])
            })
            const end = $.CONSUME(Semicolon)
            return removeEmpty({statement: 'CreateType' as const, schema: table.schema, type: table.table, ...content, ...tokenInfo2(start, end)})
        })

        this.dropStatementRule = $.RULE<() => DropStatementAst>('dropStatementRule', () => {
            const start = $.CONSUME(Drop)
            const object = $.OR([
                {ALT: () => ({kind: 'Index' as const, ...tokenInfo2(start, $.CONSUME(Index))})}, // https://www.postgresql.org/docs/current/sql-dropindex.html
                {ALT: () => ({kind: 'MaterializedView' as const, ...tokenInfo2(start, $.CONSUME(MaterializedView))})}, // https://www.postgresql.org/docs/current/sql-dropmaterializedview.html
                {ALT: () => ({kind: 'Table' as const, ...tokenInfo2(start, $.CONSUME(Table))})}, // https://www.postgresql.org/docs/current/sql-droptable.html
                {ALT: () => ({kind: 'Type' as const, ...tokenInfo2(start, $.CONSUME(Type))})}, // https://www.postgresql.org/docs/current/sql-droptype.html
                {ALT: () => ({kind: 'View' as const, ...tokenInfo2(start, $.CONSUME(View))})}, // https://www.postgresql.org/docs/current/sql-dropview.html
            ])
            const concurrently = $.OPTION(() => tokenInfo($.CONSUME(Concurrently)))
            const ifExists = $.OPTION2(() => tokenInfo2($.CONSUME(If), $.CONSUME(Exists)))
            const entities: TableAst[] = []
            $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => entities.push($.SUBRULE($.tableRule))})
            const mode = $.OPTION3(() => $.OR2([
                {ALT: () => ({kind: 'Cascade' as const, ...tokenInfo($.CONSUME(Cascade))})},
                {ALT: () => ({kind: 'Restrict' as const, ...tokenInfo($.CONSUME(Restrict))})},
            ]))
            const end = $.CONSUME(Semicolon)
            return removeUndefined({statement: 'Drop' as const, object, entities: entities.filter(isNotUndefined), concurrently, ifExists, mode, ...tokenInfo2(start, end)})
        })

        this.selectStatementRule = $.RULE<() => SelectStatementAst>('selectStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-select.html
            const select = $.SUBRULE($.selectClauseRule)
            const from = $.OPTION(() => $.SUBRULE($.fromClauseRule))
            const where = $.OPTION2(() => $.SUBRULE($.whereClauseRule))
            const end = $.CONSUME(Semicolon)
            return removeUndefined({statement: 'Select' as const, select, from, where, ...mergePositions([select, tokenInfo(end)])})
        })

        this.setStatementRule = $.RULE<() => SetStatementAst>('setStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-set.html
            const start = $.CONSUME(Set)
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
            const end = $.CONSUME(Semicolon)
            return removeUndefined({statement: 'Set' as const, scope, parameter, equal, value, ...tokenInfo2(start, end)})
        })

        // clauses

        this.selectClauseRule = $.RULE<() => SelectClauseAst>('selectClauseRule', () => {
            const token = $.CONSUME(Select)
            const expressions: SelectClauseExprAst[] = []
            $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => {
                const expression = $.SUBRULE($.expressionRule)
                const alias = $.OPTION(() => $.SUBRULE($.aliasRule))
                expression && expressions.push(removeUndefined({...expression, alias}))
            }})
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
            const type = $.SUBRULE($.columnTypeRule)
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
            const token = not ? tokenInfo2(not, nullable) : tokenInfo(nullable)
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
            const onUpdate = $.OPTION3(() => ({...tokenInfo2($.CONSUME(On), $.CONSUME(Update)), ...$.SUBRULE(foreignKeyActionsRule)}))
            const onDelete = $.OPTION4(() => ({...tokenInfo2($.CONSUME2(On), $.CONSUME(Delete)), ...$.SUBRULE2(foreignKeyActionsRule)}))
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
            const onUpdate = $.OPTION3(() => ({...tokenInfo2($.CONSUME(On), $.CONSUME(Update)), ...$.SUBRULE(foreignKeyActionsRule)}))
            const onDelete = $.OPTION4(() => ({...tokenInfo2($.CONSUME2(On), $.CONSUME(Delete)), ...$.SUBRULE2(foreignKeyActionsRule)}))
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
            { ALT: () => $.SUBRULE($.literalRule) },
            { ALT: () => {
                // extract "table" prefix from `$.functionRule` and `$.columnRule`
                const prefix = $.SUBRULE($.tableRule)
                return $.OR2([
                    {ALT: () => removeUndefined({schema: prefix.schema, function: prefix.table, parameters: $.SUBRULE(functionParamsRule)})},
                    {ALT: () => {
                        const third = $.OPTION(() => {$.CONSUME(Dot); return $.SUBRULE($.identifierRule)})
                        const [column, table, schema] = [third, prefix.table, prefix.schema].filter(isNotUndefined)
                        return removeUndefined({schema, table, column})
                    }},
                ])
            }},
        ]))

        const functionParamsRule = $.RULE<() => ExpressionAst[]>('functionParamsRule', () => {
            $.CONSUME(ParenLeft)
            const parameters: ExpressionAst[] = []
            $.MANY_SEP({SEP: Comma, DEF: () => parameters.push($.SUBRULE($.expressionRule))})
            $.CONSUME(ParenRight)
            return parameters.filter(isNotUndefined)
        })
        this.functionRule = $.RULE<() => FunctionAst>('functionRule', () => {
            const table = $.SUBRULE($.tableRule)
            const parameters = $.SUBRULE(functionParamsRule)
            return removeUndefined({schema: table.schema, function: table.table, parameters})
        })

        this.tableRule = $.RULE<() => TableAst>('tableRule', () => {
            const first = $.SUBRULE($.identifierRule)
            const second = $.OPTION(() => {
                $.CONSUME(Dot)
                return $.SUBRULE2($.identifierRule)
            })
            const [table, schema] = [second, first].filter(isNotUndefined)
            return removeUndefined({schema, table})
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
            return removeUndefined({schema, table, column})
        })

        this.columnWithTableRule = $.RULE<() => ColumnWithTableAst>('columnWithTableRule', () => {
            const first = $.SUBRULE($.identifierRule)
            $.CONSUME(Dot)
            const second = $.SUBRULE2($.identifierRule)
            const third = $.OPTION2(() => {
                $.CONSUME2(Dot)
                return $.SUBRULE3($.identifierRule)
            })
            const [column, table, schema] = [third, second, first].filter(isNotUndefined)
            return removeUndefined({schema, table, column})
        })

        this.columnTypeRule = $.RULE<() => ColumnTypeAst>('columnTypeRule', () => {
            return $.SUBRULE($.identifierRule) // TODO: handle types with space (timestamp without time zone), numbers (character varying(255)) and schema (public.citext)
        })

        this.literalRule = $.RULE<() => LiteralAst>('literalRule', () => $.OR([
            { ALT: () => $.SUBRULE($.stringRule) },
            { ALT: () => $.SUBRULE($.decimalRule) },
            { ALT: () => $.SUBRULE($.integerRule) },
            { ALT: () => $.SUBRULE($.booleanRule) },
            { ALT: () => $.SUBRULE($.nullRule) },
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

        this.nullRule = $.RULE<() => NullAst>('nullRule', () => {
            const token = $.CONSUME(Null)
            return {kind: 'Null', ...tokenInfo(token)}
        })

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

function tokenInfo2(start: IToken, end: IToken, issues?: TokenIssue[]): TokenInfo {
    return removeEmpty({...mergePositions([tokenPosition(start), tokenPosition(end)]), issues})
}

function tokenInfo3(start: IToken, _middle: IToken, end: IToken, issues?: TokenIssue[]): TokenInfo {
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
