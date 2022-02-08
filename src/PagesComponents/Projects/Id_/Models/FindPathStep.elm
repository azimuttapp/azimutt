module PagesComponents.Projects.Id_.Models.FindPathStep exposing (FindPathStep)

import PagesComponents.Projects.Id_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Projects.Id_.Models.FindPathStepDir exposing (FindPathStepDir)


type alias FindPathStep =
    { relation : ErdRelation, direction : FindPathStepDir }
