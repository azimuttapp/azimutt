module DataSources.AmlMiner.AmlAdapterTest exposing (..)

import Conf
import DataSources.AmlMiner.AmlAdapter exposing (AmlSchema, evolve)
import DataSources.AmlMiner.AmlParser exposing (AmlColumn, AmlRelation, AmlStatement(..), AmlTable)
import Dict
import Expect
import Libs.Dict as Dict
import Libs.Nel as Nel
import Models.Project.Column as Column exposing (Column)
import Models.Project.ColumnPath as ColumnPath
import Models.Project.Comment exposing (Comment)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.Relation exposing (Relation)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.Table as Table exposing (Table)
import Models.Project.Unique exposing (Unique)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "AmlAdapter"
        [ describe "evolve"
            [ test "empty changes nothing" (\_ -> schema |> evolve (AmlEmptyStatement { comment = Nothing }) |> Expect.equal schema)
            , test "add a table"
                (\_ ->
                    schema
                        |> evolve (AmlTableStatement usersAml)
                        |> Expect.equal { schema | tables = Dict.fromListBy .id [ users ] }
                )
            , test "can't add a table twice"
                (\_ ->
                    { schema | tables = Dict.fromListBy .id [ users ] }
                        |> evolve (AmlTableStatement usersAml)
                        |> Expect.equal { schema | tables = Dict.fromListBy .id [ users ], errors = [ { row = 0, col = 0, problem = "Table 'users' is already defined" } ] }
                )
            , test "add a relation"
                (\_ ->
                    schema
                        |> evolve (AmlRelationStatement loginsFkAml)
                        |> Expect.equal { schema | relations = [ loginsFk ] }
                )
            , test "add a table with relations"
                (\_ ->
                    schema
                        |> evolve (AmlTableStatement loginsAml)
                        |> Expect.equal { schema | tables = Dict.fromListBy .id [ logins ], relations = [ loginsFk ] }
                )
            ]
        ]


usersAml : AmlTable
usersAml =
    { amlTable
        | table = "users"
        , columns =
            [ { amlColumn | name = "id", kind = Just "int", primaryKey = True }
            , { amlColumn | name = "slug", kind = Just "varchar", unique = Just "", notes = Just "used in url" }
            , { amlColumn | name = "role", comment = Just "not used" }
            ]
        , notes = Just "user list"
        , comment = Just "not used"
    }


users : Table
users =
    { table
        | id = ( Conf.schema.empty, "users" )
        , schema = Conf.schema.empty
        , name = "users"
        , columns =
            Dict.fromListBy .name
                [ { column | index = 0, name = "id", kind = "int" }
                , { column | index = 1, name = "slug", kind = "varchar", comment = Just { comment | text = "used in url" } }
                , { column | index = 2, name = "role", kind = Conf.schema.column.unknownType }
                ]
        , primaryKey = Just { primaryKey | columns = "id" |> ColumnPath.fromString |> Nel.from }
        , uniques = [ { unique | name = "users_slug_unique_az", columns = "slug" |> ColumnPath.fromString |> Nel.from } ]
        , comment = Just { comment | text = "user list" }
    }


loginsAml : AmlTable
loginsAml =
    { amlTable
        | table = "logins"
        , columns =
            [ { amlColumn | name = "id", kind = Just "int" }
            , { amlColumn | name = "user_id", kind = Just "int", foreignKey = Just { schema = Nothing, table = "users", column = "id" } }
            ]
    }


logins : Table
logins =
    { table
        | id = ( Conf.schema.empty, "logins" )
        , schema = Conf.schema.empty
        , name = "logins"
        , columns =
            Dict.fromListBy .name
                [ { column | index = 0, name = "id", kind = "int" }
                , { column | index = 1, name = "user_id", kind = "int" }
                ]
    }


loginsFkAml : AmlRelation
loginsFkAml =
    { from = { schema = Nothing, table = "logins", column = "user_id" }
    , to = { schema = Nothing, table = "users", column = "id" }
    , comment = Nothing
    }


loginsFk : Relation
loginsFk =
    { id = ( ( ( Conf.schema.empty, "logins" ), "user_id" ), ( ( "", "users" ), "id" ) )
    , name = "logins_user_id_fk_az"
    , src = { table = ( Conf.schema.empty, "logins" ), column = "user_id" |> ColumnPath.fromString }
    , ref = { table = ( Conf.schema.empty, "users" ), column = "id" |> ColumnPath.fromString }
    }



-- generic models


schema : AmlSchema
schema =
    { tables = Dict.empty, relations = [], types = Dict.empty, errors = [] }


amlTable : AmlTable
amlTable =
    { schema = Nothing, table = "", isView = False, props = Nothing, notes = Nothing, comment = Nothing, columns = [] }


amlColumn : AmlColumn
amlColumn =
    { name = "", kind = Nothing, kindSchema = Nothing, values = Nothing, default = Nothing, nullable = False, primaryKey = False, index = Nothing, unique = Nothing, check = Nothing, foreignKey = Nothing, props = Nothing, notes = Nothing, comment = Nothing }


table : Table
table =
    Table.empty


column : Column
column =
    Column.empty


primaryKey : PrimaryKey
primaryKey =
    { name = Nothing, columns = "" |> ColumnPath.fromString |> Nel.from }


unique : Unique
unique =
    { name = "", columns = "" |> ColumnPath.fromString |> Nel.from, definition = Nothing }


comment : Comment
comment =
    { text = "" }


source : SourceId
source =
    SourceId.new "src"
