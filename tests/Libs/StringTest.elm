module Libs.StringTest exposing (..)

import Expect
import Libs.String exposing (hashCode, plural, unique, wordSplit)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "String"
        [ describe "unique"
            [ test "no conflict" (\_ -> unique [] "aaa" |> Expect.equal "aaa")
            , test "conflict" (\_ -> unique [ "bbb" ] "bbb" |> Expect.equal "bbb2")
            , test "conflict with number" (\_ -> unique [ "ccc2" ] "ccc2" |> Expect.equal "ccc3")
            , test "conflict with extension" (\_ -> unique [ "ddd.txt" ] "ddd.txt" |> Expect.equal "ddd2.txt")
            , test "conflict with extension and number" (\_ -> unique [ "eee2.txt" ] "eee2.txt" |> Expect.equal "eee3.txt")
            , test "multi conflicts" (\_ -> unique [ "fff.txt", "fff2.txt", "fff3.txt" ] "fff.txt" |> Expect.equal "fff4.txt")
            ]
        , describe "stringWordSplit"
            [ test "words are not split" (\_ -> wordSplit "test" |> Expect.equal [ "test" ])
            , test "split works on _" (\_ -> wordSplit "table_test" |> Expect.equal [ "table", "test" ])
            , test "split works on -" (\_ -> wordSplit "table-test" |> Expect.equal [ "table", "test" ])
            , test "split works on space" (\_ -> wordSplit "table test" |> Expect.equal [ "table", "test" ])
            ]
        , describe "stringHashCode"
            [ test "compute hello hashcode" (\_ -> hashCode "hello" |> Expect.equal -641073152)
            , test "compute demo hashcode" (\_ -> hashCode "demo" |> Expect.equal 179990644)
            ]
        , describe "plural"
            [ test "simple" (\_ -> plural "cat" |> Expect.equal "cats")
            , test "end with s" (\_ -> plural "bus" |> Expect.equal "buses")
            , test "end with x" (\_ -> plural "index" |> Expect.equal "indexes")
            , test "end with z" (\_ -> plural "blitz" |> Expect.equal "blitzes")
            , test "end with sh" (\_ -> plural "marsh" |> Expect.equal "marshes")
            , test "end with ch" (\_ -> plural "lunch" |> Expect.equal "lunches")
            , test "end with y" (\_ -> plural "blitz" |> Expect.equal "blitzes")
            , test "end with ay" (\_ -> plural "ray" |> Expect.equal "rays")
            , test "end with oy" (\_ -> plural "boy" |> Expect.equal "boys")
            ]
        ]
