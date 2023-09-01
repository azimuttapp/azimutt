module DataSources.JsonMiner.Models.JsonTableTest exposing (..)

import DataSources.JsonMiner.Models.JsonTable as JsonTable exposing (JsonColumn, JsonNestedColumns(..))
import Expect
import Json.Decode as Decode
import Libs.Nel as Nel
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "JsonTable"
        [ describe "decodeJsonColumn"
            [ test "basic"
                (\_ ->
                    """{"name":"id","type":"int"}"""
                        |> Decode.decodeString JsonTable.decodeJsonColumn
                        |> Expect.equal (Ok (JsonColumn "id" "int" Nothing Nothing Nothing Nothing Nothing))
                )
            , test "full"
                (\_ ->
                    """{"name":"id","type":"int","nullable":false,"default":"0","comment":"id col","values":["a","b"]}"""
                        |> Decode.decodeString JsonTable.decodeJsonColumn
                        |> Expect.equal (Ok (JsonColumn "id" "int" (Just False) (Just "0") (Just "id col") (Nel.fromList [ "a", "b" ]) Nothing))
                )
            , test "empty nested"
                (\_ ->
                    """{"name":"id","type":"int","columns":[]}"""
                        |> Decode.decodeString JsonTable.decodeJsonColumn
                        |> Expect.equal (Ok (JsonColumn "id" "int" Nothing Nothing Nothing Nothing Nothing))
                )
            , test "nested"
                (\_ ->
                    """{"name":"id","type":"Object","columns":[{"name":"kind","type":"string"}, {"name":"value","type":"number"}]}"""
                        |> Decode.decodeString JsonTable.decodeJsonColumn
                        |> Expect.equal
                            (Ok
                                (JsonColumn "id"
                                    "Object"
                                    Nothing
                                    Nothing
                                    Nothing
                                    Nothing
                                    ([ JsonColumn "kind" "string" Nothing Nothing Nothing Nothing Nothing
                                     , JsonColumn "value" "number" Nothing Nothing Nothing Nothing Nothing
                                     ]
                                        |> Nel.fromList
                                        |> Maybe.map JsonNestedColumns
                                    )
                                )
                            )
                )
            ]
        ]
