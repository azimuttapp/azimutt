module Services.QueryBuilder exposing (ColumnMatch, FilterOperation(..), FilterOperator(..), RowQuery, TableFilter, TableQuery, filterTable, findRow, limitResults)

import Libs.Models.DatabaseKind as DatabaseKind exposing (DatabaseKind)
import Libs.Nel as Nel exposing (Nel)
import Libs.Regex as Regex
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.ColumnType as ColumnType exposing (ColumnType)
import Models.Project.TableId exposing (TableId)


type alias TableQuery =
    { table : Maybe TableId, filters : List TableFilter }


type alias TableFilter =
    { operator : FilterOperator, column : ColumnPath, kind : ColumnType, operation : FilterOperation, value : String }


type alias RowQuery =
    { table : TableId, primaryKey : Nel ColumnMatch }


type alias ColumnMatch =
    { column : ColumnPath, kind : ColumnType, value : String }


type FilterOperator
    = OpAnd
    | OpOr


type FilterOperation
    = -- TODO: filters by column kind?
      OpEqual
    | OpNotEqual
    | OpIsNull
    | OpIsNotNull
    | OpGreaterThan
    | OpLesserThan
    | OpLike


filterTable : DatabaseKind -> TableQuery -> String
filterTable db query =
    if db == DatabaseKind.PostgreSQL then
        query.table |> Maybe.map (\table -> "SELECT * FROM " ++ formatTable db table ++ formatFilters db query.filters ++ ";") |> Maybe.withDefault ""

    else
        ""


findRow : DatabaseKind -> RowQuery -> String
findRow db query =
    if db == DatabaseKind.PostgreSQL then
        "SELECT * FROM " ++ formatTable db query.table ++ " WHERE " ++ formatMatcher db query.primaryKey ++ " LIMIT 1;"

    else
        ""


limitResults : DatabaseKind -> String -> String
limitResults db query =
    if db == DatabaseKind.PostgreSQL then
        case query |> Regex.matches "^(.+?)( limit \\d+)?( offset \\d+)?;$" of
            (Just q) :: Nothing :: Nothing :: [] ->
                q ++ " LIMIT 100;"

            (Just q) :: Nothing :: (Just offset) :: [] ->
                q ++ " LIMIT 100" ++ offset ++ ";"

            _ ->
                query

    else
        ""


formatTable : DatabaseKind -> TableId -> String
formatTable db ( schema, table ) =
    if db == DatabaseKind.PostgreSQL then
        if schema == "" then
            table

        else
            schema ++ "." ++ table

    else
        ""


formatFilters : DatabaseKind -> List TableFilter -> String
formatFilters db filters =
    if db == DatabaseKind.PostgreSQL then
        if filters |> List.isEmpty then
            ""

        else
            " WHERE "
                ++ (filters
                        |> List.indexedMap
                            (\i f ->
                                if i == 0 then
                                    formatFilter db f

                                else
                                    formatOperator db f.operator ++ " " ++ formatFilter db f
                            )
                        |> String.join " "
                   )

    else
        ""


formatFilter : DatabaseKind -> TableFilter -> String
formatFilter db filter =
    if db == DatabaseKind.PostgreSQL then
        formatColumn db filter.column ++ formatOperation db filter.operation filter.kind filter.value

    else
        ""


formatOperation : DatabaseKind -> FilterOperation -> ColumnType -> String -> String
formatOperation db op kind value =
    if db == DatabaseKind.PostgreSQL then
        case op of
            OpEqual ->
                "=" ++ formatValue db kind value

            OpNotEqual ->
                "!=" ++ formatValue db kind value

            OpIsNull ->
                " IS NULL"

            OpIsNotNull ->
                " IS NOT NULL"

            OpGreaterThan ->
                ">" ++ formatValue db kind value

            OpLesserThan ->
                "<" ++ formatValue db kind value

            OpLike ->
                " LIKE " ++ formatValue db kind value

    else
        ""


formatMatcher : DatabaseKind -> Nel ColumnMatch -> String
formatMatcher db matches =
    if db == DatabaseKind.PostgreSQL then
        matches |> Nel.toList |> List.map (\m -> formatColumn db m.column ++ "=" ++ formatValue db m.kind m.value) |> String.join " AND "

    else
        ""


formatColumn : DatabaseKind -> ColumnPath -> String
formatColumn db column =
    if db == DatabaseKind.PostgreSQL then
        column.head

    else
        ""


formatValue : DatabaseKind -> ColumnType -> String -> String
formatValue db kind value =
    if db == DatabaseKind.PostgreSQL then
        case ColumnType.parse kind of
            ColumnType.Int ->
                value

            ColumnType.Bool ->
                value

            _ ->
                "'" ++ value ++ "'"

    else
        ""


formatOperator : DatabaseKind -> FilterOperator -> String
formatOperator db op =
    if db == DatabaseKind.PostgreSQL then
        case op of
            OpAnd ->
                "AND"

            OpOr ->
                "OR"

    else
        ""
