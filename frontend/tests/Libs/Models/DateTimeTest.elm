module Libs.Models.DateTimeTest exposing (..)

import Expect
import Libs.Models.DateTime as DateTime
import Test exposing (Test, describe, test)
import Time


oct1 : Time.Posix
oct1 =
    Time.millisToPosix 1633046400000


suite : Test
suite =
    describe "Libs.Models.DateTime"
        [ describe "parse and format"
            [ test "day" (\_ -> "2021-10-01" |> DateTime.parse |> Result.map (DateTime.format "yyyy-MM-dd" Time.utc) |> Expect.equal (Ok "2021-10-01"))
            , test "parse day" (\_ -> "2021-10-01" |> DateTime.parse |> Expect.equal (Ok oct1))
            , test "format day iso" (\_ -> oct1 |> DateTime.format "yyyy-MM-dd" Time.utc |> Expect.equal "2021-10-01")
            , test "format day human" (\_ -> oct1 |> DateTime.format "MMM dd, yyyy" Time.utc |> Expect.equal "Oct 01, 2021")
            ]
        , describe "human"
            [ test "now" (\_ -> "2023-08-03T18:28:32.652Z" |> DateTime.unsafeParse |> DateTime.human now |> Expect.equal "just now")
            , test "second" (\_ -> "2023-08-03T18:28:31.652Z" |> DateTime.unsafeParse |> DateTime.human now |> Expect.equal "a few seconds ago")
            , test "minute" (\_ -> "2023-08-03T18:27:32.652Z" |> DateTime.unsafeParse |> DateTime.human now |> Expect.equal "a minute ago")
            , test "minutes" (\_ -> "2023-08-03T18:21:32.652Z" |> DateTime.unsafeParse |> DateTime.human now |> Expect.equal "7 minutes ago")
            , test "hour" (\_ -> "2023-08-03T17:28:32.652Z" |> DateTime.unsafeParse |> DateTime.human now |> Expect.equal "an hour ago")
            , test "hours" (\_ -> "2023-08-03T14:28:32.652Z" |> DateTime.unsafeParse |> DateTime.human now |> Expect.equal "4 hours ago")
            , test "day" (\_ -> "2023-08-02T18:28:32.652Z" |> DateTime.unsafeParse |> DateTime.human now |> Expect.equal "a day ago")
            , test "days" (\_ -> "2023-08-01T18:28:32.652Z" |> DateTime.unsafeParse |> DateTime.human now |> Expect.equal "2 days ago")
            , test "month" (\_ -> "2023-07-03T18:28:32.652Z" |> DateTime.unsafeParse |> DateTime.human now |> Expect.equal "a month ago")
            , test "months" (\_ -> "2023-03-03T18:28:32.652Z" |> DateTime.unsafeParse |> DateTime.human now |> Expect.equal "5 months ago")
            , test "year" (\_ -> "2022-08-03T18:28:32.652Z" |> DateTime.unsafeParse |> DateTime.human now |> Expect.equal "a year ago")
            , test "years" (\_ -> "2020-08-03T18:28:32.652Z" |> DateTime.unsafeParse |> DateTime.human now |> Expect.equal "3 years ago")
            , test "long ago" (\_ -> "2013-08-03T18:28:32.652Z" |> DateTime.unsafeParse |> DateTime.human now |> Expect.equal "a long time ago")
            ]
        ]


now : Time.Posix
now =
    "2023-08-03T18:28:32.652Z" |> DateTime.unsafeParse
