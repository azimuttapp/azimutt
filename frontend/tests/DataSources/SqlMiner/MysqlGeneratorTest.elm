module DataSources.SqlMiner.MysqlGeneratorTest exposing (..)

import DataSources.SqlMiner.MysqlGenerator as MysqlGenerator
import Dict exposing (Dict)
import Expect
import Libs.Dict as Dict
import Libs.Nel as Nel exposing (Nel)
import Models.Project.Column as Column exposing (Column)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Comment exposing (Comment)
import Models.Project.CustomType exposing (CustomType)
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.Relation exposing (Relation)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "MysqlGenerator"
        [ describe "generate"
            [ test "empty" (\_ -> emptySource |> MysqlGenerator.generate |> Expect.equal "")
            , test "empty table" (\_ -> { emptySource | tables = Dict.fromListBy .id [ { emptyTable | name = "users" } ] } |> MysqlGenerator.generate |> Expect.equal "CREATE TABLE users (\n);")
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
                        |> MysqlGenerator.generate
                        |> Expect.equal """CREATE TABLE public.users (
  id uuid NOT NULL,
  name varchar,
  role varchar NOT NULL DEFAULT "guest",
  bio text NOT NULL COMMENT "Hello :)",
  age int DEFAULT 0 COMMENT "hey!"
);"""
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
                                , primaryKey = Just { name = Nothing, columns = Nel.from (Nel.from "id") }
                                , uniques = [ { name = "users_name_unique", columns = Nel.from (Nel.from "name"), definition = Nothing } ]
                                , indexes = [ { name = "users_role_idx", columns = Nel.from (Nel.from "role"), definition = Nothing } ]
                                , checks = [ { name = "users_age_chk", columns = [ Nel.from "age" ], predicate = Nothing } ]
                                , comment = Just { emptyComment | text = "all users" }
                              }
                            ]
                                |> buildTables
                    }
                        |> MysqlGenerator.generate
                        |> Expect.equal """CREATE TABLE public.users (
  id uuid PRIMARY KEY,
  name varchar NOT NULL UNIQUE,
  role varchar NOT NULL INDEX,
  bio text NOT NULL,
  age int NOT NULL CHECK
) COMMENT="all users";"""
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
                                , primaryKey = Just { name = Nothing, columns = Nel "kind" [ "id" ] |> Nel.map Nel.from }
                                , uniques = [ { name = "users_name_unique", columns = Nel "first_name" [ "last_name" ] |> Nel.map Nel.from, definition = Nothing } ]
                                , indexes = [ { name = "users_name_idx", columns = Nel "first_name" [ "last_name" ] |> Nel.map Nel.from, definition = Nothing } ]
                                , checks = [ { name = "users_age_chk", columns = [ "age" ] |> List.map Nel.from, predicate = Just "age > 0" } ]
                                , comment = Just { emptyComment | text = "store \"all\" users" }
                              }
                            ]
                                |> buildTables
                    }
                        |> MysqlGenerator.generate
                        |> Expect.equal """CREATE TABLE users (
  kind varchar,
  id uuid,
  first_name varchar NOT NULL,
  last_name varchar NOT NULL,
  age int NOT NULL CHECK (age > 0),
  PRIMARY KEY (kind, id),
  UNIQUE (first_name, last_name),
  INDEX (first_name, last_name)
) COMMENT="store \\"all\\" users";"""
                )
            , test "table with foreign keys"
                (\_ ->
                    { emptySource
                        | tables =
                            [ { emptyTable | id = ( "", "user_roles" ), name = "user_roles", columns = [ { emptyColumn | name = "user_id", kind = "uuid" }, { emptyColumn | name = "role_id", kind = "uuid" } ] |> buildColumns }
                            , { emptyTable | id = ( "", "users" ), name = "users", columns = [ { emptyColumn | name = "id", kind = "uuid" } ] |> buildColumns }
                            , { emptyTable | id = ( "", "roles" ), name = "roles", columns = [ { emptyColumn | name = "id", kind = "uuid" } ] |> buildColumns }
                            ]
                                |> buildTables
                        , relations =
                            [ ( "user_roles_user_fk", ( "", "user_roles", "user_id" ), ( "", "users", "id" ) )
                            , ( "user_roles_role_fk", ( "", "user_roles", "role_id" ), ( "", "roles", "id" ) )
                            ]
                                |> List.map buildRelation
                    }
                        |> MysqlGenerator.generate
                        |> Expect.equal """CREATE TABLE roles (
  id uuid NOT NULL
);

CREATE TABLE user_roles (
  user_id uuid NOT NULL,
  role_id uuid NOT NULL REFERENCES roles(id)
);

CREATE TABLE users (
  id uuid NOT NULL
);
ALTER TABLE user_roles ADD CONSTRAINT user_roles_user_fk FOREIGN KEY (user_id) REFERENCES users(id);"""
                )
            ]
        ]


emptySource : { tables : Dict TableId Table, relations : List Relation, types : Dict CustomTypeId CustomType }
emptySource =
    { tables = Dict.empty, relations = [], types = Dict.empty }


emptyTable : Table
emptyTable =
    Table.empty


emptyColumn : Column
emptyColumn =
    Column.empty


emptyComment : Comment
emptyComment =
    { text = "" }


buildTables : List Table -> Dict TableId Table
buildTables tables =
    tables |> Dict.fromListBy .id


buildColumns : List Column -> Dict ColumnName Column
buildColumns columns =
    columns |> List.indexedMap (\i c -> { c | index = i }) |> Dict.fromListBy .name


buildRelation : ( String, ( String, String, String ), ( String, String, String ) ) -> Relation
buildRelation ( name, ( srcSchema, srcTable, srcColumn ), ( refSchema, refTable, refColumn ) ) =
    { id = ( ( ( srcSchema, srcTable ), srcColumn ), ( ( refSchema, refTable ), refColumn ) )
    , name = name
    , src = { table = ( srcSchema, srcTable ), column = Nel.from srcColumn }
    , ref = { table = ( refSchema, refTable ), column = Nel.from refColumn }
    }
