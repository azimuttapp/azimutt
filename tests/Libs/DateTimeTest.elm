module Libs.DateTimeTest exposing (..)

import Expect
import Libs.DateTime as DateTime
import Test exposing (Test, describe, test)
import Time


oct1 : Time.Posix
oct1 =
    Time.millisToPosix 1633046400000


suite : Test
suite =
    describe "DateTime"
        [ describe "parse and format"
            [ test "day" (\_ -> "2021-10-01" |> DateTime.parse |> Result.map (DateTime.format "yyyy-MM-dd" Time.utc) |> Expect.equal (Ok "2021-10-01"))
            , test "parse day" (\_ -> "2021-10-01" |> DateTime.parse |> Expect.equal (Ok oct1))
            , test "format day iso" (\_ -> oct1 |> DateTime.format "yyyy-MM-dd" Time.utc |> Expect.equal "2021-10-01")
            , test "format day human" (\_ -> oct1 |> DateTime.format "MMM dd, yyyy" Time.utc |> Expect.equal "Oct 01, 2021")
            ]
        ]
