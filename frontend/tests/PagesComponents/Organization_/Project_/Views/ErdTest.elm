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
                    Erd.argsToString Time.zero Platform.PC CursorMode.Drag "a" "b" "c" Nothing Nothing Nothing
                        |> Erd.stringToArgs
                        |> Expect.equal ( ( Time.zero, Platform.PC, CursorMode.Drag ), ( "a", "b", "c" ), ( Nothing, Nothing, Nothing ) )
                )
            , test "test 2"
                (\_ ->
                    Erd.argsToString (Time.millisToPosix 12) Platform.Mac CursorMode.Select "c" "d" "e" (Just ( "public", "users" )) (Just ( 1, Just "name" )) (Just { index = 1, content = "f" })
                        |> Erd.stringToArgs
                        |> Expect.equal ( ( Time.millisToPosix 12, Platform.Mac, CursorMode.Select ), ( "c", "d", "e" ), ( Just ( "public", "users" ), Just ( 1, Just "name" ), Just { index = 1, content = "f" } ) )
                )
            ]
        ]
