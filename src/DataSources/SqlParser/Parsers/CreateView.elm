module DataSources.SqlParser.Parsers.CreateView exposing (ParsedView, parseView)

import DataSources.SqlParser.Parsers.Select exposing (SelectInfo, parseSelect)
import DataSources.SqlParser.Utils.Helpers exposing (buildRawSql, buildSchemaName, buildSqlLine, buildTableName)
import DataSources.SqlParser.Utils.Types exposing (ParseError, SqlSchemaName, SqlStatement, SqlTableName)
import Libs.Regex as Regex


type alias ParsedView =
    { schema : Maybe SqlSchemaName
    , table : SqlTableName
    , select : SelectInfo
    , materialized : Bool
    , extra : Maybe String
    }


parseView : SqlStatement -> Result (List ParseError) ParsedView
parseView statement =
    case statement |> buildSqlLine |> Regex.matches "^CREATE (MATERIALIZED )?VIEW\\s+(?:(?<schema>[^ .]+)\\.)?(?<table>[^ ]+)\\s+AS\\s+(?<select>.+?)(?:\\s+(?<extra>WITH (?:NO )?DATA))?;$" of
        materialized :: schema :: (Just table) :: (Just select) :: extra :: [] ->
            parseSelect select
                |> Result.map
                    (\parsedSelect ->
                        { schema = schema |> Maybe.map buildSchemaName
                        , table = table |> buildTableName
                        , select = parsedSelect
                        , materialized = not (materialized == Nothing)
                        , extra = extra
                        }
                    )

        _ ->
            Err [ "Can't parse create view: '" ++ buildRawSql statement ++ "'" ]
