module PagesComponents.Projects.Models exposing (Model, Msg(..))

import Models.Project exposing (Project)


type alias Model =
    { navigationActive : String
    , profileOpen : Bool
    , mobileMenuOpen : Bool
    }


type Msg
    = SelectMenu String
    | ToggleProfileDropdown
    | ToggleMobileMenu
    | DeleteProject Project
