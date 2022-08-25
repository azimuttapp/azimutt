module PagesComponents.Projects.Id_.Models.DragState exposing (DragState, hasMoved)

import Libs.Models.DragId exposing (DragId)
import Models.Position as Position


type alias DragState =
    { id : DragId, init : Position.Viewport, last : Position.Viewport }


hasMoved : DragState -> Bool
hasMoved dragging =
    dragging.init /= dragging.last
