module PagesComponents.Projects.New.Models exposing (Model, Msg(..))


type alias Model =
    { navigationActive : String
    , mobileMenuOpen : Bool
    }


type Msg
    = SelectMenu String
    | ToggleMobileMenu
