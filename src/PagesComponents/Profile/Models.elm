module PagesComponents.Profile.Models exposing (Model, Msg(..))

import Dict exposing (Dict)
import Ports exposing (JsMsg)


type alias Model =
    { mobileMenuOpen : Bool
    , profileDropdownOpen : Bool
    , toggles : Dict String Bool
    }


type Msg
    = ToggleMobileMenu
    | ToggleProfileDropdown
    | TogglePrivacy String
    | JsMessage JsMsg
    | Noop String
