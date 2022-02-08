module PagesComponents.Projects.Id_.Models.FindPathDialog exposing (FindPathDialog)

import Libs.Models.HtmlId exposing (HtmlId)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models.FindPathState exposing (FindPathState)


type alias FindPathDialog =
    { id : HtmlId
    , from : Maybe TableId
    , to : Maybe TableId
    , showSettings : Bool
    , result : FindPathState
    }
