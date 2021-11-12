module PagesComponents.Projects.Models exposing (Model, Msg(..), StoredProjects(..))

import Models.Project exposing (Project)
import PagesComponents.App.Models exposing (TimeInfo)
import Ports exposing (JsMsg)


type alias Model =
    { activeMenu : Maybe String
    , profileDropdownOpen : Bool
    , mobileMenuOpen : Bool
    , storedProjects : StoredProjects
    , time : TimeInfo
    }


type StoredProjects
    = Loading
    | Loaded (List Project)


type Msg
    = SelectMenu (Maybe String)
    | ToggleProfileDropdown
    | ToggleMobileMenu
    | ProjectsLoaded (List Project)
    | JsMessage JsMsg
