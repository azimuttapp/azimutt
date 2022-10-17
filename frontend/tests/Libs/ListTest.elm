module Libs.ListTest exposing (..)

import Expect
import Libs.List as List
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "List"
        [ describe "get"
            [ test "get item by index" (\_ -> [ "a", "b", "c" ] |> List.get 0 |> Expect.equal (Just "a"))
            , test "get item by index end" (\_ -> [ "a", "b", "c" ] |> List.get 2 |> Expect.equal (Just "c"))
            , test "get nothing on negative index" (\_ -> [ "a", "b", "c" ] |> List.get -1 |> Expect.equal Nothing)
            , test "get nothing on out of array index" (\_ -> [ "a", "b", "c" ] |> List.get 4 |> Expect.equal Nothing)
            ]
        , describe "addAt"
            [ test "first" (\_ -> [ "b", "c" ] |> List.addAt "a" 0 |> Expect.equal [ "a", "b", "c" ])
            , test "middle" (\_ -> [ "a", "c" ] |> List.addAt "b" 1 |> Expect.equal [ "a", "b", "c" ])
            , test "last" (\_ -> [ "a", "b" ] |> List.addAt "c" 2 |> Expect.equal [ "a", "b", "c" ])
            , test "after" (\_ -> [ "a", "b" ] |> List.addAt "c" 5 |> Expect.equal [ "a", "b", "c" ])
            , test "bad 1" (\_ -> [ "a", "b" ] |> List.addAt "c" -1 |> Expect.equal [ "c", "a", "b" ])
            , test "bad 2" (\_ -> [ "a", "b" ] |> List.addAt "c" -2 |> Expect.equal [ "c", "a", "b" ])
            ]
        , describe "move"
            [ test "move an item from a position to an other" (\_ -> [ 1, 2, 3, 4, 5 ] |> List.moveIndex 0 2 |> Expect.equal [ 2, 3, 1, 4, 5 ])
            ]
        , describe "replaceOrAppend"
            [ test "replace a value" (\_ -> [ { id = 1, name = "a" }, { id = 2, name = "b" } ] |> List.replaceOrAppend .id { id = 2, name = "bb" } |> Expect.equal [ { id = 1, name = "a" }, { id = 2, name = "bb" } ])
            , test "append a value" (\_ -> [ { id = 1, name = "a" }, { id = 2, name = "b" } ] |> List.replaceOrAppend .id { id = 3, name = "c" } |> Expect.equal [ { id = 1, name = "a" }, { id = 2, name = "b" }, { id = 3, name = "c" } ])
            ]
        , describe "zipBy"
            [ test "empty lists" (\_ -> List.zipBy identity [] [] |> Expect.equal ( [], [], [] ))
            , test "int lists" (\_ -> List.zipBy identity [ 1, 2, 3 ] [ 2, 4, 6 ] |> Expect.equal ( [ 1, 3 ], [ ( 2, 2 ) ], [ 4, 6 ] ))
            ]
        , describe "dropWhile"
            [ test "drop items while its true" (\_ -> [ 1, 2, 3, 4, 5 ] |> List.dropWhile (\i -> i < 3) |> Expect.equal [ 3, 4, 5 ])
            ]
        , describe "dropUntil"
            [ test "drop items while its false" (\_ -> [ 1, 2, 3, 4, 5 ] |> List.dropUntil (\i -> i == 3) |> Expect.equal [ 3, 4, 5 ])
            ]
        , describe "unique"
            [ test "get unique values" (\_ -> [ "a", "b", "a" ] |> List.unique |> Expect.equal [ "a", "b" ])
            ]
        , describe "uniqueBy"
            [ test "get unique values" (\_ -> [ { id = 1, name = "a" }, { id = 2, name = "b" }, { id = 1, name = "c" } ] |> List.uniqueBy .id |> Expect.equal [ { id = 1, name = "a" }, { id = 2, name = "b" } ])
            ]
        , describe "mergeMaybe"
            [ test "merge similar values"
                (\_ ->
                    List.mergeMaybe .key (\a b -> { a | value = a.value ++ b.value }) [ { key = Nothing, value = "a" }, { key = Just "b", value = "b" } ] [ { key = Nothing, value = "c" }, { key = Just "b", value = "d" } ]
                        |> Expect.equal [ { key = Nothing, value = "a" }, { key = Just "b", value = "bd" }, { key = Nothing, value = "c" } ]
                )
            ]
        ]
