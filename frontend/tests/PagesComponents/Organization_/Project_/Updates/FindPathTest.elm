module PagesComponents.Organization_.Project_.Updates.FindPathTest exposing (..)

import Array
import Dict exposing (Dict)
import Expect
import Libs.Dict as Dict
import Libs.Nel exposing (Nel)
import Libs.Time as Time
import Models.Project.Column as Column exposing (Column)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.FindPathSettings exposing (FindPathSettings)
import Models.Project.Relation as Relation
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId
import Models.Project.SourceKind as SourceKind
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableName exposing (TableName)
import PagesComponents.Organization_.Project_.Models.Erd.RelationWithOrigin as RelationWithOrigin
import PagesComponents.Organization_.Project_.Models.Erd.TableWithOrigin as TableWithOrigin
import PagesComponents.Organization_.Project_.Models.ErdRelation as ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdTable as ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.FindPathStep exposing (FindPathStep)
import PagesComponents.Organization_.Project_.Models.FindPathStepDir exposing (FindPathStepDir(..))
import PagesComponents.Organization_.Project_.Updates.FindPath exposing (computeFindPath)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "PagesComponents.Organization_.Project_.Updates.FindPath"
        [ describe "computeFindPath"
            [ test "empty" (\_ -> computeFindPath basicTables [] (tableId "users") (tableId "roles") settings |> .paths |> Expect.equal [])
            , test "same from & to" (\_ -> computeFindPath basicTables [] (tableId "users") (tableId "users") settings |> .paths |> Expect.equal [])
            , test "basic"
                (\_ ->
                    computeFindPath basicTables basicRelations (tableId "users") (tableId "roles") settings
                        |> .paths
                        |> Expect.equal [ Nel (FindPathStep roleUserToUsers Left) [ FindPathStep roleUserToRoles Right ] ]
                )
            , test "with cycle"
                (\_ ->
                    computeFindPath basicTables (rolesToUsers :: basicRelations) (tableId "users") (tableId "roles") settings
                        |> .paths
                        |> Expect.equal
                            [ Nel (FindPathStep rolesToUsers Left) []
                            , Nel (FindPathStep roleUserToUsers Left) [ FindPathStep roleUserToRoles Right ]
                            ]
                )
            ]
        ]


basicTables : Dict TableId ErdTable
basicTables =
    [ usersTable, rolesTable, roleUserTable, credentialsTable ] |> Dict.fromListBy .id


basicRelations : List ErdRelation
basicRelations =
    [ roleUserToUsers, roleUserToRoles, credentialsToUsers ]


usersTable : ErdTable
usersTable =
    buildTable "users" [ "id" ]


rolesTable : ErdTable
rolesTable =
    buildTable "roles" [ "id", "by" ]


roleUserTable : ErdTable
roleUserTable =
    buildTable "role_user" [ "id", "role_id", "user_id" ]


credentialsTable : ErdTable
credentialsTable =
    buildTable "credentials" [ "user_id" ]


roleUserToUsers : ErdRelation
roleUserToUsers =
    buildRelation ( "role_user", "user_id" ) ( "users", "id" )


roleUserToRoles : ErdRelation
roleUserToRoles =
    buildRelation ( "role_user", "role_id" ) ( "roles", "id" )


credentialsToUsers : ErdRelation
credentialsToUsers =
    buildRelation ( "credentials", "user_id" ) ( "users", "id" )


rolesToUsers : ErdRelation
rolesToUsers =
    buildRelation ( "roles", "by" ) ( "users", "id" )


defaultSchema : SchemaName
defaultSchema =
    "public"


tableId : TableName -> TableId
tableId name =
    ( defaultSchema, name )


buildTable : TableName -> List String -> ErdTable
buildTable name columnNames =
    Table.empty
        |> (\c -> { c | id = tableId name, schema = defaultSchema, name = name, columns = columnNames |> List.map buildColumn |> Dict.fromListBy .name })
        |> TableWithOrigin.create source
        |> ErdTable.create defaultSchema Dict.empty [] Dict.empty


buildColumn : ColumnName -> Column
buildColumn name =
    Column.empty |> (\c -> { c | name = name })


buildRelation : ( TableName, ColumnName ) -> ( TableName, ColumnName ) -> ErdRelation
buildRelation ( fromTable, fromCol ) ( toTable, toCol ) =
    Relation.new "" (ColumnRef (tableId fromTable) (ColumnPath.fromString fromCol)) (ColumnRef (tableId toTable) (ColumnPath.fromString toCol))
        |> RelationWithOrigin.create source
        |> ErdRelation.create Dict.empty


source : Source
source =
    Source SourceId.zero "source" SourceKind.AmlEditor (Array.fromList []) Dict.empty [] Dict.empty True Nothing Time.zero Time.zero


settings : FindPathSettings
settings =
    FindPathSettings 10 "" ""
