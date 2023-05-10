module Services.DatabaseQueries exposing (showColumnData, showData, showTableData)

import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.TableId exposing (TableId)


showData : Maybe ColumnPath -> TableId -> DatabaseUrl -> String
showData column =
    column |> Maybe.map showColumnData |> Maybe.withDefault showTableData



-- TODO: use `url` to build queries depending on db (sql, mongo, couchbase...)


showTableData : TableId -> DatabaseUrl -> String
showTableData table _ =
    "SELECT * FROM " ++ tableRef table ++ " LIMIT 30;"


showColumnData : ColumnPath -> TableId -> DatabaseUrl -> String
showColumnData column table _ =
    "SELECT " ++ column.head ++ ", count(*) FROM " ++ tableRef table ++ " GROUP BY " ++ column.head ++ " ORDER BY count DESC, " ++ column.head ++ " LIMIT 30;"


tableRef : TableId -> String
tableRef ( schema, table ) =
    if schema /= "" then
        schema ++ "." ++ table

    else
        table
