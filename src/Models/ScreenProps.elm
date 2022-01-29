module Models.ScreenProps exposing (ScreenProps, zero)

import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size exposing (Size)


type alias ScreenProps =
    { position : Position
    , size : Size
    }


zero : ScreenProps
zero =
    { position = Position.zero, size = Size.zero }
