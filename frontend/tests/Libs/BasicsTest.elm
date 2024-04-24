module Libs.BasicsTest exposing (..)

import Expect
import Fuzz
import Libs.Basics exposing (convertBase, fromDec, inside, prettyNumber, toDec)
import Test exposing (Test, describe, fuzz, test)


suite : Test
suite =
    describe "Basics"
        [ describe "convertBase"
            [ test "10 from 10 to 2" (\_ -> "10" |> convertBase 10 2 |> Expect.equal (Ok "1010"))
            , test "10 from 10 to 8" (\_ -> "10" |> convertBase 10 8 |> Expect.equal (Ok "12"))
            , test "10 from 10 to 10" (\_ -> "10" |> convertBase 10 10 |> Expect.equal (Ok "10"))
            , test "10 from 10 to 16" (\_ -> "10" |> convertBase 10 16 |> Expect.equal (Ok "A"))
            , test "from base is too big" (\_ -> "10" |> convertBase 100 16 |> Expect.equal (Err [ "Base 100 is too big, max is 62" ]))
            , test "from base is too low" (\_ -> "10" |> convertBase 1 16 |> Expect.equal (Err [ "Base 1 is not valid" ]))
            , test "to base is too big" (\_ -> "10" |> convertBase 10 160 |> Expect.equal (Err [ "Base 160 is too big, max is 62" ]))
            , test "to base is too low" (\_ -> "10" |> convertBase 10 1 |> Expect.equal (Err [ "Base 1 is not valid" ]))
            , test "value has an invalid char" (\_ -> "1a" |> convertBase 10 16 |> Expect.equal (Err [ "Invalid digit 'a' for base 10" ]))
            , test "value has many invalid chars" (\_ -> "1a0b" |> convertBase 10 16 |> Expect.equal (Err [ "Invalid digit 'a' for base 10", "Invalid digit 'b' for base 10" ]))
            , test "works for 0" (\_ -> "0" |> convertBase 10 2 |> Expect.equal (Ok "0"))
            , test "works for negative number" (\_ -> "-3" |> convertBase 10 8 |> Expect.equal (Ok "-3"))
            , test "10 from 2 to 8" (\_ -> "1010" |> convertBase 2 8 |> Expect.equal (Ok "12"))
            , test "timestamp 16" (\_ -> "1628861814" |> convertBase 10 16 |> Expect.equal (Ok "61167576"))
            , test "timestamp 36" (\_ -> "1628861814" |> convertBase 10 36 |> Expect.equal (Ok "QXS5TI"))
            , test "timestamp 62" (\_ -> "1628861814" |> convertBase 10 62 |> Expect.equal (Ok "1mEXMk"))
            , test "timestamp ms 62" (\_ -> "1628861814000" |> convertBase 10 62 |> Expect.equal (Ok "Xz10Pw"))
            , test "timestamp min 62" (\_ -> (1628861814 // 60) |> String.fromInt |> convertBase 10 62 |> Expect.equal (Ok "1puM4"))

            -- TODO: , test "uuid to base 62" (\_ -> "ddd21a83-1c7c-4cb0-8813-996c647154b5" |> String.replace "-" "" |> convertBase 16 62 |> Expect.equal (Ok "6kZJxEQe5U4UXndtQ9ceqT"))
            ]
        , describe "fromDec & toDec"
            [ fuzz (Fuzz.pair Fuzz.int (Fuzz.intRange 2 62)) "round-trip" (\( i, base ) -> i |> fromDec base |> Result.andThen (toDec base) |> Expect.equal (Ok i))
            ]
        , describe "prettyNumber"
            [ test "zero" (\_ -> 0 |> prettyNumber |> Expect.equal "0")
            , test "lower than 1" (\_ -> 0.1234 |> prettyNumber |> Expect.equal "0.12")
            , test "lower than 10" (\_ -> 1.234 |> prettyNumber |> Expect.equal "1.2")
            , test "higher than 10" (\_ -> 12.34 |> prettyNumber |> Expect.equal "12")
            ]
        , describe "inside"
            [ test "no change" (\_ -> 10 |> inside 5 15 |> Expect.equal 10)
            , test "smaller" (\_ -> 2 |> inside 5 15 |> Expect.equal 5)
            , test "bigger" (\_ -> 20 |> inside 5 15 |> Expect.equal 15)
            , test "bag range" (\_ -> 20 |> inside 15 5 |> Expect.equal 15) -- min limit is more important
            ]
        ]
