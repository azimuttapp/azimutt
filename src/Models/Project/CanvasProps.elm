module Models.Project.CanvasProps exposing (CanvasProps)

import Libs.Models exposing (ZoomLevel)
import Libs.Position exposing (Position)


type alias CanvasProps =
    { position : Position, zoom : ZoomLevel }
