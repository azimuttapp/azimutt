module DataSources.NewSqlParser.Parsers.Basic exposing (checkParser, columnNameParser, columnTypeParser, constraintParser, defaultValueParser, foreignKeyParser, foreignKeyRefParser, notNullParser, primaryKeyParser, schemaNameParser, tableNameParser, tableRefParser)

import DataSources.NewSqlParser.Dsl exposing (ColumnConstraint(..), ForeignKeyRef)
import Libs.Parser exposing (exists, identifierOrQuoted, maybe, symbolInsensitive)
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
        |= identifierOrQuoted
        |= maybe
            (succeed identity
                |. symbol "."
                |= identifierOrQuoted
            )


schemaNameParser : Parser String
schemaNameParser =
    identifierOrQuoted


tableNameParser : Parser String
tableNameParser =
    identifierOrQuoted


columnNameParser : Parser String
columnNameParser =
    identifierOrQuoted


columnTypeParser : Parser String
columnTypeParser =
    -- cf https://www.postgresql.org/docs/current/datatype.html
    oneOf
        [ customColumnTypeParser "BIT VARYING" (maybe numbers |> Parser.map (Maybe.withDefault ""))
        , customColumnTypeParser "CHARACTER VARYING" (maybe numbers |> Parser.map (Maybe.withDefault ""))
        , customColumnTypeParser "DOUBLE PRECISION" nothing
        , customColumnTypeParser "INT IDENTITY" (maybe numbers |> Parser.map (Maybe.withDefault ""))
        , succeed (\name nums -> name ++ nums)
            |= identifierOrQuoted
            |. spaces
            |= (maybe numbers |> Parser.map (Maybe.withDefault ""))
        ]


customColumnTypeParser : String -> Parser String -> Parser String
customColumnTypeParser name parser =
    succeed (\kind value -> kind ++ value)
        |= symbolInsensitive name
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
    exists (symbolInsensitive "NOT NULL") |> Parser.map not


defaultValueParser : Parser (Maybe String)
defaultValueParser =
    oneOf
        [ succeed (\value kind -> Just (value ++ (kind |> Maybe.withDefault "")))
            |. symbolInsensitive "DEFAULT"
            |. spaces
            |= (identifierOrQuoted |> getChompedString)
            |= oneOf
                [ succeed (\t -> Just ("::" ++ t))
                    |. symbol "::"
                    |= columnTypeParser
                , succeed
                    Nothing
                ]
        , succeed Nothing
        ]


primaryKeyParser : Parser (Maybe String)
primaryKeyParser =
    maybe (succeed "" |. symbolInsensitive "PRIMARY KEY")


checkParser : Parser (Maybe String)
checkParser =
    oneOf
        [ succeed (\str -> str |> String.dropLeft 1 |> String.dropRight 1 |> Just)
            |. symbolInsensitive "CHECK"
            |. spaces
            |= (multiComment "(" ")" Nestable |> getChompedString)
        , succeed Nothing
        ]


constraintParser : Parser (Maybe ( String, ColumnConstraint ))
constraintParser =
    maybe
        (succeed (\name constraint -> ( name, constraint ))
            |. symbolInsensitive "CONSTRAINT"
            |. spaces
            |= identifierOrQuoted
            |. spaces
            |= oneOf
                [ succeed ColumnPrimaryKey |. symbolInsensitive "PRIMARY KEY"
                , foreignKeyParser |> Parser.map ColumnForeignKey
                ]
        )


foreignKeyParser : Parser ForeignKeyRef
foreignKeyParser =
    succeed identity
        |. symbolInsensitive "REFERENCES"
        |. spaces
        |= foreignKeyRefParser


foreignKeyRefParser : Parser ForeignKeyRef
foreignKeyRefParser =
    oneOf
        [ backtrackable <|
            succeed (\schema table column -> ForeignKeyRef (Just schema) table (Just column))
                |= identifierOrQuoted
                |. symbol "."
                |= identifierOrQuoted
                |. symbol "."
                |= identifierOrQuoted
        , backtrackable <|
            succeed (\table column -> ForeignKeyRef Nothing table (Just column))
                |= identifierOrQuoted
                |. symbol "."
                |= identifierOrQuoted
        , succeed (\table -> ForeignKeyRef Nothing table Nothing) |= identifierOrQuoted
        ]
