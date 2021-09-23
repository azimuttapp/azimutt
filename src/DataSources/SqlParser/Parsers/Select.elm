module DataSources.SqlParser.Parsers.Select exposing (SelectColumn(..), SelectColumnBasic, SelectColumnComplex, SelectInfo, SelectTable(..), SelectTableBasic, SelectTableComplex, TableAlias, parseSelect, parseSelectColumn, parseSelectTable)

import DataSources.SqlParser.Utils.Helpers exposing (buildColumnName, buildSchemaName, buildTableName, commaSplit)
import DataSources.SqlParser.Utils.Types exposing (ParseError, RawSql, SqlColumnName, SqlSchemaName, SqlTableName)
import Libs.List as L
import Libs.Maybe as M
import Libs.Nel as Nel exposing (Nel)
import Libs.Regex as R


type alias SelectInfo =
    { columns : Nel SelectColumn, tables : List SelectTable, whereClause : Maybe String }


type SelectColumn
    = BasicColumn SelectColumnBasic
    | ComplexColumn SelectColumnComplex


type alias SelectColumnBasic =
    { table : Maybe TableAlias, column : SqlColumnName, alias : Maybe SqlColumnName }


type alias SelectColumnComplex =
    { formula : String, alias : SqlColumnName }


type SelectTable
    = BasicTable SelectTableBasic
    | ComplexTable SelectTableComplex


type alias SelectTableBasic =
    { schema : Maybe SqlSchemaName, table : SqlTableName, alias : Maybe SqlTableName }


type alias SelectTableComplex =
    { definition : String }


type alias TableAlias =
    String


parseSelect : RawSql -> Result (List ParseError) SelectInfo
parseSelect select =
    case select |> R.matches "^SELECT(?:\\s+DISTINCT ON \\([^)]+\\))?\\s+(?<columns>.+?)(?:\\s+FROM\\s+(?<tables>.+?))?(?:\\s+WHERE\\s+(?<where>.+?))?$" of
        (Just columnsStr) :: tablesStr :: whereClause :: [] ->
            Result.map2 (\columns tables -> { columns = columns, tables = tables, whereClause = whereClause })
                (commaSplit columnsStr |> List.map String.trim |> List.map parseSelectColumn |> L.resultSeq |> Result.andThen (\cols -> cols |> Nel.fromList |> Result.fromMaybe [ "Select can't have empty columns" ]))
                (tablesStr |> M.toList |> List.map parseSelectTable |> L.resultSeq)

        _ ->
            Err [ "Can't parse select: '" ++ select ++ "'" ]


parseSelectColumn : RawSql -> Result ParseError SelectColumn
parseSelectColumn column =
    case column |> R.matches "^(?:(?<table>[^ .]+)\\.)?(?<column>[^ :]+)(?:\\s*AS\\s+(?<alias>.+))?$" of
        table :: (Just columnName) :: alias :: [] ->
            Ok (BasicColumn { table = table |> Maybe.map buildTableName, column = columnName |> buildColumnName, alias = alias |> Maybe.map buildColumnName })

        _ ->
            case column |> R.matches "^(?<formula>.+?)\\s+AS\\s+(?<alias>[^ ]+)$" of
                (Just formula) :: (Just alias) :: [] ->
                    Ok (ComplexColumn { formula = formula, alias = alias |> buildColumnName })

                _ ->
                    Err ("Can't parse select column '" ++ column ++ "'")


parseSelectTable : RawSql -> Result ParseError SelectTable
parseSelectTable table =
    case table |> R.matches "^(?:(?<schema>[^ .]+)\\.)?(?<table>[^ ]+)(?:\\s+(?<alias>[^ ]+))?$" of
        schema :: (Just tableName) :: alias :: [] ->
            Ok (BasicTable { schema = schema |> Maybe.map buildSchemaName, table = tableName |> buildTableName, alias = alias })

        _ ->
            Ok (ComplexTable { definition = table })
