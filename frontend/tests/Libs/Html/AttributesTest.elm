module Libs.Html.AttributesTest exposing (..)

import Expect
import Libs.Html.Attributes exposing (styles)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Libs.Html.Attributes"
        [ describe "computeStyles"
            [ test "empty" (\_ -> [] |> styles |> Expect.equal "")
            , test "join" (\_ -> [ "h-6  w-full", " mt-3" ] |> styles |> Expect.equal "h-6 w-full mt-3")
            ]
        ]
