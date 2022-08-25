module Models.ErdProps exposing (ErdProps, zero)

import Libs.Models.Size as Size exposing (Size)
import Models.Position as Position


type alias ErdProps =
    { position : Position.Viewport -- position of the erd in the viewport
    , size : Size
    }


zero : ErdProps
zero =
    { position = Position.zeroViewport, size = Size.zero }
