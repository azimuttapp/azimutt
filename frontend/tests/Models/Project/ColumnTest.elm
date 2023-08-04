module Models.Project.ColumnTest exposing (..)

import Json.Decode as Decode
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel as Nel exposing (Nel)
import Models.Project.Column as Column exposing (Column, NestedColumns(..))
import Models.Project.Comment exposing (Comment)
import Test exposing (Test, describe)
import TestHelpers.Helpers exposing (testSerdeJson)


suite : Test
suite =
    describe "Column"
        [ describe "serialization"
            [ testSerialization "basic"
                """{"name":"id","type":"int"}"""
                (Column 1 "id" "int" False Nothing Nothing Nothing [])
            , testSerialization "full"
                """{"name":"id","type":"int","nullable":true,"default":"0","comment":{"text":"id col"}}"""
                (Column 1 "id" "int" True (Just "0") (Just (Comment "id col" [])) Nothing [])
            , testSerialization "nested"
                """{"name":"id","type":"Object","columns":[{"name":"kind","type":"string"},{"name":"value","type":"number"}]}"""
                (Column 1
                    "id"
                    "Object"
                    False
                    Nothing
                    Nothing
                    ([ Column 0 "kind" "string" False Nothing Nothing Nothing []
                     , Column 1 "value" "number" False Nothing Nothing Nothing []
                     ]
                        |> Nel.fromList
                        |> Maybe.map (Ned.fromNelMap .name >> NestedColumns)
                    )
                    []
                )
            ]
        ]


testSerialization : String -> String -> Column -> Test
testSerialization name json column =
    testSerdeJson ("Column " ++ name) Column.encode (Column.decode |> Decode.map (\f -> f 1)) column json
