module Libs.StringTest exposing (..)

import Expect
import Libs.String exposing (capitalize, hashCode, plural, singular, slugify, splitWords, unique)
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
        , describe "capitalize"
            [ test "upper" (\_ -> "AAA" |> capitalize |> Expect.equal "Aaa")
            , test "lower" (\_ -> "aaa" |> capitalize |> Expect.equal "Aaa")
            ]
        , describe "splitWords"
            [ test "CamelUpper" (\_ -> "AzimuttIsAwesome" |> splitWords |> Expect.equal [ "azimutt", "is", "awesome" ])
            , test "CamelLower" (\_ -> "azimuttIsAwesome" |> splitWords |> Expect.equal [ "azimutt", "is", "awesome" ])
            , test "SnakeUpper" (\_ -> "AZIMUTT_IS_AWESOME" |> splitWords |> Expect.equal [ "azimutt", "is", "awesome" ])
            , test "SnakeLower" (\_ -> "azimutt_is_awesome" |> splitWords |> Expect.equal [ "azimutt", "is", "awesome" ])
            , test "Kebab" (\_ -> "azimutt-is-awesome" |> splitWords |> Expect.equal [ "azimutt", "is", "awesome" ])
            , test "single" (\_ -> splitWords "azimutt" |> Expect.equal [ "azimutt" ])
            , test "single Upper" (\_ -> "AZIMUTT" |> splitWords |> Expect.equal [ "azimutt" ])
            , test "text" (\_ -> "Azimutt is awesome" |> splitWords |> Expect.equal [ "azimutt", "is", "awesome" ])
            , test "complex" (\_ -> "[Azimutt, is awesome!]" |> splitWords |> Expect.equal [ "azimutt", "is", "awesome" ])
            , test "empty" (\_ -> "" |> splitWords |> Expect.equal [])
            ]
        , describe "stringHashCode"
            [ test "compute hello hashcode" (\_ -> hashCode "hello" |> Expect.equal 5170077755645853)
            , test "compute demo hashcode" (\_ -> hashCode "demo" |> Expect.equal 1100405414441372)
            ]
        , describe "plural"
            [ test "simple" (\_ -> plural "cat" |> Expect.equal "cats")
            , test "end with s" (\_ -> plural "bus" |> Expect.equal "buses")
            , test "end with x" (\_ -> plural "index" |> Expect.equal "indexes")
            , test "end with z" (\_ -> plural "blitz" |> Expect.equal "blitzes")
            , test "end with sh" (\_ -> plural "marsh" |> Expect.equal "marshes")
            , test "end with ch" (\_ -> plural "lunch" |> Expect.equal "lunches")
            , test "end with y" (\_ -> plural "try" |> Expect.equal "tries")
            , test "end with ay" (\_ -> plural "ray" |> Expect.equal "rays")
            , test "end with oy" (\_ -> plural "boy" |> Expect.equal "boys")
            ]
        , describe "singular"
            [ test "simple" (\_ -> singular "cats" |> Expect.equal "cat")
            , test "end with s" (\_ -> singular "buses" |> Expect.equal "bus")
            , test "end with x" (\_ -> singular "indexes" |> Expect.equal "index")
            , test "end with z" (\_ -> singular "blitzes" |> Expect.equal "blitz")
            , test "end with sh" (\_ -> singular "marshes" |> Expect.equal "marsh")
            , test "end with ch" (\_ -> singular "lunches" |> Expect.equal "lunch")
            , test "end with y" (\_ -> singular "tries" |> Expect.equal "try")
            , test "end with ay" (\_ -> singular "rays" |> Expect.equal "ray")
            , test "end with oy" (\_ -> singular "boys" |> Expect.equal "boy")
            ]
        , describe "slugify"
            [ test "no change" (\_ -> slugify "already-slug" |> Expect.equal "already-slug")
            , test "simple text" (\_ -> slugify "A title." |> Expect.equal "a-title")
            , test "with diacritics" (\_ -> slugify "àéù" |> Expect.equal "aeu")
            , test "only special chars" (\_ -> slugify "@!:,_&" |> Expect.equal "")
            ]
        ]
