module PagesComponents.Projects.Models exposing (Model, Msg(..))

import Components.Molecules.Toast as Toast
import Models.Project exposing (Project)
import Ports exposing (JsMsg)
import Shared exposing (Confirm, StoredProjects)



-- TODO migrate these common properties to shared model? How to trigger shared Msg from Projects view?


type alias Model =
    { selectedMenu : String
    , mobileMenuOpen : Bool
    , projects : StoredProjects
    , confirm : Maybe (Confirm Msg)
    , modalOpened : Bool
    , toastCpt : Int
    , toasts : List Toast.Model
    }


type Msg
    = SelectMenu String
    | ToggleMobileMenu
    | DeleteProject Project
    | ConfirmOpen (Confirm Msg)
    | ConfirmAnswer Bool (Cmd Msg)
    | ModalOpen
    | ModalClose Msg
    | NavigateTo String
    | JsMessage JsMsg
