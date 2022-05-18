module PagesComponents.Projects.Models exposing (Model, Msg(..))

import Libs.Models.HtmlId exposing (HtmlId)
import PagesComponents.Projects.Id_.Models.ProjectInfo exposing (ProjectInfo)
import Ports exposing (JsMsg)
import Shared exposing (Confirm, StoredProjects)



-- TODO migrate these common properties to shared model? How to trigger shared Msg from Projects view?


type alias Model =
    { selectedMenu : String
    , mobileMenuOpen : Bool
    , projects : StoredProjects

    -- global attrs
    , openedDropdown : HtmlId
    , confirm : Maybe (Confirm Msg)
    , modalOpened : Bool
    }


type Msg
    = SelectMenu String
    | Logout
    | DeleteProject ProjectInfo
      -- global messages
    | DropdownToggle HtmlId
    | ConfirmOpen (Confirm Msg)
    | ConfirmAnswer Bool (Cmd Msg)
    | ModalOpen
    | ModalClose Msg
    | NavigateTo String
    | JsMessage JsMsg
    | Noop String
