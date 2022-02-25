module PagesComponents.Projects.Id_.Models.DragState exposing (DragState, hasMoved, setLast)

import Libs.Models.DragId exposing (DragId)
import Libs.Models.Position as Position exposing (Position)
import Services.Lenses as Lenses


type alias DragState =
    { id : DragId, init : Position, last : Position }


hasMoved : DragState -> Bool
hasMoved dragging =
    dragging.init /= dragging.last


setLast : Position -> DragState -> DragState
setLast last dragState =
    if (dragState.init |> Position.distance last) < 10 then
        dragState |> Lenses.setLast dragState.init

    else
        dragState |> Lenses.setLast last
