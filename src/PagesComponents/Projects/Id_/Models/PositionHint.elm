module PagesComponents.Projects.Id_.Models.PositionHint exposing (PositionHint(..), move)

import Libs.Models.Delta exposing (Delta)
import Models.Position as Position
import Models.Size as Size


type PositionHint
    = PlaceLeft Position.CanvasGrid
    | PlaceRight Position.CanvasGrid Size.Canvas
    | PlaceAt Position.CanvasGrid


move : Delta -> PositionHint -> PositionHint
move delta hint =
    case hint of
        PlaceLeft pos ->
            PlaceLeft (pos |> Position.moveCanvasGrid delta)

        PlaceRight pos size ->
            PlaceRight (pos |> Position.moveCanvasGrid delta) size

        PlaceAt pos ->
            PlaceAt pos
