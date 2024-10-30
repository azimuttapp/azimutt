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
    AlterSchemaStatementAst,
    AlterSequenceStatementAst,
    AlterTableActionAst,
    AlterTableStatementAst,
    BeginStatementAst,
    BooleanAst,
    ColumnJsonAst,
    ColumnTypeAst,
    CommentAst,
    CommentOnStatementAst,
    CommitStatementAst,
    ConstraintNameAst,
    CreateExtensionStatementAst,
    CreateFunctionStatementAst,
    CreateIndexStatementAst,
    CreateMaterializedViewStatementAst,
    CreateSchemaStatementAst,
    CreateSequenceStatementAst,
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
    FunctionArgumentAst,
    FunctionReturnsAst,
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
    OnConflictClauseAst,
    OperatorAst,
    OperatorLeftAst,
    OperatorRightAst,
    OrderByClauseAst,
    ParameterAst,
    PostgresAst,
    PostgresStatementAst,
    SchemaRoleAst,
    SelectClauseAst,
    SelectClauseColumnAst,
    SelectStatementAst,
    SelectStatementInnerAst,
    SelectStatementMainAst,
    SelectStatementResultAst,
    SequenceOwnedByAst,
    SequenceParamAst,
    SequenceParamOptAst,
    SequenceTypeAst,
    SetStatementAst,
    ShowStatementAst,
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
    TransactionModeAst,
    TypeColumnAst,
    UnionClauseAst,
    UpdateColumnAst,
    UpdateStatementAst,
    WhereClauseAst,
    WindowClauseAst,
    WindowClauseContentAst
} from "./postgresAst";

const LineComment = createToken({name: 'LineComment', pattern: /--.*/, group: 'comments'})
const BlockComment = createToken({name: 'BlockComment', pattern: /\/\*[^]*?\*\//, line_breaks: true, group: 'comments'})
const WhiteSpace = createToken({name: 'WhiteSpace', pattern: /\s+/, group: Lexer.SKIPPED})

const Identifier = createToken({name: 'Identifier', pattern: /\b[a-zA-Z_]\w*\b|"([^\\"]|\\\\|\\")+"/})
const String = createToken({name: 'String', pattern: /E?'([^']|'')*'/i})
const StringDollar = createToken({name: 'StringDollar', pattern: /\$(\w*)\$[\s\S]*?\$\1\$/i})
const Decimal = createToken({name: 'Decimal', pattern: /\d+\.\d+/})
const Integer = createToken({name: 'Integer', pattern: /0|[1-9]\d*/, longer_alt: Decimal})
const valueTokens: TokenType[] = [Integer, Decimal, String, StringDollar, Identifier, LineComment, BlockComment]

const Add = createToken({name: 'Add', pattern: /\bADD\b/i, longer_alt: Identifier})
const All = createToken({name: 'All', pattern: /\bALL\b/i, longer_alt: Identifier})
const Alter = createToken({name: 'Alter', pattern: /\bALTER\b/i, longer_alt: Identifier})
const And = createToken({name: 'And', pattern: /\bAND\b/i, longer_alt: Identifier})
const As = createToken({name: 'As', pattern: /\bAS\b/i, longer_alt: Identifier})
const Asc = createToken({name: 'Asc', pattern: /\bASC\b/i, longer_alt: Identifier})
const Authorization = createToken({name: 'Authorization', pattern: /\bAUTHORIZATION\b/i, longer_alt: Identifier})
const Begin = createToken({name: 'Begin', pattern: /\bBEGIN\b/i, longer_alt: Identifier})
const By = createToken({name: 'By', pattern: /\bBY\b/i, longer_alt: Identifier})
const Cache = createToken({name: 'Cache', pattern: /\bCACHE\b/i, longer_alt: Identifier})
const Called = createToken({name: 'Called', pattern: /\bCALLED\b/i, longer_alt: Identifier})
const Cascade = createToken({name: 'Cascade', pattern: /\bCASCADE\b/i, longer_alt: Identifier})
const Chain = createToken({name: 'Chain', pattern: /\bCHAIN\b/i, longer_alt: Identifier})
const Check = createToken({name: 'Check', pattern: /\bCHECK\b/i, longer_alt: Identifier})
const Collate = createToken({name: 'Collate', pattern: /\bCOLLATE\b/i, longer_alt: Identifier})
const Column = createToken({name: 'Column', pattern: /\bCOLUMN\b/i, longer_alt: Identifier})
const Comment = createToken({name: 'Comment', pattern: /\bCOMMENT\b/i, longer_alt: Identifier})
const Commit = createToken({name: 'Commit', pattern: /\bCOMMIT\b/i, longer_alt: Identifier})
const Concurrently = createToken({name: 'Concurrently', pattern: /\bCONCURRENTLY\b/i, longer_alt: Identifier})
const Conflict = createToken({name: 'Conflict', pattern: /\bCONFLICT\b/i, longer_alt: Identifier})
const Constraint = createToken({name: 'Constraint', pattern: /\bCONSTRAINT\b/i, longer_alt: Identifier})
const Create = createToken({name: 'Create', pattern: /\bCREATE\b/i, longer_alt: Identifier})
const Cross = createToken({name: 'Cross', pattern: /\bCROSS\b/i, longer_alt: Identifier})
const CurrentRole = createToken({name: 'CurrentRole', pattern: /\bCURRENT_ROLE\b/i, longer_alt: Identifier})
const CurrentUser = createToken({name: 'CurrentUser', pattern: /\bCURRENT_USER\b/i, longer_alt: Identifier})
const Cycle = createToken({name: 'Cycle', pattern: /\bCYCLE\b/i, longer_alt: Identifier})
const Data = createToken({name: 'Data', pattern: /\bDATA\b/i, longer_alt: Identifier})
const Database = createToken({name: 'Database', pattern: /\bDATABASE\b/i, longer_alt: Identifier})
const Default = createToken({name: 'Default', pattern: /\bDEFAULT\b/i, longer_alt: Identifier})
const Deferrable = createToken({name: 'Deferrable', pattern: /\bDEFERRABLE\b/i, longer_alt: Identifier})
const Delete = createToken({name: 'Delete', pattern: /\bDELETE\b/i, longer_alt: Identifier})
const Desc = createToken({name: 'Desc', pattern: /\bDESC\b/i, longer_alt: Identifier})
const Distinct = createToken({name: 'Distinct', pattern: /\bDISTINCT\b/i, longer_alt: Identifier})
const Do = createToken({name: 'Do', pattern: /\bDO\b/i, longer_alt: Identifier})
const Domain = createToken({name: 'Domain', pattern: /\bDOMAIN\b/i, longer_alt: Identifier})
const Drop = createToken({name: 'Drop', pattern: /\bDROP\b/i, longer_alt: Identifier})
const Enum = createToken({name: 'Enum', pattern: /\bENUM\b/i, longer_alt: Identifier})
const Except = createToken({name: 'Except', pattern: /\bEXCEPT\b/i, longer_alt: Identifier})
const Exists = createToken({name: 'Exists', pattern: /\bEXISTS\b/i, longer_alt: Identifier})
const Extension = createToken({name: 'Extension', pattern: /\bEXTENSION\b/i, longer_alt: Identifier})
const False = createToken({name: 'False', pattern: /\bFALSE\b/i, longer_alt: Identifier})
const Fetch = createToken({name: 'Fetch', pattern: /\bFETCH\b/i, longer_alt: Identifier})
const Filter = createToken({name: 'Filter', pattern: /\bFILTER\b/i, longer_alt: Identifier})
const First = createToken({name: 'First', pattern: /\bFIRST\b/i, longer_alt: Identifier})
const ForeignKey = createToken({name: 'ForeignKey', pattern: /\bFOREIGN\s+KEY\b/i})
const From = createToken({name: 'From', pattern: /\bFROM\b/i, longer_alt: Identifier})
const Full = createToken({name: 'Full', pattern: /\bFULL\b/i, longer_alt: Identifier})
const Function = createToken({name: 'Function', pattern: /\bFUNCTION\b/i, longer_alt: Identifier})
const Global = createToken({name: 'Global', pattern: /\bGLOBAL\b/i, longer_alt: Identifier})
const GroupBy = createToken({name: 'GroupBy', pattern: /\bGROUP\s+BY\b/i})
const Having = createToken({name: 'Having', pattern: /\bHAVING\b/i, longer_alt: Identifier})
const If = createToken({name: 'If', pattern: /\bIF\b/i, longer_alt: Identifier})
const Immutable = createToken({name: 'Immutable', pattern: /\bIMMUTABLE\b/i, longer_alt: Identifier})
const In = createToken({name: 'In', pattern: /\bIN\b/i, longer_alt: Identifier})
const Include = createToken({name: 'Include', pattern: /\bINCLUDE\b/i, longer_alt: Identifier})
const Increment = createToken({name: 'Increment', pattern: /\bINCREMENT\b/i, longer_alt: Identifier})
const Index = createToken({name: 'Index', pattern: /\bINDEX\b/i, longer_alt: Identifier})
const Inner = createToken({name: 'Inner', pattern: /\bINNER\b/i, longer_alt: Identifier})
const InOut = createToken({name: 'InOut', pattern: /\bINOUT\b/i, longer_alt: Identifier})
const Input = createToken({name: 'Input', pattern: /\bINPUT\b/i, longer_alt: Identifier})
const InsertInto = createToken({name: 'InsertInto', pattern: /\bINSERT\s+INTO\b/i})
const Intersect = createToken({name: 'Intersect', pattern: /\bINTERSECT\b/i, longer_alt: Identifier})
const Interval = createToken({name: 'Interval', pattern: /\bINTERVAL\b/i, longer_alt: Identifier})
const Is = createToken({name: 'Is', pattern: /\bIS\b/i, longer_alt: Identifier})
const IsNull = createToken({name: 'IsNull', pattern: /\bISNULL\b/i, longer_alt: Identifier})
const IsolationLevel = createToken({name: 'IsolationLevel', pattern: /\bISOLATION\s+LEVEL\b/i})
const Join = createToken({name: 'Join', pattern: /\bJOIN\b/i, longer_alt: Identifier})
const Language = createToken({name: 'Language', pattern: /\bLANGUAGE\b/i, longer_alt: Identifier})
const Last = createToken({name: 'Last', pattern: /\bLAST\b/i, longer_alt: Identifier})
const Left = createToken({name: 'Left', pattern: /\bLEFT\b/i, longer_alt: Identifier})
const Like = createToken({name: 'Like', pattern: /\bLIKE\b/i, longer_alt: Identifier})
const Limit = createToken({name: 'Limit', pattern: /\bLIMIT\b/i, longer_alt: Identifier})
const Local = createToken({name: 'Local', pattern: /\bLOCAL\b/i, longer_alt: Identifier})
const MaterializedView = createToken({name: 'MaterializedView', pattern: /\bMATERIALIZED\s+VIEW\b/i})
const Maxvalue = createToken({name: 'Maxvalue', pattern: /\bMAXVALUE\b/i, longer_alt: Identifier})
const Minvalue = createToken({name: 'Minvalue', pattern: /\bMINVALUE\b/i, longer_alt: Identifier})
const Natural = createToken({name: 'Natural', pattern: /\bNATURAL\b/i, longer_alt: Identifier})
const Next = createToken({name: 'Next', pattern: /\bNEXT\b/i, longer_alt: Identifier})
const No = createToken({name: 'No', pattern: /\bNO\b/i, longer_alt: Identifier})
const NoAction = createToken({name: 'NoAction', pattern: /\bNO\s+ACTION\b/i})
const None = createToken({name: 'None', pattern: /\bNONE\b/i, longer_alt: Identifier})
const Not = createToken({name: 'Not', pattern: /\bNOT\b/i, longer_alt: Identifier})
const Nothing = createToken({name: 'Nothing', pattern: /\bNOTHING\b/i, longer_alt: Identifier})
const NotNull = createToken({name: 'NotNull', pattern: /\bNOTNULL\b/i, longer_alt: Identifier})
const Null = createToken({name: 'Null', pattern: /\bNULL\b/i, longer_alt: Identifier})
const Nulls = createToken({name: 'Nulls', pattern: /\bNULLS\b/i, longer_alt: Identifier})
const Offset = createToken({name: 'Offset', pattern: /\bOFFSET\b/i, longer_alt: Identifier})
const On = createToken({name: 'On', pattern: /\bON\b/i, longer_alt: Identifier})
const Only = createToken({name: 'Only', pattern: /\bONLY\b/i, longer_alt: Identifier})
const Or = createToken({name: 'Or', pattern: /\bOR\b/i, longer_alt: Identifier})
const OrderBy = createToken({name: 'OrderBy', pattern: /\bORDER\s+BY\b/i})
const Out = createToken({name: 'Out', pattern: /\bOUT\b/i, longer_alt: Identifier})
const Outer = createToken({name: 'Outer', pattern: /\bOUTER\b/i, longer_alt: Identifier})
const Over = createToken({name: 'Over', pattern: /\bOVER\b/i, longer_alt: Identifier})
const OwnedBy = createToken({name: 'OwnedBy', pattern: /\bOWNED\s+BY\b/i})
const OwnerTo = createToken({name: 'OwnerTo', pattern: /\bOWNER\s+TO\b/i})
const PartitionBy = createToken({name: 'PartitionBy', pattern: /\bPARTITION\s+BY\b/i})
const PrimaryKey = createToken({name: 'PrimaryKey', pattern: /\bPRIMARY\s+KEY\b/i})
const ReadCommitted = createToken({name: 'ReadCommitted', pattern: /\bREAD\s+COMMITTED\b/i})
const ReadOnly = createToken({name: 'ReadOnly', pattern: /\bREAD\s+ONLY\b/i})
const ReadUncommitted = createToken({name: 'ReadUncommitted', pattern: /\bREAD\s+UNCOMMITTED\b/i})
const ReadWrite = createToken({name: 'ReadWrite', pattern: /\bREAD\s+WRITE\b/i})
const Recursive = createToken({name: 'Recursive', pattern: /\bRECURSIVE\b/i, longer_alt: Identifier})
const References = createToken({name: 'References', pattern: /\bREFERENCES\b/i, longer_alt: Identifier})
const RenameTo = createToken({name: 'RenameTo', pattern: /\bRENAME\s+TO\b/i})
const RepeatableRead = createToken({name: 'RepeatableRead', pattern: /\bREPEATABLE\s+READ\b/i})
const Replace = createToken({name: 'Replace', pattern: /\bREPLACE\b/i, longer_alt: Identifier})
const Restrict = createToken({name: 'Restrict', pattern: /\bRESTRICT\b/i, longer_alt: Identifier})
const Return = createToken({name: 'Return', pattern: /\bRETURN\b/i, longer_alt: Identifier})
const Returning = createToken({name: 'Returning', pattern: /\bRETURNING\b/i, longer_alt: Identifier})
const Returns = createToken({name: 'Returns', pattern: /\bRETURNS\b/i, longer_alt: Identifier})
const Right = createToken({name: 'Right', pattern: /\bRIGHT\b/i, longer_alt: Identifier})
const Row = createToken({name: 'Row', pattern: /\bROW\b/i, longer_alt: Identifier})
const Rows = createToken({name: 'Rows', pattern: /\bROWS\b/i, longer_alt: Identifier})
const Schema = createToken({name: 'Schema', pattern: /\bSCHEMA\b/i, longer_alt: Identifier})
const Select = createToken({name: 'Select', pattern: /\bSELECT\b/i, longer_alt: Identifier})
const Sequence = createToken({name: 'Sequence', pattern: /\bSEQUENCE\b/i, longer_alt: Identifier})
const Serializable = createToken({name: 'Serializable', pattern: /\bSERIALIZABLE\b/i, longer_alt: Identifier})
const Session = createToken({name: 'Session', pattern: /\bSESSION\b/i, longer_alt: Identifier})
const SessionUser = createToken({name: 'SessionUser', pattern: /\bSESSION_USER\b/i, longer_alt: Identifier})
const Set = createToken({name: 'Set', pattern: /\bSET\b/i, longer_alt: Identifier})
const SetOf = createToken({name: 'SetOf', pattern: /\bSETOF\b/i, longer_alt: Identifier})
const Show = createToken({name: 'Show', pattern: /\bSHOW\b/i, longer_alt: Identifier})
const Stable = createToken({name: 'Stable', pattern: /\bSTABLE\b/i, longer_alt: Identifier})
const Start = createToken({name: 'Start', pattern: /\bSTART\b/i, longer_alt: Identifier})
const Strict = createToken({name: 'Strict', pattern: /\bSTRICT\b/i, longer_alt: Identifier})
const Table = createToken({name: 'Table', pattern: /\bTABLE\b/i, longer_alt: Identifier})
const Temp = createToken({name: 'Temp', pattern: /\bTEMP\b/i, longer_alt: Identifier})
const Temporary = createToken({name: 'Temporary', pattern: /\bTEMPORARY\b/i, longer_alt: Identifier})
const Ties = createToken({name: 'Ties', pattern: /\bTIES\b/i, longer_alt: Identifier})
const To = createToken({name: 'To', pattern: /\bTO\b/i, longer_alt: Identifier})
const Transaction = createToken({name: 'Transaction', pattern: /\bTRANSACTION\b/i, longer_alt: Identifier})
const True = createToken({name: 'True', pattern: /\bTRUE\b/i, longer_alt: Identifier})
const Type = createToken({name: 'Type', pattern: /\bTYPE\b/i, longer_alt: Identifier})
const Union = createToken({name: 'Union', pattern: /\bUNION\b/i, longer_alt: Identifier})
const Unique = createToken({name: 'Unique', pattern: /\bUNIQUE\b/i, longer_alt: Identifier})
const Unlogged = createToken({name: 'Unlogged', pattern: /\bUNLOGGED\b/i, longer_alt: Identifier})
const Update = createToken({name: 'Update', pattern: /\bUPDATE\b/i, longer_alt: Identifier})
const Using = createToken({name: 'Using', pattern: /\bUSING\b/i, longer_alt: Identifier})
const Valid = createToken({name: 'Valid', pattern: /\bVALID\b/i, longer_alt: Identifier})
const Values = createToken({name: 'Values', pattern: /\bVALUES\b/i, longer_alt: Identifier})
const Variadic = createToken({name: 'Variadic', pattern: /\bVARIADIC\b/i, longer_alt: Identifier})
const Version = createToken({name: 'Version', pattern: /\bVERSION\b/i, longer_alt: Identifier})
const View = createToken({name: 'View', pattern: /\bVIEW\b/i, longer_alt: Identifier})
const Volatile = createToken({name: 'Volatile', pattern: /\bVOLATILE\b/i, longer_alt: Identifier})
const Where = createToken({name: 'Where', pattern: /\bWHERE\b/i, longer_alt: Identifier})
const Window = createToken({name: 'Window', pattern: /\bWINDOW\b/i, longer_alt: Identifier})
const With = createToken({name: 'With', pattern: /\bWITH\b/i, longer_alt: Identifier})
const Work = createToken({name: 'Work', pattern: /\bWORK\b/i, longer_alt: Identifier})
const keywordTokens: TokenType[] = [
    Add, All, Alter, And, As, Asc, Authorization, Begin, By, Cache, Called, Cascade, Chain, Check, Collate, Column,
    Comment, Commit, Concurrently, Conflict, Constraint, Create, Cross, CurrentRole, CurrentUser, Cycle, Data, Database,
    Default, Deferrable, Delete, Desc, Distinct, Do, Domain, Drop, Enum, Except, Exists, Extension, False, Fetch,
    Filter, First, ForeignKey, From, Full, Function, Global, GroupBy, Having, If, Immutable, In, Include, Increment,
    Index, Inner, InOut, Input, InsertInto, Intersect, Interval, Is, IsNull, IsolationLevel, Join, Language, Last, Left,
    Like, Limit, Local, MaterializedView, Maxvalue, Minvalue, Natural, Next, No, None, NoAction, Not, Nothing, NotNull,
    Null, Nulls, Offset, On, Only, Or, OrderBy, Out, Outer, Over, OwnedBy, OwnerTo, PartitionBy, PrimaryKey,
    ReadCommitted, ReadOnly, ReadUncommitted, ReadWrite, Recursive, References, RenameTo, RepeatableRead, Replace,
    Restrict, Return, Returning, Returns, Right, Row, Rows, Schema, Select, Sequence, Serializable, Session,
    SessionUser, Set, SetOf, Show, Table, Stable, Start, Strict, Temp, Temporary, Ties, To, Transaction, True, Type,
    Union, Unique, Unlogged, Update, Using, Valid, Values, Version, View, Volatile, Where, Window, With, Work
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
const Dollar = createToken({name: 'Dollar', pattern: /\$/, longer_alt: StringDollar})
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
    alterSchemaStatementRule: () => AlterSchemaStatementAst
    alterSequenceStatementRule: () => AlterSequenceStatementAst
    alterTableStatementRule: () => AlterTableStatementAst
    beginStatementRule: () => BeginStatementAst
    commentOnStatementRule: () => CommentOnStatementAst
    commitStatementRule: () => CommitStatementAst
    createExtensionStatementRule: () => CreateExtensionStatementAst
    createFunctionStatementRule: () => CreateFunctionStatementAst
    createIndexStatementRule: () => CreateIndexStatementAst
    createMaterializedViewStatementRule: () => CreateMaterializedViewStatementAst
    createSchemaStatementRule: () => CreateSchemaStatementAst
    createSequenceStatementRule: () => CreateSequenceStatementAst
    createTableStatementRule: () => CreateTableStatementAst
    createTypeStatementRule: () => CreateTypeStatementAst
    createViewStatementRule: () => CreateViewStatementAst
    deleteStatementRule: () => DeleteStatementAst
    dropStatementRule: () => DropStatementAst
    insertIntoStatementRule: () => InsertIntoStatementAst
    selectStatementRule: () => SelectStatementAst
    setStatementRule: () => SetStatementAst
    showStatementRule: () => ShowStatementAst
    updateStatementRule: () => UpdateStatementAst
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
            {ALT: () => $.SUBRULE($.alterSchemaStatementRule)},
            {ALT: () => $.SUBRULE($.alterSequenceStatementRule)},
            {ALT: () => $.SUBRULE($.alterTableStatementRule)},
            {ALT: () => $.SUBRULE($.beginStatementRule)},
            {ALT: () => $.SUBRULE($.commentOnStatementRule)},
            {ALT: () => $.SUBRULE($.commitStatementRule)},
            {ALT: () => $.SUBRULE($.createExtensionStatementRule)},
            {ALT: () => $.SUBRULE($.createFunctionStatementRule)},
            {ALT: () => $.SUBRULE($.createIndexStatementRule)},
            {ALT: () => $.SUBRULE($.createMaterializedViewStatementRule)},
            {ALT: () => $.SUBRULE($.createSchemaStatementRule)},
            {ALT: () => $.SUBRULE($.createSequenceStatementRule)},
            {ALT: () => $.SUBRULE($.createTableStatementRule)},
            {ALT: () => $.SUBRULE($.createTypeStatementRule)},
            {ALT: () => $.SUBRULE($.createViewStatementRule)},
            {ALT: () => $.SUBRULE($.deleteStatementRule)},
            {ALT: () => $.SUBRULE($.dropStatementRule)},
            {ALT: () => $.SUBRULE($.insertIntoStatementRule)},
            {ALT: () => $.SUBRULE($.selectStatementRule)},
            {ALT: () => $.SUBRULE($.setStatementRule)},
            {ALT: () => $.SUBRULE($.showStatementRule)},
            {ALT: () => $.SUBRULE($.updateStatementRule)},
        ]))

        this.alterSchemaStatementRule = $.RULE<() => AlterSchemaStatementAst>('alterSchemaStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-alterschema.html
            const start = $.CONSUME(Alter)
            const token = tokenInfo2(start, $.CONSUME(Schema))
            const schema = $.SUBRULE($.identifierRule)
            const action = $.OR([
                {ALT: () => ({kind: 'Rename' as const, token: tokenInfo($.CONSUME(RenameTo)), schema: $.SUBRULE2($.identifierRule)})},
                {ALT: () => ({kind: 'Owner' as const, token: tokenInfo($.CONSUME(OwnerTo)), role: $.SUBRULE(schemaRoleRule)})},
            ])
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'AlterSchema' as const, meta: tokenInfo2(start, end), token, schema, action})
        })

        this.alterSequenceStatementRule = $.RULE<() => AlterSequenceStatementAst>('alterSequenceStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-altersequence.html
            const begin = $.CONSUME(Alter)
            const token = tokenInfo2(begin, $.CONSUME(Sequence))
            const ifExists = $.SUBRULE(ifExistsRule)
            const object = $.SUBRULE($.objectNameRule)
            const as = $.OPTION3(() => $.SUBRULE(sequenceTypeRule))
            const start = $.OPTION4(() => $.SUBRULE(sequenceStartRule))
            const increment = $.OPTION5(() => $.SUBRULE(sequenceIncrementRule))
            const minValue = $.OPTION6(() => $.SUBRULE(sequenceMinValueRule))
            const maxValue = $.OPTION7(() => $.SUBRULE(sequenceMaxValueRule))
            const cache = $.OPTION8(() => $.SUBRULE(sequenceCacheRule))
            // TODO: CYCLE
            const ownedBy = $.OPTION9(() => $.SUBRULE(sequenceOwnedByRule))
            // TODO: RESTART
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'AlterSequence' as const, meta: tokenInfo2(begin, end), token, ifExists, ...object, as, start, increment, minValue, maxValue, cache, ownedBy})
        })

        this.alterTableStatementRule = $.RULE<() => AlterTableStatementAst>('alterTableStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-altertable.html
            const start = $.CONSUME(Alter)
            const token = tokenInfo2(start, $.CONSUME(Table))
            const ifExists = $.SUBRULE(ifExistsRule)
            const only = $.OPTION(() => tokenInfo($.CONSUME(Only)))
            const object = $.SUBRULE($.objectNameRule)
            const actions: AlterTableActionAst[] = []
            $.MANY_SEP({SEP: Comma, DEF: () => actions.push($.OR([
                {ALT: () => removeUndefined({kind: 'AddColumn' as const, token: tokenInfo2($.CONSUME(Add), $.OPTION2(() => $.CONSUME(Column))), ifNotExists: $.SUBRULE(ifNotExistsRule), column: $.SUBRULE($.tableColumnRule)})},
                {ALT: () => removeUndefined({kind: 'DropColumn' as const, token: tokenInfo2($.CONSUME(Drop), $.OPTION3(() => $.CONSUME2(Column))), ifExists: $.SUBRULE2(ifExistsRule), column: $.SUBRULE($.identifierRule)})},
                {ALT: () => removeUndefined({kind: 'AlterColumn' as const, token: tokenInfo2($.CONSUME2(Alter), $.OPTION4(() => $.CONSUME3(Column))), column: $.SUBRULE2($.identifierRule), action: $.OR2([
                    {ALT: () => removeUndefined({kind: 'Default' as const, action: $.SUBRULE(constraintActionRule), token: tokenInfo($.CONSUME(Default)), expression: $.OPTION5(() => $.SUBRULE($.expressionRule))})},
                    {ALT: () => ({kind: 'NotNull' as const, action: $.SUBRULE2(constraintActionRule), token: tokenInfo2($.CONSUME(Not), $.CONSUME(Null))})},
                ])})},
                {ALT: () => removeUndefined({kind: 'AddConstraint' as const, token: tokenInfo($.CONSUME2(Add)), constraint: $.SUBRULE($.tableConstraintRule), notValid: $.OPTION6(() => tokenInfo2($.CONSUME2(Not), $.CONSUME(Valid)))})},
                {ALT: () => removeUndefined({kind: 'DropConstraint' as const, token: tokenInfo2($.CONSUME2(Drop), $.CONSUME(Constraint)), ifExists: $.SUBRULE3(ifExistsRule), constraint: $.SUBRULE3($.identifierRule)})},
            ]))})
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'AlterTable' as const, meta: tokenInfo2(start, end), token, ifExists, only, schema: object.schema, table: object.name, actions})
        })
        const constraintActionRule =$.RULE<() => { kind: 'Set' | 'Drop', token: TokenInfo }>('constraintActionRule', () => $.OR([
            {ALT: () => ({kind: 'Set' as const, token: tokenInfo($.CONSUME(Set))})},
            {ALT: () => ({kind: 'Drop' as const, token: tokenInfo($.CONSUME(Drop))})},
        ]))

        this.beginStatementRule = $.RULE<() => BeginStatementAst>('beginStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-begin.html
            const start = $.CONSUME(Begin)
            const token = tokenInfo(start)
            const object = $.OPTION(() => $.OR([
                {ALT: () => ({kind: 'Work' as const, token: tokenInfo($.CONSUME(Work))})},
                {ALT: () => ({kind: 'Transaction' as const, token: tokenInfo($.CONSUME(Transaction))})},
            ]))
            const modes: TransactionModeAst[] = []
            $.MANY_SEP({SEP: Comma, DEF: () => modes.push($.OR2([
                {ALT: () => ({kind: 'IsolationLevel' as const, token: tokenInfo($.CONSUME(IsolationLevel)), level: $.OR3([
                    {ALT: () => ({kind: 'Serializable' as const, token: tokenInfo($.CONSUME(Serializable))})},
                    {ALT: () => ({kind: 'RepeatableRead' as const, token: tokenInfo($.CONSUME(RepeatableRead))})},
                    {ALT: () => ({kind: 'ReadCommitted' as const, token: tokenInfo($.CONSUME(ReadCommitted))})},
                    {ALT: () => ({kind: 'ReadUncommitted' as const, token: tokenInfo($.CONSUME(ReadUncommitted))})},
                ])})},
                {ALT: () => ({kind: 'ReadOnly' as const, token: tokenInfo($.CONSUME(ReadOnly))})},
                {ALT: () => ({kind: 'ReadWrite' as const, token: tokenInfo($.CONSUME(ReadWrite))})},
                {ALT: () => ({not: $.OPTION2(() => tokenInfo($.CONSUME(Not))), kind: 'Deferrable' as const, token: tokenInfo($.CONSUME(Deferrable))})}
            ]))})
            const end = $.CONSUME(Semicolon)
            return removeEmpty({kind: 'Begin' as const, meta: tokenInfo2(start, end), token, object, modes})
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

        this.commitStatementRule = $.RULE<() => CommitStatementAst>('commitStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-commit.html
            const start = $.CONSUME(Commit)
            const token = tokenInfo(start)
            const object = $.OPTION(() => $.OR([
                {ALT: () => ({kind: 'Work' as const, token: tokenInfo($.CONSUME(Work))})},
                {ALT: () => ({kind: 'Transaction' as const, token: tokenInfo($.CONSUME(Transaction))})},
            ]))
            const chain = $.OPTION2(() => {
                const and = $.CONSUME(And)
                const no = $.OPTION3(() => tokenInfo($.CONSUME(No)))
                const chain = $.CONSUME(Chain)
                return {token: tokenInfo2(and, chain), no}
            })
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'Commit' as const, meta: tokenInfo2(start, end), token, object, chain})
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

        this.createFunctionStatementRule = $.RULE<() => CreateFunctionStatementAst>('createFunctionStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-createfunction.html
            const start = $.CONSUME(Create)
            const replace = undefined // TODO: $.OPTION(() => tokenInfo2($.CONSUME(Or), $.CONSUME(Replace)))
            const token = tokenInfo2(start, $.CONSUME(Function))
            const object = $.SUBRULE($.objectNameRule)
            const args = $.SUBRULE(functionArgumentsRule)
            const statement: Pick<CreateFunctionStatementAst, 'returns' | 'language' | 'behavior' | 'definition' | 'nullBehavior' | 'return'> = {}
            $.MANY({DEF: () => $.OR([
                {ALT: () => statement.returns = $.SUBRULE(functionReturnsRule)},
                {ALT: () => statement.language = {token: tokenInfo($.CONSUME(Language)), name: $.SUBRULE3($.identifierRule)}},
                {ALT: () => statement.behavior = $.OR2([
                    {ALT: () => ({kind: 'Immutable' as const, token: tokenInfo($.CONSUME(Immutable))})},
                    {ALT: () => ({kind: 'Stable' as const, token: tokenInfo($.CONSUME(Stable))})},
                    {ALT: () => ({kind: 'Volatile' as const, token: tokenInfo($.CONSUME(Volatile))})},
                ])},
                {ALT: () => statement.definition = {token: tokenInfo($.CONSUME(As)), value: $.SUBRULE(this.stringRule)}},
                {ALT: () => statement.nullBehavior = $.OR3([
                    {ALT: () => ({kind: 'Called' as const, token: tokenInfoN([$.CONSUME(Called), $.CONSUME(On), $.CONSUME(Null), $.CONSUME(Input)])})},
                    {ALT: () => ({kind: 'ReturnsNull' as const, token: tokenInfoN([$.CONSUME(Returns), $.CONSUME2(Null), $.CONSUME2(On), $.CONSUME3(Null), $.CONSUME2(Input)])})},
                    {ALT: () => ({kind: 'Strict' as const, token: tokenInfo($.CONSUME(Strict))})},
                ])},
                {ALT: () => statement.return = {token: tokenInfo($.CONSUME(Return)), expression: $.SUBRULE(this.expressionRule)}},
            ])})
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'CreateFunction' as const, meta: tokenInfo2(start, end), token, replace, ...object, args, ...statement})
        })
        const functionArgumentsRule = $.RULE<() => FunctionArgumentAst[]>('functionArgumentsRule', () => {
            const args: FunctionArgumentAst[] = []
            $.CONSUME(ParenLeft)
            $.MANY_SEP({SEP: Comma, DEF: () => {
                const mode = $.OPTION(() => $.OR([
                    {ALT: () => ({kind: 'In' as const, token: tokenInfo($.CONSUME(In))})},
                    {ALT: () => ({kind: 'Out' as const, token: tokenInfo($.CONSUME(Out))})},
                    {ALT: () => ({kind: 'InOut' as const, token: tokenInfo($.CONSUME(InOut))})},
                    {ALT: () => ({kind: 'Variadic' as const, token: tokenInfo($.CONSUME(Variadic))})},
                ]))
                const name = $.OPTION2(() => $.SUBRULE($.identifierRule))
                const type = $.SUBRULE($.columnTypeRule)
                args.push(removeUndefined({mode, name, type}))
            }})
            $.CONSUME(ParenRight)
            return args
        })
        const functionReturnsRule = $.RULE<() => FunctionReturnsAst>('functionReturnsRule', () => {
            const ret = $.CONSUME(Returns)
            return $.OR([
                {ALT: () => removeUndefined({kind: 'Type' as const, token: tokenInfo(ret), setOf: $.OPTION(() => tokenInfo($.CONSUME(SetOf))), type: $.SUBRULE($.columnTypeRule)})},
                {ALT: () => {
                    const token = tokenInfo2(ret, $.CONSUME(Table))
                    $.CONSUME(ParenLeft)
                    const columns: {name: IdentifierAst, type: ColumnTypeAst}[] = []
                    $.MANY_SEP({SEP: Comma, DEF: () => columns.push({name: $.SUBRULE($.identifierRule), type: $.SUBRULE2($.columnTypeRule)})})
                    $.CONSUME(ParenRight)
                    return {kind: 'Table' as const, token, columns}
                }},
            ])
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

        this.createMaterializedViewStatementRule = $.RULE<() => CreateMaterializedViewStatementAst>('createMaterializedViewStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-creatematerializedview.html
            const start = $.CONSUME(Create)
            const token = tokenInfo2(start, $.CONSUME(MaterializedView))
            const ifNotExists = $.OPTION(() => $.SUBRULE(ifNotExistsRule))
            const object = $.SUBRULE($.objectNameRule)
            const columns: IdentifierAst[] = []
            $.OPTION2(() => {
                $.CONSUME(ParenLeft)
                $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => columns.push($.SUBRULE($.identifierRule))})
                $.CONSUME(ParenRight)
            })
            // TODO: USING
            // TODO: WITH
            // TODO: TABLESPACE
            $.CONSUME(As)
            const query = $.SUBRULE(selectStatementInnerRule)
            const withData = $.OPTION3(() => {
                const with_ = $.CONSUME(With)
                const no = $.OPTION4(() => tokenInfo($.CONSUME(No)))
                const data = $.CONSUME(Data)
                return {token: tokenInfo2(with_, data), no}
            })
            const end = $.CONSUME(Semicolon)
            return removeEmpty({kind: 'CreateMaterializedView' as const, meta: tokenInfo2(start, end), token, ifNotExists, ...object, columns, query, withData})
        })

        this.createSchemaStatementRule = $.RULE<() => CreateSchemaStatementAst>('createSchemaStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-createschema.html
            const start = $.CONSUME(Create)
            const token = tokenInfo2(start, $.CONSUME(Schema))
            const ifNotExists = $.SUBRULE(ifNotExistsRule)
            const schema = $.OPTION2(() => $.SUBRULE($.identifierRule))
            const authorization = $.OPTION3(() => ({token: tokenInfo($.CONSUME(Authorization)), role: $.SUBRULE(schemaRoleRule)}))
            const end = $.CONSUME(Semicolon)
            return removeEmpty({kind: 'CreateSchema' as const, meta: tokenInfo2(start, end), token, ifNotExists, schema, authorization})
        })
        const schemaRoleRule = $.RULE<() => SchemaRoleAst>('schemaRoleRule', () => $.OR([
            {ALT: () => ({kind: 'Role' as const, name: $.SUBRULE2($.identifierRule)})},
            {ALT: () => ({kind: 'CurrentRole' as const, token: tokenInfo($.CONSUME(CurrentRole))})},
            {ALT: () => ({kind: 'CurrentUser' as const, token: tokenInfo($.CONSUME(CurrentUser))})},
            {ALT: () => ({kind: 'SessionUser' as const, token: tokenInfo($.CONSUME(SessionUser))})},
        ]))

        this.createSequenceStatementRule = $.RULE<() => CreateSequenceStatementAst>('createSequenceStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-createsequence.html
            const begin = $.CONSUME(Create)
            const mode = $.OPTION(() => $.OR([
                {ALT: () => ({kind: 'Unlogged' as const, token: tokenInfo($.CONSUME(Unlogged))})},
                {ALT: () => ({kind: 'Temporary' as const, token: $.OR2([
                    {ALT: () => tokenInfo($.CONSUME(Temp))},
                    {ALT: () => tokenInfo($.CONSUME(Temporary))}
                ])})}
            ]))
            const token = tokenInfo2(begin, $.CONSUME(Sequence))
            const ifNotExists = $.OPTION2(() => $.SUBRULE(ifNotExistsRule))
            const object = $.SUBRULE($.objectNameRule)

            const statement: Pick<CreateSequenceStatementAst, 'as' | 'start' | 'increment' | 'minValue' | 'maxValue' | 'cache' | 'ownedBy'> = {}
            $.MANY({DEF: () => $.OR3([
                {ALT: () => statement.as = $.SUBRULE(sequenceTypeRule)},
                {ALT: () => statement.start = $.SUBRULE(sequenceStartRule)},
                {ALT: () => statement.increment = $.SUBRULE(sequenceIncrementRule)},
                {ALT: () => statement.minValue = $.SUBRULE(sequenceMinValueRule)},
                {ALT: () => statement.maxValue = $.SUBRULE(sequenceMaxValueRule)},
                {ALT: () => statement.cache = $.SUBRULE(sequenceCacheRule)},
                // TODO: CYCLE
                {ALT: () => statement.ownedBy = $.SUBRULE(sequenceOwnedByRule)},
            ])})
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'CreateSequence' as const, meta: tokenInfo2(begin, end), token, mode, ifNotExists, ...object, ...statement})
        })
        const sequenceTypeRule = $.RULE<() => SequenceTypeAst>('sequenceTypeRule', () => ({token: tokenInfo($.CONSUME(As)), type: $.SUBRULE($.identifierRule)}))
        const sequenceStartRule = $.RULE<() => SequenceParamAst>('sequenceStartRule', () => ({token: tokenInfo2($.CONSUME(Start), $.OPTION(() => $.CONSUME(With))), value: $.SUBRULE($.integerRule)}))
        const sequenceIncrementRule = $.RULE<() => SequenceParamAst>('sequenceIncrementRule', () => ({token: tokenInfo2($.CONSUME(Increment), $.OPTION(() => $.CONSUME(By))), value: $.SUBRULE($.integerRule)}))
        const sequenceMinValueRule = $.RULE<() => SequenceParamOptAst>('sequenceMinValueRule', () => $.OR([
            {ALT: () => ({token: tokenInfo2($.CONSUME(No), $.CONSUME(Minvalue))})},
            {ALT: () => ({token: tokenInfo($.CONSUME2(Minvalue)), value: $.SUBRULE($.integerRule)})},
        ]))
        const sequenceMaxValueRule = $.RULE<() => SequenceParamOptAst>('sequenceMaxValueRule', () => $.OR([
            {ALT: () => ({token: tokenInfo2($.CONSUME(No), $.CONSUME(Maxvalue))})},
            {ALT: () => ({token: tokenInfo($.CONSUME2(Maxvalue)), value: $.SUBRULE($.integerRule)})},
        ]))
        const sequenceCacheRule = $.RULE<() => SequenceParamAst>('sequenceCacheRule', () => ({token: tokenInfo($.CONSUME(Cache)), value: $.SUBRULE5($.integerRule)}))
        const sequenceOwnedByRule = $.RULE<() => SequenceOwnedByAst>('sequenceOwnedByRule', () => {
            return {token: tokenInfo($.CONSUME(OwnedBy)), owner: $.OR([
                {ALT: () => ({kind: 'None' as const, token: $.CONSUME(None)})},
                {ALT: () => {
                    const first = $.SUBRULE($.identifierRule)
                    $.CONSUME(Dot)
                    const second = $.SUBRULE2($.identifierRule)
                    const third = $.OPTION(() => {
                        $.CONSUME2(Dot)
                        return $.SUBRULE3($.identifierRule)
                    })
                    return third ? {kind: 'Column' as const, schema: first, table: second, column: third} : {kind: 'Column' as const, table: first, column: second}
                }},
            ])}
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
            return removeEmpty({kind: 'CreateTable' as const, meta: tokenInfo2(start, end), token, mode, ifNotExists, ...object, columns: columns.filter(isNotUndefined), constraints: constraints.filter(isNotUndefined)})
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
            return removeEmpty({kind: 'CreateType' as const, meta: tokenInfo2(start, end), token, ...object, ...content})
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
            return removeEmpty({kind: 'CreateView' as const, meta: tokenInfo2(start, end), token, replace, temporary, recursive, ...object, columns, query})
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
                {ALT: () => ({token: tokenInfo2(start, $.CONSUME(Sequence)), object: 'Sequence' as const})}, // https://www.postgresql.org/docs/current/sql-dropsequence.html
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
            const onConflict = $.OPTION2(() => $.SUBRULE(onConflictClauseRule))
            const returning = $.OPTION3(() => $.SUBRULE(returningClauseRule))
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'InsertInto' as const, meta: tokenInfo2(start, end), token: tokenInfo(start), schema: object.schema, table: object.name, columns, values, onConflict, returning})
        })
        const onConflictClauseRule = $.RULE<() => OnConflictClauseAst>('onConflictClauseRule', () => {
            const token = tokenInfo2($.CONSUME(On), $.CONSUME(Conflict))
            const target = $.OPTION(() => $.OR([
                {ALT: () => ({kind: 'Constraint' as const, token: tokenInfo2($.CONSUME2(On), $.CONSUME(Constraint)), name: $.SUBRULE($.identifierRule)})},
                {ALT: () => {
                    $.CONSUME(ParenLeft)
                    const columns: IdentifierAst[] = []
                    $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => columns.push($.SUBRULE2($.identifierRule))})
                    $.CONSUME(ParenRight)
                    const where = $.OPTION2(() => $.SUBRULE($.whereClauseRule))
                    return {kind: 'Columns' as const, columns, where}
                }}
            ]))
            const do_ = $.CONSUME(Do)
            const action = $.OR2([
                {ALT: () => ({kind: 'Nothing' as const, token: tokenInfo2(do_, $.CONSUME(Nothing))})},
                {ALT: () => {
                    const token = tokenInfo2(do_, $.CONSUME(Update))
                    $.CONSUME(Set)
                    const columns = $.SUBRULE(updateColumnsRule)
                    const where = $.OPTION3(() => $.SUBRULE2($.whereClauseRule))
                    return ({kind: 'Update' as const, token, columns, where})
                }},
            ])
            return {token, target, action}
        })
        const returningClauseRule = $.RULE<() => SelectClauseAst>('returningClauseRule', () => {
            const token = tokenInfo($.CONSUME(Returning))
            const columns: SelectClauseColumnAst[] = []
            $.AT_LEAST_ONE_SEP4({SEP: Comma, DEF: () => columns.push($.SUBRULE(selectClauseColumnRule))})
            return {token, columns}
        })

        this.selectStatementRule = $.RULE<() => SelectStatementAst>('selectStatementRule', () => {
            const select = $.SUBRULE(selectStatementInnerRule)
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'Select' as const, meta: mergePositions([select?.token, tokenInfo(end)]), ...select})
        })
        const selectStatementInnerRule = $.RULE<() => SelectStatementInnerAst>('selectStatementInnerRule', (): SelectStatementInnerAst => {
            // https://www.postgresql.org/docs/current/sql-select.html
            return $.OR([
                {ALT: () => {
                    const main = $.SUBRULE(selectStatementMainRule)
                    const result = $.SUBRULE(selectStatementResultRule)
                    return removeUndefined({...main, ...result})
                }},
                {ALT: () => { // additional parenthesis
                    $.CONSUME(ParenLeft)
                    const main = $.SUBRULE2(selectStatementMainRule)
                    const result = $.SUBRULE2(selectStatementResultRule)
                    $.CONSUME(ParenRight)
                    const union = $.OPTION(() => $.SUBRULE(unionClauseRule))
                    return removeUndefined({...main, union, ...result})
                }},
            ])
        })
        const selectStatementMainRule = $.RULE<() => SelectStatementMainAst>('selectStatementMainRule', (): SelectStatementInnerAst => {
            const select = $.SUBRULE($.selectClauseRule)
            const from = $.OPTION(() => $.SUBRULE($.fromClauseRule))
            const where = $.OPTION2(() => $.SUBRULE($.whereClauseRule))
            const groupBy = $.OPTION3(() => $.SUBRULE(groupByClauseRule))
            const having = $.OPTION4(() => $.SUBRULE(havingClauseRule))
            const window: WindowClauseAst[] = []
            $.MANY(() => window.push($.SUBRULE(windowClauseRule)))
            return removeEmpty({...select, from, where, groupBy, having, window})
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

        this.showStatementRule = $.RULE<() => ShowStatementAst>('showStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-show.html
            const start = $.CONSUME(Show)
            const name = $.SUBRULE($.identifierRule)
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'Show' as const, meta: tokenInfo2(start, end), token: tokenInfo(start), name})
        })

        this.updateStatementRule = $.RULE<() => UpdateStatementAst>('updateStatementRule', () => {
            // https://www.postgresql.org/docs/current/sql-update.html
            const start = $.CONSUME(Update)
            const only = $.OPTION(() => tokenInfo($.CONSUME(Only)))
            const object = $.SUBRULE($.objectNameRule)
            const descendants = $.OPTION2(() => tokenInfo($.CONSUME(Asterisk)))
            const alias = $.OPTION3(() => $.SUBRULE($.aliasRule))
            $.CONSUME(Set)
            const columns = $.SUBRULE(updateColumnsRule)
            const where = $.OPTION4(() => $.SUBRULE($.whereClauseRule))
            const returning = $.OPTION5(() => $.SUBRULE(returningClauseRule))
            const end = $.CONSUME(Semicolon)
            return removeUndefined({kind: 'Update' as const, meta: tokenInfo2(start, end), token: tokenInfo(start), only, schema: object.schema, table: object.name, descendants, alias, columns, where, returning})
        })
        const updateColumnsRule = $.RULE<() => UpdateColumnAst[]>('updateColumnsRule', () => {
            const columns: UpdateColumnAst[] = []
            $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => {
                const column = $.SUBRULE($.identifierRule)
                $.CONSUME(Equal)
                const value = $.OR([
                    {ALT: () => $.SUBRULE($.expressionRule)},
                    {ALT: () => ({kind: 'Default' as const, token: tokenInfo($.CONSUME(Default))})}
                ])
                columns.push({column, value})
            }})
            return columns
        })

        // clauses

        this.selectClauseRule = $.RULE<() => SelectClauseAst>('selectClauseRule', () => {
            const token = tokenInfo($.CONSUME(Select))
            $.OPTION(() => $.CONSUME(All)) // default behavior, not specified most of the time but just in case...
            const distinct = $.OPTION2(() => removeUndefined({
                token: tokenInfo($.CONSUME(Distinct)),
                on: $.OPTION3(() => {
                    const token = tokenInfo($.CONSUME(On))
                    $.CONSUME(ParenLeft)
                    const columns: ExpressionAst[] = []
                    $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => columns.push($.SUBRULE($.expressionRule))})
                    $.CONSUME(ParenRight)
                    return ({token, columns})
                })
            }))
            const columns: SelectClauseColumnAst[] = []
            $.AT_LEAST_ONE_SEP2({SEP: Comma, DEF: () => columns.push($.SUBRULE(selectClauseColumnRule))})
            return {token, distinct, columns}
        })
        const selectClauseColumnRule = $.RULE<() => SelectClauseColumnAst>('selectClauseColumnRule', () => {
            const expression = $.SUBRULE($.expressionRule)
            const filter = $.OPTION(() => {
                const token = tokenInfo($.CONSUME(Filter))
                $.CONSUME(ParenLeft)
                const where = $.SUBRULE($.whereClauseRule)
                $.CONSUME(ParenRight)
                return {token, where}
            })
            const over = $.OPTION2(() => {
                const token = tokenInfo($.CONSUME(Over))
                const content = $.OR([
                    {ALT: () => ({name: $.SUBRULE($.identifierRule)})},
                    {ALT: () => $.SUBRULE(windowClauseContentRule)}
                ])
                return {token, ...content}
            })
            const alias = $.OPTION3(() => $.SUBRULE($.aliasRule))
            return removeUndefined({...expression, filter, over, alias})
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
        const windowClauseRule = $.RULE<() => WindowClauseAst>('windowClauseRule', () => {
            const token = tokenInfo($.CONSUME(Window))
            const name = $.SUBRULE($.identifierRule)
            $.CONSUME(As)
            const content = $.SUBRULE(windowClauseContentRule)
            return {token, name, ...content}
        })
        const windowClauseContentRule = $.RULE<() => WindowClauseContentAst>('windowClauseContentRule', () => {
            $.CONSUME(ParenLeft)
            const partitionBy = $.OPTION(() => {
                const token = tokenInfo($.CONSUME(PartitionBy))
                const columns: ExpressionAst[] = []
                $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => columns.push($.SUBRULE($.expressionRule))})
                return {token, columns}
            })
            const orderBy = $.OPTION2(() => $.SUBRULE(orderByClauseRule))
            $.CONSUME(ParenRight)
            return removeUndefined({partitionBy, orderBy})
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
                {ALT: () => ({kind: 'SetNull' as const, token: tokenInfo2($.CONSUME(Set), $.CONSUME(Null))})},
                {ALT: () => ({kind: 'SetDefault' as const, token: tokenInfo2($.CONSUME2(Set), $.CONSUME(Default))})},
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
            let expr = $.SUBRULE(unaryExpressionRule) // unary has higher precedence than other operators
            $.MANY(() => {
                const op = $.SUBRULE(operatorRule)
                if (['In', 'NotIn'].includes(op?.kind)) {
                    const right = $.SUBRULE(listRule)
                    expr = {kind: 'Operation', left: expr, op, right}
                } else {
                    const right = $.SUBRULE2(unaryExpressionRule)
                    expr = {kind: 'Operation', left: expr, op, right}
                }
            })
            return expr
        })
        const unaryExpressionRule = $.RULE<() => ExpressionAst>('unaryExpressionRule', () => $.OR([
            {ALT: () => {
                const opLeft = $.SUBRULE(operatorLeftRule)
                const expr = $.SUBRULE(atomicExpressionRule) // atomic has the highest precedence
                return {kind: 'OperationLeft', op: opLeft, right: expr}
            }},
            {ALT: () => {
                const expr = $.SUBRULE2(atomicExpressionRule) // atomic has the highest precedence
                const opRight = $.OPTION(() => $.SUBRULE(operatorRightRule))
                return opRight ? {kind: 'OperationRight', left: expr, op: opRight} : expr
            }},
        ]))
        const atomicExpressionRule = $.RULE<() => ExpressionAst>('atomicExpressionRule', () => {
            const expr = $.OR([
                {ALT: () => $.SUBRULE(groupRule)},
                {ALT: () => $.SUBRULE($.literalRule)},
                {ALT: () => ({kind: 'Wildcard', token: tokenInfo($.CONSUME(Asterisk))})},
                {ALT: () => {
                    const first = $.SUBRULE($.identifierRule)
                    const nest = $.OPTION(() => $.OR2([
                        {ALT: () => removeUndefined({kind: 'Function', function: first, ...($.SUBRULE(functionParamsRule) || {})})},
                        {ALT: () => {
                            $.CONSUME(Dot)
                            return $.OR3([
                                {ALT: () => ({kind: 'Wildcard', table: first, token: tokenInfo($.CONSUME2(Asterisk))})},
                                {ALT: () => {
                                    const second = $.SUBRULE2($.identifierRule)
                                    const nest2 = $.OPTION2(() => $.OR4([
                                        {ALT: () => removeUndefined({kind: 'Function', schema: first, function: second, ...($.SUBRULE2(functionParamsRule) || {})})},
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
            {ALT: () => ({kind: 'Is' as const, token: tokenInfo($.CONSUME(Is))})},
            {ALT: () => ({kind: 'In' as const, token: tokenInfo($.CONSUME(In))})},
            {ALT: () => ({kind: 'Like' as const, token: tokenInfo($.CONSUME(Like))})},
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
        const operatorLeftRule = $.RULE<() => OperatorLeftAst>('operatorLeftRule', () => $.OR([
            {ALT: () => ({kind: 'Not' as const, token: tokenInfo($.CONSUME(Not))})},
            {ALT: () => ({kind: 'Interval' as const, token: tokenInfo($.CONSUME(Interval))})},
            {ALT: () => ({kind: '~' as const, token: tokenInfo($.CONSUME(Tilde))})},
        ]))
        const operatorRightRule = $.RULE<() => OperatorRightAst>('operatorRightRule', () => $.OR([
            {ALT: () => ({kind: 'IsNull' as const, token: tokenInfo($.CONSUME(IsNull))})},
            {ALT: () => ({kind: 'NotNull' as const, token: tokenInfo($.CONSUME(NotNull))})},
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
                const field = $.OR([
                    {ALT: () => $.SUBRULE($.stringRule)},
                    {ALT: () => $.SUBRULE($.parameterRule)}
                ])
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
        const functionParamsRule = $.RULE<() => { distinct?: {token: TokenInfo}, parameters: ExpressionAst[] }>('functionParamsRule', () => {
            $.CONSUME(ParenLeft)
            const distinct = $.OPTION(() => ({token: tokenInfo($.CONSUME(Distinct))}))
            const parameters: ExpressionAst[] = []
            $.MANY_SEP({SEP: Comma, DEF: () => parameters.push($.SUBRULE($.expressionRule))})
            $.CONSUME(ParenRight)
            return {distinct, parameters: parameters.filter(isNotUndefined)}
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
            {ALT: () => $.SUBRULE($.parameterRule)},
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
            // tokens allowed as identifiers:
            {ALT: () => toIdentifier($.CONSUME(Add))},
            {ALT: () => toIdentifier($.CONSUME(Commit))},
            {ALT: () => toIdentifier($.CONSUME(Data))},
            {ALT: () => toIdentifier($.CONSUME(Database))},
            {ALT: () => toIdentifier($.CONSUME(Deferrable))},
            {ALT: () => toIdentifier($.CONSUME(Domain))},
            {ALT: () => toIdentifier($.CONSUME(Increment))},
            {ALT: () => toIdentifier($.CONSUME(Index))},
            {ALT: () => toIdentifier($.CONSUME(Input))},
            {ALT: () => toIdentifier($.CONSUME(Nulls))},
            {ALT: () => toIdentifier($.CONSUME(Rows))},
            {ALT: () => toIdentifier($.CONSUME(Schema))},
            {ALT: () => toIdentifier($.CONSUME(Start))},
            {ALT: () => toIdentifier($.CONSUME(Temporary))},
            {ALT: () => toIdentifier($.CONSUME(Type))},
            {ALT: () => toIdentifier($.CONSUME(Version))},
        ]))

        this.stringRule = $.RULE<() => StringAst>('stringRule', () => $.OR([
            {ALT: () => {
                const token = $.CONSUME(String)
                if (token.image.match(/^E/i)) {
                    // https://www.postgresql.org/docs/current/sql-syntax-lexical.html
                    return {kind: 'String', token: tokenInfo(token), value: token.image.slice(2, -1).replaceAll(/''/g, "'"), escaped: true}
                } else {
                    return {kind: 'String', token: tokenInfo(token), value: token.image.slice(1, -1).replaceAll(/''/g, "'")}
                }
            }},
            {ALT: () => {
                // https://www.postgresql.org/docs/current/sql-syntax-lexical.html#SQL-SYNTAX-DOLLAR-QUOTING
                const token = $.CONSUME(StringDollar)
                const [, dollar] = token.image.match(/^(\$[^$]*\$)/) || []
                const prefix = dollar?.length || 0
                return {kind: 'String', token: tokenInfo(token), value: token.image.slice(prefix, -prefix).trim(), dollar}
            }},
        ]))

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

export function parsePostgresAst(input: string, opts: { strict?: boolean } = {strict: false}): ParserResult<PostgresAst> {
    return parseRule(p => p.statementsRule(), input, opts.strict || false)
}

export function parsePostgresStatementAst(input: string, opts: { strict?: boolean } = {strict: false}): ParserResult<PostgresStatementAst> {
    return parseRule(p => p.statementRule(), input, opts.strict || false)
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

function tokenInfoN(tokens: (IToken | undefined)[], issues?: TokenIssue[]): TokenInfo {
    return removeEmpty({...mergePositions(tokens.map(t => t ? tokenPosition(t) : undefined)), issues})
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
