module Models.Project.FindPathDialog exposing (FindPathDialog)

import Libs.Models.HtmlId exposing (HtmlId)
import Models.Project.FindPathState exposing (FindPathState)
import Models.Project.TableId exposing (TableId)


type alias FindPathDialog =
    { id : HtmlId
    , from : Maybe TableId
    , to : Maybe TableId
    , showSettings : Bool
    , result : FindPathState
    }
