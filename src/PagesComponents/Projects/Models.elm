module PagesComponents.Projects.Models exposing (Model, Msg(..))

import Ports exposing (JsMsg)


type alias Model =
    { activeMenu : Maybe String
    , profileDropdownOpen : Bool
    , mobileMenuOpen : Bool
    }


type Msg
    = SelectMenu (Maybe String)
    | ToggleProfileDropdown
    | ToggleMobileMenu
    | JsMessage JsMsg
