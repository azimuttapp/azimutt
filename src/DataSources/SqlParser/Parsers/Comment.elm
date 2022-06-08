module DataSources.SqlParser.Parsers.Comment exposing (CommentOnColumn, CommentOnTable, parseColumnComment, parseTableComment)

import DataSources.SqlParser.Utils.Helpers exposing (buildColumnName, buildComment, buildRawSql, buildSchemaName, buildSqlLine, buildTableName)
import DataSources.SqlParser.Utils.Types exposing (ParseError, SqlColumnName, SqlComment, SqlSchemaName, SqlStatement, SqlTableName)
import Libs.Regex as Regex


type alias CommentOnTable =
    { schema : Maybe SqlSchemaName, table : SqlTableName, comment : SqlComment }


type alias CommentOnColumn =
    { schema : Maybe SqlSchemaName, table : SqlTableName, column : SqlColumnName, comment : SqlComment }


parseTableComment : SqlStatement -> Result (List ParseError) CommentOnTable
parseTableComment statement =
    case statement |> buildSqlLine |> Regex.matches "^COMMENT ON (?:TABLE|VIEW)\\s+(?:(?<schema>[^ .]+)\\.)?(?<table>[^ .]+)\\s+IS\\s+'(?<comment>(?:[^']|'')+)';$" of
        schema :: (Just table) :: (Just comment) :: [] ->
            Ok { schema = schema |> Maybe.map buildSchemaName, table = table |> buildTableName, comment = comment |> buildComment }

        _ ->
            Err [ "Can't parse table comment: '" ++ buildRawSql statement ++ "'" ]


parseColumnComment : SqlStatement -> Result (List ParseError) CommentOnColumn
parseColumnComment statement =
    case statement |> buildSqlLine |> Regex.matches "^COMMENT ON COLUMN\\s+(?:(?<schema>[^ .]+)\\.)?(?<table>[^ .]+)\\.(?<column>[^ .]+)\\s+IS\\s+'(?<comment>(?:[^']|'')+)';$" of
        schema :: (Just table) :: (Just column) :: (Just comment) :: [] ->
            Ok { schema = schema |> Maybe.map buildSchemaName, table = table |> buildTableName, column = column |> buildColumnName, comment = comment |> buildComment }

        _ ->
            Err [ "Can't parse column comment: '" ++ buildRawSql statement ++ "'" ]
