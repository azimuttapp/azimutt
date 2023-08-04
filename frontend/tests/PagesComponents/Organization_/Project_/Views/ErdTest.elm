module PagesComponents.Organization_.Project_.Views.ErdTest exposing (..)

import Expect
import Libs.Models.Platform as Platform
import Libs.Time as Time
import PagesComponents.Organization_.Project_.Models.CursorMode as CursorMode
import PagesComponents.Organization_.Project_.Views.Erd as Erd
import Test exposing (Test, describe, test)
import Time


suite : Test
suite =
    describe "PagesComponents.Organization_.Project_.Views.Erd"
        [ describe "viewErd.argsToString"
            [ test "test 1"
                (\_ ->
                    Erd.argsToString Platform.PC CursorMode.Drag Nothing "a" "b" "c" Nothing Time.zero
                        |> Erd.stringToArgs
                        |> Expect.equal ( ( Platform.PC, CursorMode.Drag, Nothing ), ( "a", "b", "c" ), ( Nothing, Time.zero ) )
                )
            , test "test 2"
                (\_ ->
                    Erd.argsToString Platform.Mac CursorMode.Select (Just ( "public", "users" )) "c" "d" "e" (Just { index = 1, content = "f" }) (Time.millisToPosix 12)
                        |> Erd.stringToArgs
                        |> Expect.equal ( ( Platform.Mac, CursorMode.Select, Just ( "public", "users" ) ), ( "c", "d", "e" ), ( Just { index = 1, content = "f" }, Time.millisToPosix 12 ) )
                )
            ]
        ]
