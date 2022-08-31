module Models.ErdProps exposing (ErdProps, zero)

import Models.Position as Position
import Models.Size as Size


type alias ErdProps =
    { position : Position.Viewport -- position of the erd in the viewport
    , size : Size.Viewport
    }


zero : ErdProps
zero =
    { position = Position.zeroViewport, size = Size.zeroViewport }
