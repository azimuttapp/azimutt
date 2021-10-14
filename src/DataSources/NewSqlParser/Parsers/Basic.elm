module DataSources.NewSqlParser.Parsers.Basic exposing (columnNameParser, columnTypeParser, defaultValueParser, notNullParser, primaryKeyParser, schemaNameParser, tableNameParser, tableRefParser)

import Libs.Parser exposing (getWhile, identifier, notSpace, quotedParser)
import Parser exposing ((|.), (|=), Parser, int, oneOf, spaces, succeed, symbol)



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
    identifier


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
        [ customColumnTypeParser "bit varying" number
        , customColumnTypeParser "character varying" number
        , customColumnTypeParser "double precision" nothing
        , customColumnTypeParser "numeric" numbers
        , identifier
        ]


customColumnTypeParser : String -> Parser String -> Parser String
customColumnTypeParser name parser =
    succeed (\value -> name ++ value)
        |. symbol name
        |= parser


nothing : Parser String
nothing =
    succeed ""


number : Parser String
number =
    succeed (\size -> "(" ++ String.fromInt size ++ ")")
        |. spaces
        |. symbol "("
        |. spaces
        |= int
        |. spaces
        |. symbol ")"


numbers : Parser String
numbers =
    succeed (\p s -> "(" ++ String.fromInt p ++ ", " ++ String.fromInt s ++ ")")
        |. spaces
        |. symbol "("
        |. spaces
        |= int
        |. spaces
        |. symbol ","
        |. spaces
        |= int
        |. spaces
        |. symbol ")"


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


defaultValueParser : Parser (Maybe String)
defaultValueParser =
    oneOf
        [ succeed (\value kind -> Just (value ++ (kind |> Maybe.map (\k -> "::" ++ k) |> Maybe.withDefault "")))
            |. symbol "DEFAULT"
            |. spaces
            |= oneOf
                [ quotedParser '\'' '\''
                , identifier
                ]
            |= oneOf
                [ succeed (\t -> Just t)
                    |. symbol "::"
                    |= getWhile Char.isAlpha notSpace
                , succeed
                    Nothing
                ]
        , succeed Nothing
        ]
