module PagesComponents.Projects.New.Models exposing (ConfirmDialog, Model, Msg(..), Tab(..), confirm)

import Components.Atoms.Icon exposing (Icon(..))
import Html exposing (Html)
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
    , sqlSourceUpload : SqlSourceUpload Msg
    , projectImport : ProjectImport
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
    | ToggleMobileMenu
    | ToggleCollapse HtmlId
    | SelectTab Tab
    | SqlSourceUploadMsg SqlSourceUploadMsg
    | DropSchema
    | CreateProject ProjectId Source
    | ProjectImportMsg ProjectImportMsg
    | DropProject
    | ImportProject Project
    | ImportNewProject ProjectId Project
    | ConfirmOpen (Confirm Msg)
    | ConfirmAnswer Bool (Cmd Msg)
    | ModalOpen HtmlId
    | ModalClose Msg
    | JsMessage JsMsg
    | Noop


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
