module DataSources.SqlParser.Parsers.CreateView exposing (ParsedView, parseView)

import DataSources.SqlParser.Parsers.Select exposing (SelectInfo, parseSelect)
import DataSources.SqlParser.Utils.Helpers exposing (buildRawSql)
import DataSources.SqlParser.Utils.Types exposing (ParseError, SqlSchemaName, SqlStatement, SqlTableName)
import Libs.Regex as R


type alias ParsedView =
    { schema : Maybe SqlSchemaName
    , table : SqlTableName
    , select : SelectInfo
    , materialized : Bool
    , extra : Maybe String
    , source : SqlStatement
    }


parseView : SqlStatement -> Result (List ParseError) ParsedView
parseView statement =
    case statement |> buildRawSql |> R.matches "^CREATE (MATERIALIZED )?VIEW[ \t]+(?:(?<schema>[^ .]+)\\.)?(?<table>[^ ]+)[ \t]+AS[ \t]+(?<select>.+?)(?:[ \t]+(?<extra>WITH (?:NO )?DATA))?;$" of
        materialized :: schema :: (Just table) :: (Just select) :: extra :: [] ->
            parseSelect select
                |> Result.map
                    (\parsedSelect ->
                        { schema = schema
                        , table = table
                        , select = parsedSelect
                        , materialized = not (materialized == Nothing)
                        , extra = extra
                        , source = statement
                        }
                    )

        _ ->
            Err [ "Can't parse create view: '" ++ buildRawSql statement ++ "'" ]
