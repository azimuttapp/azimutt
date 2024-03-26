import {createToken, EmbeddedActionsParser, IRecognitionException, IToken, Lexer, TokenType} from "chevrotain";
import {
    BooleanAst,
    ColumnRefAst,
    ConditionAst,
    ConditionElemAst,
    ConditionOpAst,
    IdentifierAst,
    IntegerAst,
    SelectAst,
    SelectColumnAst,
    SelectFromAst,
    SelectResultAst,
    SelectWhereAst,
    SqlScriptAst,
    StatementAst,
    StringAst,
    TableRefAst,
    TokenInfo,
    WildcardAst
} from "./ast";
import {removeUndefined} from "@azimutt/utils";
import {ParserError, ParserResult} from "@azimutt/database-model";

// https://chevrotain.io/docs/features/lexer_modes.html
// https://chevrotain.io/docs/features/custom_token_patterns.html => indentation

// special
const WhiteSpace = createToken({name: 'WhiteSpace', pattern: /\s+/, group: Lexer.SKIPPED})
const Identifier = createToken({ name: 'Identifier', pattern: /"([^\\"]|\\\\|\\")*"|[a-zA-Z]\w*/ })

// values
const Float = createToken({ name: 'Float', pattern: /\d+\.\d+/ })
const Integer = createToken({ name: 'Integer', pattern: /\d+/, longer_alt: Float })
const String = createToken({ name: 'String', pattern: /'([^\\']|\\\\|\\')*'/ })
const Boolean = createToken({ name: 'Boolean', pattern: /true|false/, longer_alt: Identifier })
const valueTokens: TokenType[] = [Integer, Float, String, Boolean]

// keywords
const CreateTable = createToken({ name: 'CreateTable', pattern: /CREATE TABLE/, longer_alt: Identifier })
const PrimaryKey = createToken({ name: 'PrimaryKey', pattern: /PRIMARY KEY/, longer_alt: Identifier })
const Constraint = createToken({ name: 'Constraint', pattern: /CONSTRAINT/, longer_alt: Identifier })
const Select = createToken({ name: 'Select', pattern: /SELECT/, longer_alt: Identifier })
const From = createToken({ name: 'From', pattern: /FROM/, longer_alt: Identifier })
const Where = createToken({ name: 'Where', pattern: /WHERE/, longer_alt: Identifier })
const And = createToken({ name: 'And', pattern: /AND/ })
const Or = createToken({ name: 'And', pattern: /OR/ })
const keywordTokens: TokenType[] = [CreateTable, PrimaryKey, Constraint, Select, From, Where, And, Or]

// chars
const Star = createToken({ name: 'Star', pattern: /\*/ })
const Dot = createToken({ name: 'Dot', pattern: /\./ })
const Comma = createToken({ name: 'Comma', pattern: /,/ })
const Semicolon = createToken({ name: 'Semicolon', pattern: /;/ })
const Equal = createToken({ name: 'Equal', pattern: /=/ })
const NotEqual = createToken({ name: 'NotEqual', pattern: /!=/ })
const GreaterThanOrEqual = createToken({ name: 'GreaterThanOrEqual', pattern: />=/ })
const GreaterThan = createToken({ name: 'GreaterThan', pattern: />/ })
const LessThanOrEqual = createToken({ name: 'LessThanOrEqual', pattern: /<=/ })
const LessThan = createToken({ name: 'LessThan', pattern: /</ })
const LParen = createToken({ name: 'LParen', pattern: /\(/ })
const RParen = createToken({ name: 'RParen', pattern: /\)/ })
const LCurly = createToken({ name: 'LCurly', pattern: /\{/ })
const RCurly = createToken({ name: 'RCurly', pattern: /\}/ })
const LBraket = createToken({ name: 'LBraket', pattern: /\[/ })
const RBraket = createToken({ name: 'RBraket', pattern: /\]/ })
const charTokens: TokenType[] = [Star, Dot, Comma, Semicolon, Equal, NotEqual, GreaterThanOrEqual, GreaterThan, LessThanOrEqual, LessThan, LParen, RParen, LCurly, RCurly, LBraket, RBraket]

// token order is important as they are tried in order, so the Identifier must be last
const allTokens: TokenType[] = [WhiteSpace, ...charTokens, ...keywordTokens, ...valueTokens, Identifier]

class SqlParser extends EmbeddedActionsParser {
    // common
    integerRule: () => IntegerAst
    stringRule: () => StringAst
    booleanRule: () => BooleanAst
    identifierRule: () => IdentifierAst
    namespaceRule: () => IdentifierAst
    tableRefRule: () => TableRefAst
    columnRefRule: () => ColumnRefAst
    conditionOpRule: () => ConditionOpAst
    conditionElemRule: () => ConditionElemAst
    conditionRule: () => ConditionAst
    // select
    selectResultColumnRule: () => SelectColumnAst
    selectResultRule: () => SelectResultAst
    selectFromRule: () => SelectFromAst
    selectWhereRule: () => SelectWhereAst
    selectRule: () => SelectAst
    // general
    statementRule: () => StatementAst
    sqlScriptRule: () => SqlScriptAst

    constructor(tokens: TokenType[]) {
        super(tokens)
        const $ = this

        // common rules
        this.integerRule = $.RULE<() => IntegerAst>('integerRule', () => {
            const token = $.CONSUME(Integer)
            return {value: parseInt(token.image), parser: parserInfo(token)}
        })

        this.stringRule = $.RULE<() => StringAst>('stringRule', () => {
            const token = $.CONSUME(String)
            return {value: token.image.slice(1, -1).replaceAll(/\\'/g, "'"), parser: parserInfo(token)}
        })

        this.booleanRule = $.RULE<() => BooleanAst>('booleanRule', () => {
            const token = $.CONSUME(Boolean)
            return {value: token.image === 'true', parser: parserInfo(token)}
        })

        this.identifierRule = $.RULE<() => IdentifierAst>('identifierRule', () => {
            const token = $.CONSUME(Identifier)
            if (token.image.startsWith('"')) {
                return {identifier: token.image.slice(1, -1).replaceAll(/\\"/g, '"'), parser: parserInfo(token)}
            } else {
                return {identifier: token.image, parser: parserInfo(token)}
            }
        })

        this.namespaceRule = $.RULE<() => IdentifierAst>('namespaceRule', () => {
            const token = $.SUBRULE($.identifierRule)
            $.CONSUME(Dot)
            return token
        })

        this.tableRefRule = $.RULE<() => TableRefAst>('tableRefRule', () => {
            const schema = $.OPTION(() => $.SUBRULE2($.namespaceRule))
            const table = $.SUBRULE($.identifierRule)
            return removeUndefined({table, schema})
        })

        this.columnRefRule = $.RULE<() => ColumnRefAst>('columnRefRule', () => {
            let schema = $.OPTION(() => $.SUBRULE($.namespaceRule))
            let table = $.OPTION2(() => $.SUBRULE2($.namespaceRule))
            if (!table) { [table, schema] = [schema, table] }
            const column = $.SUBRULE3($.identifierRule)
            return removeUndefined({column, table, schema})
        })

        this.conditionOpRule = $.RULE<() => ConditionOpAst>('conditionOpRule', () => {
            return $.OR([
                { ALT: () => ({operator: '=', parser: parserInfo($.CONSUME(Equal))})},
                { ALT: () => ({operator: '!=', parser: parserInfo($.CONSUME(NotEqual))})},
                { ALT: () => ({operator: '<', parser: parserInfo($.CONSUME(LessThan))})},
                { ALT: () => ({operator: '>', parser: parserInfo($.CONSUME(GreaterThan))})},
            ])
        })

        this.conditionElemRule = $.RULE<() => ConditionElemAst>('conditionElemRule', () => {
            return $.OR([
                { ALT: () => $.SUBRULE($.integerRule)},
                { ALT: () => $.SUBRULE($.stringRule)},
                { ALT: () => $.SUBRULE($.booleanRule)},
                { ALT: () => $.SUBRULE($.columnRefRule)},
            ])
        })

        this.conditionRule = $.RULE<() => ConditionAst>('conditionRule', () => {
            const left = $.SUBRULE($.conditionElemRule)
            const operation = $.SUBRULE($.conditionOpRule)
            const right = $.SUBRULE2($.conditionElemRule)
            return {left, operation, right}
        })

        // select rules
        this.selectResultColumnRule = $.RULE<() => SelectColumnAst>('selectResultColumnRule', () => {
            let schema = $.OPTION(() => $.SUBRULE($.namespaceRule))
            let table = $.OPTION2(() => $.SUBRULE2($.namespaceRule))
            if (!table) { [table, schema] = [schema, table] }
            const column = $.OR([
                { ALT: () => ({wildcard: '*', parser: parserInfo($.CONSUME(Star))} as WildcardAst)},
                { ALT: () => $.SUBRULE3($.identifierRule) },
            ])
            return removeUndefined({column, table, schema})
        })

        this.selectResultRule = $.RULE<() => SelectResultAst>('selectResultRule', () => {
            let columns: SelectColumnAst[] = []
            $.CONSUME(Select)
            $.AT_LEAST_ONE_SEP({
                SEP: Comma,
                DEF: () => {
                    columns.push($.SUBRULE($.selectResultColumnRule))
                }
            })
            return {columns}
        })

        this.selectFromRule = $.RULE<() => SelectFromAst>('selectFromRule', () => {
            $.CONSUME(From)
            const table = $.SUBRULE($.tableRefRule)
            // TODO: alias, joins
            return table
        })

        this.selectWhereRule = $.RULE<() => SelectWhereAst>('selectWhereRule', () => {
            $.CONSUME(Where)
            return $.SUBRULE($.conditionRule)
        })

        this.selectRule = $.RULE<() => SelectAst>('selectRule', () => {
            const result = $.SUBRULE($.selectResultRule)
            const from = $.SUBRULE($.selectFromRule)
            const where = $.OPTION(() => $.SUBRULE($.selectWhereRule))
            $.CONSUME(Semicolon)
            return removeUndefined({command: 'SELECT' as const, result, from, where})
        })

        // general rules
        this.statementRule = $.RULE<() => StatementAst>('statementRule', () => {
            return $.OR([
                { ALT: () => $.SUBRULE($.selectRule) },
            ])
        })

        this.sqlScriptRule = $.RULE<() => SqlScriptAst>('sqlScriptRule', () => {
            const stmts: StatementAst[] = []
            $.MANY_SEP({
                SEP: Semicolon,
                DEF: () => stmts.push($.SUBRULE($.statementRule))
            })
            return stmts
        })

        this.performSelfAnalysis()
    }
}

const lexer = new Lexer(allTokens)
const parser = new SqlParser(allTokens)

// exported only for tests, use the `parse` function instead
export function parseRule<T>(parse: (p: SqlParser) => T, input: string): ParserResult<T> {
    const lexingResult = lexer.tokenize(input)
    parser.input = lexingResult.tokens // "input" is a setter which will reset the parser's state.
    const res = parse(parser)
    if (parser.errors.length > 0) {
        return ParserResult.failure(parser.errors.map(formatError))
    }
    return ParserResult.success(res)
}

export function parse(input: string): ParserResult<SqlScriptAst> {
    return parseRule(p => p.sqlScriptRule(), input)
}

function formatError(err: IRecognitionException): ParserError {
    const {offset, line, column} = parserInfo(err.token)
    return {name: err.name, message: err.message, position: {offset, line, column}}
}

function parserInfo(token: IToken): TokenInfo {
    return {
        token: token.tokenType?.name || 'missing',
        offset: [token.startOffset, token.endOffset || 0],
        line: [token.startLine || 0, token.endLine || 0],
        column: [token.startColumn || 0, token.endColumn || 0]
    }
}
