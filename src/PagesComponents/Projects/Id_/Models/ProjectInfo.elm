module PagesComponents.Projects.Id_.Models.ProjectInfo exposing (ProjectInfo, create)

import Models.Project exposing (Project)
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.ProjectName exposing (ProjectName)
import Models.Project.ProjectStorage exposing (ProjectStorage)
import Time


type alias ProjectInfo =
    { id : ProjectId
    , name : ProjectName
    , storage : ProjectStorage
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


create : Project -> ProjectInfo
create project =
    { id = project.id
    , name = project.name
    , storage = project.storage
    , createdAt = project.createdAt
    , updatedAt = project.updatedAt
    }
