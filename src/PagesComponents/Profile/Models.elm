module PagesComponents.Profile.Models exposing (Model, Msg(..))

import Libs.Models.Website exposing (Website)
import Models.User exposing (User)
import Models.Username exposing (Username)
import Ports exposing (JsMsg)


type alias Model =
    { mobileMenuOpen : Bool
    , profileDropdownOpen : Bool
    , user : Maybe User
    , updating : Bool
    }


type Msg
    = ToggleMobileMenu
    | ToggleProfileDropdown
    | UpdateUsername Username
    | UpdateBio String
    | UpdateName String
    | UpdateWebsite Website
    | UpdateLocation String
    | UpdateCompany String
    | UpdateGithub Username
    | UpdateTwitter Username
    | UpdateUser User
    | ResetUser
    | DeleteAccount
    | DoLogout
    | JsMessage JsMsg
    | Noop String
