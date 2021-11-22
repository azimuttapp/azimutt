module PagesComponents.Projects.Models exposing (Confirm, Model, Msg(..))

import Components.Atoms.Icon exposing (Icon)
import Html.Styled exposing (Html)
import Libs.Models.TwColor exposing (TwColor)
import Models.Project exposing (Project)


type alias Model =
    { navigationActive : String
    , mobileMenuOpen : Bool
    , confirm : Confirm
    }


type alias Confirm =
    { color : TwColor
    , icon : Icon
    , title : String
    , message : Html Msg
    , confirm : String
    , cancel : String
    , cmd : Cmd Msg
    , isOpen : Bool
    }


type Msg
    = SelectMenu String
    | ToggleMobileMenu
    | DeleteProject Project
    | ConfirmOpen Confirm
    | ConfirmAnswer Bool (Cmd Msg)
    | Noop
