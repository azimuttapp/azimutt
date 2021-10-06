module DataSources.NewSqlParser.Parsers.CreateTable exposing (createTableParser)

import DataSources.NewSqlParser.Utils.Types exposing (ParseError, ParsedColumn, ParsedTable, SqlStatement)
import Parser exposing ((|.), (|=), Parser, Trailing(..), chompIf, chompWhile, getChompedString, sequence, spaces, succeed, symbol)



-- https://www.postgresql.org/docs/current/sql-createtable.html
-- https://dev.mysql.com/doc/refman/8.0/en/create-table.html
-- https://docs.microsoft.com/fr-fr/sql/t-sql/statements/create-table-transact-sql
-- https://docs.oracle.com/en/database/oracle/oracle-database/21/sqlrf/CREATE-TABLE.html
-- https://www.sqlite.org/lang_createtable.html


createTableParser : Parser ParsedTable
createTableParser =
    succeed (\tableName columns -> ParsedTable Nothing tableName columns)
        |. symbol "CREATE TABLE"
        |. spaces
        |= tableNameParser
        |. spaces
        |= parseColumns


tableNameParser : Parser String
tableNameParser =
    getChompedString <|
        succeed ()
            |. chompIf Char.isAlpha
            |. chompWhile (\c -> c /= ' ' && c /= '(')


parseColumns : Parser (List ParsedColumn)
parseColumns =
    sequence
        { start = "("
        , separator = ","
        , end = ")"
        , spaces = spaces
        , item = parseColumn
        , trailing = Forbidden -- demand a trailing semi-colon
        }


parseColumn : Parser ParsedColumn
parseColumn =
    succeed (\name kind -> ParsedColumn name kind True Nothing Nothing Nothing Nothing)
        |= columnName
        |. spaces
        |= columnType


columnName : Parser String
columnName =
    getChompedString <|
        succeed ()
            |. chompIf Char.isAlpha
            |. chompWhile (\c -> c /= ' ' && c /= '(')


columnType : Parser String
columnType =
    getChompedString <|
        succeed ()
            |. chompIf Char.isAlpha
            |. chompWhile (\c -> c /= ' ' && c /= ',' && c /= '\n')
