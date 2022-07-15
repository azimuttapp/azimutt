module PagesComponents.Projects.New.Models exposing (ConfirmDialog, Model, Msg(..), Tab(..), confirm)

import Components.Atoms.Icon exposing (Icon(..))
import Html exposing (Html)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw
import Libs.Task as T
import Models.Project exposing (Project)
import Models.Project.Source exposing (Source)
import PagesComponents.Projects.Id_.Models.ProjectInfo exposing (ProjectInfo)
import Ports exposing (JsMsg)
import Random
import Services.DatabaseSource as DatabaseSource
import Services.ProjectImport exposing (ProjectImport, ProjectImportMsg)
import Services.SqlSourceUpload exposing (SqlSourceUpload, SqlSourceUploadMsg)
import Services.Toasts as Toasts
import Shared exposing (Confirm)


type alias Model =
    { seed : Random.Seed
    , selectedMenu : String
    , mobileMenuOpen : Bool
    , openedCollapse : HtmlId
    , projects : List ProjectInfo
    , selectedTab : Tab
    , sqlSourceUpload : Maybe (SqlSourceUpload Msg)
    , databaseSource : Maybe DatabaseSource.Model
    , projectImport : Maybe ProjectImport
    , sampleSelection : Maybe ProjectImport

    -- global attrs
    , openedDropdown : HtmlId
    , toasts : Toasts.Model
    , confirm : Maybe ConfirmDialog
    , openedDialogs : List HtmlId
    }


type Tab
    = TabSql
    | TabDatabase
    | TabProject
    | TabSamples


type alias ConfirmDialog =
    { id : HtmlId, content : Confirm Msg }


type Msg
    = SelectMenu String
    | Logout
    | ToggleCollapse HtmlId
    | SelectTab Tab
    | SqlSourceUploadMsg SqlSourceUploadMsg
    | SqlSourceUploadDrop
    | DatabaseSourceMsg DatabaseSource.Msg
    | ProjectImportMsg ProjectImportMsg
    | ProjectImportDrop
    | SampleSelectMsg ProjectImportMsg
    | SampleSelectDrop
    | CreateProjectFromSource Source
    | CreateProject Project
      -- global messages
    | DropdownToggle HtmlId
    | Toast Toasts.Msg
    | ConfirmOpen (Confirm Msg)
    | ConfirmAnswer Bool (Cmd Msg)
    | ModalOpen HtmlId
    | ModalClose Msg
    | JsMessage JsMsg
    | Noop String


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
