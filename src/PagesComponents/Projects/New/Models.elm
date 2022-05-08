module PagesComponents.Projects.New.Models exposing (ConfirmDialog, Model, Msg(..), Tab(..), confirm, toastError)

import Components.Atoms.Icon exposing (Icon(..))
import Components.Molecules.Toast as Toast exposing (Content(..))
import Html exposing (Html)
import Libs.Models exposing (Millis)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw
import Libs.Task as T
import Models.Project exposing (Project)
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.Source exposing (Source)
import Ports exposing (JsMsg)
import Services.ProjectImport exposing (ProjectImport, ProjectImportMsg)
import Services.SqlSourceUpload exposing (SqlSourceUpload, SqlSourceUploadMsg)
import Shared exposing (Confirm)


type alias Model =
    { selectedMenu : String
    , mobileMenuOpen : Bool
    , openedCollapse : HtmlId
    , projects : List Project
    , selectedTab : Tab
    , sqlSourceUpload : Maybe (SqlSourceUpload Msg)
    , projectImport : Maybe ProjectImport
    , sampleSelection : Maybe ProjectImport

    -- global attrs
    , openedDropdown : HtmlId
    , toastIdx : Int
    , toasts : List Toast.Model
    , confirm : Maybe ConfirmDialog
    , openedDialogs : List HtmlId
    }


type Tab
    = Schema
    | Import
    | Sample


type alias ConfirmDialog =
    { id : HtmlId, content : Confirm Msg }


type Msg
    = SelectMenu String
    | Logout
    | ToggleCollapse HtmlId
    | SelectTab Tab
    | SqlSourceUploadMsg SqlSourceUploadMsg
    | SqlSourceUploadDrop
    | SqlSourceUploadCreate ProjectId Source
    | ProjectImportMsg ProjectImportMsg
    | ProjectImportDrop
    | ProjectImportCreate Project
    | ProjectImportCreateNew ProjectId Project
    | SampleSelectMsg ProjectImportMsg
    | SampleSelectDrop
    | SampleSelectCreate Project
      -- global messages
    | DropdownToggle HtmlId
    | ToastAdd (Maybe Millis) Toast.Content
    | ToastShow (Maybe Millis) String
    | ToastHide String
    | ToastRemove String
    | ConfirmOpen (Confirm Msg)
    | ConfirmAnswer Bool (Cmd Msg)
    | ModalOpen HtmlId
    | ModalClose Msg
    | JsMessage JsMsg
    | Noop String


toastError : String -> Msg
toastError message =
    ToastAdd Nothing (Simple { color = Tw.red, icon = Exclamation, title = message, message = "" })


confirm : String -> Html Msg -> Msg -> Msg
confirm title content message =
    ConfirmOpen
        { color = Tw.blue
        , icon = QuestionMarkCircle
        , title = title
        , message = content
        , confirm = "Yes!"
        , cancel = "Nope"
        , onConfirm = T.send message
        }
