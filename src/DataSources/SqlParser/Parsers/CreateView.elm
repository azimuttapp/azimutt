module DataSources.SqlParser.Parsers.CreateView exposing (ParsedView, parseView)

import DataSources.SqlParser.Parsers.Select exposing (SelectInfo, parseSelect)
import DataSources.SqlParser.Utils.Helpers exposing (buildRawSql, buildSchemaName, buildSqlLine, buildTableName)
import DataSources.SqlParser.Utils.Types exposing (ParseError, SqlSchemaName, SqlStatement, SqlTableName)
import Libs.Regex as Regex


type alias ParsedView =
    { schema : Maybe SqlSchemaName
    , table : SqlTableName
    , select : SelectInfo
    , replace : Bool
    , materialized : Bool
    , extra : Maybe String
    }


parseView : SqlStatement -> Result (List ParseError) ParsedView
parseView statement =
    case statement |> buildSqlLine |> Regex.matches "^CREATE( OR REPLACE)?( MATERIALIZED)? VIEW\\s+(?:(?<schema>[^ .]+)\\.)?(?<table>[^ ]+)(?:\\s+WITH .*)?\\s+AS(?:\\s+WITH .*)?\\s+(?<select>SELECT .+?)(?:\\s+(?<extra>WITH (?:NO )?DATA))?;$" of
        replace :: materialized :: schema :: (Just table) :: (Just select) :: extra :: [] ->
            Ok
                { schema = schema |> Maybe.map buildSchemaName
                , table = table |> buildTableName

                -- FIXME: allow to send warnings along with the result
                , select = parseSelect select |> Result.withDefault { columns = [], tables = [], whereClause = Nothing }
                , replace = not (replace == Nothing)
                , materialized = not (materialized == Nothing)
                , extra = extra
                }

        _ ->
            Err [ "Can't parse create view: '" ++ buildRawSql statement ++ "'" ]
