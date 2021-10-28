module Models.Project.FindPathResult exposing (FindPathResult)

import Models.Project.FindPathPath exposing (FindPathPath)
import Models.Project.FindPathSettings exposing (FindPathSettings)
import Models.Project.TableId exposing (TableId)


type alias FindPathResult =
    { from : TableId
    , to : TableId
    , paths : List FindPathPath
    , settings : FindPathSettings
    }
