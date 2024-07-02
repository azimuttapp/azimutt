module Models.ProjectRef exposing (ProjectRef, one, zero)

import Models.Organization as Organization exposing (Organization)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)


type alias ProjectRef =
    { id : Maybe ProjectId, organization : Maybe Organization }


zero : ProjectRef
zero =
    { id = Just ProjectId.zero, organization = Just Organization.zero }


one : ProjectRef
one =
    { id = Just ProjectId.one, organization = Just Organization.one }
