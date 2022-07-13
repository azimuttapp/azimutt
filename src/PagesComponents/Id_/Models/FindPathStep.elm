module PagesComponents.Id_.Models.FindPathStep exposing (FindPathStep)

import PagesComponents.Id_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Id_.Models.FindPathStepDir exposing (FindPathStepDir)


type alias FindPathStep =
    { relation : ErdRelation, direction : FindPathStepDir }
