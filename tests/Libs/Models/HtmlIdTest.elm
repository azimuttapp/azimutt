module Libs.Models.HtmlIdTest exposing (..)

import Expect
import Libs.Models.HtmlId as HtmlId
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Libs.HtmlId"
        [ describe "from"
            [ test "basic" (\_ -> "hello" |> HtmlId.from |> Expect.equal "hello")
            , test "with -" (\_ -> "hello-you" |> HtmlId.from |> Expect.equal "hello-you")
            , test "with _" (\_ -> "hello_you" |> HtmlId.from |> Expect.equal "hello_you")
            , test "with uppercase" (\_ -> "Hello" |> HtmlId.from |> Expect.equal "hello")
            , test "with space" (\_ -> "hello you" |> HtmlId.from |> Expect.equal "hello-you")
            ]
        ]
