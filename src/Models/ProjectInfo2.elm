module Models.ProjectInfo2 exposing (ProjectInfo2)

import Libs.Models.Slug exposing (Slug)
import Models.Organization exposing (Organization)
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.ProjectName exposing (ProjectName)
import Models.Project.ProjectStorage exposing (ProjectStorage)
import Time


type alias ProjectInfo2 =
    { organization : Organization
    , id : ProjectId
    , slug : Slug
    , name : ProjectName
    , description : Maybe String
    , encodingVersion : Int
    , storage : ProjectStorage
    , nbSources : Int
    , nbTables : Int
    , nbColumns : Int
    , nbRelations : Int
    , nbTypes : Int
    , nbComments : Int
    , nbNotes : Int
    , nbLayouts : Int
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    , archivedAt : Maybe Time.Posix
    }
