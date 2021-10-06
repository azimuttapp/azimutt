module DataSources.NewSqlParser.Parsers.CreateTable exposing (parseCreateTable)

import DataSources.NewSqlParser.Utils.Types exposing (ParseError, ParsedTable, SqlStatement)



-- https://www.postgresql.org/docs/current/sql-createtable.html
-- https://dev.mysql.com/doc/refman/8.0/en/create-table.html
-- https://docs.microsoft.com/fr-fr/sql/t-sql/statements/create-table-transact-sql
-- https://docs.oracle.com/en/database/oracle/oracle-database/21/sqlrf/CREATE-TABLE.html
-- https://www.sqlite.org/lang_createtable.html


parseCreateTable : SqlStatement -> Result (List ParseError) ParsedTable
parseCreateTable statement =
    Err []
