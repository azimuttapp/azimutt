module Libs.TimeTest exposing (..)

import Expect
import Json.Decode as Decode
import Libs.Time as Time
import Test exposing (Test, describe, test)
import Time


time : Time.Posix
time =
    Time.millisToPosix 1662981182611


suite : Test
suite =
    describe "Time"
        [ describe "decode"
            [ test "timestamp" (\_ -> "1662981182611" |> Decode.decodeString Time.decode |> Expect.equal (Ok time))
            , test "iso" (\_ -> "\"2022-09-12T11:13:02.611316Z\"" |> Decode.decodeString Time.decode |> Expect.equal (Ok time))
            ]
        ]
