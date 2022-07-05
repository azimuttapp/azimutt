module PagesComponents.Id_.Models.PositionHint exposing (PositionHint(..), move)

import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size exposing (Size)


type PositionHint
    = PlaceLeft Position
    | PlaceRight Position Size
    | PlaceAt Position


move : Position -> PositionHint -> PositionHint
move position hint =
    case hint of
        PlaceLeft pos ->
            PlaceLeft (pos |> Position.add position)

        PlaceRight pos size ->
            PlaceRight (pos |> Position.add position) size

        PlaceAt pos ->
            PlaceAt pos
