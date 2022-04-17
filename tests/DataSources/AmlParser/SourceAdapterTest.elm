module DataSources.AmlParser.SourceAdapterTest exposing (..)

import Conf
import DataSources.AmlParser.AmlParser exposing (AmlColumn, AmlStatement(..), AmlTable)
import DataSources.AmlParser.SourceAdapter exposing (AmlSchema, evolve)
import Dict
import Expect
import Libs.Dict as Dict
import Models.Project.Column exposing (Column)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.Table exposing (Table)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "SourceAdapter"
        [ describe "evolve"
            [ test "empty changes nothing" (\_ -> schema |> evolve source (AmlEmptyStatement { comment = Nothing }) |> Expect.equal schema)
            , test "add a table"
                (\_ ->
                    schema
                        |> evolve source (AmlTableStatement usersAml)
                        |> Expect.equal { schema | tables = Dict.fromList [ ( users.id, users ) ] }
                )
            , test "fail on add a table twice"
                (\_ ->
                    { schema | tables = Dict.fromList [ ( users.id, users ) ] }
                        |> evolve source (AmlTableStatement usersAml)
                        |> Expect.equal { schema | tables = Dict.fromList [ ( users.id, users ) ], errors = [ "Table 'users' is already defined" ] }
                )
            ]
        ]


users : Table
users =
    { table | id = ( Conf.schema.default, "users" ), schema = Conf.schema.default, name = "users", columns = Dict.from "id" { column | index = 0, name = "id", kind = "int" } }


usersAml : AmlTable
usersAml =
    { amlTable | table = "users", columns = [ { amlColumn | name = "id", kind = Just "int" } ] }


table : Table
table =
    { id = ( "", "" ), schema = "", name = "", view = False, columns = Dict.from "" column, primaryKey = Nothing, uniques = [], indexes = [], checks = [], comment = Nothing, origins = [ { id = source, lines = [] } ] }


column : Column
column =
    { index = 0, name = "", kind = "", nullable = False, default = Nothing, comment = Nothing, origins = [ { id = source, lines = [] } ] }


amlTable : AmlTable
amlTable =
    { schema = Nothing, table = "", isView = False, props = Nothing, notes = Nothing, comment = Nothing, columns = [] }


amlColumn : AmlColumn
amlColumn =
    { name = "", kind = Nothing, default = Nothing, nullable = False, primaryKey = False, index = Nothing, unique = Nothing, check = Nothing, foreignKey = Nothing, props = Nothing, notes = Nothing, comment = Nothing }


schema : AmlSchema
schema =
    { tables = Dict.empty, relations = [], errors = [] }


source : SourceId
source =
    SourceId.new "src"
