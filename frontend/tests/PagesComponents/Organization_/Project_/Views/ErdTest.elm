module PagesComponents.Organization_.Project_.Views.ErdTest exposing (..)

import Expect
import Libs.Models.Platform as Platform
import PagesComponents.Organization_.Project_.Models.CursorMode as CursorMode
import PagesComponents.Organization_.Project_.Views.Erd as Erd
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "PagesComponents.Organization_.Project_.Views.Erd"
        [ describe "viewErd.argsToString"
            [ test "test 1"
                (\_ ->
                    Erd.argsToString Platform.PC CursorMode.Drag Nothing "a" "b" "c"
                        |> Erd.stringToArgs
                        |> Expect.equal ( ( Platform.PC, CursorMode.Drag, Nothing ), ( "a", "b", "c" ) )
                )
            , test "test 2"
                (\_ ->
                    Erd.argsToString Platform.Mac CursorMode.Select (Just ( "public", "users" )) "c" "d" "e"
                        |> Erd.stringToArgs
                        |> Expect.equal ( ( Platform.Mac, CursorMode.Select, Just ( "public", "users" ) ), ( "c", "d", "e" ) )
                )
            ]
        ]
