module PagesComponents.Projects.Id_.Updates.FindPathTest exposing (..)

import Dict exposing (Dict)
import Expect
import Libs.Dict as Dict
import Libs.Nel exposing (Nel)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.FindPathSettings exposing (FindPathSettings)
import Models.Project.Relation as Relation
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableName exposing (TableName)
import PagesComponents.Projects.Id_.Models.ErdRelation as ErdRelation exposing (ErdRelation)
import PagesComponents.Projects.Id_.Models.ErdTable as ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.FindPathStep exposing (FindPathStep)
import PagesComponents.Projects.Id_.Models.FindPathStepDir exposing (FindPathStepDir(..))
import PagesComponents.Projects.Id_.Updates.FindPath exposing (computeFindPath)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "PagesComponents.Projects.Id_.Updates.FindPath"
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
    [ usersTable, rolesTable, roleUserTable, credentialsTable ] |> Dict.fromListMap .id


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
    Table (tableId name) defaultSchema name False (columnNames |> List.map buildColumn |> Dict.fromListMap .name) Nothing [] [] [] Nothing [] |> ErdTable.create defaultSchema Dict.empty Dict.empty []


buildColumn : ColumnName -> Column
buildColumn name =
    Column 0 name "int" False Nothing Nothing []


buildRelation : ( TableName, ColumnName ) -> ( TableName, ColumnName ) -> ErdRelation
buildRelation ( fromTable, fromCol ) ( toTable, toCol ) =
    Relation.new "" (ColumnRef (tableId fromTable) fromCol) (ColumnRef (tableId toTable) toCol) [] |> ErdRelation.create Dict.empty


settings : FindPathSettings
settings =
    FindPathSettings 10 "" ""
