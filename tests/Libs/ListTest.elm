module Libs.ListTest exposing (..)

import Expect
import Libs.List as L
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "List"
        [ describe "addAt"
            [ test "first" (\_ -> [ "b", "c" ] |> L.addAt "a" 0 |> Expect.equal [ "a", "b", "c" ])
            , test "middle" (\_ -> [ "a", "c" ] |> L.addAt "b" 1 |> Expect.equal [ "a", "b", "c" ])
            , test "last" (\_ -> [ "a", "b" ] |> L.addAt "c" 2 |> Expect.equal [ "a", "b", "c" ])
            , test "after" (\_ -> [ "a", "b" ] |> L.addAt "c" 5 |> Expect.equal [ "a", "b", "c" ])
            , test "bad 1" (\_ -> [ "a", "b" ] |> L.addAt "c" -1 |> Expect.equal [ "c", "a", "b" ])
            , test "bad 2" (\_ -> [ "a", "b" ] |> L.addAt "c" -2 |> Expect.equal [ "c", "a", "b" ])
            ]
        , describe "move"
            [ test "move an item from a position to an other" (\_ -> [ 1, 2, 3, 4, 5 ] |> L.move 0 2 |> Expect.equal [ 2, 3, 1, 4, 5 ])
            ]
        , describe "uniqueBy"
            [ test "get unique values" (\_ -> [ { id = 1, name = "a" }, { id = 2, name = "b" }, { id = 1, name = "c" } ] |> L.uniqueBy .id |> Expect.equal [ { id = 1, name = "a" }, { id = 2, name = "b" } ])
            ]
        , describe "dropWhile"
            [ test "drop items while its true" (\_ -> [ 1, 2, 3, 4, 5 ] |> L.dropWhile (\i -> i < 3) |> Expect.equal [ 3, 4, 5 ])
            ]
        , describe "dropUntil"
            [ test "drop items while its false" (\_ -> [ 1, 2, 3, 4, 5 ] |> L.dropUntil (\i -> i == 3) |> Expect.equal [ 3, 4, 5 ])
            ]
        ]
