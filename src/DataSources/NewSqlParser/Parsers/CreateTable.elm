module DataSources.NewSqlParser.Parsers.CreateTable exposing (createTableParser)

import DataSources.NewSqlParser.Utils.Types exposing (ParsedColumn, ParsedTable)
import Parser exposing ((|.), (|=), Parser, Trailing(..), chompIf, chompWhile, getChompedString, oneOf, sequence, spaces, succeed, symbol)



-- https://www.postgresql.org/docs/current/sql-createtable.html
-- https://dev.mysql.com/doc/refman/8.0/en/create-table.html
-- https://docs.microsoft.com/fr-fr/sql/t-sql/statements/create-table-transact-sql
-- https://docs.oracle.com/en/database/oracle/oracle-database/21/sqlrf/CREATE-TABLE.html
-- https://www.sqlite.org/lang_createtable.html


createTableParser : Parser ParsedTable
createTableParser =
    succeed (\schemaName tableName columns -> ParsedTable schemaName tableName columns)
        |. symbol "CREATE TABLE"
        |. spaces
        |. oneOf
            [ symbol "IF NOT EXISTS"
            , succeed ()
            ]
        |. spaces
        |= oneOf
            [ succeed Just
                |= schemaNameParser
                |. symbol "."
            , succeed Nothing
            ]
        |= tableNameParser
        |. spaces
        |= columnsParser


schemaNameParser : Parser String
schemaNameParser =
    getChompedString <|
        succeed ()
            |. chompIf Char.isAlpha
            |. chompWhile (\c -> c /= '.')


tableNameParser : Parser String
tableNameParser =
    getChompedString <|
        succeed ()
            |. chompIf Char.isAlpha
            |. chompWhile (\c -> notSpace c && c /= '(')


columnsParser : Parser (List ParsedColumn)
columnsParser =
    sequence
        { start = "("
        , separator = ","
        , end = ")"
        , spaces = spaces
        , item = columnParser
        , trailing = Forbidden
        }


columnParser : Parser ParsedColumn
columnParser =
    succeed (\name kind nullable primaryKey -> ParsedColumn name kind nullable Nothing primaryKey Nothing Nothing)
        |= columnNameParser
        |. spaces
        |= columnTypeParser
        |. spaces
        |= oneOf
            [ succeed False
                |. symbol "NOT NULL"
            , succeed True
            ]
        |. spaces
        |= oneOf
            [ succeed (Just "")
                |. symbol "PRIMARY KEY"
            , succeed Nothing
            ]


columnNameParser : Parser String
columnNameParser =
    oneOf
        [ quotedParser '`' '`'
        , quotedParser '\'' '\''
        , quotedParser '"' '"'
        , quotedParser '[' ']'
        , getChompedString <|
            succeed ()
                |. chompIf Char.isAlpha
                |. chompWhile (\c -> notSpace c && c /= '(')
        ]


columnTypeParser : Parser String
columnTypeParser =
    getChompedString <|
        succeed ()
            |. chompIf Char.isAlpha
            |. chompWhile notSpace


quotedParser : Char -> Char -> Parser String
quotedParser first last =
    succeed identity
        |. chompIf (\c -> c == first)
        |= getChompedString
            (succeed ()
                |. chompIf (\c -> c /= last)
                |. chompWhile (\c -> c /= last)
            )
        |. chompIf (\c -> c == last)


isSpace : Char -> Bool
isSpace c =
    c == ' ' || c == '\n' || c == '\u{000D}'


notSpace : Char -> Bool
notSpace c =
    not (isSpace c)
