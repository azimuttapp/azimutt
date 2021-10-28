module Libs.DomInfo exposing (DomInfo)

import Libs.Models.Position exposing (Position)
import Libs.Models.Size exposing (Size)


type alias DomInfo =
    { position : Position, size : Size }
