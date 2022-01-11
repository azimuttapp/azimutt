module PagesComponents.Projects.Id_.Models exposing (ConfirmDialog, CursorMode(..), DragState, FindPathMsg(..), HelpDialog, HelpMsg(..), LayoutDialog, LayoutMsg(..), Model, Msg(..), NavbarModel, ProjectSettingsDialog, ProjectSettingsMsg(..), SourceUploadDialog, VirtualRelation, VirtualRelationMsg(..), confirm, resetCanvas, toastError, toastInfo, toastSuccess, toastWarning)

import Components.Atoms.Icon exposing (Icon(..))
import Components.Molecules.Toast as Toast exposing (Content(..))
import Dict exposing (Dict)
import Html.Styled exposing (Html, text)
import Libs.Area exposing (Area)
import Libs.Html.Events exposing (WheelEvent)
import Libs.Models exposing (Millis, ZoomDelta)
import Libs.Models.Color as Color
import Libs.Models.DragId exposing (DragId)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position exposing (Position)
import Libs.Task as T
import Models.ColumnOrder exposing (ColumnOrder)
import Models.Project exposing (Project)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.FindPathDialog exposing (FindPathDialog)
import Models.Project.FindPathSettings exposing (FindPathSettings)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.Relation exposing (Relation)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Ports exposing (JsMsg)
import Services.SQLSource exposing (SQLSource, SQLSourceMsg)
import Shared exposing (Confirm, StoredProjects)


type alias Model =
    { navbar : NavbarModel
    , projects : StoredProjects
    , project : Maybe Project
    , hoverTable : Maybe TableId
    , hoverColumn : Maybe ColumnRef
    , cursorMode : CursorMode
    , selectionBox : Maybe Area
    , newLayout : Maybe LayoutDialog
    , virtualRelation : Maybe VirtualRelation
    , findPath : Maybe FindPathDialog
    , settings : Maybe ProjectSettingsDialog
    , sourceUpload : Maybe SourceUploadDialog
    , help : Maybe HelpDialog

    -- global attrs
    , openedDropdown : HtmlId
    , dragging : Maybe DragState
    , toastIdx : Int
    , toasts : List Toast.Model
    , confirm : Maybe ConfirmDialog
    , openedDialogs : List HtmlId
    }


type alias NavbarModel =
    { mobileMenuOpen : Bool
    , search : { text : String, active : Int }
    }


type CursorMode
    = CursorDrag
    | CursorSelect


type alias LayoutDialog =
    { id : HtmlId, name : LayoutName }


type alias VirtualRelation =
    { src : Maybe ColumnRef, mouse : Position }


type alias ProjectSettingsDialog =
    { id : HtmlId }


type alias SourceUploadDialog =
    { id : HtmlId, parsing : SQLSource Msg }


type alias HelpDialog =
    { id : HtmlId, openedSection : String }


type alias ConfirmDialog =
    { id : HtmlId, content : Confirm Msg }


type alias DragState =
    { id : DragId, init : Position, last : Position }


type Msg
    = ToggleMobileMenu
    | SearchUpdated String
    | SaveProject
    | ShowTable TableId
    | ShowTables (List TableId)
    | ShowAllTables
    | HideTable TableId
    | HideAllTables
    | ShowColumn ColumnRef
    | HideColumn ColumnRef
    | ShowColumns TableId String
    | HideColumns TableId String
    | ToggleHiddenColumns TableId
    | SelectTable TableId Bool
    | TableOrder TableId Int
    | SortColumns TableId ColumnOrder
    | ToggleHoverTable TableId Bool
    | ToggleHoverColumn ColumnRef Bool
    | ResetCanvas
    | LayoutMsg LayoutMsg
    | VirtualRelationMsg VirtualRelationMsg
    | FindPathMsg FindPathMsg
    | ProjectSettingsMsg ProjectSettingsMsg
    | HelpMsg HelpMsg
    | CursorMode CursorMode
    | FitContent
    | OnWheel WheelEvent
    | Zoom ZoomDelta
      -- global messages
    | Focus HtmlId
    | DropdownToggle HtmlId
    | DragStart DragId Position
    | DragMove Position
    | DragEnd Position
    | DragCancel
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


type LayoutMsg
    = LOpen
    | LEdit LayoutName
    | LCreate LayoutName
    | LCancel
    | LLoad LayoutName
    | LUnload
    | LUpdate LayoutName
    | LDelete LayoutName


type VirtualRelationMsg
    = VRCreate
    | VRUpdate ColumnRef Position
    | VRMove Position
    | VRCancel


type FindPathMsg
    = FPOpen (Maybe TableId) (Maybe TableId)
    | FPToggleSettings
    | FPUpdateFrom (Maybe TableId)
    | FPUpdateTo (Maybe TableId)
    | FPSearch
    | FPCompute (Dict TableId Table) (List Relation) TableId TableId FindPathSettings
    | FPToggleResult Int
    | FPSettingsUpdate FindPathSettings
    | FPClose


type ProjectSettingsMsg
    = PSOpen
    | PSClose
    | PSToggleSource Source
    | PSDeleteSource Source
    | PSSourceUploadOpen (Maybe Source)
    | PSSourceUploadClose
    | PSSQLSourceMsg SQLSourceMsg
    | PSSourceRefresh Source
    | PSSourceAdd Source
    | PSToggleSchema SchemaName
    | PSToggleRemoveViews
    | PSUpdateRemovedTables String
    | PSUpdateHiddenColumns String
    | PSUpdateColumnOrder ColumnOrder


type HelpMsg
    = HOpen String
    | HClose
    | HToggle String


toastSuccess : String -> Msg
toastSuccess message =
    ToastAdd (Just 8000) (Simple { color = Color.green, icon = CheckCircle, title = message, message = "" })


toastInfo : String -> Msg
toastInfo message =
    ToastAdd (Just 8000) (Simple { color = Color.blue, icon = InformationCircle, title = message, message = "" })


toastWarning : String -> Msg
toastWarning message =
    ToastAdd (Just 8000) (Simple { color = Color.yellow, icon = ExclamationCircle, title = message, message = "" })


toastError : String -> Msg
toastError message =
    ToastAdd Nothing (Simple { color = Color.red, icon = Exclamation, title = message, message = "" })


confirm : String -> Html Msg -> Msg -> Msg
confirm title content message =
    ConfirmOpen
        { color = Color.blue
        , icon = QuestionMarkCircle
        , title = title
        , message = content
        , confirm = "Yes!"
        , cancel = "Nope"
        , onConfirm = T.send message
        }


resetCanvas : Msg
resetCanvas =
    ResetCanvas |> confirm "Reset canvas?" (text "You will loose your current canvas state.")
