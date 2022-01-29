module PagesComponents.Projects.Id_.Models.ProjectInfo exposing (ProjectInfo, create)

import Models.Project exposing (Project)
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.ProjectName exposing (ProjectName)
import Time


type alias ProjectInfo =
    { id : ProjectId
    , name : ProjectName
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


create : Project -> ProjectInfo
create project =
    { id = project.id
    , name = project.name
    , createdAt = project.createdAt
    , updatedAt = project.updatedAt
    }
