module PagesComponents.Projects.New.Models exposing (Model, Msg(..), Tab(..))

import Models.Project exposing (Project)
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.Source exposing (Source)
import Ports exposing (JsMsg)
import Services.SQLSource exposing (SQLSource, SQLSourceMsg)


type alias Model =
    { selectedMenu : String
    , mobileMenuOpen : Bool
    , projects : List Project
    , selectedTab : Tab
    , parsing : SQLSource Msg
    }


type Tab
    = Schema
    | Sample


type Msg
    = SelectMenu String
    | ToggleMobileMenu
    | SelectTab Tab
    | SQLSourceMsg SQLSourceMsg
    | DropSchema
    | CreateProject ProjectId Source
    | JsMessage JsMsg
