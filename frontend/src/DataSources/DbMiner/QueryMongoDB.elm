module DataSources.DbMiner.QueryMongoDB exposing (exploreColumn, exploreTable)

import Libs.Maybe as Maybe
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableName exposing (TableName)
import Models.SqlQuery exposing (SqlQuery)



-- FIXME: remove hardcoded limits & implement `addLimit`


exploreTable : TableId -> SqlQuery
exploreTable ( schema, table ) =
    let
        ( collection, filter ) =
            mixedCollection table

        query : String
        query =
            filter |> Maybe.mapOrElse (\( field, value ) -> "{\"" ++ field ++ "\":\"" ++ value ++ "\"}") "{}"
    in
    schema ++ "/" ++ collection ++ "/find/" ++ query ++ "/100"


exploreColumn : TableId -> ColumnPath -> SqlQuery
exploreColumn ( schema, table ) column =
    let
        ( collection, filter ) =
            mixedCollection table

        whereClause : String
        whereClause =
            filter |> Maybe.mapOrElse (\( field, value ) -> "{\"$match\":{\"" ++ field ++ "\":{\"$eq\":\"" ++ value ++ "\"}}},") ""
    in
    schema ++ "/" ++ collection ++ "/aggregate/[" ++ whereClause ++ "{\"$sortByCount\":\"$" ++ column.head ++ "\"},{\"$project\":{\"_id\":0,\"" ++ column.head ++ "\":\"$_id\",\"count\":\"$count\"}}]/100"



-- PRIVATE


mixedCollection : TableName -> ( TableName, Maybe ( String, String ) )
mixedCollection table =
    case table |> String.split "__" of
        [ collection, field, value ] ->
            ( collection, Just ( field, value ) )

        _ ->
            ( table, Nothing )
