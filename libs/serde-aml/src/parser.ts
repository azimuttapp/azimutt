import {createToken, EmbeddedActionsParser, IRecognitionException, IToken, Lexer, TokenType} from "chevrotain";

// special
const WhiteSpace = createToken({name: 'WhiteSpace', pattern: /\s+/, group: Lexer.SKIPPED})
const Identifier = createToken({ name: 'Identifier', pattern: /"([^\\"]|\\\\|\\")*"|[a-zA-Z]\w*/ })
const Note = createToken({ name: 'Note', pattern: /\|[^#]+/ })
const Comment = createToken({ name: 'Comment', pattern: /#.*/ })

// values
const Float = createToken({ name: 'Float', pattern: /\d+\.\d+/ })
const Integer = createToken({ name: 'Integer', pattern: /\d+/, longer_alt: Float })
const String = createToken({ name: 'String', pattern: /'([^\\']|\\\\|\\')*'/ })
const Boolean = createToken({ name: 'Boolean', pattern: /true|false/, longer_alt: Identifier })
const valueTokens: TokenType[] = [Integer, Float, String, Boolean]

// keywords
const Relation = createToken({ name: 'Relation', pattern: /rel/, longer_alt: Identifier })
const Type = createToken({ name: 'Type', pattern: /type/, longer_alt: Identifier })
const keywordTokens: TokenType[] = [Relation, Type]

// chars
const ManyToOne = createToken({ name: 'ManyToOne', pattern: />-|->/ })
const OneToMany = createToken({ name: 'ManyToOne', pattern: /-<|<-/ })
const OneToOne = createToken({ name: 'ManyToOne', pattern: /--/ })
const ManyToMany = createToken({ name: 'ManyToOne', pattern: /><|<>/ })
const Comma = createToken({ name: 'Comma', pattern: /,/ })
const Colon = createToken({ name: 'Colon', pattern: /:/ })
const LCurly = createToken({ name: 'LCurly', pattern: /\{/ })
const RCurly = createToken({ name: 'RCurly', pattern: /\}/ })
const charTokens: TokenType[] = [ManyToOne, OneToMany, OneToOne, ManyToMany, Comma, Colon, LCurly, RCurly]

// token order is important as they are tried in order, so the Identifier must be last
const allTokens: TokenType[] = [WhiteSpace, ...charTokens, ...keywordTokens, ...valueTokens, Identifier, Note, Comment]

export type Position = [number, number]
export type TokenInfo = {token: string, offset: Position, line: Position, column: Position}
export type ParserError = {kind: string, message: string, offset: Position, line: Position, column: Position}
export type ParserResult<T> = {
    result?: T
    errors?: ParserError[]
    warnings?: ParserError[]
}

export type AmlAst = AmlStatementAst[]
export type AmlStatementAst = AmlEntityAst | AmlRelationAst | AmlTypeAst
export type AmlEntityAst = { command: 'ENTITY' }
export type AmlRelationAst = { command: 'RELATION' }
export type AmlTypeAst = { command: 'TYPE' }

export type PropertiesAst = PropertyAst[]
export type PropertyAst = {key: IdentifierAst, value?: IdentifierAst | IntegerAst}
export type NoteAst = {note: string, parser: TokenInfo}
export type CommentAst = {comment: string, parser: TokenInfo}
export type IdentifierAst = {identifier: string, parser: TokenInfo}
export type IntegerAst = {value: number, parser: TokenInfo}

class AmlParser extends EmbeddedActionsParser {
    // common
    integerRule: () => IntegerAst
    identifierRule: () => IdentifierAst
    commentRule: () => CommentAst
    noteRule: () => NoteAst
    propertiesRule: () => PropertiesAst

    // entity
    // relation
    // type
    // general
    // amlStatementRule: () => AmlStatementAst
    // amlRule: () => AmlAst

    constructor(tokens: TokenType[]) {
        super(tokens)
        const $ = this

        // common rules
        this.integerRule = $.RULE<() => IntegerAst>('integerRule', () => {
            const token = $.CONSUME(Integer)
            return {value: parseInt(token.image), parser: parserInfo(token)}
        })

        this.identifierRule = $.RULE<() => IdentifierAst>('identifierRule', () => {
            const token = $.CONSUME(Identifier)
            if (token.image.startsWith('"')) {
                return {identifier: token.image.slice(1, -1).replaceAll(/\\"/g, '"'), parser: parserInfo(token)}
            } else {
                return {identifier: token.image, parser: parserInfo(token)}
            }
        })

        this.commentRule = $.RULE<() => CommentAst>('commentRule', () => {
            const token = $.CONSUME(Comment)
            return {comment: token.image.slice(1).trim(), parser: parserInfo(token)}
        })

        this.noteRule = $.RULE<() => NoteAst>('noteRule', () => {
            const token = $.CONSUME(Note)
            return {note: token.image.slice(1).trim(), parser: parserInfo(token)}
        })

        this.propertiesRule = $.RULE<() => PropertiesAst>('propertiesRule', () => {
            const props: PropertiesAst = []
            $.CONSUME(LCurly)
            $.MANY_SEP({
                SEP: Comma,
                DEF: () => {
                    const key = $.SUBRULE($.identifierRule)
                    const value = $.OPTION(() => {
                        $.CONSUME(Colon)
                        return $.OR([
                            { ALT: () => $.SUBRULE2($.identifierRule) },
                            { ALT: () => $.SUBRULE3($.integerRule) },
                        ])
                    })
                    props.push({key, value})
                }
            })
            $.CONSUME(RCurly)
            return props
        })

        // entity rules

        // general rules
        /*this.amlStatementRule = $.RULE<() => AmlStatementAst>('amlStatementRule', () => {
            return $.OR([
                // { ALT: () => $.SUBRULE($.entityRule) },
                // { ALT: () => $.SUBRULE($.relationRule) },
                // { ALT: () => $.SUBRULE($.typeRule) },
            ])
        })

        this.amlRule = $.RULE<() => AmlAst>('amlRule', () => {
            let stmts: AmlStatementAst[] = []
            $.MANY({
                DEF: () => stmts.push($.SUBRULE($.amlStatementRule))
            })
            return stmts
        })*/

        this.performSelfAnalysis()
    }
}

const lexer = new Lexer(allTokens)
const parser = new AmlParser(allTokens)

// exported only for tests, use the `parse` function instead
export function parseRule<T>(parse: (p: AmlParser) => T, input: string): ParserResult<T> {
    const lexingResult = lexer.tokenize(input)
    parser.input = lexingResult.tokens // "input" is a setter which will reset the parser's state.
    const res = parse(parser)
    if (parser.errors.length > 0) {
        return {errors: parser.errors.map(formatError)}
    }
    return {result: res}
}

/*export function parse(input: string): ParserResult<AmlAst> {
    return parseRule(p => p.amlRule(), input)
}*/

function formatError(err: IRecognitionException): ParserError {
    const {offset, line, column} = parserInfo(err.token)
    return {kind: err.name, message: err.message, offset, line, column}
}

function parserInfo(token: IToken): TokenInfo {
    return {
        token: token.tokenType?.name || 'missing',
        offset: [token.startOffset, token.endOffset || 0],
        line: [token.startLine || 0, token.endLine || 0],
        column: [token.startColumn || 0, token.endColumn || 0]
    }
}
