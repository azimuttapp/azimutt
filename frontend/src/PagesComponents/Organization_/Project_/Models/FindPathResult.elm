module PagesComponents.Organization_.Project_.Models.FindPathResult exposing (FindPathResult)

import Models.Project.FindPathSettings exposing (FindPathSettings)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Organization_.Project_.Models.FindPathPath exposing (FindPathPath)


type alias FindPathResult =
    { from : TableId
    , to : TableId
    , paths : List FindPathPath
    , opened : Maybe Int
    , settings : FindPathSettings
    }
