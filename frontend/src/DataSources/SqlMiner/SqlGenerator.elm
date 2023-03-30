module DataSources.SqlMiner.SqlGenerator exposing (organizeTablesAndRelations)

import Dict exposing (Dict)
import Libs.List as List
import Libs.Tuple as Tuple
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Relation exposing (Relation)
import Models.Project.Schema exposing (Schema)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)



-- Generic functions for SQL generators: PostgreSqlGenerator, MysqlGenerator...


organizeTablesAndRelations : Schema -> ( List Table, Dict TableId (Dict ColumnName (List Relation)), Dict TableId (List Relation) )
organizeTablesAndRelations schema =
    let
        tables : List Table
        tables =
            -- TODO: improve table ordering to minimize lazy relations (on tables not yet created)
            schema.tables |> Dict.values

        ( relations, lazyRelation ) =
            schema.relations
                |> List.filterZip (\r -> Maybe.map2 Tuple.new (tables |> List.findIndexBy .id r.src.table) (tables |> List.findIndexBy .id r.ref.table))
                |> List.partition (\( _, ( src, ref ) ) -> ref <= src)
                |> Tuple.mapFirst (List.map Tuple.first >> relationsByTarget .src)
                |> Tuple.mapSecond (List.map Tuple.first >> relationsByTarget .ref)
    in
    ( tables, relations, lazyRelation |> Dict.map (\_ -> Dict.values >> List.concatMap identity) )


relationsByTarget : (Relation -> ColumnRef) -> List Relation -> Dict TableId (Dict ColumnName (List Relation))
relationsByTarget getTarget relations =
    relations
        |> List.groupBy (getTarget >> .table)
        |> Dict.map (\_ r -> r |> List.groupBy (getTarget >> .column >> .head))
