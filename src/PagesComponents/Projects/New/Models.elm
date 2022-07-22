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
import Services.DatabaseSource as DatabaseSource
import Services.ImportProject as ImportProject exposing (Model, Msg)
import Services.JsonSource as JsonSource
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts
import Shared exposing (Confirm)


type alias Model =
    { selectedMenu : String
    , mobileMenuOpen : Bool
    , openedCollapse : HtmlId
    , projects : List ProjectInfo
    , selectedTab : Tab
    , sqlSource : Maybe (SqlSource.Model Msg)
    , databaseSource : Maybe (DatabaseSource.Model Msg)
    , jsonSource : Maybe (JsonSource.Model Msg)
    , importProject : Maybe ImportProject.Model
    , sampleProject : Maybe ImportProject.Model

    -- global attrs
    , openedDropdown : HtmlId
    , toasts : Toasts.Model
    , confirm : Maybe ConfirmDialog
    , openedDialogs : List HtmlId
    }


type Tab
    = TabSql
    | TabDatabase
    | TabJson
    | TabProject
    | TabSamples


type alias ConfirmDialog =
    { id : HtmlId, content : Confirm Msg }


type Msg
    = SelectMenu String
    | Logout
    | ToggleCollapse HtmlId
    | SelectTab Tab
    | SqlSourceMsg SqlSource.Msg
    | SqlSourceDrop
    | DatabaseSourceMsg DatabaseSource.Msg
    | DatabaseSourceDrop
    | JsonSourceMsg JsonSource.Msg
    | JsonSourceDrop
    | ImportProjectMsg ImportProject.Msg
    | ImportProjectDrop
    | SampleProjectMsg ImportProject.Msg
    | SampleProjectDrop
    | CreateProject Project
    | CreateProjectNew Project
    | CreateProjectFromSource Source
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
