module Libs.Models.BytesTest exposing (..)

import Expect
import Libs.Models.Bytes as Bytes
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Libs.Models.Bytes"
        [ describe "humanize"
            [ test "bytes" (\_ -> 42 |> Bytes.humanize |> Expect.equal "42 bytes")
            , test "ko" (\_ -> 4056 |> Bytes.humanize |> Expect.equal "4.0 Ko")
            , test "mo" (\_ -> 5872025 |> Bytes.humanize |> Expect.equal "5.6 Mo")
            , test "go" (\_ -> 3435973836 |> Bytes.humanize |> Expect.equal "3.2 Go")
            , test "to" (\_ -> 13194139530000 |> Bytes.humanize |> Expect.equal "12 To")
            , test "po" (\_ -> 385057768100000000 |> Bytes.humanize |> Expect.equal "342 Po")
            ]
        ]
