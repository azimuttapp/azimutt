module DataSources.DatabaseMiner.Models.DatabaseTypeTest exposing (..)

import DataSources.DatabaseMiner.Models.DatabaseType as DatabaseType
import Expect
import Json.Decode as Decode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "DatabaseType"
        [ describe "decode"
            [ test "enum"
                (\_ ->
                    """{"schema":"public","name":"user_role","values":["guest","admin"]}"""
                        |> Decode.decodeString DatabaseType.decode
                        |> Expect.equal (Ok { schema = "public", name = "user_role", values = Just [ "guest", "admin" ] })
                )
            , test "other"
                (\_ ->
                    """{"schema":"public","name":"user_role","values":null}"""
                        |> Decode.decodeString DatabaseType.decode
                        |> Expect.equal (Ok { schema = "public", name = "user_role", values = Nothing })
                )
            ]
        ]
