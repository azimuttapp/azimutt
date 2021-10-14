module DataSources.NewSqlParser.Parsers.Basic exposing (checkParser, columnNameParser, columnTypeParser, constraintParser, defaultValueParser, foreignKeyParser, foreignKeyRefParser, notNullParser, primaryKeyParser, schemaNameParser, tableNameParser, tableRefParser)

import DataSources.NewSqlParser.Dsl exposing (ColumnConstraint(..), ForeignKeyRef)
import Libs.Parser exposing (identifier, quotedParser, quotedParserKeep, symbolInsensitive)
import Parser exposing ((|.), (|=), Nestable(..), Parser, Trailing(..), backtrackable, getChompedString, int, multiComment, oneOf, sequence, spaces, succeed, symbol)



-- reusable (small) building blocks for bigger parsers


tableRefParser : Parser ( Maybe String, String )
tableRefParser =
    succeed
        (\schemaName tableName ->
            case ( schemaName, tableName ) of
                ( part1, Nothing ) ->
                    ( Nothing, part1 )

                ( part1, Just part2 ) ->
                    ( Just part1, part2 )
        )
        |= schemaNameParser
        |= oneOf
            [ succeed Just
                |. symbol "."
                |= tableNameParser
            , succeed Nothing
            ]


schemaNameParser : Parser String
schemaNameParser =
    oneOf
        [ quotedParser '[' ']'
        , identifier
        ]


tableNameParser : Parser String
tableNameParser =
    oneOf
        [ quotedParser '[' ']'
        , identifier
        ]


columnNameParser : Parser String
columnNameParser =
    oneOf
        [ quotedParser '`' '`'
        , quotedParser '\'' '\''
        , quotedParser '"' '"'
        , quotedParser '[' ']'
        , identifier
        ]


columnTypeParser : Parser String
columnTypeParser =
    -- cf https://www.postgresql.org/docs/current/datatype.html
    oneOf
        [ customColumnTypeParser "bit varying" numbers
        , customColumnTypeParser "character varying" (oneOf [ numbers, nothing ])
        , customColumnTypeParser "double precision" nothing
        , customColumnTypeParser "int identity" numbers
        , succeed (\name nums -> name ++ nums)
            |= identifier
            |. spaces
            |= oneOf [ numbers, nothing ]
        ]


customColumnTypeParser : String -> Parser String -> Parser String
customColumnTypeParser name parser =
    succeed (\value -> name ++ value)
        |. symbol name
        |. spaces
        |= parser


numbers : Parser String
numbers =
    Parser.map (\nums -> "(" ++ (nums |> List.map String.fromInt |> String.join ",") ++ ")")
        (sequence
            { start = "("
            , separator = ","
            , end = ")"
            , spaces = spaces
            , item = int
            , trailing = Forbidden
            }
        )


nothing : Parser String
nothing =
    succeed ""


notNullParser : Parser Bool
notNullParser =
    oneOf
        [ succeed False
            |. symbol "NOT NULL"
        , succeed True
        ]


primaryKeyParser : Parser (Maybe String)
primaryKeyParser =
    oneOf
        [ succeed (Just "")
            |. symbol "PRIMARY KEY"
        , succeed Nothing
        ]


constraintParser : Parser (Maybe ( String, ColumnConstraint ))
constraintParser =
    oneOf
        [ succeed (\name constraint -> Just ( name, constraint ))
            |. symbol "CONSTRAINT"
            |. spaces
            |= identifier
            |. spaces
            |= oneOf
                [ succeed ColumnPrimaryKey |. symbol "PRIMARY KEY"
                , foreignKeyParser |> Parser.map ColumnForeignKey
                ]
        , succeed Nothing
        ]


foreignKeyParser : Parser ForeignKeyRef
foreignKeyParser =
    succeed identity
        |. symbol "REFERENCES"
        |. spaces
        |= foreignKeyRefParser


foreignKeyRefParser : Parser ForeignKeyRef
foreignKeyRefParser =
    oneOf
        [ backtrackable <|
            succeed (\schema table column -> ForeignKeyRef (Just schema) table (Just column))
                |= identifier
                |. symbol "."
                |= identifier
                |. symbol "."
                |= identifier
        , backtrackable <|
            succeed (\table column -> ForeignKeyRef Nothing table (Just column))
                |= identifier
                |. symbol "."
                |= identifier
        , succeed (\table -> ForeignKeyRef Nothing table Nothing) |= identifier
        ]


checkParser : Parser (Maybe String)
checkParser =
    oneOf
        [ succeed (\str -> str |> String.dropLeft 1 |> String.dropRight 1 |> Just)
            |. symbolInsensitive "CHECK"
            |. spaces
            |= (getChompedString <|
                    multiComment "(" ")" Nestable
               )
        , succeed Nothing
        ]


defaultValueParser : Parser (Maybe String)
defaultValueParser =
    oneOf
        [ succeed (\value kind -> Just (value ++ (kind |> Maybe.withDefault "")))
            |. symbolInsensitive "DEFAULT"
            |. spaces
            |= oneOf
                [ quotedParserKeep '\'' '\''
                , identifier
                ]
            |= oneOf
                [ succeed (\t -> Just ("::" ++ t))
                    |. symbol "::"
                    |= columnTypeParser
                , succeed
                    Nothing
                ]
        , succeed Nothing
        ]
