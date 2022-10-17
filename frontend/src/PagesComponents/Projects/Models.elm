module PagesComponents.Projects.Models exposing (Model, Msg(..))

import Libs.Models.HtmlId exposing (HtmlId)
import Models.ProjectInfo exposing (ProjectInfo)
import Ports exposing (JsMsg)
import Services.Toasts as Toasts exposing (Model, Msg)
import Shared exposing (Confirm)



-- TODO: migrate these common properties to shared model? How to trigger shared Msg from Projects view?


type alias Model =
    { selectedMenu : String
    , mobileMenuOpen : Bool

    -- global attrs
    , openedDropdown : HtmlId
    , toasts : Toasts.Model
    , confirm : Maybe (Confirm Msg)
    , modalOpened : Bool
    }


type Msg
    = SelectMenu String
    | DeleteProject ProjectInfo
      -- global messages
    | DropdownToggle HtmlId
    | Toast Toasts.Msg
    | ConfirmOpen (Confirm Msg)
    | ConfirmAnswer Bool (Cmd Msg)
    | ModalOpen
    | ModalClose Msg
    | JsMessage JsMsg
    | Noop String
