module PagesComponents.Projects.New.Models exposing (Model, Msg(..), Tab(..))

import FileValue exposing (File)
import Libs.Models exposing (FileContent)
import Models.Project exposing (Project)
import Models.Project.ProjectId exposing (ProjectId)
import Models.SourceInfo exposing (SourceInfo)
import PagesComponents.Projects.New.Updates.ProjectParser as ProjectParser
import Ports exposing (JsMsg)


type alias Model =
    { navigationActive : String
    , mobileMenuOpen : Bool
    , tabActive : Tab
    , schemaFile : Maybe File
    , schemaFileContent : Maybe ( ProjectId, SourceInfo, FileContent )
    , schemaParser : Maybe (ProjectParser.Model Msg)
    , project : Maybe Project
    }


type Tab
    = Schema
    | Sample


type Msg
    = SelectMenu String
    | ToggleMobileMenu
    | SelectTab Tab
    | FileDragOver
    | FileDragLeave
    | LoadLocalFile File
    | FileLoaded ProjectId SourceInfo FileContent
    | ParseMsg ProjectParser.Msg
    | BuildProject
    | DropSchema
    | CreateProject Project
    | JsMessage JsMsg
    | Noop
