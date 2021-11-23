module PagesComponents.Projects.Models exposing (Confirm, Model, Msg(..))

import Components.Atoms.Icon exposing (Icon)
import Components.Molecules.Toast as Toast
import Html.Styled exposing (Html)
import Libs.Models exposing (Millis)
import Libs.Models.TwColor exposing (TwColor)
import Models.Project exposing (Project)


type alias Model =
    { navigationActive : String
    , mobileMenuOpen : Bool
    , confirm : Confirm
    , toastCpt : Int
    , toasts : List Toast.Model
    }


type alias Confirm =
    { color : TwColor
    , icon : Icon
    , title : String
    , message : Html Msg
    , confirm : String
    , cancel : String
    , onConfirm : Cmd Msg
    , isOpen : Bool
    }


type Msg
    = SelectMenu String
    | ToggleMobileMenu
    | DeleteProject Project
    | ToastAdd (Maybe Millis) Toast.Content
    | ToastShow (Maybe Millis) String
    | ToastHide String
    | ToastRemove String
    | ConfirmOpen Confirm
    | ConfirmAnswer Bool (Cmd Msg)
    | Noop
