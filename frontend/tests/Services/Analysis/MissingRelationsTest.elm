module Services.Analysis.MissingRelationsTest exposing (..)

import Dict exposing (Dict)
import Expect exposing (Expectation)
import Libs.Dict as Dict
import Libs.Nel as Nel exposing (Nel)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath exposing (ColumnPathStr)
import Models.Project.ColumnValue exposing (ColumnValue)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableName exposing (TableName)
import PagesComponents.Organization_.Project_.Models.SuggestedRelation exposing (SuggestedRelation)
import Services.Analysis.MissingRelations exposing (forTables)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "MissingRelations"
        [ test "basic relation"
            (\_ ->
                [ ( "organizations", [ ( "id", [] ) ] )
                , ( "projects", [ ( "organization_id", [] ) ] )
                ]
                    |> shouldFindRelations [ ( ( "projects", "organization_id" ), Just ( "organizations", "id" ), Nothing ) ]
            )
        , test "id list"
            (\_ ->
                [ ( "organizations", [ ( "id", [] ) ] )
                , ( "projects", [ ( "organization_ids", [] ) ] )
                ]
                    |> shouldFindRelations [ ( ( "projects", "organization_ids" ), Just ( "organizations", "id" ), Nothing ) ]
            )
        , test "with prefix"
            (\_ ->
                [ ( "organizations", [ ( "id", [] ) ] )
                , ( "projects", [ ( "original_organization_id", [] ) ] )
                ]
                    |> shouldFindRelations [ ( ( "projects", "original_organization_id" ), Just ( "organizations", "id" ), Nothing ) ]
            )
        , test "missing target"
            (\_ ->
                [ ( "projects", [ ( "organization_id", [] ) ] ) ]
                    |> shouldFindRelations [ ( ( "projects", "organization_id" ), Nothing, Nothing ) ]
            )
        , test "polymorphic relation"
            (\_ ->
                [ ( "organizations", [ ( "id", [] ) ] )
                , ( "events", [ ( "item_type", [ "Organization", "Projects" ] ), ( "item_id", [] ) ] )
                ]
                    |> shouldFindRelations [ ( ( "events", "item_id" ), Just ( "organizations", "id" ), Just ( "item_type", "Organization" ) ) ]
            )
        ]


type alias SimpleRelation =
    ( ( TableName, ColumnName ), Maybe ( TableName, ColumnName ), Maybe ( ColumnName, ColumnValue ) )


shouldFindRelations : List SimpleRelation -> List ( TableName, List ( ColumnName, List ColumnValue ) ) -> Expectation
shouldFindRelations relations tables =
    tables |> buildTables |> (\t -> forTables t [] Dict.empty) |> formatRelations |> Expect.equal relations


buildTables : List ( TableName, List ( ColumnName, List ColumnValue ) ) -> Dict TableId Table
buildTables list =
    list |> List.map buildTable |> Dict.fromListMap .id


formatRelations : Dict TableId (Dict ColumnPathStr (List SuggestedRelation)) -> List SimpleRelation
formatRelations relations =
    relations
        |> Dict.values
        |> List.concatMap Dict.values
        |> List.concatMap identity
        |> List.map (\r -> ( ( Tuple.second r.src.table, r.src.column.head ), r.ref |> Maybe.map (\ref -> ( Tuple.second ref.table, ref.column.head )), r.when |> Maybe.map (\w -> ( w.column.head, w.value )) ))


buildTable : ( TableName, List ( ColumnName, List ColumnValue ) ) -> Table
buildTable ( name, columns ) =
    let
        id : TableId
        id =
            ( "", name )
    in
    { id = id
    , schema = ""
    , name = name
    , view = False
    , columns = columns |> List.indexedMap buildColumn |> Dict.fromListMap .name
    , primaryKey = Nothing
    , uniques = []
    , indexes = []
    , checks = []
    , comment = Nothing
    }


buildColumn : Int -> ( String, List String ) -> Column
buildColumn index ( name, values ) =
    { index = index
    , name = name
    , kind = "text"
    , nullable = False
    , default = Nothing
    , comment = Nothing
    , values = Nel.fromList values
    , columns = Nothing
    }
