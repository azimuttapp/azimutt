module Libs.Html.AttributesTest exposing (..)

import Expect
import Libs.Html.Attributes exposing (computeStyles)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Libs.Html.Attributes"
        [ describe "computeStyles"
            [ test "empty" (\_ -> [] |> computeStyles |> Expect.equal "")
            , test "join" (\_ -> [ "h-6  w-full", " mt-3" ] |> computeStyles |> Expect.equal "h-6 w-full mt-3")
            ]
        ]
