module PagesComponents.New.Models exposing (ConfirmDialog, Model, Msg(..), Tab(..), confirm)

import Components.Atoms.Icon exposing (Icon(..))
import Html exposing (Html)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw
import Libs.Task as T
import Models.Project exposing (Project)
import Models.Project.ProjectName exposing (ProjectName)
import Models.ProjectInfo exposing (ProjectInfo)
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
    , databaseSource : Maybe (DatabaseSource.Model Msg)
    , sqlSource : Maybe (SqlSource.Model Msg)
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
    = TabDatabase
    | TabSql
    | TabJson
    | TabEmptyProject
    | TabProject
    | TabSamples


type alias ConfirmDialog =
    { id : HtmlId, content : Confirm Msg }


type Msg
    = SelectMenu String
    | ToggleCollapse HtmlId
    | InitTab Tab
    | DatabaseSourceMsg DatabaseSource.Msg
    | SqlSourceMsg SqlSource.Msg
    | JsonSourceMsg JsonSource.Msg
    | ImportProjectMsg ImportProject.Msg
    | SampleProjectMsg ImportProject.Msg
    | CreateProject Project
    | CreateEmptyProject ProjectName
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
