module PagesComponents.Projects.Id_.Models.PositionHint exposing (PositionHint(..), move)

import Libs.Delta exposing (Delta)
import Libs.Models.Size exposing (Size)
import Models.Position as Position


type PositionHint
    = PlaceLeft Position.Grid
    | PlaceRight Position.Grid Size
    | PlaceAt Position.Grid


move : Delta -> PositionHint -> PositionHint
move delta hint =
    case hint of
        PlaceLeft pos ->
            PlaceLeft (pos |> Position.moveGrid delta)

        PlaceRight pos size ->
            PlaceRight (pos |> Position.moveGrid delta) size

        PlaceAt pos ->
            PlaceAt pos
