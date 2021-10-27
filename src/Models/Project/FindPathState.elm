module Models.Project.FindPathState exposing (FindPathState(..))

import Models.Project.FindPathResult exposing (FindPathResult)


type FindPathState
    = Empty
    | Searching
    | Found FindPathResult
