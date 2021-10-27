module Models.Project.FindPathStep exposing (FindPathStep)

import Models.Project.FindPathStepDir exposing (FindPathStepDir)
import Models.Project.Relation exposing (Relation)


type alias FindPathStep =
    { relation : Relation, direction : FindPathStepDir }
