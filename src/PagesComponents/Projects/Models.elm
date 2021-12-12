module PagesComponents.Projects.Models exposing (Model, Msg(..))

import Components.Molecules.Toast as Toast
import Models.Project exposing (Project)
import Shared exposing (Confirm)



-- TODO migrate these common properties to shared model? How to trigger shared Msg from Projects view?


type alias Model =
    { selectedMenu : String
    , mobileMenuOpen : Bool
    , confirm : Confirm Msg
    , toastCpt : Int
    , toasts : List Toast.Model
    }


type Msg
    = SelectMenu String
    | ToggleMobileMenu
    | DeleteProject Project
    | ConfirmOpen (Confirm Msg)
    | ConfirmAnswer Bool (Cmd Msg)
    | NavigateTo String
    | Noop
