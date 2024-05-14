module Models.OpenAIModelTest exposing (..)

import Expect
import Models.OpenAIModel exposing (all, fromString, toString)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "OpenAIModel"
        [ test "to/from string" (\_ -> all |> List.map (toString >> fromString) |> Expect.equal (all |> List.map Just))
        ]
