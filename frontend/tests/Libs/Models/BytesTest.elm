module Libs.Models.BytesTest exposing (..)

import Expect
import Libs.Models.Bytes as Bytes
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Libs.Models.Bytes"
        [ describe "humanize"
            [ test "bytes" (\_ -> 42 |> Bytes.humanize |> Expect.equal "42 bytes")
            , test "ko" (\_ -> 4056 |> Bytes.humanize |> Expect.equal "4.1 ko")
            , test "mo" (\_ -> 5872025 |> Bytes.humanize |> Expect.equal "5.9 Mo")
            , test "go" (\_ -> 3435973836 |> Bytes.humanize |> Expect.equal "3.4 Go")
            , test "to" (\_ -> 13194139530000 |> Bytes.humanize |> Expect.equal "13 To")
            , test "po" (\_ -> 385057768100000000 |> Bytes.humanize |> Expect.equal "385 Po")
            ]
        ]
