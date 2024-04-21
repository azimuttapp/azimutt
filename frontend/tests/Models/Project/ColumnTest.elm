module Models.Project.ColumnTest exposing (..)

import Libs.Ned as Ned exposing (Ned)
import Libs.Nel as Nel exposing (Nel)
import Models.Project.Column as Column exposing (Column, NestedColumns(..))
import Models.Project.Comment exposing (Comment)
import Test exposing (Test, describe)
import TestHelpers.Helpers exposing (testEncode)


suite : Test
suite =
    describe "Column"
        [ describe "serialization"
            [ testEncode "basic"
                Column.encode
                { emptyColumn | index = 1, name = "id", kind = "int" }
                """{"name":"id","type":"int"}"""
            , testEncode "full"
                Column.encode
                { emptyColumn | index = 1, name = "id", kind = "int", nullable = True, default = Just "0", comment = Just (Comment "id col"), values = Nel.fromList [ "a" ] }
                """{"name":"id","type":"int","nullable":true,"default":"0","comment":{"text":"id col"},"values":["a"]}"""
            , testEncode "nested"
                Column.encode
                { emptyColumn
                    | index = 1
                    , name = "id"
                    , kind = "Object"
                    , columns =
                        [ { emptyColumn | index = 0, name = "kind", kind = "string" }
                        , { emptyColumn | index = 1, name = "value", kind = "number" }
                        ]
                            |> Nel.fromList
                            |> Maybe.map (Ned.fromNelMap .name >> NestedColumns)
                }
                """{"name":"id","type":"Object","columns":[{"name":"kind","type":"string"},{"name":"value","type":"number"}]}"""
            ]
        ]


emptyColumn : Column
emptyColumn =
    Column.empty
