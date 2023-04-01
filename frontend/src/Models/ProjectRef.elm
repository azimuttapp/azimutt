module Models.ProjectRef exposing (ProjectRef, one, zero)

import Models.Organization as Organization exposing (Organization)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)


type alias ProjectRef =
    { organization : Organization
    , id : ProjectId
    }


zero : ProjectRef
zero =
    { organization = Organization.zero, id = ProjectId.zero }


one : ProjectRef
one =
    { organization = Organization.one, id = ProjectId.one }
