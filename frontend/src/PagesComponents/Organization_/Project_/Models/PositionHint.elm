module PagesComponents.Organization_.Project_.Models.PositionHint exposing (PositionHint(..), move)

import Libs.Models.Delta exposing (Delta)
import Models.Position as Position
import Models.Size as Size


type PositionHint
    = PlaceLeft Position.Grid
    | PlaceRight Position.Grid Size.Canvas
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
