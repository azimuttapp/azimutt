module PagesComponents.Projects.Models exposing (Model, Msg(..))

import Models.Project exposing (Project)


type alias Model =
    { activeMenu : Maybe String
    , profileDropdownOpen : Bool
    , mobileMenuOpen : Bool
    }


type Msg
    = SelectMenu (Maybe String)
    | ToggleProfileDropdown
    | ToggleMobileMenu
    | DeleteProject Project
