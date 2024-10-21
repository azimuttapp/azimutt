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
    AlterTableStatementAst,
    BooleanAst,
    ColumnJsonAst,
    ColumnTypeAst,
    CommentAst,
    CommentOnStatementAst,
    ConstraintNameAst,
    CreateExtensionStatementAst,
    CreateIndexStatementAst,
    CreateTableStatementAst,
    CreateTypeStatementAst,
    CreateViewStatementAst,
    DecimalAst,
    DeleteStatementAst,
    DropStatementAst,
    ExpressionAst,
    FetchClauseAst,
    ForeignKeyActionAst,
    FromClauseAst,
    FromItemAst,
    FromJoinAst,
    FromQueryAst,
    FromTableAst,
    GroupAst,
    GroupByClauseAst,
    HavingClauseAst,
    IdentifierAst,
    IndexColumnAst,
    InsertIntoStatementAst,
    IntegerAst,
    JsonOp,
    LimitClauseAst,
    ListAst,
    LiteralAst,
    NullAst,
    ObjectNameAst,
    OffsetClauseAst,
    OperatorAst,
    OrderByClauseAst,
    ParameterAst,
    SelectClauseAst,
    SelectClauseExprAst,
    SelectStatementAst,
    SelectStatementInnerAst,
    SelectStatementMainAst,
    SelectStatementResultAst,
    SetStatementAst,
    SortNullsAst,
    SortOrderAst,
    StatementAst,
    StatementsAst,
    StringAst,
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
    UnionClauseAst,
    WhereClauseAst
} from "./postgresAst";

const LineComment = createToken({name: 'LineComment', pattern: /--.*/, group: 'comments'})
const BlockComment = createToken({name: 'BlockComment', pattern: /\/\*[^]*?\*\//, line_breaks: true, group: 'comments'})
const WhiteSpace = createToken({name: 'WhiteSpace', pattern: /\s+/, group: Lexer.SKIPPED})

const Identifier = createToken({name: 'Identifier', pattern: /\b[a-zA-Z_]\w*\b|"([^\\"]|\\\\|\\")+"/})
const String = createToken({name: 'String', pattern: /E?'([^']|'')*'/i})
const Decimal = createToken({name: 'Decimal', pattern: /\d+\.\d+/})
const Integer = createToken({name: 'Integer', pattern: /0|[1-9]\d*/, longer_alt: Decimal})
const valueTokens: TokenType[] = [Integer, Decimal, String, Identifier, LineComment, BlockComment]

const Add = createToken({name: 'Add', pattern: /\bADD\b/i, longer_alt: Identifier})
const All = createToken({name: 'All', pattern: /\bALL\b/i, longer_alt: Identifier})
const Alter = createToken({name: 'Alter', pattern: /\bALTER\b/i, longer_alt: Identifier})
const And = createToken({name: 'And', pattern: /\bAND\b/i, longer_alt: Identifier})
const As = createToken({name: 'As', pattern: /\bAS\b/i, longer_alt: Identifier})
const Asc = createToken({name: 'Asc', pattern: /\bASC\b/i, longer_alt: Identifier})
const Cascade = createToken({name: 'Cascade', pattern: /\bCASCADE\b/i, longer_alt: Identifier})
const Check = createToken({name: 'Check', pattern: /\bCHECK\b/i, longer_alt: Identifier})
const Collate = createToken({name: 'Collate', pattern: /\bCOLLATE\b/i, longer_alt: Identifier})
const Column = createToken({name: 'Column', pattern: /\bCOLUMN\b/i, longer_alt: Identifier})
const Comment = createToken({name: 'Comment', pattern: /\bCOMMENT\b/i, longer_alt: Identifier})
const Concurrently = createToken({name: 'Concurrently', pattern: /\bCONCURRENTLY\b/i, longer_alt: Identifier})
const Constraint = createToken({name: 'Constraint', pattern: /\bCONSTRAINT\b/i, longer_alt: Identifier})
const Create = createToken({name: 'Create', pattern: /\bCREATE\b/i, longer_alt: Identifier})
const Cross = createToken({name: 'Cross', pattern: /\bCROSS\b/i, longer_alt: Identifier})
const Database = createToken({name: 'Database', pattern: /\bDATABASE\b/i, longer_alt: Identifier})
const Default = createToken({name: 'Default', pattern: /\bDEFAULT\b/i, longer_alt: Identifier})
const Delete = createToken({name: 'Delete', pattern: /\bDELETE\b/i, longer_alt: Identifier})
const Desc = createToken({name: 'Desc', pattern: /\bDESC\b/i, longer_alt: Identifier})
const Distinct = createToken({name: 'Distinct', pattern: /\bDISTINCT\b/i, longer_alt: Identifier})
const Domain = createToken({name: 'Domain', pattern: /\bDOMAIN\b/i, longer_alt: Identifier})
const Drop = createToken({name: 'Drop', pattern: /\bDROP\b/i, longer_alt: Identifier})
const Enum = createToken({name: 'Enum', pattern: /\bENUM\b/i, longer_alt: Identifier})
const Except = createToken({name: 'Except', pattern: /\bEXCEPT\b/i, longer_alt: Identifier})
const Exists = createToken({name: 'Exists', pattern: /\bEXISTS\b/i, longer_alt: Identifier})
const Extension = createToken({name: 'Extension', pattern: /\bEXTENSION\b/i, longer_alt: Identifier})
const False = createToken({name: 'False', pattern: /\bFALSE\b/i, longer_alt: Identifier})
const Fetch = createToken({name: 'Fetch', pattern: /\bFETCH\b/i, longer_alt: Identifier})
const First = createToken({name: 'First', pattern: /\bFIRST\b/i, longer_alt: Identifier})
const ForeignKey = createToken({name: 'ForeignKey', pattern: /\bFOREIGN\s+KEY\b/i})
const From = createToken({name: 'From', pattern: /\bFROM\b/i, longer_alt: Identifier})
const Full = createToken({name: 'Full', pattern: /\bFULL\b/i, longer_alt: Identifier})
const Global = createToken({name: 'Global', pattern: /\bGLOBAL\b/i, longer_alt: Identifier})
const GroupBy = createToken({name: 'GroupBy', pattern: /\bGROUP\s+BY\b/i})
const Having = createToken({name: 'Having', pattern: /\bHAVING\b/i, longer_alt: Identifier})
const If = createToken({name: 'If', pattern: /\bIF\b/i, longer_alt: Identifier})
const In = createToken({name: 'In', pattern: /\bIN\b/i, longer_alt: Identifier})
const Include = createToken({name: 'Include', pattern: /\bINCLUDE\b/i, longer_alt: Identifier})
const Index = createToken({name: 'Index', pattern: /\bINDEX\b/i, longer_alt: Identifier})
const Inner = createToken({name: 'Inner', pattern: /\bINNER\b/i, longer_alt: Identifier})
const InsertInto = createToken({name: 'InsertInto', pattern: /\bINSERT\s+INTO\b/i})
const Intersect = createToken({name: 'Intersect', pattern: /\bINTERSECT\b/i, longer_alt: Identifier})
const Is = createToken({name: 'Is', pattern: /\bIS\b/i, longer_alt: Identifier})
const Join = createToken({name: 'Join', pattern: /\bJOIN\b/i, longer_alt: Identifier})
const Last = createToken({name: 'Last', pattern: /\bLAST\b/i, longer_alt: Identifier})
const Left = createToken({name: 'Left', pattern: /\bLEFT\b/i, longer_alt: Identifier})
const Like = createToken({name: 'Like', pattern: /\bLIKE\b/i, longer_alt: Identifier})
const Limit = createToken({name: 'Limit', pattern: /\bLIMIT\b/i, longer_alt: Identifier})
const Local = createToken({name: 'Local', pattern: /\bLOCAL\b/i, longer_alt: Identifier})
const MaterializedView = createToken({name: 'MaterializedView', pattern: /\bMATERIALIZED\s+VIEW\b/i})
const Natural = createToken({name: 'Natural', pattern: /\bNATURAL\b/i, longer_alt: Identifier})
const Next = createToken({name: 'Next', pattern: /\bNEXT\b/i, longer_alt: Identifier})
const NoAction = createToken({name: 'NoAction', pattern: /\bNO\s+ACTION\b/i})
const Not = createToken({name: 'Not', pattern: /\bNOT\b/i, longer_alt: Identifier})
const Null = createToken({name: 'Null', pattern: /\bNULL\b/i, longer_alt: Identifier})
const Nulls = createToken({name: 'Nulls', pattern: /\bNULLS\b/i, longer_alt: Identifier})
const Offset = createToken({name: 'Offset', pattern: /\bOFFSET\b/i, longer_alt: Identifier})
const On = createToken({name: 'On', pattern: /\bON\b/i, longer_alt: Identifier})
const Only = createToken({name: 'Only', pattern: /\bONLY\b/i, longer_alt: Identifier})
const Or = createToken({name: 'Or', pattern: /\bOR\b/i, longer_alt: Identifier})
const OrderBy = createToken({name: 'OrderBy', pattern: /\bORDER\s+BY\b/i})
const Outer = createToken({name: 'Outer', pattern: /\bOUTER\b/i, longer_alt: Identifier})
const PrimaryKey = createToken({name: 'PrimaryKey', pattern: /\bPRIMARY\s+KEY\b/i})
const Recursive = createToken({name: 'Recursive', pattern: /\bRECURSIVE\b/i, longer_alt: Identifier})
const References = createToken({name: 'References', pattern: /\bREFERENCES\b/i, longer_alt: Identifier})
const Replace = createToken({name: 'Replace', pattern: /\bREPLACE\b/i, longer_alt: Identifier})
const Restrict = createToken({name: 'Restrict', pattern: /\bRESTRICT\b/i, longer_alt: Identifier})
const Returning = createToken({name: 'Returning', pattern: /\bRETURNING\b/i, longer_alt: Identifier})
const Right = createToken({name: 'Right', pattern: /\bRIGHT\b/i, longer_alt: Identifier})
const Row = createToken({name: 'Row', pattern: /\bROW\b/i, longer_alt: Identifier})
const Rows = createToken({name: 'Rows', pattern: /\bROWS\b/i, longer_alt: Identifier})
const Schema = createToken({name: 'Schema', pattern: /\bSCHEMA\b/i, longer_alt: Identifier})
const Select = createToken({name: 'Select', pattern: /\bSELECT\b/i, longer_alt: Identifier})
const Session = createToken({name: 'Session', pattern: /\bSESSION\b/i, longer_alt: Identifier})
const SetDefault = createToken({name: 'SetDefault', pattern: /\bSET\s+DEFAULT\b/i})
const SetNull = createToken({name: 'SetNull', pattern: /\bSET\s+NULL\b/i})
const Set = createToken({name: 'Set', pattern: /\bSET\b/i, longer_alt: Identifier})
const Table = createToken({name: 'Table', pattern: /\bTABLE\b/i, longer_alt: Identifier})
const Temp = createToken({name: 'Temp', pattern: /\bTEMP\b/i, longer_alt: Identifier})
const Temporary = createToken({name: 'Temporary', pattern: /\bTEMPORARY\b/i, longer_alt: Identifier})
const Ties = createToken({name: 'Ties', pattern: /\bTIES\b/i, longer_alt: Identifier})
const To = createToken({name: 'To', pattern: /\bTO\b/i, longer_alt: Identifier})
const True = createToken({name: 'True', pattern: /\bTRUE\b/i, longer_alt: Identifier})
const Type = createToken({name: 'Type', pattern: /\bTYPE\b/i, longer_alt: Identifier})
const Union = createToken({name: 'Union', pattern: /\bUNION\b/i, longer_alt: Identifier})
const Unique = createToken({name: 'Unique', pattern: /\bUNIQUE\b/i, longer_alt: Identifier})
const Unlogged = createToken({name: 'Unlogged', pattern: /\bUNLOGGED\b/i, longer_alt: Identifier})
const Update = createToken({name: 'Update', pattern: /\bUPDATE\b/i, longer_alt: Identifier})
const Using = createToken({name: 'Using', pattern: /\bUSING\b/i, longer_alt: Identifier})
const Values = createToken({name: 'Values', pattern: /\bVALUES\b/i, longer_alt: Identifier})
const Version = createToken({name: 'Version', pattern: /\bVERSION\b/i, longer_alt: Identifier})
const View = createToken({name: 'View', pattern: /\bVIEW\b/i, longer_alt: Identifier})
const Where = createToken({name: 'Where', pattern: /\bWHERE\b/i, longer_alt: Identifier})
const Window = createToken({name: 'Window', pattern: /\bWINDOW\b/i, longer_alt: Identifier})
const With = createToken({name: 'With', pattern: /\bWITH\b/i, longer_alt: Identifier})
const keywordTokens: TokenType[] = [
    Add, All, Alter, And, As, Asc, Cascade, Check, Collate, Column, Comment, Concurrently, Constraint, Create, Cross,
    Database, Default, Delete, Desc, Distinct, Domain, Drop, Enum, Except, Exists, Extension, False, Fetch, First, ForeignKey, From, Full,
    Global, GroupBy, Having, If, In, Include, Index, Inner, InsertInto, Intersect, Is, Join, Last, Left, Like, Limit, Local,
    MaterializedView, Natural, Next, NoAction, Not, Null, Nulls, Offset, On, Only, Or, OrderBy, Outer, PrimaryKey,
    Recursive, References, Replace, Restrict, Returning, Right, Row, Rows, Schema, Select, Session, SetDefault, SetNull, Set,
    Table, Temp, Temporary, Ties, To, True, Type, Union, Unique, Unlogged, Update, Using, Values, Version, View, Where, Window, With
]

const Amp = createToken({name: 'Amp', pattern: /&/})
const Asterisk = createToken({name: 'Asterisk', pattern: /\*/})
const BracketLeft = createToken({name: 'BracketLeft', pattern: /\[/})
const BracketRight = createToken({name: 'BracketRight', pattern: /]/})
const Caret = createToken({name: 'Caret', pattern: /\^/})
const Colon = createToken({name: 'Colon', pattern: /:/})
const Comma = createToken({name: 'Comma', pattern: /,/})
const CurlyLeft = createToken({name: 'CurlyLeft', pattern: /\{/})
const CurlyRight = createToken({name: 'CurlyRight', pattern: /}/})
const Dash = createToken({name: 'Dash', pattern: /-/, longer_alt: LineComment})
const Dollar = createToken({name: 'Dollar', pattern: /\$/})
const Dot = createToken({name: 'Dot', pattern: /\./})
const Equal = createToken({name: 'Equal', pattern: /=/})
const Exclamation = createToken({name: 'Exclamation', pattern: /!/})
const GreaterThan = createToken({name: 'GreaterThan', pattern: />/})
const Hash = createToken({name: 'Hash', pattern: /#/})
const LowerThan = createToken({name: 'LowerThan', pattern: /</})
const ParenLeft = createToken({name: 'ParenLeft', pattern: /\(/})
const ParenRight = createToken({name: 'ParenRight', pattern: /\)/})
const Percent = createToken({name: 'Percent', pattern: /%/})
const Pipe = createToken({name: 'Pipe', pattern: /\|/})
const Plus = createToken({name: 'Plus', pattern: /\+/})
const QuestionMark = createToken({name: 'QuestionMark', pattern: /\?/})
const Semicolon = createToken({name: 'Semicolon', pattern: /;/})
const Slash = createToken({name: 'Slash', pattern: /\//, longer_alt: BlockComment})
const Tilde = createToken({name: 'Tilde', pattern: /~/})
const charTokens: TokenType[] = [
    Amp, Asterisk, BracketLeft, BracketRight, Caret, Colon, Comma, CurlyLeft, CurlyRight, Dash, Dollar, Dot, Equal, Exclamation,
    GreaterThan, Hash, LowerThan, ParenLeft, ParenRight, Percent, Pipe, Plus, QuestionMark, Semicolon, Slash, Tilde
]

const allTokens: TokenType[] = [WhiteSpace, ...keywordTokens, ...charTokens, ...valueTokens]

const defaultPos: number = -1 // used when error position is undefined

class PostgresParser extends EmbeddedActionsParser {
    // top level
    statementsRule: () => StatementsAst
    // statements
    statementRule: () => StatementAst
    alterTableStatementRule: () => AlterTableStatementAst
    commentOnStatementRule: () => CommentOnStatementAst
    createExtensionStatementRule: () => CreateExtensionStatementAst
    createIndexStatementRule: () => CreateIndexStatementAst
    createTableStatementRule: () => CreateTableStatementAst
    createTypeStatementRule: () => CreateTypeStatementAst
    createViewStatementRule: () => CreateViewStatementAst
    deleteStatementRule: () => DeleteStatementAst
    dropStatementRule: () => DropStatementAst
    insertIntoStatementRule: () => InsertIntoStatementAst
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
    expressionRule: () => ExpressionAst
    objectNameRule: () => ObjectNameAst
    columnTypeRule: () => ColumnTypeAst
    literalRule: () => LiteralAst
    // elements
    parameterRule: () => ParameterAst
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
            {ALT: () => $.SUBRULE($.alterTableStatementRule)},
            {ALT: () => $.SUBRULE($.commentOnStatementRule)},
            {ALT: () => $.SUBRULE($.createExtensionStatementRule)},
            {ALT: () => $.SUBRULE($.createIndexStatementRule)},
            {ALT: () => $.SUBRULE($.createTableStatementRule)},
            {ALT: () => $.SUBRULE($.createTypeStatementRule)},
            {ALT: () => $.SUBRULE($.createViewStatementRule)},
            {ALT: () => $.SUBRULE($.deleteStatementRule)},
            {ALT: () => $.SUBRULE($.dropStatementRule)},
            {ALT: () => $.SUBRULE($.insertIntoStatementRule)},
            {ALT: () => $.SUBRULE($.selectStatementRule)},
            {ALT: () => $.SUBRULE($.setStatementRule)},
        ]))

        this.alterTableStatementRule = $.RULE<() => AlterTableStatementAst>('alterTableStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-altertable.html
            const start = $.CONSUME(Alter)
            const token = tokenInfo2(start, $.CONSUME(Table))
            const ifExists = $.SUBRULE(ifExistsRule)
            const only = $.OPTION(() => tokenInfo($.CONSUME(Only)))
            const object = $.SUBRULE($.objectNameRule)
            const action = $.OR([
                {ALT: () => removeUndefined({kind: 'AddColumn' as const, token: tokenInfo2($.CONSUME(Add), $.OPTION2(() => $.CONSUME(Column))), ifNotExists: $.SUBRULE(ifNotExistsRule), column: $.SUBRULE($.tableColumnRule)})},
                {ALT: () => removeUndefined({kind: 'AddConstraint' as const, token: tokenInfo($.CONSUME2(Add)), constraint: $.SUBRULE($.tableConstraintRule)})},
                {ALT: () => removeUndefined({kind: 'DropColumn' as const, token: tokenInfo2($.CONSUME(Drop), $.OPTION3(() => $.CONSUME2(Column))), ifExists: $.SUBRULE2(ifExistsRule), column: $.SUBRULE($.identifierRule)})},
                {ALT: () => removeUndefined({kind: 'DropConstraint' as const, token: tokenInfo2($.CONSUME2(Drop), $.CONSUME(Constraint)), ifExists: $.SUBRULE3(ifExistsRule), constraint: $.SUBRULE2($.identifierRule)})},
            ])
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'AlterTable' as const, meta: tokenInfo2(start, end), token, ifExists, only, schema: object.schema, table: object.name, action})
        })

        this.commentOnStatementRule = $.RULE<() => CommentOnStatementAst>('commentOnStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-comment.html
            const start = $.CONSUME(Comment)
            const token = tokenInfo2(start, $.CONSUME(On))
            const {object, schema, parent, entity} = $.OR([
                {ALT: () => ({object: {kind: 'Column' as const, token: tokenInfo($.CONSUME(Column))}, ...$.SUBRULE(commentColumnRule)})},
                {ALT: () => ({object: {kind: 'Constraint' as const, token: tokenInfo($.CONSUME(Constraint))}, ...$.SUBRULE(commentConstraintRule)})},
                {ALT: () => ({object: {kind: 'Database' as const, token: tokenInfo($.CONSUME(Database))}, ...$.SUBRULE(commentObjectDefaultRule)})},
                {ALT: () => ({object: {kind: 'Extension' as const, token: tokenInfo($.CONSUME(Extension))}, ...$.SUBRULE2(commentObjectDefaultRule)})},
                {ALT: () => ({object: {kind: 'Index' as const, token: tokenInfo($.CONSUME(Index))}, ...$.SUBRULE3(commentObjectDefaultRule)})},
                {ALT: () => ({object: {kind: 'MaterializedView' as const, token: tokenInfo($.CONSUME(MaterializedView))}, ...$.SUBRULE4(commentObjectDefaultRule)})},
                {ALT: () => ({object: {kind: 'Schema' as const, token: tokenInfo($.CONSUME(Schema))}, ...$.SUBRULE5(commentObjectDefaultRule)})},
                {ALT: () => ({object: {kind: 'Table' as const, token: tokenInfo($.CONSUME(Table))}, ...$.SUBRULE6(commentObjectDefaultRule)})},
                {ALT: () => ({object: {kind: 'Type' as const, token: tokenInfo($.CONSUME(Type))}, ...$.SUBRULE7(commentObjectDefaultRule)})},
                {ALT: () => ({object: {kind: 'View' as const, token: tokenInfo($.CONSUME(View))}, ...$.SUBRULE8(commentObjectDefaultRule)})},
            ])
            $.CONSUME(Is)
            const comment = $.OR2([
                {ALT: () => $.SUBRULE($.stringRule)},
                {ALT: () => $.SUBRULE($.nullRule)},
            ])
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'CommentOn' as const, meta: tokenInfo2(start, end), token, object, schema, parent, entity, comment})
        })
        const commentObjectDefaultRule = $.RULE<() => {schema?: IdentifierAst, entity: IdentifierAst}>('commentObjectDefaultRule', () => {
            const object = $.SUBRULE($.objectNameRule)
            return removeUndefined({schema: object.schema, entity: object.name})
        })
        const commentColumnRule = $.RULE<() => {schema?: IdentifierAst, parent: IdentifierAst, entity: IdentifierAst}>('commentColumnRule', () => {
            const first = $.SUBRULE($.identifierRule)
            $.CONSUME(Dot)
            const second = $.SUBRULE2($.identifierRule)
            const third = $.OPTION2(() => {
                $.CONSUME2(Dot)
                return $.SUBRULE3($.identifierRule)
            })
            return third ? {schema: first, parent: second, entity: third} : {parent: first, entity: second}
        })
        const commentConstraintRule = $.RULE<() => {schema?: IdentifierAst, parent: IdentifierAst, entity: IdentifierAst}>('commentConstraintRule', () => {
            const entity = $.SUBRULE($.identifierRule)
            $.CONSUME(On)
            $.OPTION(() => $.CONSUME(Domain))
            const object = $.SUBRULE($.objectNameRule)
            return {entity, schema: object.schema, parent: object.name}
        })

        this.createExtensionStatementRule = $.RULE<() => CreateExtensionStatementAst>('createExtensionStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-createextension.html
            const start = $.CONSUME(Create)
            const token = tokenInfo2(start, $.CONSUME(Extension))
            const ifNotExists = $.SUBRULE(ifNotExistsRule)
            const name = $.SUBRULE($.identifierRule)
            const withh = $.OPTION(() => tokenInfo($.CONSUME(With)))
            const schema = $.OPTION2(() => ({token: tokenInfo($.CONSUME(Schema)), name: $.SUBRULE2($.identifierRule)}))
            const version = $.OPTION3(() => ({token: tokenInfo($.CONSUME(Version)), number: $.OR([{ALT: () => $.SUBRULE($.stringRule)}, {ALT: () => $.SUBRULE3($.identifierRule)}])}))
            const cascade = $.OPTION4(() => tokenInfo($.CONSUME(Cascade)))
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'CreateExtension' as const, meta: tokenInfo2(start, end), token, ifNotExists, name, with: withh, schema, version, cascade})
        })

        this.createIndexStatementRule = $.RULE<() => CreateIndexStatementAst>('createIndexStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-createindex.html
            const start = $.CONSUME(Create)
            const unique = $.OPTION(() => tokenInfo($.CONSUME(Unique)))
            const token = tokenInfo2(start, $.CONSUME(Index))
            const concurrently = $.OPTION2(() => tokenInfo($.CONSUME(Concurrently)))
            const name = $.OPTION3(() => ({ifNotExists: $.SUBRULE(ifNotExistsRule), index: $.SUBRULE($.identifierRule)}))
            $.CONSUME(On)
            const only = $.OPTION4(() => tokenInfo($.CONSUME(Only)))
            const object = $.SUBRULE($.objectNameRule)
            const using = $.OPTION5(() => ({token: tokenInfo($.CONSUME(Using)), method: $.SUBRULE2($.identifierRule)}))
            $.CONSUME(ParenLeft)
            const columns: IndexColumnAst[] = []
            $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => columns.push($.SUBRULE(indexColumnRule))})
            $.CONSUME(ParenRight)
            const include = $.OPTION6(() => {
                const token = tokenInfo($.CONSUME(Include))
                $.CONSUME2(ParenLeft)
                const columns: IdentifierAst[] = []
                $.AT_LEAST_ONE_SEP2({SEP: Comma, DEF: () => columns.push($.SUBRULE3($.identifierRule))})
                $.CONSUME2(ParenRight)
                return {token, columns}
            })
            // TODO: NULLS [ NOT ] DISTINCT
            // TODO: WITH (parameters)
            // TODO: TABLESPACE name
            const where = $.OPTION7(() => $.SUBRULE($.whereClauseRule))
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'CreateIndex' as const, meta: tokenInfo2(start, end), token, unique, concurrently, ...name, only, schema: object.schema, table: object.name, using, columns, include, where})
        })

        this.createTableStatementRule = $.RULE<() => CreateTableStatementAst>('createTableStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-createtable.html
            const start = $.CONSUME(Create)
            const mode = $.OPTION(() => $.OR([
                {ALT: () => ({kind: 'Unlogged' as const, token: tokenInfo($.CONSUME(Unlogged))})},
                {ALT: () => {
                    const scope = $.OPTION2(() => $.OR2([
                        {ALT: () => ({kind: 'Global' as const, token: tokenInfo($.CONSUME(Global))})},
                        {ALT: () => ({kind: 'Local' as const, token: tokenInfo($.CONSUME(Local))})},
                    ]))
                    const temporary = $.OR3([{ALT: () => tokenInfo($.CONSUME(Temp))}, {ALT: () => tokenInfo($.CONSUME(Temporary))}])
                    return removeUndefined({kind: 'Temporary' as const, ...temporary, scope})
                }}
            ]))
            const token = tokenInfo2(start, $.CONSUME(Table))
            const ifNotExists = $.OPTION3(() => $.SUBRULE(ifNotExistsRule))
            const object = $.SUBRULE($.objectNameRule)
            $.CONSUME(ParenLeft)
            const columns: TableColumnAst[] = []
            const constraints: TableConstraintAst[] = []
            $.MANY_SEP({SEP: Comma, DEF: () => $.OR4([
                {ALT: () => columns.push($.SUBRULE($.tableColumnRule))},
                {ALT: () => constraints.push($.SUBRULE($.tableConstraintRule))},
            ])})
            $.CONSUME(ParenRight)
            const end = $.CONSUME(Semicolon)
            return removeEmpty({kind: 'CreateTable' as const, meta: tokenInfo2(start, end), token, mode, ifNotExists, schema: object.schema, table: object.name, columns: columns.filter(isNotUndefined), constraints: constraints.filter(isNotUndefined)})
        })

        this.createTypeStatementRule = $.RULE<() => CreateTypeStatementAst>('createTypeStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-createtype.html
            const start = $.CONSUME(Create)
            const token = tokenInfo2(start, $.CONSUME(Type))
            const object = $.SUBRULE($.objectNameRule)
            const content = $.OPTION(() => $.OR([
                {ALT: () => ({struct: {token: tokenInfo($.CONSUME(As)), attrs: $.SUBRULE(createTypeStructAttrs)}})},
                {ALT: () => ({enum: {token: tokenInfo2($.CONSUME2(As), $.CONSUME(Enum)), values: $.SUBRULE(createTypeEnumValues)}})},
                // TODO: RANGE
                {ALT: () => ({base: $.SUBRULE(createTypeBase)})}
            ]))
            const end = $.CONSUME(Semicolon)
            return removeEmpty({kind: 'CreateType' as const, meta: tokenInfo2(start, end), token, schema: object.schema, type: object.name, ...content})
        })

        this.createViewStatementRule = $.RULE<() => CreateViewStatementAst>('createViewStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-createview.html
            const start = $.CONSUME(Create)
            const replace = $.OPTION(() => tokenInfo2($.CONSUME(Or), $.CONSUME(Replace)))
            const temporary = $.OPTION2(() => $.OR([{ALT: () => tokenInfo($.CONSUME(Temp))}, {ALT: () => tokenInfo($.CONSUME(Temporary))}]))
            const recursive = $.OPTION3(() => tokenInfo($.CONSUME(Recursive)))
            const token = tokenInfo2(start, $.CONSUME(View))
            const object = $.SUBRULE($.objectNameRule)
            const columns: IdentifierAst[] = []
            $.OPTION4(() => {
                $.CONSUME(ParenLeft)
                $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => columns.push($.SUBRULE($.identifierRule))})
                $.CONSUME(ParenRight)
            })
            $.CONSUME(As)
            const query = $.SUBRULE(selectStatementInnerRule)
            const end = $.CONSUME(Semicolon)
            return removeEmpty({kind: 'CreateView' as const, meta: tokenInfo2(start, end), token, replace, temporary, recursive, schema: object.schema, view: object.name, columns, query})
        })

        this.deleteStatementRule = $.RULE<() => DeleteStatementAst>('deleteStatementRule', () => {
            const start = $.CONSUME(Delete)
            const token = tokenInfo2(start, $.CONSUME(From))
            const only = $.OPTION(() => tokenInfo($.CONSUME(Only)))
            const object = $.SUBRULE($.objectNameRule)
            const descendants = $.OPTION2(() => tokenInfo($.CONSUME(Asterisk)))
            const alias = $.OPTION3(() => $.SUBRULE($.aliasRule))
            const using = $.OPTION4(() => ({token: tokenInfo($.CONSUME(Using)), ...$.SUBRULE(fromItemRule)}))
            const where = $.OPTION5(() => $.SUBRULE($.whereClauseRule))
            const returning = $.OPTION6(() => $.SUBRULE(returningClauseRule))
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'Delete' as const, meta: tokenInfo2(start, end), token, only, schema: object.schema, table: object.name, descendants, alias, using, where, returning})
        })

        this.dropStatementRule = $.RULE<() => DropStatementAst>('dropStatementRule', () => {
            const start = $.CONSUME(Drop)
            const {token, object} = $.OR([
                {ALT: () => ({token: tokenInfo2(start, $.CONSUME(Index)), object: 'Index' as const})}, // https://www.postgresql.org/docs/current/sql-dropindex.html
                {ALT: () => ({token: tokenInfo2(start, $.CONSUME(MaterializedView)), object: 'MaterializedView' as const})}, // https://www.postgresql.org/docs/current/sql-dropmaterializedview.html
                {ALT: () => ({token: tokenInfo2(start, $.CONSUME(Table)), object: 'Table' as const})}, // https://www.postgresql.org/docs/current/sql-droptable.html
                {ALT: () => ({token: tokenInfo2(start, $.CONSUME(Type)), object: 'Type' as const})}, // https://www.postgresql.org/docs/current/sql-droptype.html
                {ALT: () => ({token: tokenInfo2(start, $.CONSUME(View)), object: 'View' as const})}, // https://www.postgresql.org/docs/current/sql-dropview.html
            ])
            const concurrently = $.OPTION(() => tokenInfo($.CONSUME(Concurrently)))
            const ifExists = $.SUBRULE(ifExistsRule)
            const objects: ObjectNameAst[] = []
            $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => objects.push($.SUBRULE($.objectNameRule))})
            const mode = $.OPTION2(() => $.OR2([
                {ALT: () => ({token: tokenInfo($.CONSUME(Cascade)), kind: 'Cascade' as const})},
                {ALT: () => ({token: tokenInfo($.CONSUME(Restrict)), kind: 'Restrict' as const})},
            ]))
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'Drop' as const, meta: tokenInfo2(start, end), token, object, entities: objects.filter(isNotUndefined), concurrently, ifExists, mode})
        })

        this.insertIntoStatementRule = $.RULE<() => InsertIntoStatementAst>('insertIntoStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-insert.html
            const start = $.CONSUME(InsertInto)
            const object = $.SUBRULE($.objectNameRule)
            const columns = $.OPTION(() => {
                const columns: IdentifierAst[] = []
                $.CONSUME(ParenLeft)
                $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => columns.push($.SUBRULE($.identifierRule))})
                $.CONSUME(ParenRight)
                return columns
            })
            $.CONSUME(Values)
            const values: (ExpressionAst | { kind: 'Default', token: TokenInfo })[][] = []
            $.AT_LEAST_ONE_SEP2({SEP: Comma, DEF: () => {
                const row: ExpressionAst[] = []
                $.CONSUME2(ParenLeft)
                $.AT_LEAST_ONE_SEP3({SEP: Comma, DEF: () => row.push($.OR([
                    {ALT: () => $.SUBRULE($.expressionRule)},
                    {ALT: () => ({kind: 'Default' as const, token: tokenInfo($.CONSUME(Default))})}
                ]))})
                $.CONSUME2(ParenRight)
                values.push(row)
            }})
            const returning = $.OPTION2(() => $.SUBRULE(returningClauseRule))
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'InsertInto' as const, meta: tokenInfo2(start, end), token: tokenInfo(start), schema: object.schema, table: object.name, columns, values, returning})
        })
        const returningClauseRule = $.RULE<() => SelectClauseAst>('returningClauseRule', () => {
            const token = tokenInfo($.CONSUME(Returning))
            const columns: SelectClauseExprAst[] = []
            $.AT_LEAST_ONE_SEP4({SEP: Comma, DEF: () => columns.push($.SUBRULE(selectClauseColumnRule))})
            return {token, columns}
        })

        this.selectStatementRule = $.RULE<() => SelectStatementAst>('selectStatementRule', () => {
            const select = $.SUBRULE(selectStatementInnerRule)
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'Select' as const, meta: mergePositions([select.token, tokenInfo(end)]), ...select})
        })
        const selectStatementInnerRule = $.RULE<() => SelectStatementInnerAst>('selectStatementInnerRule', (): SelectStatementInnerAst => {
            // https://www.postgresql.org/docs/current/sql-select.html
            return $.OR([
                {ALT: () => {
                    const main = $.SUBRULE(selectStatementMainRule)
                    const result = $.SUBRULE(selectStatementResultRule)
                    return removeUndefined({...main, ...result})
                }},
                {ALT: () => { // allow additional parenthesis
                    $.CONSUME(ParenLeft)
                    const main = $.SUBRULE2(selectStatementMainRule)
                    return $.OR2([
                        {ALT: () => { // close parenthesis before union
                            $.CONSUME(ParenRight)
                            const union = $.SUBRULE(unionClauseRule)
                            const orderBy = $.OPTION2(() => $.SUBRULE(orderByClauseRule))
                            const limit = $.OPTION3(() => $.SUBRULE(limitClauseRule))
                            const offset = $.OPTION4(() => $.SUBRULE(offsetClauseRule))
                            const fetch = $.OPTION5(() => $.SUBRULE(fetchClauseRule))
                            return removeUndefined({...main, union, orderBy, limit, offset, fetch})
                        }},
                        // TODO: close parenthesis before orderBy
                        // TODO: close parenthesis before limit
                        // TODO: close parenthesis before offset
                        // TODO: close parenthesis before fetch
                        {ALT: () => { // close parenthesis at the end
                            const result = $.SUBRULE2(selectStatementResultRule)
                            $.CONSUME2(ParenRight)
                            return removeUndefined({...main, ...result})
                        }},
                    ])
                }},
            ])
        })
        const selectStatementMainRule = $.RULE<() => SelectStatementMainAst>('selectStatementMainRule', (): SelectStatementInnerAst => {
            const select = $.SUBRULE($.selectClauseRule)
            const from = $.OPTION(() => $.SUBRULE($.fromClauseRule))
            const where = $.OPTION2(() => $.SUBRULE($.whereClauseRule))
            const groupBy = $.OPTION3(() => $.SUBRULE(groupByClauseRule))
            const having = $.OPTION4(() => $.SUBRULE(havingClauseRule))
            return removeUndefined({...select, from, where, groupBy, having})
        })
        const selectStatementResultRule = $.RULE<() => SelectStatementResultAst>('selectStatementResultRule', () => {
            const union = $.OPTION(() => $.SUBRULE3(unionClauseRule))
            const orderBy = $.OPTION2(() => $.SUBRULE(orderByClauseRule))
            const limit = $.OPTION3(() => $.SUBRULE(limitClauseRule))
            const offset = $.OPTION4(() => $.SUBRULE(offsetClauseRule))
            const fetch = $.OPTION5(() => $.SUBRULE(fetchClauseRule))
            return removeUndefined({union, orderBy, limit, offset, fetch})
        })

        this.setStatementRule = $.RULE<() => SetStatementAst>('setStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-set.html
            const start = $.CONSUME(Set)
            const scope = $.OPTION(() => $.OR([
                {ALT: () => ({kind: 'Session' as const, token: tokenInfo($.CONSUME(Session))})},
                {ALT: () => ({kind: 'Local' as const, token: tokenInfo($.CONSUME(Local))})},
            ]))
            const parameter = $.SUBRULE($.identifierRule)
            const equal = $.OPTION2(() => $.OR2([
                {ALT: () => ({kind: '=' as const, token: tokenInfo($.CONSUME(Equal))})},
                {ALT: () => ({kind: 'To' as const, token: tokenInfo($.CONSUME(To))})},
            ]))
            const value = $.OR3([
                {ALT: () => ({kind: 'Default' as const, token: tokenInfo($.CONSUME(Default))})},
                {ALT: () => {
                    const values: (IdentifierAst | LiteralAst)[] = []
                    $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => values.push($.OR4([
                        {ALT: () => $.SUBRULE2($.literalRule)},
                        {ALT: () => $.SUBRULE3($.identifierRule)},
                        {ALT: () => toIdentifier($.CONSUME(On))}, // special case, `on` being a valid identifier here
                    ]))})
                    return values.length === 1 ? values[0] : values
                }},
            ])
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'Set' as const, meta: tokenInfo2(start, end), token: tokenInfo(start), scope, parameter, equal, value})
        })

        // clauses

        this.selectClauseRule = $.RULE<() => SelectClauseAst>('selectClauseRule', () => {
            const token = tokenInfo($.CONSUME(Select))
            const columns: SelectClauseExprAst[] = []
            $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => columns.push($.SUBRULE(selectClauseColumnRule))})
            return {token, columns}
        })
        const selectClauseColumnRule = $.RULE<() => SelectClauseExprAst>('selectClauseColumnRule', () => {
            const expression = $.SUBRULE($.expressionRule)
            const alias = $.OPTION(() => $.SUBRULE($.aliasRule))
            return removeUndefined({...expression, alias})
        })

        this.fromClauseRule = $.RULE<() => FromClauseAst>('fromClauseRule', () => {
            const token = tokenInfo($.CONSUME(From))
            const item = $.SUBRULE(fromItemRule)
            const joins: FromJoinAst[] = []
            $.MANY({DEF: () => joins.push($.SUBRULE(fromJoinRule))})
            return removeEmpty({token, ...item, joins})
        })
        const fromItemRule = $.RULE<() => FromItemAst>('fromItemRule', () => {
            const item = $.OR([
                {ALT: () => $.SUBRULE(fromTableRule)},
                {ALT: () => $.SUBRULE(fromQueryRule)},
            ])
            const alias = $.OPTION(() => $.SUBRULE($.aliasRule))
            return removeUndefined({...item, alias})
        })
        const fromTableRule = $.RULE<() => FromTableAst>('fromTableRule', () => {
            const object = $.SUBRULE($.objectNameRule)
            return removeUndefined({kind: 'Table' as const, schema: object.schema, table: object.name})
        })
        const fromQueryRule = $.RULE<() => FromQueryAst>('fromQueryRule', () => {
            $.CONSUME(ParenLeft)
            const select = $.SUBRULE(selectStatementInnerRule)
            $.CONSUME(ParenRight)
            return {kind: 'Select', select}
        })
        const fromJoinRule = $.RULE<() => FromJoinAst>('fromJoinRule', () => {
            const natural = $.OPTION(() => ({kind: 'Natural', token: tokenInfo($.CONSUME(Natural))}))
            const {kind, token} = $.OR([
                {ALT: () => ({kind: 'Inner' as const, token: tokenInfo2($.OPTION2(() => $.CONSUME(Inner)), $.CONSUME(Join))})},
                {ALT: () => ({kind: 'Left' as const, token: tokenInfo3($.CONSUME(Left), $.OPTION3(() => $.CONSUME(Outer)), $.CONSUME2(Join))})},
                {ALT: () => ({kind: 'Right' as const, token: tokenInfo3($.CONSUME(Right), $.OPTION4(() => $.CONSUME2(Outer)), $.CONSUME3(Join))})},
                {ALT: () => ({kind: 'Full' as const, token: tokenInfo3($.CONSUME(Full), $.OPTION5(() => $.CONSUME3(Outer)), $.CONSUME4(Join))})},
                {ALT: () => ({kind: 'Cross' as const, token: tokenInfo2($.CONSUME(Cross), $.CONSUME5(Join))})},
            ])
            const from = $.SUBRULE(fromItemRule)
            const on = $.OPTION6(() => $.OR2([
                {ALT: () => ({kind: 'On', token: tokenInfo($.CONSUME(On)), predicate: $.SUBRULE($.expressionRule)})},
                {ALT: () => {
                    const token = tokenInfo($.CONSUME(Using))
                    const columns: IdentifierAst[] = []
                    $.CONSUME(ParenLeft)
                    $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => columns.push($.SUBRULE($.identifierRule))})
                    $.CONSUME(ParenRight)
                    return {kind: 'Using', token, columns: columns.filter(isNotUndefined)}
                }},
            ])) || natural
            const alias = $.OPTION7(() => $.SUBRULE($.aliasRule))
            return removeUndefined({kind, token, from, on, alias})
        })

        this.whereClauseRule = $.RULE<() => WhereClauseAst>('whereClauseRule', () => {
            const token = tokenInfo($.CONSUME(Where))
            return {token, predicate: $.SUBRULE($.expressionRule)}
        })
        const groupByClauseRule = $.RULE<() => GroupByClauseAst>('groupByClauseRule', () => {
            const token = tokenInfo($.CONSUME(GroupBy))
            const mode = $.OPTION(() => $.OR([
                {ALT: () => ({kind: 'All' as const, token: tokenInfo($.CONSUME(All))})},
                {ALT: () => ({kind: 'Distinct' as const, token: tokenInfo($.CONSUME(Distinct))})},
            ]))
            const expressions: ExpressionAst[] = []
            $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => expressions.push($.SUBRULE($.expressionRule))})
            return removeUndefined({token, mode, expressions: expressions.filter(isNotUndefined)})
        })
        const havingClauseRule = $.RULE<() => HavingClauseAst>('havingClauseRule', () => {
            const token = tokenInfo($.CONSUME(Having))
            return {token, predicate: $.SUBRULE($.expressionRule)}
        })
        const unionClauseRule = $.RULE<() => UnionClauseAst>('unionClauseRule', () => {
            const {kind, token} = $.OR([
                {ALT: () => ({kind: 'Union' as const, token: tokenInfo($.CONSUME(Union))})},
                {ALT: () => ({kind: 'Intersect' as const, token: tokenInfo($.CONSUME(Intersect))})},
                {ALT: () => ({kind: 'Except' as const, token: tokenInfo($.CONSUME(Except))})},
            ])
            const mode = $.OPTION(() => $.OR2([
                {ALT: () => ({kind: 'All' as const, token: tokenInfo($.CONSUME(All))})},
                {ALT: () => ({kind: 'Distinct' as const, token: tokenInfo($.CONSUME(Distinct))})},
            ]))
            const select = $.SUBRULE(selectStatementInnerRule)
            return removeUndefined({kind, token, mode, select})
        })
        const orderByClauseRule = $.RULE<() => OrderByClauseAst>('orderByClauseRule', () => {
            const token = tokenInfo($.CONSUME(OrderBy))
            const expressions: (ExpressionAst & {order?: SortOrderAst, nulls?: SortNullsAst})[] = []
            $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => {
                const expr = $.SUBRULE($.expressionRule)
                const order = $.OPTION2(() => $.SUBRULE(sortOrderRule))
                const nulls = $.OPTION3(() => $.SUBRULE(sortNullsRule))
                expr && expressions.push(removeUndefined({...expr, order, nulls}))
            }})
            return {token, expressions}
        })
        const limitClauseRule = $.RULE<() => LimitClauseAst>('limitClauseRule', () => {
            const token = tokenInfo($.CONSUME(Limit))
            const value = $.OR([
                {ALT: () => $.SUBRULE($.integerRule)},
                {ALT: () => $.SUBRULE($.parameterRule)},
                {ALT: () => ({kind: 'All' as const, token: tokenInfo($.CONSUME(All))})},
            ])
            return {token, value}
        })
        const offsetClauseRule = $.RULE<() => OffsetClauseAst>('offsetClauseRule', () => {
            const token = tokenInfo($.CONSUME(Offset))
            const value = $.OR([
                {ALT: () => $.SUBRULE($.integerRule)},
                {ALT: () => $.SUBRULE($.parameterRule)},
            ])
            const rows = $.OPTION(() => $.OR2([
                {ALT: () => ({kind: 'Row' as const, token: tokenInfo($.CONSUME(Row))})},
                {ALT: () => ({kind: 'Rows' as const, token: tokenInfo($.CONSUME(Rows))})},
            ]))
            return removeUndefined({token, value, rows})
        })
        const fetchClauseRule = $.RULE<() => FetchClauseAst>('fetchClauseRule', () => {
            const token = tokenInfo($.CONSUME(Fetch))
            const first = $.OR([
                {ALT: () => ({kind: 'First' as const, token: tokenInfo($.CONSUME(First))})},
                {ALT: () => ({kind: 'Next' as const, token: tokenInfo($.CONSUME(Next))})},
            ])
            const value = $.OR2([
                {ALT: () => $.SUBRULE($.integerRule)},
                {ALT: () => $.SUBRULE($.parameterRule)},
            ])
            const rows = $.OR3([
                {ALT: () => ({kind: 'Row' as const, token: tokenInfo($.CONSUME(Row))})},
                {ALT: () => ({kind: 'Rows' as const, token: tokenInfo($.CONSUME(Rows))})},
            ])
            const mode = $.OR4([
                {ALT: () => ({kind: 'Only' as const, token: tokenInfo($.CONSUME(Only))})},
                {ALT: () => ({kind: 'WithTies' as const, token: tokenInfo2($.CONSUME(With), $.CONSUME(Ties))})},
            ])
            return {token, first, value, rows, mode}
        })

        const indexColumnRule = $.RULE<() => IndexColumnAst>('indexColumnRule', () => {
            const expr = $.SUBRULE($.expressionRule)
            const collation = $.OPTION(() => ({token: tokenInfo($.CONSUME(Collate)), name: $.SUBRULE3($.identifierRule)}))
            const order = $.OPTION2(() => $.SUBRULE(sortOrderRule))
            const nulls = $.OPTION3(() => $.SUBRULE(sortNullsRule))
            return removeUndefined({...expr, collation, order, nulls})
        })
        const sortOrderRule = $.RULE<() => SortOrderAst>('sortOrderRule', () => {
            return $.OR([
                {ALT: () => ({kind: 'Asc' as const, token: tokenInfo($.CONSUME(Asc))})},
                {ALT: () => ({kind: 'Desc' as const, token: tokenInfo($.CONSUME(Desc))})},
            ])
        })
        const sortNullsRule = $.RULE<() => SortNullsAst>('sortNullsRule', () => {
            const nulls = $.CONSUME(Nulls)
            return $.OR([
                {ALT: () => ({kind: 'First' as const, token: tokenInfo2(nulls, $.CONSUME(First))})},
                {ALT: () => ({kind: 'Last' as const, token: tokenInfo2(nulls, $.CONSUME(Last))})},
            ])
        })

        this.tableColumnRule = $.RULE<() => TableColumnAst>('tableColumnRule', () => {
            const name = $.SUBRULE($.identifierRule)
            const type = $.SUBRULE($.columnTypeRule)
            const constraints: TableColumnConstraintAst[] = []
            $.MANY(() => constraints.push($.SUBRULE(tableColumnConstraintRule)))
            return removeEmpty({name, type, constraints: constraints.filter(isNotUndefined)})
        })
        const tableColumnConstraintRule = $.RULE<() => TableColumnConstraintAst>('tableColumnConstraintRule', () => $.OR([
            {ALT: () => $.SUBRULE(tableColumnNullableRule)},
            {ALT: () => $.SUBRULE(tableColumnDefaultRule)},
            {ALT: () => $.SUBRULE(tableColumnPkRule)},
            {ALT: () => $.SUBRULE(tableColumnUniqueRule)},
            {ALT: () => $.SUBRULE(tableColumnCheckRule)},
            {ALT: () => $.SUBRULE(tableColumnFkRule)},
        ]))
        const tableColumnNullableRule = $.RULE<() => TableColumnNullableAst>('tableColumnNullableRule', () => {
            const constraint = $.OPTION(() => $.SUBRULE(constraintNameRule))
            const not = $.OPTION2(() => $.CONSUME(Not))
            const nullable = $.CONSUME(Null)
            return removeUndefined({kind: 'Nullable' as const, constraint, token: tokenInfo2(not, nullable), value: !not})
        })
        const tableColumnDefaultRule = $.RULE<() => TableColumnDefaultAst>('tableColumnDefaultRule', () => {
            const constraint = $.OPTION(() => $.SUBRULE(constraintNameRule))
            const token = tokenInfo($.CONSUME(Default))
            const expression = $.SUBRULE(atomicExpressionRule)
            return removeUndefined({kind: 'Default' as const, constraint, token, expression})
        })
        const tableColumnPkRule = $.RULE<() => TableColumnPkAst>('tableColumnPkRule', () => {
            const constraint = $.OPTION(() => $.SUBRULE(constraintNameRule))
            const token = tokenInfo($.CONSUME(PrimaryKey))
            return removeUndefined({kind: 'PrimaryKey' as const, constraint, token})
        })
        const tableColumnUniqueRule = $.RULE<() => TableColumnUniqueAst>('tableColumnUniqueRule', () => {
            const constraint = $.OPTION(() => $.SUBRULE(constraintNameRule))
            const token = tokenInfo($.CONSUME(Unique))
            return removeUndefined({kind: 'Unique' as const, constraint, token})
        })
        const tableColumnCheckRule = $.RULE<() => TableColumnCheckAst>('tableColumnCheckRule', () => {
            const constraint = $.OPTION(() => $.SUBRULE(constraintNameRule))
            const token = tokenInfo($.CONSUME(Check))
            $.CONSUME(ParenLeft)
            const predicate = $.SUBRULE($.expressionRule)
            $.CONSUME(ParenRight)
            return removeUndefined({kind: 'Check' as const, constraint, token, predicate})
        })
        const tableColumnFkRule = $.RULE<() => TableColumnFkAst>('tableColumnFkRule', () => {
            const constraint = $.OPTION(() => $.SUBRULE(constraintNameRule))
            const token = tokenInfo($.CONSUME(References))
            const object = $.SUBRULE($.objectNameRule)
            const column = $.OPTION2(() => {
                $.CONSUME(ParenLeft)
                const column = $.SUBRULE($.identifierRule)
                $.CONSUME(ParenRight)
                return column
            })
            const onUpdate = $.OPTION3(() => ({token: tokenInfo2($.CONSUME(On), $.CONSUME(Update)), ...$.SUBRULE(foreignKeyActionsRule)}))
            const onDelete = $.OPTION4(() => ({token: tokenInfo2($.CONSUME2(On), $.CONSUME(Delete)), ...$.SUBRULE2(foreignKeyActionsRule)}))
            return removeUndefined({kind: 'ForeignKey' as const, constraint, token, schema: object.schema, table: object.name, column, onUpdate, onDelete})
        })

        this.tableConstraintRule = $.RULE<() => TableConstraintAst>('tableConstraintRule', () => $.OR([
            {ALT: () => $.SUBRULE(tablePkRule)},
            {ALT: () => $.SUBRULE(tableUniqueRule)},
            {ALT: () => $.SUBRULE(tableCheckRule)},
            {ALT: () => $.SUBRULE(tableFkRule)},
        ]))
        const tablePkRule = $.RULE<() => TablePkAst>('tablePkRule', () => {
            const constraint = $.OPTION(() => $.SUBRULE(constraintNameRule))
            const token = tokenInfo($.CONSUME(PrimaryKey))
            const columns = $.SUBRULE(columnNamesRule)
            return removeUndefined({kind: 'PrimaryKey' as const, constraint, token, columns})
        })
        const tableUniqueRule = $.RULE<() => TableUniqueAst>('tableUniqueRule', () => {
            const constraint = $.OPTION(() => $.SUBRULE(constraintNameRule))
            const token = tokenInfo($.CONSUME(Unique))
            const columns = $.SUBRULE(columnNamesRule)
            return removeUndefined({kind: 'Unique' as const, constraint, token, columns})
        })
        const tableCheckRule = tableColumnCheckRule // exactly the same ^^
        const tableFkRule = $.RULE<() => TableFkAst>('tableFkRule', () => {
            const constraint = $.OPTION(() => $.SUBRULE(constraintNameRule))
            const token = tokenInfo($.CONSUME(ForeignKey))
            const columns = $.SUBRULE(columnNamesRule)
            const refToken = $.CONSUME(References)
            const refTable = $.SUBRULE($.objectNameRule)
            const refColumns = $.OPTION2(() => $.SUBRULE2(columnNamesRule))
            const onUpdate = $.OPTION3(() => ({token: tokenInfo2($.CONSUME(On), $.CONSUME(Update)), ...$.SUBRULE(foreignKeyActionsRule)}))
            const onDelete = $.OPTION4(() => ({token: tokenInfo2($.CONSUME2(On), $.CONSUME(Delete)), ...$.SUBRULE2(foreignKeyActionsRule)}))
            const ref = removeUndefined({token: tokenInfo(refToken), schema: refTable.schema, table: refTable.name, columns: refColumns})
            return removeUndefined({kind: 'ForeignKey' as const, constraint, token, columns, ref, onUpdate, onDelete})
        })

        const createTypeStructAttrs = $.RULE<() => TypeColumnAst[]>('createTypeStructAttrs', () => {
            $.CONSUME(ParenLeft)
            const attrs: TypeColumnAst[] = []
            $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => attrs.push(removeUndefined({
                name: $.SUBRULE($.identifierRule),
                type: $.SUBRULE($.columnTypeRule),
                collation: $.OPTION(() => ({token: tokenInfo($.CONSUME(Collate)), name: $.SUBRULE2($.identifierRule)}))
            }))})
            $.CONSUME(ParenRight)
            return attrs.filter(isNotUndefined)
        })
        const createTypeEnumValues = $.RULE<() => StringAst[]>('createTypeEnumValues', () => {
            $.CONSUME(ParenLeft)
            const values: StringAst[] = []
            $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => values.push($.SUBRULE($.stringRule))})
            $.CONSUME(ParenRight)
            return values
        })
        const createTypeBase = $.RULE<() => {name: IdentifierAst, value: ExpressionAst}[]>('createTypeBase', () => {
            $.CONSUME(ParenLeft)
            const params: {name: IdentifierAst, value: ExpressionAst}[] = []
            $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => {
                const name = $.SUBRULE($.identifierRule)
                $.CONSUME(Equal)
                const value = $.SUBRULE($.expressionRule)
                params.push({name, value})
            }})
            $.CONSUME(ParenRight)
            return params
        })

        const constraintNameRule = $.RULE<() => ConstraintNameAst>('constraintNameRule', () => ({token: tokenInfo($.CONSUME(Constraint)), name: $.SUBRULE($.identifierRule)}))
        const foreignKeyActionsRule = $.RULE<() => ForeignKeyActionAst>('foreignKeyActionsRule', () => {
            const action = $.OR([
                {ALT: () => ({kind: 'NoAction' as const, token: tokenInfo($.CONSUME(NoAction))})},
                {ALT: () => ({kind: 'Restrict' as const, token: tokenInfo($.CONSUME(Restrict))})},
                {ALT: () => ({kind: 'Cascade' as const, token: tokenInfo($.CONSUME(Cascade))})},
                {ALT: () => ({kind: 'SetNull' as const, token: tokenInfo($.CONSUME(SetNull))})},
                {ALT: () => ({kind: 'SetDefault' as const, token: tokenInfo($.CONSUME(SetDefault))})},
            ])
            const columns = $.OPTION(() => $.SUBRULE(columnNamesRule))
            return removeEmpty({action, columns})
        })
        const columnNamesRule = $.RULE<() => IdentifierAst[]>('columnNamesRule', () => {
            $.CONSUME(ParenLeft)
            const columns: IdentifierAst[] = []
            $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => columns.push($.SUBRULE($.identifierRule))})
            $.CONSUME(ParenRight)
            return columns.filter(isNotUndefined)
        })

        const ifExistsRule = $.RULE<() => TokenInfo | undefined>('ifExistsRule', () => $.OPTION(() => tokenInfo2($.CONSUME(If), $.CONSUME(Exists))))
        const ifNotExistsRule = $.RULE<() => TokenInfo | undefined>('ifNotExistsRule', () => $.OPTION(() => tokenInfo3($.CONSUME(If), $.CONSUME(Not), $.CONSUME(Exists))))

        // basic parts

        this.aliasRule = $.RULE<() => AliasAst>('aliasRule', () => {
            const token = $.OPTION(() => tokenInfo($.CONSUME(As)))
            const name = $.SUBRULE($.identifierRule)
            return removeUndefined({token, name})
        })

        this.expressionRule = $.RULE<() => ExpressionAst>('expressionRule', () => $.SUBRULE(orExpressionRule)) // Start with OR expressions (lowest precedence)
        const orExpressionRule = $.RULE<() => ExpressionAst>('orExpressionRule', () => {
            let expr = $.SUBRULE(andExpressionRule) // AND has higher precedence than OR
            $.MANY(() => {
                const op = {kind: 'Or' as const, token: tokenInfo($.CONSUME(Or))}
                const right = $.SUBRULE2(andExpressionRule)
                expr = {kind: 'Operation', left: expr, op, right}
            })
            return expr
        })
        const andExpressionRule = $.RULE<() => ExpressionAst>('andExpressionRule', () => {
            let expr = $.SUBRULE(operatorExpressionRule) // operator has higher precedence than AND
            $.MANY(() => {
                const op = {kind: 'And' as const, token: tokenInfo($.CONSUME(And))}
                const right = $.SUBRULE2(operatorExpressionRule)
                expr = {kind: 'Operation', left: expr, op, right}
            })
            return expr
        })
        const operatorExpressionRule = $.RULE<() => ExpressionAst>('operatorExpressionRule', () => {
            let expr = $.SUBRULE(atomicExpressionRule) // atomic has the highest precedence
            $.OPTION(() => {
                const op = $.SUBRULE(operatorRule)
                if (['In', 'NotIn'].includes(op?.kind)) {
                    const right = $.SUBRULE(listRule)
                    expr = {kind: 'Operation', left: expr, op, right}
                } else {
                    const right = $.SUBRULE2(atomicExpressionRule)
                    expr = {kind: 'Operation', left: expr, op, right}
                }
            })
            return expr
        })
        const atomicExpressionRule = $.RULE<() => ExpressionAst>('atomicExpressionRule', () => {
            const expr = $.OR([
                {ALT: () => $.SUBRULE(groupRule)},
                {ALT: () => $.SUBRULE($.literalRule)},
                {ALT: () => $.SUBRULE($.parameterRule)},
                {ALT: () => ({kind: 'Wildcard', token: tokenInfo($.CONSUME(Asterisk))})},
                {ALT: () => {
                    const first = $.SUBRULE($.identifierRule)
                    const nest = $.OPTION(() => $.OR2([
                        {ALT: () => ({kind: 'Function', function: first, parameters: $.SUBRULE(functionParamsRule)})},
                        {ALT: () => {
                            $.CONSUME(Dot)
                            return $.OR3([
                                {ALT: () => ({kind: 'Wildcard', table: first, token: tokenInfo($.CONSUME2(Asterisk))})},
                                {ALT: () => {
                                    const second = $.SUBRULE2($.identifierRule)
                                    const nest2 = $.OPTION2(() => $.OR4([
                                        {ALT: () => ({kind: 'Function', schema: first, function: second, parameters: $.SUBRULE2(functionParamsRule)})},
                                        {ALT: () => {
                                            $.CONSUME2(Dot)
                                            return $.OR5([
                                                {ALT: () => ({kind: 'Wildcard', schema: first, table: second, token: tokenInfo($.CONSUME3(Asterisk))})},
                                                {ALT: () => removeEmpty({kind: 'Column', schema: first, table: second, column: $.SUBRULE3($.identifierRule), json: $.SUBRULE3(columnJsonRule)})},
                                            ])
                                        }}
                                    ]))
                                    return nest2 ? nest2 : removeEmpty({kind: 'Column', table: first, column: second, json: $.SUBRULE2(columnJsonRule)})
                                }}
                            ])
                        }}
                    ]))
                    return nest ? nest : removeEmpty({kind: 'Column', column: first, json: $.SUBRULE(columnJsonRule)})
                }}
            ])
            const cast = $.OPTION3(() => ({token: tokenInfo2($.CONSUME(Colon), $.CONSUME2(Colon)), type: $.SUBRULE($.columnTypeRule)}))
            return removeUndefined({...expr, cast})
        })
        const operatorRule = $.RULE<() => OperatorAst>('operatorRule', () => $.OR([
            // https://www.postgresql.org/docs/current/functions.html
            {ALT: () => ({kind: '+' as const, token: tokenInfo($.CONSUME(Plus))})},
            {ALT: () => ({kind: '-' as const, token: tokenInfo($.CONSUME(Dash))})},
            {ALT: () => ({kind: '*' as const, token: tokenInfo($.CONSUME(Asterisk))})},
            {ALT: () => ({kind: '/' as const, token: tokenInfo($.CONSUME(Slash))})},
            {ALT: () => ({kind: '%' as const, token: tokenInfo($.CONSUME(Percent))})},
            {ALT: () => ({kind: '^' as const, token: tokenInfo($.CONSUME(Caret))})},
            {ALT: () => ({kind: '&' as const, token: tokenInfo($.CONSUME(Amp))})},
            {ALT: () => ({kind: '#' as const, token: tokenInfo($.CONSUME(Hash))})},
            {ALT: () => ({kind: '=' as const, token: tokenInfo($.CONSUME(Equal))})},
            {ALT: () => ({kind: 'Like' as const, token: tokenInfo($.CONSUME(Like))})},
            {ALT: () => ({kind: 'In' as const, token: tokenInfo($.CONSUME(In))})},
            {ALT: () => {
                const lt = $.CONSUME(LowerThan)
                const res = $.OPTION(() => $.OR2([
                    {ALT: () => ({kind: '<=' as const, token: tokenInfo2(lt, $.CONSUME2(Equal))})},
                    {ALT: () => ({kind: '<<' as const, token: tokenInfo2(lt, $.CONSUME2(LowerThan))})},
                    {ALT: () => ({kind: '<>' as const, token: tokenInfo2(lt, $.CONSUME(GreaterThan))})},
                ]))
                return res ? res : {kind: '<' as const, token: tokenInfo(lt)}
            }},
            {ALT: () => {
                const gt = $.CONSUME2(GreaterThan)
                const res = $.OPTION2(() => $.OR3([
                    {ALT: () => ({kind: '>=' as const, token: tokenInfo2(gt, $.CONSUME3(Equal))})},
                    {ALT: () => ({kind: '>>' as const, token: tokenInfo2(gt, $.CONSUME3(GreaterThan))})},
                ]))
                return res ? res : {kind: '>' as const, token: tokenInfo(gt)}
            }},
            {ALT: () => {
                const pipe = $.CONSUME(Pipe)
                const res = $.OPTION3(() => ({kind: '||' as const, token: tokenInfo2(pipe, $.CONSUME2(Pipe))}))
                return res ? res : {kind: '|' as const, token: tokenInfo(pipe)}
            }},
            {ALT: () => {
                const tilde = $.CONSUME(Tilde)
                const res = $.OPTION4(() => ({kind: '~*' as const, token: tokenInfo2(tilde, $.CONSUME2(Asterisk))}))
                return res ? res : {kind: '~' as const, token: tokenInfo(tilde)}
            }},
            {ALT: () => {
                const exclamation = $.CONSUME(Exclamation)
                return $.OR4([
                    {ALT: () => ({kind: '!=' as const, token: tokenInfo2(exclamation, $.CONSUME4(Equal))})},
                    {ALT: () => {
                        const tilde = $.CONSUME2(Tilde)
                        const res = $.OPTION5(() => ({kind: '!~*' as const, token: tokenInfo3(exclamation, tilde, $.CONSUME3(Asterisk))}))
                        return res ? res : {kind: '!~' as const, token: tokenInfo2(exclamation, tilde)}
                    }}
                ])
            }},
            {ALT: () => {
                const not = $.CONSUME2(Not)
                return $.OPTION6(() => $.OR5([
                    {ALT: () => ({kind: 'NotLike' as const, token: tokenInfo2(not, $.CONSUME2(Like))})},
                    {ALT: () => ({kind: 'NotIn' as const, token: tokenInfo2(not, $.CONSUME2(In))})},
                ]))
            }},
        ]))
        const groupRule = $.RULE<() => GroupAst>('groupRule', () => {
            $.CONSUME(ParenLeft)
            const expression = $.SUBRULE($.expressionRule)
            $.CONSUME(ParenRight)
            return {kind: 'Group', expression}
        })
        const listRule = $.RULE<() => ListAst>('listRule', () => {
            $.CONSUME(ParenLeft)
            const items: LiteralAst[] = []
            $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => items.push($.SUBRULE($.literalRule))})
            $.CONSUME(ParenRight)
            return {kind: 'List', items}
        })
        const columnJsonRule = $.RULE<() => ColumnJsonAst[]>('columnJsonRule', () => {
            const res: ColumnJsonAst[] = []
            $.MANY({DEF: () => {
                const nest = $.SUBRULE(jsonOpRule)
                const field = $.SUBRULE($.stringRule)
                res.push({...nest, field})
            }})
            return res
        })
        const jsonOpRule = $.RULE<() => { kind: JsonOp, token: TokenInfo }>('jsonOpRule', () => {
            const dash = $.CONSUME(Dash)
            const gt = $.CONSUME(GreaterThan)
            const gt2 = $.OPTION(() => $.CONSUME2(GreaterThan))
            return gt2 ? {kind: '->>' as const, token: tokenInfo3(dash, gt, gt2)} : {kind: '->' as const, token: tokenInfo2(dash, gt)}
        })
        const functionParamsRule = $.RULE<() => ExpressionAst[]>('functionParamsRule', () => {
            $.CONSUME(ParenLeft)
            const parameters: ExpressionAst[] = []
            $.MANY_SEP({SEP: Comma, DEF: () => parameters.push($.SUBRULE($.expressionRule))})
            $.CONSUME(ParenRight)
            return parameters.filter(isNotUndefined)
        })

        this.objectNameRule = $.RULE<() => ObjectNameAst>('objectNameRule', () => {
            const first = $.SUBRULE($.identifierRule)
            const second = $.OPTION(() => {
                $.CONSUME(Dot)
                return $.SUBRULE2($.identifierRule)
            })
            return second ? {schema: first, name: second} : {name: first}
        })

        this.columnTypeRule = $.RULE<() => ColumnTypeAst>('columnTypeRule', () => {
            const schema = $.OPTION(() => {
                const s = $.SUBRULE($.identifierRule)
                $.CONSUME(Dot)
                return s
            })
            const parts: {name: IdentifierAst, args?: IntegerAst[], last?: TokenInfo}[] = []
            $.AT_LEAST_ONE({DEF: () => parts.push($.OR([
                {ALT: () => {
                    const name = $.SUBRULE2($.identifierRule)
                    const params = $.OPTION2(() => {
                        $.CONSUME(ParenLeft)
                        const values: IntegerAst[] = []
                        $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => values.push($.SUBRULE($.integerRule))})
                        const last = tokenInfo($.CONSUME(ParenRight))
                        return {values, last}
                    })
                    return {name, args: params?.values, last: params?.last}
                }},
                {ALT: () => ({name: toIdentifier($.CONSUME(With))})}, // needed for `with time zone`
            ]))})
            const array = $.OPTION3(() => tokenInfo2($.CONSUME(BracketLeft), $.CONSUME(BracketRight)))
            const name = {
                token: mergePositions(parts.flatMap(p => [p.name?.token, p.last]).concat([array])),
                value: parts.filter(isNotUndefined).map(p => p.name?.value + (p.args ? `(${p.args.map(v => v.value).join(', ')})` : '')).join(' ') + (array ? '[]' : '')
            }
            return removeEmpty({schema, name, args: parts.flatMap(p => p.args || []), array, token: mergePositions([schema?.token, name.token])})
        })

        this.literalRule = $.RULE<() => LiteralAst>('literalRule', () => $.OR([
            {ALT: () => $.SUBRULE($.stringRule)},
            {ALT: () => $.SUBRULE($.decimalRule)},
            {ALT: () => $.SUBRULE($.integerRule)},
            {ALT: () => $.SUBRULE($.booleanRule)},
            {ALT: () => $.SUBRULE($.nullRule)},
        ]))

        // elements

        this.parameterRule = $.RULE<() => ParameterAst>('parameterRule', () => $.OR([
            {ALT: () => ({kind: 'Parameter', value: '?', token: tokenInfo($.CONSUME(QuestionMark))})},
            {ALT: () => {
                const d = $.CONSUME(Dollar)
                const i = $.CONSUME(Integer)
                return {kind: 'Parameter', value: `${d.image}${i.image}`, index: parseInt(i.image), token: tokenInfo2(d, i)}
            }}
        ]))

        this.identifierRule = $.RULE<() => IdentifierAst>('identifierRule', () => $.OR([
            {ALT: () => {
                const token = $.CONSUME(Identifier)
                if (token.image.startsWith('"') && token.image.endsWith('"')) {
                    return {kind: 'Identifier', token: tokenInfo(token), value: token.image.slice(1, -1).replaceAll(/\\"/g, '"'), quoted: true}
                } else {
                    return {kind: 'Identifier', token: tokenInfo(token), value: token.image}
                }
            }},
            {ALT: () => toIdentifier($.CONSUME(Index))}, // allowed as identifier
            {ALT: () => toIdentifier($.CONSUME(Version))}, // allowed as identifier
        ]))

        this.stringRule = $.RULE<() => StringAst>('stringRule', () => {
            const token = $.CONSUME(String)
            if (token.image.match(/^E/i)) {
                // https://www.postgresql.org/docs/current/sql-syntax-lexical.html
                return {kind: 'String', token: tokenInfo(token), value: token.image.slice(2, -1).replaceAll(/''/g, "'"), escaped: true}
            } else {
                return {kind: 'String', token: tokenInfo(token), value: token.image.slice(1, -1).replaceAll(/''/g, "'")}
            }
        })

        this.integerRule = $.RULE<() => IntegerAst>('integerRule', () => {
            const neg = $.OPTION(() => $.CONSUME(Dash))
            const token = $.CONSUME(Integer)
            return neg ? {kind: 'Integer', token: tokenInfo2(neg, token), value: parseInt(neg.image + token.image)} :
                {kind: 'Integer', token: tokenInfo(token), value: parseInt(token.image)}
        })

        this.decimalRule = $.RULE<() => DecimalAst>('decimalRule', () => {
            const neg = $.OPTION(() => $.CONSUME(Dash))
            const token = $.CONSUME(Decimal)
            return neg ? {kind: 'Decimal', token: tokenInfo2(neg, token), value: parseFloat(neg.image + token.image)} :
                {kind: 'Decimal', token: tokenInfo(token), value: parseFloat(token.image)}
        })

        this.booleanRule = $.RULE<() => BooleanAst>('booleanRule', () => $.OR([
            {ALT: () => ({kind: 'Boolean', token: tokenInfo($.CONSUME(True)), value: true})},
            {ALT: () => ({kind: 'Boolean', token: tokenInfo($.CONSUME(False)), value: false})},
        ]))

        this.nullRule = $.RULE<() => NullAst>('nullRule', () => ({kind: 'Null', token: tokenInfo($.CONSUME(Null))}))

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
        return {kind: 'line', token: tokenInfo(token), value: token.image.slice(2).trim()}
    } else if (token.image.startsWith('/*\n *') && token.image.endsWith('\n */')) {
        return {kind: 'doc', token: tokenInfo(token), value: token.image.slice(3, -4).split('\n').map(line => line.startsWith(' *') ? line.slice(2).trim() : line.trim()).join('\n')}
    } else {
        return {kind: 'block', token: tokenInfo(token), value: token.image.slice(2, -2).trim()}
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

function toIdentifier(token: IToken): IdentifierAst {
    return {kind: 'Identifier', token: tokenInfo(token), value: token.image}
}

function tokenInfo(token: IToken, issues?: TokenIssue[]): TokenInfo {
    return removeEmpty({...tokenPosition(token), issues})
}

function tokenInfo2(start: IToken | undefined, end: IToken | undefined, issues?: TokenIssue[]): TokenInfo {
    return removeEmpty({...mergePositions([start, end].map(t => t ? tokenPosition(t) : undefined)), issues})
}

function tokenInfo3(start: IToken | undefined, middle: IToken | undefined, end: IToken | undefined, issues?: TokenIssue[]): TokenInfo {
    return removeEmpty({...mergePositions([start, middle, end].map(t => t ? tokenPosition(t) : undefined)), issues})
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
