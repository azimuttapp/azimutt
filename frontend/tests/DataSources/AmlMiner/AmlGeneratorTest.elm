module DataSources.AmlMiner.AmlGeneratorTest exposing (..)

import DataSources.AmlMiner.AmlGenerator as AmlGenerator
import Dict exposing (Dict)
import Expect
import Libs.Dict as Dict
import Libs.Nel as Nel exposing (Nel)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Comment exposing (Comment)
import Models.Project.CustomType exposing (CustomType)
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.Relation exposing (Relation)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "AmlGenerator"
        [ describe "generate"
            [ test "empty" (\_ -> emptySource |> AmlGenerator.generate |> Expect.equal "")
            , test "empty table" (\_ -> { emptySource | tables = Dict.fromListMap .id [ { emptyTable | name = "users" } ] } |> AmlGenerator.generate |> Expect.equal "users")
            , test "table with columns"
                (\_ ->
                    { emptySource
                        | tables =
                            [ { emptyTable
                                | schema = "public"
                                , name = "users"
                                , columns =
                                    [ { emptyColumn | name = "id", kind = "uuid" }
                                    , { emptyColumn | name = "name", kind = "varchar", nullable = True }
                                    , { emptyColumn | name = "role", kind = "varchar", default = Just "guest" }
                                    , { emptyColumn | name = "bio", kind = "text", comment = Just { emptyComment | text = "Hello :)" } }
                                    , { emptyColumn | name = "age", kind = "int", nullable = True, default = Just "0", comment = Just { emptyComment | text = "hey!" } }
                                    ]
                                        |> buildColumns
                              }
                            ]
                                |> buildTables
                    }
                        |> AmlGenerator.generate
                        |> Expect.equal """public.users
  id uuid
  name varchar nullable
  role varchar=guest
  bio text | Hello :)
  age int=0 nullable | hey!"""
                )
            , test "table with constraints"
                (\_ ->
                    { emptySource
                        | tables =
                            [ { emptyTable
                                | schema = "public"
                                , name = "users"
                                , columns =
                                    [ { emptyColumn | name = "id", kind = "uuid" }
                                    , { emptyColumn | name = "name", kind = "varchar" }
                                    , { emptyColumn | name = "role", kind = "varchar" }
                                    , { emptyColumn | name = "bio", kind = "text" }
                                    , { emptyColumn | name = "age", kind = "int" }
                                    ]
                                        |> buildColumns
                                , primaryKey = Just { name = Nothing, columns = Nel.from (Nel.from "id"), origins = [] }
                                , uniques = [ { name = "users_name_unique", columns = Nel.from (Nel.from "name"), definition = Nothing, origins = [] } ]
                                , indexes = [ { name = "users_role_idx", columns = Nel.from (Nel.from "role"), definition = Nothing, origins = [] } ]
                                , checks = [ { name = "users_age_chk", columns = [ Nel.from "age" ], predicate = Nothing, origins = [] } ]
                                , comment = Just { emptyComment | text = "all users" }
                              }
                            ]
                                |> buildTables
                    }
                        |> AmlGenerator.generate
                        |> Expect.equal """public.users | all users
  id uuid pk
  name varchar unique
  role varchar index
  bio text
  age int check"""
                )
            , test "table with complex constraints"
                (\_ ->
                    { emptySource
                        | tables =
                            [ { emptyTable
                                | name = "users"
                                , columns =
                                    [ { emptyColumn | name = "kind", kind = "varchar" }
                                    , { emptyColumn | name = "id", kind = "uuid" }
                                    , { emptyColumn | name = "first_name", kind = "varchar" }
                                    , { emptyColumn | name = "last_name", kind = "varchar" }
                                    , { emptyColumn | name = "age", kind = "int" }
                                    ]
                                        |> buildColumns
                                , primaryKey = Just { name = Nothing, columns = Nel "kind" [ "id" ] |> Nel.map Nel.from, origins = [] }
                                , uniques = [ { name = "users_name_unique", columns = Nel "first_name" [ "last_name" ] |> Nel.map Nel.from, definition = Nothing, origins = [] } ]
                                , indexes = [ { name = "users_name_idx", columns = Nel "first_name" [ "last_name" ] |> Nel.map Nel.from, definition = Nothing, origins = [] } ]
                                , checks = [ { name = "users_age_chk", columns = [ "age" ] |> List.map Nel.from, predicate = Just "age > 0", origins = [] } ]
                                , comment = Just { emptyComment | text = "store \"all\" users" }
                              }
                            ]
                                |> buildTables
                    }
                        |> AmlGenerator.generate
                        |> Expect.equal """users | store "all" users
  kind varchar pk
  id uuid pk
  first_name varchar unique=users_name_unique index=users_name_idx
  last_name varchar unique=users_name_unique index=users_name_idx
  age int check="age > 0\""""
                )
            , test "table with foreign keys"
                (\_ ->
                    { emptySource
                        | tables = [ { emptyTable | name = "user_roles", columns = [ { emptyColumn | name = "user_id", kind = "uuid" }, { emptyColumn | name = "role_id", kind = "uuid" } ] |> buildColumns } ] |> buildTables
                        , relations =
                            [ ( "user_roles_user_fk", ( "", "user_roles", "user_id" ), ( "", "users", "id" ) )
                            , ( "user_roles_role_fk", ( "", "user_roles", "role_id" ), ( "public", "roles", "id" ) )
                            ]
                                |> List.map buildRelation
                    }
                        |> AmlGenerator.generate
                        |> Expect.equal """user_roles
  user_id uuid fk users.id
  role_id uuid fk public.roles.id"""
                )
            ]
        ]


emptySource : { tables : Dict TableId Table, relations : List Relation, types : Dict CustomTypeId CustomType }
emptySource =
    { tables = Dict.empty, relations = [], types = Dict.empty }


emptyTable : Table
emptyTable =
    { id = ( "", "" ), schema = "", name = "", view = False, columns = Dict.empty, primaryKey = Nothing, uniques = [], indexes = [], checks = [], comment = Nothing, origins = [] }


emptyColumn : Column
emptyColumn =
    { index = 0, name = "", kind = "", nullable = False, default = Nothing, comment = Nothing, columns = Nothing, origins = [] }


emptyComment : Comment
emptyComment =
    { text = "", origins = [] }


buildTables : List Table -> Dict TableId Table
buildTables tables =
    tables |> Dict.fromListMap .id


buildColumns : List Column -> Dict ColumnName Column
buildColumns columns =
    columns |> List.indexedMap (\i c -> { c | index = i }) |> Dict.fromListMap .name


buildRelation : ( String, ( String, String, String ), ( String, String, String ) ) -> Relation
buildRelation ( name, ( srcSchema, srcTable, srcColumn ), ( refSchema, refTable, refColumn ) ) =
    { id = ( ( ( srcSchema, srcTable ), srcColumn ), ( ( refSchema, refTable ), refColumn ) )
    , name = name
    , src = { table = ( srcSchema, srcTable ), column = Nel.from srcColumn }
    , ref = { table = ( refSchema, refTable ), column = Nel.from refColumn }
    , origins = []
    }
