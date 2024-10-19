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
    CommentStatementAst,
    ConstraintNameAst,
    CreateExtensionStatementAst,
    CreateIndexStatementAst,
    CreateTableStatementAst,
    CreateTypeStatementAst,
    DecimalAst,
    DropStatementAst,
    ExpressionAst,
    ForeignKeyActionAst,
    FromClauseAst,
    GroupAst,
    IdentifierAst,
    IndexColumnAst,
    InsertIntoStatementAst,
    IntegerAst,
    JsonOp,
    LiteralAst,
    NullAst,
    ObjectNameAst,
    OperatorAst,
    ParameterAst,
    SelectClauseAst,
    SelectClauseExprAst,
    SelectStatementAst,
    SetStatementAst,
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

const Add = createToken({name: 'Add', pattern: /\bADD\b/i, longer_alt: Identifier})
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
const Database = createToken({name: 'Database', pattern: /\bDATABASE\b/i, longer_alt: Identifier})
const Default = createToken({name: 'Default', pattern: /\bDEFAULT\b/i, longer_alt: Identifier})
const Delete = createToken({name: 'Delete', pattern: /\bDELETE\b/i, longer_alt: Identifier})
const Desc = createToken({name: 'Desc', pattern: /\bDESC\b/i, longer_alt: Identifier})
const Distinct = createToken({name: 'Distinct', pattern: /\bDISTINCT\b/i, longer_alt: Identifier})
const Domain = createToken({name: 'Domain', pattern: /\bDOMAIN\b/i, longer_alt: Identifier})
const Drop = createToken({name: 'Drop', pattern: /\bDROP\b/i, longer_alt: Identifier})
const Enum = createToken({name: 'Enum', pattern: /\bENUM\b/i, longer_alt: Identifier})
const Exists = createToken({name: 'Exists', pattern: /\bEXISTS\b/i, longer_alt: Identifier})
const Extension = createToken({name: 'Extension', pattern: /\bEXTENSION\b/i, longer_alt: Identifier})
const False = createToken({name: 'False', pattern: /\bFALSE\b/i, longer_alt: Identifier})
const Fetch = createToken({name: 'Fetch', pattern: /\bFETCH\b/i, longer_alt: Identifier})
const First = createToken({name: 'First', pattern: /\bFIRST\b/i, longer_alt: Identifier})
const ForeignKey = createToken({name: 'ForeignKey', pattern: /\bFOREIGN\s+KEY\b/i})
const From = createToken({name: 'From', pattern: /\bFROM\b/i, longer_alt: Identifier})
const GroupBy = createToken({name: 'GroupBy', pattern: /\bGROUP\s+BY\b/i})
const Having = createToken({name: 'Having', pattern: /\bHAVING\b/i, longer_alt: Identifier})
const If = createToken({name: 'If', pattern: /\bIF\b/i, longer_alt: Identifier})
const Include = createToken({name: 'Include', pattern: /\bINCLUDE\b/i, longer_alt: Identifier})
const Index = createToken({name: 'Index', pattern: /\bINDEX\b/i, longer_alt: Identifier})
const InsertInto = createToken({name: 'InsertInto', pattern: /\bINSERT\s+INTO\b/i})
const Is = createToken({name: 'Is', pattern: /\bIS\b/i, longer_alt: Identifier})
const Join = createToken({name: 'Join', pattern: /\bJOIN\b/i, longer_alt: Identifier})
const Last = createToken({name: 'Last', pattern: /\bLAST\b/i, longer_alt: Identifier})
const Like = createToken({name: 'Like', pattern: /\bLIKE\b/i, longer_alt: Identifier})
const Limit = createToken({name: 'Limit', pattern: /\bLIMIT\b/i, longer_alt: Identifier})
const Local = createToken({name: 'Local', pattern: /\bLOCAL\b/i, longer_alt: Identifier})
const MaterializedView = createToken({name: 'MaterializedView', pattern: /\bMATERIALIZED\s+VIEW\b/i})
const NoAction = createToken({name: 'NoAction', pattern: /\bNO\s+ACTION\b/i})
const Not = createToken({name: 'Not', pattern: /\bNOT\b/i, longer_alt: Identifier})
const Null = createToken({name: 'Null', pattern: /\bNULL\b/i, longer_alt: Identifier})
const Nulls = createToken({name: 'Nulls', pattern: /\bNULLS\b/i, longer_alt: Identifier})
const Offset = createToken({name: 'Offset', pattern: /\bOFFSET\b/i, longer_alt: Identifier})
const On = createToken({name: 'On', pattern: /\bON\b/i, longer_alt: Identifier})
const Only = createToken({name: 'Only', pattern: /\bONLY\b/i, longer_alt: Identifier})
const Or = createToken({name: 'Or', pattern: /\bOR\b/i, longer_alt: Identifier})
const OrderBy = createToken({name: 'OrderBy', pattern: /\bORDER\s+BY\b/i})
const PrimaryKey = createToken({name: 'PrimaryKey', pattern: /\bPRIMARY\s+KEY\b/i})
const References = createToken({name: 'References', pattern: /\bREFERENCES\b/i, longer_alt: Identifier})
const Restrict = createToken({name: 'Restrict', pattern: /\bRESTRICT\b/i, longer_alt: Identifier})
const Returning = createToken({name: 'Returning', pattern: /\bRETURNING\b/i, longer_alt: Identifier})
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
const Using = createToken({name: 'Using', pattern: /\bUSING\b/i, longer_alt: Identifier})
const Values = createToken({name: 'Values', pattern: /\bVALUES\b/i, longer_alt: Identifier})
const Version = createToken({name: 'Version', pattern: /\bVERSION\b/i, longer_alt: Identifier})
const View = createToken({name: 'View', pattern: /\bVIEW\b/i, longer_alt: Identifier})
const Where = createToken({name: 'Where', pattern: /\bWHERE\b/i, longer_alt: Identifier})
const Window = createToken({name: 'Window', pattern: /\bWINDOW\b/i, longer_alt: Identifier})
const With = createToken({name: 'With', pattern: /\bWITH\b/i, longer_alt: Identifier})
const keywordTokens: TokenType[] = [
    Add, Alter, And, As, Asc, Cascade, Check, Collate, Column, Comment, Concurrently, Constraint, Create, Default, Database, Delete, Desc, Distinct, Domain, Drop,
    Enum, Exists, Extension, False, Fetch, First, ForeignKey, From, GroupBy, Having, If, Include, Index, InsertInto, Is, Join, Last, Like, Limit, Local,
    MaterializedView, NoAction, Not, Null, Nulls, Offset, On, Only, Or, OrderBy, PrimaryKey, References, Restrict, Returning, Schema, Select, Session, SetDefault, SetNull, Set,
    Table, To, True, Type, Union, Unique, Update, Using, Values, Version, View, Where, Window, With
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
const charTokens: TokenType[] = [
    Amp, Asterisk, BracketLeft, BracketRight, Caret, Colon, Comma, CurlyLeft, CurlyRight, Dash, Dollar, Dot, Equal, Exclamation,
    GreaterThan, Hash, LowerThan, ParenLeft, ParenRight, Percent, Pipe, Plus, QuestionMark, Semicolon, Slash
]

const allTokens: TokenType[] = [WhiteSpace, ...keywordTokens, ...charTokens, ...valueTokens]

const defaultPos: number = -1 // used when error position is undefined

class PostgresParser extends EmbeddedActionsParser {
    // top level
    statementsRule: () => StatementsAst
    // statements
    statementRule: () => StatementAst
    alterTableStatementRule: () => AlterTableStatementAst
    commentStatementRule: () => CommentStatementAst
    createExtensionStatementRule: () => CreateExtensionStatementAst
    createIndexStatementRule: () => CreateIndexStatementAst
    createTableStatementRule: () => CreateTableStatementAst
    createTypeStatementRule: () => CreateTypeStatementAst
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
            {ALT: () => $.SUBRULE($.commentStatementRule)},
            {ALT: () => $.SUBRULE($.createExtensionStatementRule)},
            {ALT: () => $.SUBRULE($.createIndexStatementRule)},
            {ALT: () => $.SUBRULE($.createTableStatementRule)},
            {ALT: () => $.SUBRULE($.createTypeStatementRule)},
            {ALT: () => $.SUBRULE($.dropStatementRule)},
            {ALT: () => $.SUBRULE($.insertIntoStatementRule)},
            {ALT: () => $.SUBRULE($.selectStatementRule)},
            {ALT: () => $.SUBRULE($.setStatementRule)},
        ]))

        this.alterTableStatementRule = $.RULE<() => AlterTableStatementAst>('alterTableStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-altertable.html
            const start = $.CONSUME(Alter)
            $.CONSUME(Table)
            const ifExists = $.SUBRULE(ifExistsRule)
            const only = $.OPTION(() => tokenInfo($.CONSUME(Only)))
            const object = $.SUBRULE($.objectNameRule)
            const action = $.OR([
                {ALT: () => removeUndefined({kind: 'AddColumn' as const, ...tokenInfo2($.CONSUME(Add), $.OPTION2(() => $.CONSUME(Column))), ifNotExists: $.SUBRULE(ifNotExistsRule), column: $.SUBRULE($.tableColumnRule)})},
                {ALT: () => removeUndefined({kind: 'AddConstraint' as const, ...tokenInfo($.CONSUME2(Add)), constraint: $.SUBRULE($.tableConstraintRule)})},
                {ALT: () => removeUndefined({kind: 'DropColumn' as const, ...tokenInfo2($.CONSUME(Drop), $.OPTION3(() => $.CONSUME2(Column))), ifExists: $.SUBRULE2(ifExistsRule), column: $.SUBRULE($.identifierRule)})},
                {ALT: () => removeUndefined({kind: 'DropConstraint' as const, ...tokenInfo2($.CONSUME2(Drop), $.CONSUME(Constraint)), ifExists: $.SUBRULE3(ifExistsRule), constraint: $.SUBRULE2($.identifierRule)})},
            ])
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'AlterTable' as const, ifExists, only, schema: object.schema, table: object.name, action, ...tokenInfo2(start, end)})
        })

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
            return removeUndefined({kind: 'Comment' as const, object, schema, parent, entity, comment, ...tokenInfo2(start, end)})
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
            $.CONSUME(Extension)
            const ifNotExists = $.SUBRULE(ifNotExistsRule)
            const name = $.SUBRULE($.identifierRule)
            const withh = $.OPTION(() => tokenInfo($.CONSUME(With)))
            const schema = $.OPTION2(() => ({...tokenInfo($.CONSUME(Schema)), name: $.SUBRULE2($.identifierRule)}))
            const version = $.OPTION3(() => ({...tokenInfo($.CONSUME(Version)), number: $.OR([{ALT: () => $.SUBRULE($.stringRule)}, {ALT: () => $.SUBRULE3($.identifierRule)}])}))
            const cascade = $.OPTION4(() => tokenInfo($.CONSUME(Cascade)))
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'CreateExtension' as const, ifNotExists, name, with: withh, schema, version, cascade, ...tokenInfo2(start, end)})
        })

        this.createIndexStatementRule = $.RULE<() => CreateIndexStatementAst>('createIndexStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-createindex.html
            const start = $.CONSUME(Create)
            const unique = $.OPTION(() => tokenInfo($.CONSUME(Unique)))
            $.CONSUME(Index)
            const concurrently = $.OPTION2(() => tokenInfo($.CONSUME(Concurrently)))
            const name = $.OPTION3(() => ({ifNotExists: $.SUBRULE(ifNotExistsRule), index: $.SUBRULE($.identifierRule)}))
            $.CONSUME(On)
            const only = $.OPTION4(() => tokenInfo($.CONSUME(Only)))
            const object = $.SUBRULE($.objectNameRule)
            const using = $.OPTION5(() => ({...tokenInfo($.CONSUME(Using)), method: $.SUBRULE2($.identifierRule)}))
            $.CONSUME(ParenLeft)
            const columns: IndexColumnAst[] = []
            $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => columns.push($.SUBRULE(indexColumnRule))})
            $.CONSUME(ParenRight)
            const include = $.OPTION6(() => {
                const token = $.CONSUME(Include)
                $.CONSUME2(ParenLeft)
                const columns: IdentifierAst[] = []
                $.AT_LEAST_ONE_SEP2({SEP: Comma, DEF: () => columns.push($.SUBRULE3($.identifierRule))})
                $.CONSUME2(ParenRight)
                return {...tokenInfo(token), columns}
            })
            // TODO: NULLS [ NOT ] DISTINCT
            // TODO: WITH (parameters)
            // TODO: TABLESPACE name
            const where = $.OPTION7(() => ({...tokenInfo($.CONSUME(Where)), predicate: $.SUBRULE($.expressionRule)}))
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'CreateIndex' as const, unique, concurrently, ...name, only, schema: object.schema, table: object.name, using, columns, include, where, ...tokenInfo2(start, end)})
        })

        this.createTableStatementRule = $.RULE<() => CreateTableStatementAst>('createTableStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-createtable.html
            const start = $.CONSUME(Create)
            $.CONSUME(Table)
            const object = $.SUBRULE($.objectNameRule)
            $.CONSUME(ParenLeft)
            const columns: TableColumnAst[] = []
            const constraints: TableConstraintAst[] = []
            $.MANY_SEP({SEP: Comma, DEF: () => $.OR([
                {ALT: () => columns.push($.SUBRULE($.tableColumnRule))},
                {ALT: () => constraints.push($.SUBRULE($.tableConstraintRule))},
            ])})
            $.CONSUME(ParenRight)
            const end = $.CONSUME(Semicolon)
            return removeEmpty({kind: 'CreateTable' as const, schema: object.schema, table: object.name, columns: columns.filter(isNotUndefined), constraints: constraints.filter(isNotUndefined), ...tokenInfo2(start, end)})
        })

        this.createTypeStatementRule = $.RULE<() => CreateTypeStatementAst>('createTypeStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-createtype.html
            const start = $.CONSUME(Create)
            $.CONSUME(Type)
            const object = $.SUBRULE($.objectNameRule)
            const content = $.OPTION(() => $.OR([
                {ALT: () => ({struct: {...tokenInfo($.CONSUME(As)), attrs: $.SUBRULE(createTypeStructAttrs)}})},
                {ALT: () => ({enum: {...tokenInfo2($.CONSUME2(As), $.CONSUME(Enum)), values: $.SUBRULE(createTypeEnumValues)}})},
                // TODO: RANGE
                {ALT: () => ({base: $.SUBRULE(createTypeBase)})}
            ]))
            const end = $.CONSUME(Semicolon)
            return removeEmpty({kind: 'CreateType' as const, schema: object.schema, type: object.name, ...content, ...tokenInfo2(start, end)})
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
            const ifExists = $.SUBRULE(ifExistsRule)
            const objects: ObjectNameAst[] = []
            $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => objects.push($.SUBRULE($.objectNameRule))})
            const mode = $.OPTION2(() => $.OR2([
                {ALT: () => ({kind: 'Cascade' as const, ...tokenInfo($.CONSUME(Cascade))})},
                {ALT: () => ({kind: 'Restrict' as const, ...tokenInfo($.CONSUME(Restrict))})},
            ]))
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'Drop' as const, object, entities: objects.filter(isNotUndefined), concurrently, ifExists, mode, ...tokenInfo2(start, end)})
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
            const values: (ExpressionAst | { kind: 'Default' } & TokenInfo)[][] = []
            $.AT_LEAST_ONE_SEP2({SEP: Comma, DEF: () => {
                const row: ExpressionAst[] = []
                $.CONSUME2(ParenLeft)
                $.AT_LEAST_ONE_SEP3({SEP: Comma, DEF: () => row.push($.OR([
                    {ALT: () => $.SUBRULE($.expressionRule)},
                    {ALT: () => ({kind: 'Default' as const, ...tokenInfo($.CONSUME(Default))})}
                ]))})
                $.CONSUME2(ParenRight)
                values.push(row)
            }})
            const returning = $.OPTION2(() => {
                const token = $.CONSUME(Returning)
                const expressions: SelectClauseExprAst[] = []
                $.AT_LEAST_ONE_SEP4({SEP: Comma, DEF: () => expressions.push($.SUBRULE(selectClauseColumnRule))})
                return {...tokenInfo(token), expressions}
            })
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'InsertInto' as const, schema: object.schema, table: object.name, columns, values, returning, ...tokenInfo2(start, end)})
        })

        this.selectStatementRule = $.RULE<() => SelectStatementAst>('selectStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-select.html
            const select = $.SUBRULE($.selectClauseRule)
            const from = $.OPTION(() => $.SUBRULE($.fromClauseRule))
            const where = $.OPTION2(() => $.SUBRULE($.whereClauseRule))
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'Select' as const, select, from, where, ...mergePositions([select, tokenInfo(end)])})
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
                        {ALT: () => toIdentifier($.CONSUME(On))}, // special case, `on` being a valid identifier here
                    ]))})
                    return values.length === 1 ? values[0] : values
                }},
            ])
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'Set' as const, scope, parameter, equal, value, ...tokenInfo2(start, end)})
        })

        // clauses

        this.selectClauseRule = $.RULE<() => SelectClauseAst>('selectClauseRule', () => {
            const token = $.CONSUME(Select)
            const expressions: SelectClauseExprAst[] = []
            $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => expressions.push($.SUBRULE(selectClauseColumnRule))})
            return {...tokenInfo(token), expressions}
        })
        const selectClauseColumnRule = $.RULE<() => SelectClauseExprAst>('selectClauseColumnRule', () => {
            const expression = $.SUBRULE($.expressionRule)
            const alias = $.OPTION(() => $.SUBRULE($.aliasRule))
            return removeUndefined({...expression, alias})
        })

        this.fromClauseRule = $.RULE<() => FromClauseAst>('fromClauseRule', () => {
            const token = $.CONSUME(From)
            const table = $.SUBRULE($.identifierRule)
            const alias = $.OPTION(() => $.SUBRULE($.aliasRule))
            return removeUndefined({...tokenInfo(token), table, alias})
        })

        this.whereClauseRule = $.RULE<() => WhereClauseAst>('whereClauseRule', () => {
            const token = $.CONSUME(Where)
            return {...tokenInfo(token), predicate: $.SUBRULE($.expressionRule)}
        })

        const indexColumnRule = $.RULE<() => IndexColumnAst>('indexColumnRule', () => {
            const expr = $.SUBRULE($.expressionRule)
            const collation = $.OPTION(() => ({...tokenInfo($.CONSUME(Collate)), name: $.SUBRULE3($.identifierRule)}))
            const order = $.OPTION2(() => $.OR([
                {ALT: () => ({kind: 'Asc' as const, ...tokenInfo($.CONSUME(Asc))})},
                {ALT: () => ({kind: 'Desc' as const, ...tokenInfo($.CONSUME(Desc))})},
            ]))
            const nulls = $.OPTION3(() => $.OR2([
                {ALT: () => ({kind: 'First' as const, ...tokenInfo2($.CONSUME(Nulls), $.CONSUME(First))})},
                {ALT: () => ({kind: 'Last' as const, ...tokenInfo2($.CONSUME2(Nulls), $.CONSUME(Last))})},
            ]))
            return removeUndefined({...expr, collation, order, nulls})
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
            const value = !not
            const token = not ? tokenInfo2(not, nullable) : tokenInfo(nullable)
            return removeUndefined({kind: 'Nullable' as const, value, constraint, ...token})
        })
        const tableColumnDefaultRule = $.RULE<() => TableColumnDefaultAst>('tableColumnDefaultRule', () => {
            const constraint = $.OPTION(() => $.SUBRULE(constraintNameRule))
            const token = $.CONSUME(Default)
            const expression = $.SUBRULE($.expressionRule)
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
            const predicate = $.SUBRULE($.expressionRule)
            $.CONSUME(ParenRight)
            return removeUndefined({kind: 'Check' as const, constraint, ...tokenInfo(token), predicate})
        })
        const tableColumnFkRule = $.RULE<() => TableColumnFkAst>('tableColumnFkRule', () => {
            const constraint = $.OPTION(() => $.SUBRULE(constraintNameRule))
            const token = $.CONSUME(References)
            const object = $.SUBRULE($.objectNameRule)
            const column = $.OPTION2(() => {
                $.CONSUME(ParenLeft)
                const column = $.SUBRULE($.identifierRule)
                $.CONSUME(ParenRight)
                return column
            })
            const onUpdate = $.OPTION3(() => ({...tokenInfo2($.CONSUME(On), $.CONSUME(Update)), ...$.SUBRULE(foreignKeyActionsRule)}))
            const onDelete = $.OPTION4(() => ({...tokenInfo2($.CONSUME2(On), $.CONSUME(Delete)), ...$.SUBRULE2(foreignKeyActionsRule)}))
            return removeUndefined({kind: 'ForeignKey' as const, schema: object.schema, table: object.name, column, onUpdate, onDelete, constraint, ...tokenInfo(token)})
        })

        this.tableConstraintRule = $.RULE<() => TableConstraintAst>('tableConstraintRule', () => $.OR([
            {ALT: () => $.SUBRULE(tablePkRule)},
            {ALT: () => $.SUBRULE(tableUniqueRule)},
            {ALT: () => $.SUBRULE(tableCheckRule)},
            {ALT: () => $.SUBRULE(tableFkRule)},
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
            const refTable = $.SUBRULE($.objectNameRule)
            const refColumns = $.OPTION2(() => $.SUBRULE2(columnNamesRule))
            const onUpdate = $.OPTION3(() => ({...tokenInfo2($.CONSUME(On), $.CONSUME(Update)), ...$.SUBRULE(foreignKeyActionsRule)}))
            const onDelete = $.OPTION4(() => ({...tokenInfo2($.CONSUME2(On), $.CONSUME(Delete)), ...$.SUBRULE2(foreignKeyActionsRule)}))
            const ref = removeUndefined({...tokenInfo(refToken), schema: refTable.schema, table: refTable.name, columns: refColumns})
            return removeUndefined({kind: 'ForeignKey' as const, ...tokenInfo(token), columns, ref, onUpdate, onDelete, constraint})
        })

        const createTypeStructAttrs = $.RULE<() => TypeColumnAst[]>('createTypeStructAttrs', () => {
            $.CONSUME(ParenLeft)
            const attrs: TypeColumnAst[] = []
            $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => attrs.push(removeUndefined({
                name: $.SUBRULE($.identifierRule),
                type: $.SUBRULE($.columnTypeRule),
                collation: $.OPTION(() => ({...tokenInfo($.CONSUME(Collate)), name: $.SUBRULE2($.identifierRule)}))
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

        const constraintNameRule = $.RULE<() => ConstraintNameAst>('constraintNameRule', () => {
            const token = $.CONSUME(Constraint)
            const name = $.SUBRULE($.identifierRule)
            return {...tokenInfo(token), name}
        })
        const foreignKeyActionsRule = $.RULE<() => ForeignKeyActionAst>('foreignKeyActionsRule', () => {
            const res = $.OR([
                {ALT: () => ({action: {kind: 'NoAction' as const, ...tokenInfo($.CONSUME(NoAction))}})},
                {ALT: () => ({action: {kind: 'Restrict' as const, ...tokenInfo($.CONSUME(Restrict))}})},
                {ALT: () => ({action: {kind: 'Cascade' as const, ...tokenInfo($.CONSUME(Cascade))}})},
                {ALT: () => ({action: {kind: 'SetNull' as const, ...tokenInfo($.CONSUME(SetNull))}})},
                {ALT: () => ({action: {kind: 'SetDefault' as const, ...tokenInfo($.CONSUME(SetDefault))}})},
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

        const ifExistsRule = $.RULE<() => TokenInfo | undefined>('ifExistsRule', () => $.OPTION(() => tokenInfo2($.CONSUME(If), $.CONSUME(Exists))))
        const ifNotExistsRule = $.RULE<() => TokenInfo | undefined>('ifNotExistsRule', () => $.OPTION(() => tokenInfo3($.CONSUME(If), $.CONSUME(Not), $.CONSUME(Exists))))

        // basic parts

        this.aliasRule = $.RULE<() => AliasAst>('aliasRule', () => {
            const token = $.CONSUME(As)
            const name = $.SUBRULE($.identifierRule)
            return {...tokenInfo(token), name}
        })

        this.expressionRule = $.RULE<() => ExpressionAst>('expressionRule', () => $.SUBRULE(orExpressionRule)) // Start with OR expressions (lowest precedence)
        const orExpressionRule = $.RULE<() => ExpressionAst>('orExpressionRule', () => {
            let expr = $.SUBRULE(andExpressionRule) // AND has higher precedence than OR
            $.MANY(() => {
                const op = {kind: 'Or' as const, ...tokenInfo($.CONSUME(Or))}
                const right = $.SUBRULE2(andExpressionRule)
                expr = {kind: 'Operation', left: expr, op, right}
            })
            return expr
        })
        const andExpressionRule = $.RULE<() => ExpressionAst>('andExpressionRule', () => {
            let expr = $.SUBRULE(operatorExpressionRule) // operator has higher precedence than AND
            $.MANY(() => {
                const op = {kind: 'And' as const, ...tokenInfo($.CONSUME(And))}
                const right = $.SUBRULE2(operatorExpressionRule)
                expr = {kind: 'Operation', left: expr, op, right}
            })
            return expr
        })
        const operatorExpressionRule = $.RULE<() => ExpressionAst>('operatorExpressionRule', () => {
            let expr = $.SUBRULE(atomicExpressionRule) // atomic has the highest precedence
            $.OPTION(() => {
                const op = $.SUBRULE(operatorRule)
                const right = $.SUBRULE2(atomicExpressionRule)
                expr = {kind: 'Operation', left: expr, op, right}
            })
            return expr
        })
        const atomicExpressionRule = $.RULE<() => ExpressionAst>('atomicExpressionRule', () => {
            const expr = $.OR([
                {ALT: () => $.SUBRULE(groupRule)},
                {ALT: () => $.SUBRULE($.literalRule)},
                {ALT: () => $.SUBRULE($.parameterRule)},
                {ALT: () => ({kind: 'Wildcard', ...tokenInfo($.CONSUME(Asterisk))})},
                {ALT: () => {
                    const first = $.SUBRULE($.identifierRule)
                    const nest = $.OPTION(() => $.OR2([
                        {ALT: () => ({kind: 'Function', function: first, parameters: $.SUBRULE(functionParamsRule)})},
                        {ALT: () => {
                            $.CONSUME(Dot)
                            return $.OR3([
                                {ALT: () => ({kind: 'Wildcard', table: first, ...tokenInfo($.CONSUME2(Asterisk))})},
                                {ALT: () => {
                                    const second = $.SUBRULE2($.identifierRule)
                                    const nest2 = $.OPTION2(() => $.OR4([
                                        {ALT: () => ({kind: 'Function', schema: first, function: second, parameters: $.SUBRULE2(functionParamsRule)})},
                                        {ALT: () => {
                                            $.CONSUME2(Dot)
                                            return $.OR5([
                                                {ALT: () => ({kind: 'Wildcard', schema: first, table: second, ...tokenInfo($.CONSUME3(Asterisk))})},
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
            const cast = $.OPTION3(() => {
                const token = tokenInfo2($.CONSUME(Colon), $.CONSUME2(Colon))
                const type = $.SUBRULE($.columnTypeRule)
                return {...token, type}
            })
            return removeUndefined({...expr, cast})
        })
        const groupRule = $.RULE<() => GroupAst>('groupRule', () => {
            $.CONSUME(ParenLeft)
            const expression = $.SUBRULE($.expressionRule)
            $.CONSUME(ParenRight)
            return {kind: 'Group', expression}
        })
        const operatorRule = $.RULE<() => OperatorAst>('operatorRule', () => $.OR([
            // https://www.postgresql.org/docs/current/functions.html
            {ALT: () => ({kind: '+' as const, ...tokenInfo($.CONSUME(Plus))})},
            {ALT: () => ({kind: '-' as const, ...tokenInfo($.CONSUME(Dash))})},
            {ALT: () => ({kind: '*' as const, ...tokenInfo($.CONSUME(Asterisk))})},
            {ALT: () => ({kind: '/' as const, ...tokenInfo($.CONSUME(Slash))})},
            {ALT: () => ({kind: '%' as const, ...tokenInfo($.CONSUME(Percent))})},
            {ALT: () => ({kind: '^' as const, ...tokenInfo($.CONSUME(Caret))})},
            {ALT: () => ({kind: '&' as const, ...tokenInfo($.CONSUME(Amp))})},
            {ALT: () => ({kind: '|' as const, ...tokenInfo($.CONSUME(Pipe))})},
            {ALT: () => ({kind: '#' as const, ...tokenInfo($.CONSUME(Hash))})},
            {ALT: () => ({kind: '=' as const, ...tokenInfo($.CONSUME(Equal))})},
            {ALT: () => ({kind: '!=' as const, ...tokenInfo2($.CONSUME(Exclamation), $.CONSUME2(Equal))})},
            {ALT: () => ({kind: 'Like' as const, ...tokenInfo($.CONSUME(Like))})},
            // {ALT: () => ({kind: 'NotLike' as const, ...tokenInfo2($.CONSUME(Not), $.CONSUME2(Like))})},
            {ALT: () => {
                const lt = $.CONSUME(LowerThan)
                const res = $.OPTION(() => $.OR2([
                    {ALT: () => ({kind: '<=' as const, ...tokenInfo2(lt, $.CONSUME3(Equal))})},
                    {ALT: () => ({kind: '<<' as const, ...tokenInfo2(lt, $.CONSUME2(LowerThan))})},
                    {ALT: () => ({kind: '<>' as const, ...tokenInfo2(lt, $.CONSUME(GreaterThan))})},
                ]))
                return res ? res : {kind: '<' as const, ...tokenInfo(lt)}
            }},
            {ALT: () => {
                const gt = $.CONSUME2(GreaterThan)
                const res = $.OPTION2(() => $.OR3([
                    {ALT: () => ({kind: '>=' as const, ...tokenInfo2(gt, $.CONSUME4(Equal))})},
                    {ALT: () => ({kind: '>>' as const, ...tokenInfo2(gt, $.CONSUME3(GreaterThan))})},
                ]))
                return res ? res : {kind: '>' as const, ...tokenInfo(gt)}
            }},
        ]))
        const columnJsonRule = $.RULE<() => ColumnJsonAst[]>('columnJsonRule', () => {
            const res: ColumnJsonAst[] = []
            $.MANY({DEF: () => {
                const nest = $.SUBRULE(jsonOpRule)
                const field = $.SUBRULE($.stringRule)
                res.push({...nest, field})
            }})
            return res
        })
        const jsonOpRule = $.RULE<() => {kind: JsonOp} & TokenInfo>('jsonOpRule', () => {
            const dash = $.CONSUME(Dash)
            const gt = $.CONSUME(GreaterThan)
            const gt2 = $.OPTION(() => $.CONSUME2(GreaterThan))
            return gt2 ? {kind: '->>' as const, ...tokenInfo3(dash, gt, gt2)} : {kind: '->' as const, ...tokenInfo2(dash, gt)}
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
                value: parts.filter(isNotUndefined).map(p => p.name?.value + (p.args ? `(${p.args.map(v => v.value).join(', ')})` : '')).join(' ') + (array ? '[]' : ''),
                ...mergePositions(parts.flatMap(p => [p.name, p.last]).concat([array]))
            }
            return removeEmpty({schema, name, args: parts.flatMap(p => p.args || []), array, ...mergePositions([schema, name])})
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
            {ALT: () => ({kind: 'Parameter', value: '?', ...tokenInfo($.CONSUME(QuestionMark))})},
            {ALT: () => {
                const d = $.CONSUME(Dollar)
                const i = $.CONSUME(Integer)
                return {kind: 'Parameter', value: `${d.image}${i.image}`, index: parseInt(i.image), ...tokenInfo2(d, i)}
            }}
        ]))

        this.identifierRule = $.RULE<() => IdentifierAst>('identifierRule', () => $.OR([
            {ALT: () => {
                const token = $.CONSUME(Identifier)
                if (token.image.startsWith('"') && token.image.endsWith('"')) {
                    return {kind: 'Identifier', value: token.image.slice(1, -1).replaceAll(/\\"/g, '"'), quoted: true, ...tokenInfo(token)}
                } else {
                    return {kind: 'Identifier', value: token.image, ...tokenInfo(token)}
                }
            }},
            {ALT: () => toIdentifier($.CONSUME(Version))}, // allowed as identifier
        ]))

        this.stringRule = $.RULE<() => StringAst>('stringRule', () => {
            const token = $.CONSUME(String)
            return {kind: 'String', value: token.image.slice(1, -1).replaceAll(/''/g, "'"), ...tokenInfo(token)}
        })

        this.integerRule = $.RULE<() => IntegerAst>('integerRule', () => {
            const neg = $.OPTION(() => $.CONSUME(Dash))
            const token = $.CONSUME(Integer)
            return neg ? {kind: 'Integer', value: parseInt(neg.image + token.image), ...tokenInfo2(neg, token)} :
                {kind: 'Integer', value: parseInt(token.image), ...tokenInfo(token)}
        })

        this.decimalRule = $.RULE<() => DecimalAst>('decimalRule', () => {
            const neg = $.OPTION(() => $.CONSUME(Dash))
            const token = $.CONSUME(Decimal)
            return neg ? {kind: 'Decimal', value: parseFloat(neg.image + token.image), ...tokenInfo2(neg, token)} :
                {kind: 'Decimal', value: parseFloat(token.image), ...tokenInfo(token)}
        })

        this.booleanRule = $.RULE<() => BooleanAst>('booleanRule', () => $.OR([
            {ALT: () => ({kind: 'Boolean', value: true, ...tokenInfo($.CONSUME(True))})},
            {ALT: () => ({kind: 'Boolean', value: false, ...tokenInfo($.CONSUME(False))})},
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

function toIdentifier(token: IToken): IdentifierAst {
    return {kind: 'Identifier', value: token.image, ...tokenInfo(token)}
}

function tokenInfo(token: IToken, issues?: TokenIssue[]): TokenInfo {
    return removeEmpty({...tokenPosition(token), issues})
}

function tokenInfo2(start: IToken, end: IToken | undefined, issues?: TokenIssue[]): TokenInfo {
    return removeEmpty({...mergePositions([tokenPosition(start), end ? tokenPosition(end) : undefined]), issues})
}

function tokenInfo3(start: IToken, middle: IToken | undefined, end: IToken | undefined, issues?: TokenIssue[]): TokenInfo {
    return removeEmpty({...mergePositions([tokenPosition(start), middle ? tokenPosition(middle) : undefined, end ? tokenPosition(end) : undefined]), issues})
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
