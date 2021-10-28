module Models.Project.FindPathPath exposing (FindPathPath)

import Libs.Nel exposing (Nel)
import Models.Project.FindPathStep exposing (FindPathStep)


type alias FindPathPath =
    Nel FindPathStep
