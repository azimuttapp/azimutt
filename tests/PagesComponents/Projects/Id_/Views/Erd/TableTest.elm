module PagesComponents.Projects.Id_.Views.Erd.TableTest exposing (..)

import Expect
import Libs.Models.Platform as Platform
import PagesComponents.Projects.Id_.Models.CursorMode as CursorMode
import PagesComponents.Projects.Id_.Views.Erd.Table as Table
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "PagesComponents.Projects.Id_.Views.Erd.Table"
        [ describe "viewTable.argsToString"
            [ test "test 1"
                (\_ ->
                    Table.argsToString Platform.PC CursorMode.Drag "a" "b" "c" 2 True False True False
                        |> Table.stringToArgs
                        |> Expect.equal ( ( Platform.PC, CursorMode.Drag, "a" ), ( "b", "c", 2 ), ( ( True, False ), ( True, False ) ) )
                )
            , test "test 2"
                (\_ ->
                    Table.argsToString Platform.Mac CursorMode.Select "d" "e" "f" 4 False True False True
                        |> Table.stringToArgs
                        |> Expect.equal ( ( Platform.Mac, CursorMode.Select, "d" ), ( "e", "f", 4 ), ( ( False, True ), ( False, True ) ) )
                )
            ]
        ]
