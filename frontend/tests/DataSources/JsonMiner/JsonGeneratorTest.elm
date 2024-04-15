module DataSources.JsonMiner.JsonGeneratorTest exposing (..)

import DataSources.JsonMiner.JsonGenerator as JsonGenerator
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
            [ test "empty" (\_ -> emptySource |> JsonGenerator.generate |> Expect.equal """{
  "tables": [],
  "relations": []
}""")
            , test "empty table" (\_ -> { emptySource | tables = Dict.fromListMap .id [ { emptyTable | name = "users" } ] } |> JsonGenerator.generate |> Expect.equal """{
  "tables": [
    {
      "schema": "",
      "table": "users",
      "columns": []
    }
  ],
  "relations": []
}""")
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
                        |> JsonGenerator.generate
                        |> Expect.equal """{
  "tables": [
    {
      "schema": "public",
      "table": "users",
      "columns": [
        {
          "name": "id",
          "type": "uuid"
        },
        {
          "name": "name",
          "type": "varchar",
          "nullable": true
        },
        {
          "name": "role",
          "type": "varchar",
          "default": "guest"
        },
        {
          "name": "bio",
          "type": "text",
          "comment": "Hello :)"
        },
        {
          "name": "age",
          "type": "int",
          "nullable": true,
          "default": "0",
          "comment": "hey!"
        }
      ]
    }
  ],
  "relations": []
}"""
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
                        |> JsonGenerator.generate
                        |> Expect.equal """{
  "tables": [
    {
      "schema": "public",
      "table": "users",
      "columns": [
        {
          "name": "id",
          "type": "uuid"
        },
        {
          "name": "name",
          "type": "varchar"
        },
        {
          "name": "role",
          "type": "varchar"
        },
        {
          "name": "bio",
          "type": "text"
        },
        {
          "name": "age",
          "type": "int"
        }
      ],
      "primaryKey": {
        "columns": [
          "id"
        ]
      },
      "uniques": [
        {
          "name": "users_name_unique",
          "columns": [
            "name"
          ]
        }
      ],
      "indexes": [
        {
          "name": "users_role_idx",
          "columns": [
            "role"
          ]
        }
      ],
      "checks": [
        {
          "name": "users_age_chk",
          "columns": [
            "age"
          ]
        }
      ],
      "comment": "all users"
    }
  ],
  "relations": []
}"""
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
                        |> JsonGenerator.generate
                        |> Expect.equal """{
  "tables": [
    {
      "schema": "",
      "table": "users",
      "columns": [
        {
          "name": "kind",
          "type": "varchar"
        },
        {
          "name": "id",
          "type": "uuid"
        },
        {
          "name": "first_name",
          "type": "varchar"
        },
        {
          "name": "last_name",
          "type": "varchar"
        },
        {
          "name": "age",
          "type": "int"
        }
      ],
      "primaryKey": {
        "columns": [
          "kind",
          "id"
        ]
      },
      "uniques": [
        {
          "name": "users_name_unique",
          "columns": [
            "first_name",
            "last_name"
          ]
        }
      ],
      "indexes": [
        {
          "name": "users_name_idx",
          "columns": [
            "first_name",
            "last_name"
          ]
        }
      ],
      "checks": [
        {
          "name": "users_age_chk",
          "columns": [
            "age"
          ],
          "predicate": "age > 0"
        }
      ],
      "comment": "store \\"all\\" users"
    }
  ],
  "relations": []
}"""
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
                        |> JsonGenerator.generate
                        |> Expect.equal """{
  "tables": [
    {
      "schema": "",
      "table": "user_roles",
      "columns": [
        {
          "name": "user_id",
          "type": "uuid"
        },
        {
          "name": "role_id",
          "type": "uuid"
        }
      ]
    }
  ],
  "relations": [
    {
      "name": "user_roles_user_fk",
      "src": {
        "schema": "",
        "table": "user_roles",
        "column": "user_id"
      },
      "ref": {
        "schema": "",
        "table": "users",
        "column": "id"
      }
    },
    {
      "name": "user_roles_role_fk",
      "src": {
        "schema": "",
        "table": "user_roles",
        "column": "role_id"
      },
      "ref": {
        "schema": "public",
        "table": "roles",
        "column": "id"
      }
    }
  ]
}"""
                )
            ]
        ]


emptySource : { tables : Dict TableId Table, relations : List Relation, types : Dict CustomTypeId CustomType }
emptySource =
    { tables = Dict.empty, relations = [], types = Dict.empty }


emptyTable : Table
emptyTable =
    { id = ( "", "" ), schema = "", name = "", view = False, definition = Nothing, columns = Dict.empty, primaryKey = Nothing, uniques = [], indexes = [], checks = [], comment = Nothing, stats = Nothing }


emptyColumn : Column
emptyColumn =
    { index = 0, name = "", kind = "", nullable = False, default = Nothing, comment = Nothing, values = Nothing, columns = Nothing, stats = Nothing }


emptyComment : Comment
emptyComment =
    { text = "" }


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
    }
