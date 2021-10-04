module DataSources.NewSqlParser.Parsers.CreateTable exposing (parseCreateTable)

import DataSources.NewSqlParser.Utils.Types exposing (ParseError, ParsedTable, SqlStatement)


parseCreateTable : SqlStatement -> Result (List ParseError) ParsedTable
parseCreateTable statement =
    Err []
