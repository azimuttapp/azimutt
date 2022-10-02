module PagesComponents.Organization_.Project_.Models.FindPathStep exposing (FindPathStep)

import PagesComponents.Organization_.Project_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.FindPathStepDir exposing (FindPathStepDir)


type alias FindPathStep =
    { relation : ErdRelation, direction : FindPathStepDir }
