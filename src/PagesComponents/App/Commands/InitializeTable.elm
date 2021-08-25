module PagesComponents.App.Commands.InitializeTable exposing (initializeTable)

import Libs.Area exposing (Area)
import Libs.Position exposing (Position)
import Libs.Size exposing (Size)
import Models.Project exposing (TableId)
import PagesComponents.App.Models exposing (Msg(..))
import Random


initializeTable : Size -> Area -> TableId -> Cmd Msg
initializeTable size area id =
    positionGen size area |> Random.generate (InitializedTable id)


positionGen : Size -> Area -> Random.Generator Position
positionGen size area =
    Random.map2 Position
        (Random.float area.left (max area.left (area.right - size.width)))
        (Random.float area.top (max area.top (area.bottom - size.height)))
