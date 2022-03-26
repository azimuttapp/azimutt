module PagesComponents.Projects.Id_.Models.DragState exposing (DragState, hasMoved, setLast)

import Libs.Models.DragId exposing (DragId)
import Libs.Models.Position exposing (Position)
import Services.Lenses as Lenses


type alias DragState =
    { id : DragId, init : Position, last : Position }


hasMoved : DragState -> Bool
hasMoved dragging =
    dragging.init /= dragging.last


setLast : Position -> DragState -> DragState
setLast last dragState =
    dragState |> Lenses.setLast last
