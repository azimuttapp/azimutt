module DataSources.AmlParser.Parsers exposing (column, columnName, columnProps, columnRef, columnType, columnValue, comment, constraint, notes, properties, property, schemaName, table, tableName, tableProps, tableRef)

import DataSources.AmlParser.AmlParser exposing (AmlColumn, AmlColumnName, AmlColumnProps, AmlColumnRef, AmlColumnType, AmlColumnValue, AmlComment, AmlNotes, AmlSchemaName, AmlTable, AmlTableName, AmlTableProps, AmlTableRef)
import Dict exposing (Dict)
import Libs.Models.Position exposing (Position)
import Libs.Tailwind as Color exposing (Color)
import Parser exposing ((|.), (|=), Parser, Trailing(..), chompIf, chompWhile, getChompedString, oneOf, sequence, spaces, succeed, symbol)


table : Parser AmlTable
table =
    succeed
        (\ref props ntes coms cols ->
            { schema = ref.schema
            , table = ref.table
            , props = props
            , notes = ntes
            , comment = coms
            , columns = cols
            }
        )
        |. spaces
        |= tableRef
        |. spaces
        |= maybe (succeed identity |= tableProps |. spaces)
        |= maybe (succeed identity |= notes |. spaces)
        |= maybe (succeed identity |= comment |. spaces)
        |= columns
        |. spaces


columns : Parser (List AmlColumn)
columns =
    sequence
        { start = ""
        , separator = "\n"
        , end = ""
        , spaces = spaces
        , item = column
        , trailing = Forbidden
        }


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
        |= columnName
        |. spaces
        |= maybe columnType
        |. spaces
        |= maybe (succeed identity |. symbol "=" |= columnValue |. spaces)
        |= maybe (succeed identity |. oneOf [ symbol "nullable", symbol "NULLABLE" ] |. spaces)
        |= maybe (succeed identity |. oneOf [ symbol "pk", symbol "PK" ] |. spaces)
        |= maybe (succeed identity |= constraint "index" |. spaces)
        |= maybe (succeed identity |= constraint "unique" |. spaces)
        |= maybe (succeed identity |= constraint "check" |. spaces)
        |= maybe (succeed identity |. oneOf [ symbol "fk", symbol "FK" ] |. spaces |= columnRef |. spaces)
        |= maybe (succeed identity |= columnProps |. spaces)
        |= maybe (succeed identity |= notes |. spaces)
        |= maybe (succeed identity |= comment |. spaces)


constraint : String -> Parser String
constraint kind =
    succeed (\value -> value |> Maybe.withDefault "")
        |. oneOf [ symbol (kind |> String.toLower), symbol (kind |> String.toUpper) ]
        |. spaces
        |= maybe
            (succeed identity
                |. symbol "="
                |. spaces
                |= oneOf [ quoted '"' '"', until [ ' ' ] ]
            )


tableProps : Parser AmlTableProps
tableProps =
    properties
        |> Parser.map
            (\p ->
                let
                    position : Maybe Position
                    position =
                        Maybe.map2 (\left top -> { left = left, top = top })
                            (p |> Dict.get "left" |> Maybe.andThen String.toFloat)
                            (p |> Dict.get "top" |> Maybe.andThen String.toFloat)

                    color : Maybe Color
                    color =
                        p |> Dict.get "color" |> Maybe.andThen Color.from
                in
                { position = position, color = color }
            )


columnProps : Parser AmlColumnProps
columnProps =
    properties
        |> Parser.map
            (\p ->
                let
                    hidden : Bool
                    hidden =
                        p |> Dict.get "hidden" |> Maybe.map (\s -> s == "" || s == "true" || s == "yes" || s == "y" || s == "Y") |> Maybe.withDefault False
                in
                { hidden = hidden }
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
    oneOf [ quoted '"' '"', untilNonEmpty [ ' ', '.', '\n' ] ]


tableName : Parser AmlTableName
tableName =
    oneOf [ quoted '"' '"', untilNonEmpty [ ' ', '.', '\n' ] ]


columnName : Parser AmlColumnName
columnName =
    oneOf [ quoted '"' '"', untilNonEmpty [ ' ', '.', '\n' ] ]


columnType : Parser AmlColumnType
columnType =
    oneOf [ quoted '"' '"', untilNonEmpty [ ' ', '=', '\n' ] ]


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



-- utils


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
