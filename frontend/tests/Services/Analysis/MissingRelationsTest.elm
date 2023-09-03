module Services.Analysis.MissingRelationsTest exposing (..)

import Dict exposing (Dict)
import Expect exposing (Expectation)
import Libs.Dict as Dict
import Libs.Nel as Nel exposing (Nel)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnValue exposing (ColumnValue)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableName exposing (TableName)
import PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable)
import Services.Analysis.MissingRelations exposing (SuggestedRelation, SuggestedRelationRef, forTables)
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
    tables |> buildTables |> forTables |> formatRelations |> Expect.equal relations


buildTables : List ( TableName, List ( ColumnName, List ColumnValue ) ) -> Dict TableId ErdTable
buildTables list =
    list |> List.map erdTable |> Dict.fromListMap .id


formatRelations : List SuggestedRelation -> List SimpleRelation
formatRelations relations =
    relations |> List.map (\r -> ( ( r.src.table.name, r.src.column.name ), r.ref |> Maybe.map (\ref -> ( ref.table.name, ref.column.name )), r.when |> Maybe.map (\w -> ( w.column.name, w.value )) ))


erdTable : ( TableName, List ( ColumnName, List ColumnValue ) ) -> ErdTable
erdTable ( name, columns ) =
    let
        id : TableId
        id =
            ( "", name )
    in
    { id = id
    , htmlId = id |> TableId.toHtmlId
    , label = id |> TableId.show ""
    , schema = ""
    , name = name
    , view = False
    , columns = columns |> List.indexedMap erdColumn |> Dict.fromListMap .name
    , primaryKey = Nothing
    , uniques = []
    , indexes = []
    , checks = []
    , comment = Nothing
    , origins = []
    }


erdColumn : Int -> ( String, List String ) -> ErdColumn
erdColumn index ( name, values ) =
    { index = index
    , name = name
    , path = Nel name []
    , kind = "text"
    , kindLabel = "text"
    , customType = Nothing
    , nullable = False
    , default = Nothing
    , defaultLabel = Nothing
    , comment = Nothing
    , isPrimaryKey = False
    , inRelations = []
    , outRelations = []
    , uniques = []
    , indexes = []
    , checks = []
    , values = Nel.fromList values
    , columns = Nothing
    , origins = []
    }
