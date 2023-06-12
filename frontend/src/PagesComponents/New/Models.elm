module PagesComponents.New.Models exposing (ConfirmDialog, Model, Msg(..), Tab(..), confirm)

import Components.Atoms.Icon exposing (Icon(..))
import Html exposing (Html)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw
import Libs.Task as T
import Models.Project exposing (Project)
import Models.Project.ProjectName exposing (ProjectName)
import Ports exposing (JsMsg)
import Services.Backend as Backend exposing (Sample)
import Services.DatabaseSource as DatabaseSource
import Services.JsonSource as JsonSource
import Services.PrismaSource as PrismaSource
import Services.ProjectSource as ProjectSource exposing (Model, Msg)
import Services.SampleSource as SampleSource
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts
import Shared exposing (Confirm)


type alias Model =
    { selectedMenu : String
    , mobileMenuOpen : Bool
    , openedCollapse : HtmlId
    , samples : List Sample
    , selectedTab : Tab
    , databaseSource : Maybe (DatabaseSource.Model Msg)
    , sqlSource : Maybe (SqlSource.Model Msg)
    , prismaSource : Maybe (PrismaSource.Model Msg)
    , jsonSource : Maybe (JsonSource.Model Msg)
    , projectSource : Maybe ProjectSource.Model
    , sampleSource : Maybe SampleSource.Model

    -- global attrs
    , openedDropdown : HtmlId
    , toasts : Toasts.Model
    , confirm : Maybe ConfirmDialog
    , openedDialogs : List HtmlId
    }


type Tab
    = TabDatabase
    | TabSql
    | TabPrisma
    | TabJson
    | TabEmptyProject
    | TabProject
    | TabSamples


type alias ConfirmDialog =
    { id : HtmlId, content : Confirm Msg }


type Msg
    = SelectMenu String
    | ToggleCollapse HtmlId
    | GotSamples (Result Backend.Error (List Sample))
    | InitTab Tab
    | DatabaseSourceMsg DatabaseSource.Msg
    | SqlSourceMsg SqlSource.Msg
    | PrismaSourceMsg PrismaSource.Msg
    | JsonSourceMsg JsonSource.Msg
    | ProjectSourceMsg ProjectSource.Msg
    | SampleSourceMsg SampleSource.Msg
    | CreateProjectTmp Project
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
