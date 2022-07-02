module PagesComponents.Projects.Id_.Models.CursorModeTest exposing (..)

import Expect
import PagesComponents.Projects.Id_.Models.CursorMode as CursorMode exposing (CursorMode(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "PagesComponents.Projects.Id_.Models.CursorMode"
        [ test "fromString / toString" (\_ -> [ Drag, Select ] |> (\all -> all |> List.map CursorMode.toString |> List.map CursorMode.fromString |> Expect.equal all))
        ]
