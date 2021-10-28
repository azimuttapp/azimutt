module PagesComponents.App.Commands.InitializeTable exposing (initializeTable)

import Libs.Area exposing (Area)
import Libs.Models.Position exposing (Position)
import Libs.Models.Size exposing (Size)
import Models.Project.TableId exposing (TableId)
import PagesComponents.App.Models exposing (Msg(..))
import Random


initializeTable : Size -> Area -> TableId -> Cmd Msg
initializeTable size area id =
    positionGen size area |> Random.generate (InitializedTable id)


positionGen : Size -> Area -> Random.Generator Position
positionGen size area =
    Random.map2 Position
        (Random.float 0 (max 0 (area.size.width - size.width)) |> Random.map (\v -> area.position.left + v))
        (Random.float 0 (max 0 (area.size.height - size.height)) |> Random.map (\v -> area.position.top + v))
