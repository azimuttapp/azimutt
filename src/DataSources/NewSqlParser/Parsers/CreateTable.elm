module DataSources.NewSqlParser.Parsers.CreateTable exposing (columnParser, columnsParser, createTableParser)

import DataSources.NewSqlParser.Dsl exposing (ParsedColumn, ParsedTable)
import DataSources.NewSqlParser.Parsers.Basic exposing (columnNameParser, columnTypeParser, defaultValueParser, notNullParser, primaryKeyParser, tableRefParser)
import Parser exposing ((|.), (|=), Parser, Trailing(..), oneOf, sequence, spaces, succeed, symbol)



-- https://www.postgresql.org/docs/current/sql-createtable.html
-- https://dev.mysql.com/doc/refman/8.0/en/create-table.html
-- https://docs.microsoft.com/fr-fr/sql/t-sql/statements/create-table-transact-sql
-- https://docs.oracle.com/en/database/oracle/oracle-database/21/sqlrf/CREATE-TABLE.html
-- https://www.sqlite.org/lang_createtable.html


createTableParser : Parser ParsedTable
createTableParser =
    succeed (\( schemaName, tableName ) columns -> ParsedTable schemaName tableName columns)
        |. symbol "CREATE TABLE"
        |. spaces
        |. oneOf
            [ symbol "IF NOT EXISTS"
            , succeed ()
            ]
        |. spaces
        |= tableRefParser
        |. spaces
        |= columnsParser


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
    succeed (\name kind nullable primaryKey default -> ParsedColumn name kind nullable default primaryKey Nothing Nothing)
        |= columnNameParser
        |. spaces
        |= columnTypeParser
        |. spaces
        |= notNullParser
        |. spaces
        |= primaryKeyParser
        |. spaces
        |= defaultValueParser
