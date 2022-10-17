module PagesComponents.Organization_.Project_.Models.FindPathDialog exposing (FindPathDialog)

import Libs.Models.HtmlId exposing (HtmlId)
import PagesComponents.Organization_.Project_.Models.FindPathState exposing (FindPathState)


type alias FindPathDialog =
    { id : HtmlId
    , from : String
    , to : String
    , showSettings : Bool
    , result : FindPathState
    }
