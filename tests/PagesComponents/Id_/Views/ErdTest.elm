module PagesComponents.Id_.Views.ErdTest exposing (..)

import Expect
import Libs.Models.Platform as Platform
import PagesComponents.Id_.Models.CursorMode as CursorMode
import PagesComponents.Id_.Views.Erd as Erd
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "PagesComponents.Id_.Views.Erd"
        [ describe "viewErd.argsToString"
            [ test "test 1"
                (\_ ->
                    Erd.argsToString Platform.PC CursorMode.Drag "a" "b"
                        |> Erd.stringToArgs
                        |> Expect.equal ( ( Platform.PC, CursorMode.Drag ), ( "a", "b" ) )
                )
            , test "test 2"
                (\_ ->
                    Erd.argsToString Platform.Mac CursorMode.Select "c" "d"
                        |> Erd.stringToArgs
                        |> Expect.equal ( ( Platform.Mac, CursorMode.Select ), ( "c", "d" ) )
                )
            ]
        ]
