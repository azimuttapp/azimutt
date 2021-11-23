module PagesComponents.Projects.Models exposing (Model, Msg(..))

import Components.Molecules.Toast as Toast
import Libs.Models exposing (Millis)
import Models.Project exposing (Project)
import Shared exposing (Confirm)



-- TODO migrate these common properties to shared model? How to trigger shared Msg from Projects view?


type alias Model =
    { navigationActive : String
    , mobileMenuOpen : Bool
    , confirm : Confirm Msg
    , toastCpt : Int
    , toasts : List Toast.Model
    }


type Msg
    = SelectMenu String
    | ToggleMobileMenu
    | DeleteProject Project
    | ToastAdd (Maybe Millis) Toast.Content
    | ToastShow (Maybe Millis) String
    | ToastHide String
    | ToastRemove String
    | ConfirmOpen (Confirm Msg)
    | ConfirmAnswer Bool (Cmd Msg)
    | Noop
