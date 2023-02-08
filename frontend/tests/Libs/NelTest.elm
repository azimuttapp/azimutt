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
        , describe "startsWith"
            [ test "is true when equal" (\_ -> Nel 0 [ 1, 2 ] |> Nel.startsWith (Nel 0 [ 1, 2 ]) |> Expect.equal True)
            , test "is true when shorter" (\_ -> Nel 0 [ 1, 2 ] |> Nel.startsWith (Nel 0 [ 1 ]) |> Expect.equal True)
            , test "is false when longer" (\_ -> Nel 0 [ 1, 2 ] |> Nel.startsWith (Nel 0 [ 1, 2, 3 ]) |> Expect.equal False)
            , test "is false when different" (\_ -> Nel 0 [ 1, 2 ] |> Nel.startsWith (Nel 0 [ 2, 2 ]) |> Expect.equal False)
            ]
        ]
