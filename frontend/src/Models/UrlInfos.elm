module Models.UrlInfos exposing (UrlInfos, empty)

import Models.OrganizationId exposing (OrganizationId)
import Models.Project.ProjectId exposing (ProjectId)


type alias UrlInfos =
    { organization : Maybe OrganizationId
    , project : Maybe ProjectId
    }


empty : UrlInfos
empty =
    { organization = Nothing, project = Nothing }
