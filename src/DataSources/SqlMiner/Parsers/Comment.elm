module DataSources.SqlMiner.Parsers.Comment exposing (CommentOnColumn, CommentOnConstraint, CommentOnTable, parseColumnComment, parseColumnConstraint, parseTableComment)

import DataSources.SqlMiner.Utils.Helpers exposing (buildColumnName, buildComment, buildConstraintName, buildRawSql, buildSchemaName, buildSqlLine, buildTableName)
import DataSources.SqlMiner.Utils.Types exposing (ParseError, SqlColumnName, SqlComment, SqlConstraintName, SqlSchemaName, SqlStatement, SqlTableName)
import Libs.Regex as Regex


type alias CommentOnTable =
    { schema : Maybe SqlSchemaName, table : SqlTableName, comment : SqlComment }


type alias CommentOnColumn =
    { schema : Maybe SqlSchemaName, table : SqlTableName, column : SqlColumnName, comment : SqlComment }


type alias CommentOnConstraint =
    { schema : Maybe SqlSchemaName, table : SqlTableName, constraint : SqlConstraintName, comment : SqlComment }


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


parseColumnConstraint : SqlStatement -> Result (List ParseError) CommentOnConstraint
parseColumnConstraint statement =
    case statement |> buildSqlLine |> Regex.matches "^COMMENT ON CONSTRAINT\\s+(?<constraint>[^ ]+)\\s+ON\\s+(?:(?<schema>[^ .]+)\\.)?(?<table>[^ .]+)\\s+IS\\s+'(?<comment>(?:[^']|'')+)';$" of
        (Just constraint) :: schema :: (Just table) :: (Just comment) :: [] ->
            Ok { schema = schema |> Maybe.map buildSchemaName, table = table |> buildTableName, constraint = constraint |> buildConstraintName, comment = comment |> buildComment }

        _ ->
            Err [ "Can't parse constraint comment: '" ++ buildRawSql statement ++ "'" ]
