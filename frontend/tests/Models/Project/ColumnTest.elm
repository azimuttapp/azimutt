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
                (Column 1 "id" "int" False Nothing Nothing Nothing Nothing [])
                """{"name":"id","type":"int"}"""
            , testEncode "full"
                Column.encode
                (Column 1 "id" "int" True (Just "0") (Just (Comment "id col" [])) (Nel.fromList [ "a" ]) Nothing [])
                """{"name":"id","type":"int","nullable":true,"default":"0","comment":{"text":"id col"},"values":["a"]}"""
            , testEncode "nested"
                Column.encode
                (Column 1
                    "id"
                    "Object"
                    False
                    Nothing
                    Nothing
                    Nothing
                    ([ Column 0 "kind" "string" False Nothing Nothing Nothing Nothing []
                     , Column 1 "value" "number" False Nothing Nothing Nothing Nothing []
                     ]
                        |> Nel.fromList
                        |> Maybe.map (Ned.fromNelMap .name >> NestedColumns)
                    )
                    []
                )
                """{"name":"id","type":"Object","columns":[{"name":"kind","type":"string"},{"name":"value","type":"number"}]}"""
            ]
        ]
