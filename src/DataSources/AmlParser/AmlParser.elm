module DataSources.AmlParser.AmlParser exposing (AmlColumn, AmlColumnName, AmlColumnProps, AmlColumnRef, AmlColumnType, AmlColumnValue, AmlComment, AmlEmpty, AmlNotes, AmlRelation, AmlSchemaName, AmlStatement(..), AmlTable, AmlTableName, AmlTableProps, AmlTableRef, aml, column, columnName, columnProps, columnRef, columnType, columnValue, comment, constraint, empty, notes, parse, properties, property, relation, schemaName, statement, table, tableName, tableProps, tableRef)

import Dict exposing (Dict)
import Libs.Models.Position exposing (Position)
import Libs.Tailwind as Color exposing (Color)
import Parser exposing ((|.), (|=), DeadEnd, Parser, Step(..), Trailing(..), chompIf, chompWhile, end, getChompedString, loop, oneOf, problem, sequence, succeed, symbol, variable)
import Set



-- specs from https://azimutt.app/blog/aml-a-language-to-define-your-database-schema


type AmlStatement
    = AmlTableStatement AmlTable
    | AmlRelationStatement AmlRelation
    | AmlEmptyStatement AmlEmpty


type alias AmlEmpty =
    { comment : Maybe AmlComment }


type alias AmlRelation =
    { from : AmlColumnRef, to : AmlColumnRef, comment : Maybe AmlComment }


type alias AmlTable =
    { schema : Maybe AmlSchemaName
    , table : AmlTableName
    , isView : Bool
    , props : Maybe AmlTableProps
    , notes : Maybe AmlNotes
    , comment : Maybe AmlComment
    , columns : List AmlColumn
    }


type alias AmlTableProps =
    { position : Maybe Position, color : Maybe Color }


type alias AmlColumn =
    { name : AmlColumnName
    , kind : Maybe AmlColumnType
    , default : Maybe AmlColumnValue
    , nullable : Bool
    , primaryKey : Bool
    , index : Maybe String
    , unique : Maybe String
    , check : Maybe String
    , foreignKey : Maybe AmlColumnRef
    , props : Maybe AmlColumnProps
    , notes : Maybe AmlNotes
    , comment : Maybe AmlComment
    }


type alias AmlColumnProps =
    { hidden : Bool }


type alias AmlTableRef =
    { schema : Maybe AmlSchemaName, table : AmlTableName }


type alias AmlColumnRef =
    { schema : Maybe AmlSchemaName, table : AmlTableName, column : AmlColumnName }


type alias AmlSchemaName =
    String


type alias AmlTableName =
    String


type alias AmlColumnName =
    String


type alias AmlColumnType =
    String


type alias AmlColumnValue =
    String


type alias AmlNotes =
    String


type alias AmlComment =
    String


parse : String -> Result (List DeadEnd) (List AmlStatement)
parse input =
    input |> Parser.run aml


aml : Parser (List AmlStatement)
aml =
    succeed identity
        |= list statement
        |. end


statement : Parser AmlStatement
statement =
    oneOf
        [ empty |> Parser.map AmlEmptyStatement
        , relation |> Parser.map AmlRelationStatement
        , table |> Parser.map AmlTableStatement
        ]


empty : Parser AmlEmpty
empty =
    succeed (\coms -> { comment = coms })
        |= maybe (succeed identity |= comment |. spaces)
        |. endOfLine


relation : Parser AmlRelation
relation =
    succeed (\from to coms -> { from = from, to = to, comment = coms })
        |. symbolI "fk"
        |. spaces
        |= columnRef
        |. spaces
        |. symbol "->"
        |. spaces
        |= columnRef
        |. spaces
        |= maybe (succeed identity |= comment |. spaces)
        |. endOfLine


table : Parser AmlTable
table =
    succeed
        (\ref view props ntes coms cols ->
            { schema = ref.schema
            , table = ref.table
            , isView = view /= Nothing
            , props = props
            , notes = ntes
            , comment = coms
            , columns = cols
            }
        )
        |. spaces
        |= tableRef
        |= maybe (succeed identity |. symbol "*" |. spaces)
        |. spaces
        |= maybe (succeed identity |= tableProps |. spaces)
        |= maybe (succeed identity |= notes |. spaces)
        |= maybe (succeed identity |= comment |. spaces)
        |. endOfLine
        |= list column


column : Parser AmlColumn
column =
    succeed
        (\name kind default nullable pk idx unq chk fk props ntes coms ->
            { name = name
            , kind = kind
            , default = default
            , nullable = nullable /= Nothing
            , primaryKey = pk /= Nothing
            , index = idx
            , unique = unq
            , check = chk
            , foreignKey = fk
            , props = props
            , notes = ntes
            , comment = coms
            }
        )
        |. symbol "  "
        |= columnName
        |. spaces
        |= maybe (succeed identity |= columnType |. spaces)
        |= maybe (succeed identity |. symbol "=" |= columnValue |. spaces)
        |= maybe (succeed identity |. symbolI "nullable" |. spaces)
        |= maybe (succeed identity |. symbolI "pk" |. spaces)
        |= maybe (succeed identity |= constraint "index" |. spaces)
        |= maybe (succeed identity |= constraint "unique" |. spaces)
        |= maybe (succeed identity |= constraint "check" |. spaces)
        |= maybe (succeed identity |. symbolI "fk" |. spaces |= columnRef |. spaces)
        |= maybe (succeed identity |= columnProps |. spaces)
        |= maybe (succeed identity |= notes |. spaces)
        |= maybe (succeed identity |= comment |. spaces)
        |. endOfLine


constraint : String -> Parser String
constraint kind =
    succeed (\value -> value |> Maybe.withDefault "")
        |. symbolI kind
        |. spaces
        |= maybe
            (succeed identity
                |. symbol "="
                |. spaces
                |= oneOf [ quoted '"' '"', until [ ' ', '\n' ] ]
            )


tableProps : Parser AmlTableProps
tableProps =
    properties
        |> Parser.andThen
            (\p ->
                p
                    |> Dict.foldl
                        (\k v acc ->
                            case k of
                                "color" ->
                                    Color.from v
                                        |> Maybe.map (\c -> acc |> Parser.map (\a -> { a | color = Just c }))
                                        |> Maybe.withDefault (problem ("Unknown color '" ++ v ++ "'"))

                                "left" ->
                                    case ( v |> String.toFloat, p |> Dict.get "top" |> Maybe.map String.toFloat ) of
                                        ( Just left, Just (Just top) ) ->
                                            acc |> Parser.map (\a -> { a | position = Just { left = left, top = top } })

                                        ( Nothing, _ ) ->
                                            problem "Table property 'left' should be a number"

                                        ( _, Just Nothing ) ->
                                            problem "Table property 'top' should be a number"

                                        ( _, Nothing ) ->
                                            problem "Missing table property 'top'"

                                "top" ->
                                    case ( p |> Dict.get "left" |> Maybe.map String.toFloat, v |> String.toFloat ) of
                                        ( Just (Just left), Just top ) ->
                                            acc |> Parser.map (\a -> { a | position = Just { left = left, top = top } })

                                        ( _, Nothing ) ->
                                            problem "Table property 'top' should be a number"

                                        ( Just Nothing, _ ) ->
                                            problem "Table property 'left' should be a number"

                                        ( Nothing, _ ) ->
                                            problem "Missing table property 'left'"

                                _ ->
                                    problem ("Unknown table property '" ++ k ++ "'")
                        )
                        (succeed { color = Nothing, position = Nothing })
            )


columnProps : Parser AmlColumnProps
columnProps =
    properties
        |> Parser.andThen
            (Dict.foldl
                (\k v acc ->
                    case k of
                        "hidden" ->
                            if v == "" then
                                acc |> Parser.map (\a -> { a | hidden = True })

                            else
                                problem "Column property 'hidden' should not have a value"

                        _ ->
                            problem ("Unknown column property '" ++ k ++ "'")
                )
                (succeed { hidden = False })
            )


properties : Parser (Dict String String)
properties =
    sequence
        { start = "{"
        , separator = ","
        , end = "}"
        , spaces = spaces
        , item = property
        , trailing = Forbidden
        }
        |> Parser.map Dict.fromList


property : Parser ( String, String )
property =
    succeed (\key value -> ( key, value |> Maybe.withDefault "" ))
        |= oneOf [ quoted '"' '"', untilNonEmpty [ ' ', '=', ',', '}' ] ]
        |. spaces
        |= maybe
            (succeed identity
                |. symbol "="
                |. spaces
                |= oneOf [ quoted '"' '"', until [ ' ', ',', '}' ] ]
            )


tableRef : Parser AmlTableRef
tableRef =
    succeed
        (\schema tbl ->
            case tbl of
                Just t ->
                    { schema = Just schema, table = t }

                Nothing ->
                    { schema = Nothing, table = schema }
        )
        |= schemaName
        |= maybe
            (succeed identity
                |. symbol "."
                |= tableName
            )


columnRef : Parser AmlColumnRef
columnRef =
    succeed
        (\schema tbl col ->
            case col of
                Just c ->
                    { schema = Just schema, table = tbl, column = c }

                Nothing ->
                    { schema = Nothing, table = schema, column = tbl }
        )
        |= schemaName
        |. symbol "."
        |= tableName
        |= maybe
            (succeed identity
                |. symbol "."
                |= columnName
            )


schemaName : Parser AmlSchemaName
schemaName =
    oneOf [ quoted '"' '"', untilNonEmpty [ ' ', '.', '*', '\n' ] ]


tableName : Parser AmlTableName
tableName =
    oneOf [ quoted '"' '"', untilNonEmpty [ ' ', '.', '*', '\n' ] ]


columnName : Parser AmlColumnName
columnName =
    oneOf [ quoted '"' '"', untilNonEmpty [ ' ', '.', '\n' ] ]


columnType : Parser AmlColumnType
columnType =
    oneOf
        [ quoted '"' '"'
        , variable
            { start = \c -> [ '=', ' ', '\n', '{', '|', '#' ] |> List.member c |> not
            , inner = \c -> [ '=', ' ', '\n' ] |> List.member c |> not
            , reserved = Set.fromList [ "nullable", "NULLABLE", "pk", "PK", "index", "INDEX", "unique", "UNIQUE", "check", "CHECK", "fk", "FK" ]
            }
        ]


columnValue : Parser AmlColumnValue
columnValue =
    oneOf [ quoted '"' '"', untilNonEmpty [ ' ', '\n' ] ]


notes : Parser AmlNotes
notes =
    succeed String.trim
        |. symbol "|"
        |. spaces
        |= oneOf [ quoted '"' '"', until [ '#', '\n' ] ]


comment : Parser AmlComment
comment =
    succeed String.trim
        |. symbol "#"
        |. spaces
        |= oneOf [ quoted '"' '"', until [ '\n' ] ]



-- UTILS


symbolI : String -> Parser ()
symbolI s =
    oneOf [ symbol (s |> String.toLower), symbol (s |> String.toUpper) ]


endOfLine : Parser ()
endOfLine =
    symbol "\n"


spaces : Parser ()
spaces =
    chompWhile (\c -> c == ' ')


quoted : Char -> Char -> Parser String
quoted first last =
    succeed identity
        |. chompIf (\c -> c == first)
        |= until [ last ]
        |. chompIf (\c -> c == last)


until : List Char -> Parser String
until stop =
    chompWhile (\c -> stop |> List.all (\s -> s /= c))
        |> getChompedString


untilNonEmpty : List Char -> Parser String
untilNonEmpty stop =
    succeed (\first others -> first ++ others)
        |= (chompIf (\c -> stop |> List.all (\s -> s /= c)) |> getChompedString)
        |= (chompWhile (\c -> stop |> List.all (\s -> s /= c)) |> getChompedString)


maybe : Parser a -> Parser (Maybe a)
maybe p =
    oneOf
        [ succeed Just |= p
        , succeed Nothing
        ]


list : Parser a -> Parser (List a)
list p =
    loop [] (listHelp p)


listHelp : Parser a -> List a -> Parser (Step (List a) (List a))
listHelp p revList =
    oneOf
        [ succeed (\col -> Loop (col :: revList)) |= p
        , succeed () |> Parser.map (\_ -> Done (List.reverse revList))
        ]
