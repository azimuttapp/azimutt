module Models.Project.FindPath exposing (FindPath)

import Models.Project.FindPathState exposing (FindPathState)
import Models.Project.TableId exposing (TableId)


type alias FindPath =
    { from : Maybe TableId
    , to : Maybe TableId
    , result : FindPathState
    }
