module PagesComponents.Projects.New.Models exposing (Model, Msg(..), Tab(..))

import FileValue exposing (File)
import Libs.Models exposing (FileContent)
import Models.Project exposing (Project)
import Models.Project.ProjectId exposing (ProjectId)
import Models.SourceInfo exposing (SourceInfo)
import Ports exposing (JsMsg)
import Services.SourceParsing.Models exposing (ParsingMsg, ParsingState)


type alias Model =
    { selectedMenu : String
    , mobileMenuOpen : Bool
    , selectedTab : Tab
    , selectedLocalFile : Maybe File
    , selectedSample : Maybe String
    , loadedFile : Maybe ( ProjectId, SourceInfo, FileContent )
    , parsedSchema : Maybe (ParsingState Msg)
    , project : Maybe Project
    }


type Tab
    = Schema
    | Sample


type Msg
    = SelectMenu String
    | ToggleMobileMenu
    | SelectTab Tab
    | SelectLocalFile File
    | SelectSample String
    | FileLoaded ProjectId SourceInfo FileContent
    | ParseMsg ParsingMsg
    | BuildProject
    | DropSchema
    | CreateProject Project
    | JsMessage JsMsg
    | Noop
