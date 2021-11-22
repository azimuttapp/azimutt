module PagesComponents.Projects.Models exposing (Model, Msg(..))

import Models.Project exposing (Project)


type alias Model =
    { navigationActive : String
    , mobileMenuOpen : Bool
    }


type Msg
    = SelectMenu String
    | ToggleMobileMenu
    | DeleteProject Project
