module Libs.DomInfo exposing (DomInfo)

import Libs.Position exposing (Position)
import Libs.Size exposing (Size)


type alias DomInfo =
    { position : Position, size : Size }
