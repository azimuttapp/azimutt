module Libs.NedTest exposing (..)

import Dict
import Expect
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Ned"
        [ describe "fromNel"
            [ test "build" (\_ -> Ned.fromNel (Nel ( 1, "1" ) [ ( 2, "2" ), ( 3, "3" ) ]) |> Expect.equal (Ned ( 1, "1" ) (Dict.fromList [ ( 2, "2" ), ( 3, "3" ) ])))
            , test "with duplicates on head" (\_ -> Ned.fromNel (Nel ( 1, "1" ) [ ( 1, "2" ), ( 3, "3" ) ]) |> Expect.equal (Ned ( 1, "1" ) (Dict.fromList [ ( 3, "3" ) ])))
            , test "with duplicates after head" (\_ -> Ned.fromNel (Nel ( 1, "1" ) [ ( 2, "2" ), ( 1, "3" ) ]) |> Expect.equal (Ned ( 1, "1" ) (Dict.fromList [ ( 2, "2" ) ])))
            ]
        , describe "fromList"
            [ test "build" (\_ -> Ned.fromList [ ( 1, "1" ), ( 2, "2" ), ( 3, "3" ) ] |> Expect.equal (Just (Ned ( 1, "1" ) (Dict.fromList [ ( 2, "2" ), ( 3, "3" ) ]))))
            , test "with duplicates on head" (\_ -> Ned.fromList [ ( 1, "1" ), ( 1, "2" ), ( 3, "3" ) ] |> Expect.equal (Just (Ned ( 1, "1" ) (Dict.fromList [ ( 3, "3" ) ]))))
            , test "with duplicates after head" (\_ -> Ned.fromList [ ( 1, "1" ), ( 2, "2" ), ( 1, "3" ) ] |> Expect.equal (Just (Ned ( 1, "1" ) (Dict.fromList [ ( 2, "2" ) ]))))
            ]
        ]
