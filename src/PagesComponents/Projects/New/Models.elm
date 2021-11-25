module PagesComponents.Projects.New.Models exposing (Model, Msg(..), Tab(..))


type alias Model =
    { navigationActive : String
    , mobileMenuOpen : Bool
    , tabActive : Tab
    }


type Tab
    = Schema
    | Sample


type Msg
    = SelectMenu String
    | ToggleMobileMenu
    | SelectTab Tab
