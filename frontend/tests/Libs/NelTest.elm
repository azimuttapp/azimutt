module Libs.NelTest exposing (..)

import Expect
import Libs.Nel as Nel exposing (Nel)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Nel"
        [ describe "indexedMap"
            [ test "basic" (\_ -> Nel "0" [ "1", "2" ] |> Nel.indexedMap (\i v -> ( i, v )) |> Expect.equal (Nel ( 0, "0" ) [ ( 1, "1" ), ( 2, "2" ) ]))
            ]
        ]
