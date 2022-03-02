module PagesComponents.Projects.Id_.Models exposing (ConfirmDialog, ContextMenu, CursorMode(..), FindPathMsg(..), HelpDialog, HelpMsg(..), LayoutDialog, LayoutMsg(..), Model, Msg(..), NavbarModel, ProjectSettingsDialog, ProjectSettingsMsg(..), PromptDialog, SchemaAnalysisDialog, SchemaAnalysisMsg(..), SearchModel, SourceUploadDialog, VirtualRelation, VirtualRelationMsg(..), confirm, prompt, resetCanvas, toastError, toastInfo, toastSuccess, toastWarning)

import Components.Atoms.Icon exposing (Icon(..))
import Components.Molecules.Toast as Toast exposing (Content(..))
import Dict exposing (Dict)
import Html exposing (Html, text)
import Libs.Area exposing (Area)
import Libs.Delta exposing (Delta)
import Libs.Html.Events exposing (PointerEvent, WheelEvent)
import Libs.Models exposing (Millis, ZoomDelta)
import Libs.Models.DragId exposing (DragId)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position exposing (Position)
import Libs.Tailwind as Tw
import Libs.Task as T
import Models.ColumnOrder exposing (ColumnOrder)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.FindPathSettings exposing (FindPathSettings)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectName exposing (ProjectName)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.TableId exposing (TableId)
import Models.ScreenProps exposing (ScreenProps)
import PagesComponents.Projects.Id_.Models.DragState exposing (DragState)
import PagesComponents.Projects.Id_.Models.Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.FindPathDialog exposing (FindPathDialog)
import PagesComponents.Projects.Id_.Models.PositionHint exposing (PositionHint)
import Ports exposing (JsMsg)
import Services.SqlSourceUpload exposing (SqlSourceUpload, SqlSourceUploadMsg)
import Shared exposing (Confirm, Prompt)


type alias Model =
    { navbar : NavbarModel
    , screen : ScreenProps
    , loaded : Bool
    , erd : Maybe Erd
    , hoverTable : Maybe TableId -- TODO remove?
    , hoverColumn : Maybe ColumnRef -- TODO remove?
    , cursorMode : CursorMode
    , selectionBox : Maybe Area
    , newLayout : Maybe LayoutDialog
    , virtualRelation : Maybe VirtualRelation
    , findPath : Maybe FindPathDialog
    , schemaAnalysis : Maybe SchemaAnalysisDialog
    , settings : Maybe ProjectSettingsDialog
    , sourceUpload : Maybe SourceUploadDialog
    , help : Maybe HelpDialog

    -- global attrs
    , openedDropdown : HtmlId
    , openedPopover : HtmlId
    , contextMenu : Maybe ContextMenu
    , dragging : Maybe DragState
    , toastIdx : Int
    , toasts : List Toast.Model
    , confirm : Maybe ConfirmDialog
    , prompt : Maybe PromptDialog
    , openedDialogs : List HtmlId
    }


type alias NavbarModel =
    { mobileMenuOpen : Bool
    , search : SearchModel
    }


type alias SearchModel =
    { text : String, active : Int }


type CursorMode
    = CursorDrag
    | CursorSelect


type alias LayoutDialog =
    { id : HtmlId, name : LayoutName }


type alias VirtualRelation =
    { src : Maybe ColumnRef, mouse : Position }


type alias SchemaAnalysisDialog =
    { id : HtmlId }


type alias ProjectSettingsDialog =
    { id : HtmlId }


type alias SourceUploadDialog =
    { id : HtmlId, parsing : SqlSourceUpload Msg }


type alias HelpDialog =
    { id : HtmlId, openedSection : String }


type alias ContextMenu =
    { content : Html Msg, position : Position, show : Bool }


type alias ConfirmDialog =
    { id : HtmlId, content : Confirm Msg }


type alias PromptDialog =
    { id : HtmlId, content : Prompt Msg, input : String }


type Msg
    = ToggleMobileMenu
    | SearchUpdated String
    | SaveProject
    | RenameProject ProjectName
    | ShowTable TableId (Maybe PositionHint)
    | ShowTables (List TableId) (Maybe PositionHint)
    | ShowAllTables
    | HideTable TableId
    | HideAllTables
    | ShowColumn ColumnRef
    | HideColumn ColumnRef
    | ShowColumns TableId String
    | HideColumns TableId String
    | ToggleHiddenColumns TableId
    | SelectTable TableId Bool
    | TableMove TableId Delta
    | TableOrder TableId Int
    | SortColumns TableId ColumnOrder
    | MoveColumn ColumnRef Int
    | ToggleHoverTable TableId Bool
    | ToggleHoverColumn ColumnRef Bool
    | CreateRelation ColumnRef ColumnRef
    | ResetCanvas
    | LayoutMsg LayoutMsg
    | VirtualRelationMsg VirtualRelationMsg
    | FindPathMsg FindPathMsg
    | SchemaAnalysisMsg SchemaAnalysisMsg
    | ProjectSettingsMsg ProjectSettingsMsg
    | HelpMsg HelpMsg
    | CursorMode CursorMode
    | FitContent
    | OnWheel WheelEvent
    | Zoom ZoomDelta
      -- global messages
    | Focus HtmlId
    | DropdownToggle HtmlId
    | PopoverSet HtmlId
    | ContextMenuCreate (Html Msg) PointerEvent
    | ContextMenuShow
    | ContextMenuClose
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
    | PromptOpen (Prompt Msg) String
    | PromptUpdate String
    | PromptAnswer (Cmd Msg)
    | ModalOpen HtmlId
    | ModalClose Msg
    | JsMessage JsMsg
    | Send (Cmd Msg)
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
    | FPCompute (Dict TableId ErdTable) (List ErdRelation) TableId TableId FindPathSettings
    | FPToggleResult Int
    | FPSettingsUpdate FindPathSettings
    | FPClose


type SchemaAnalysisMsg
    = SAOpen
    | SAClose


type ProjectSettingsMsg
    = PSOpen
    | PSClose
    | PSSourceToggle Source
    | PSSourceDelete Source
    | PSSourceUploadOpen (Maybe Source)
    | PSSourceUploadClose
    | PSSqlSourceMsg SqlSourceUploadMsg
    | PSSourceRefresh Source
    | PSSourceAdd Source
    | PSSchemaToggle SchemaName
    | PSRemoveViewsToggle
    | PSRemovedTablesUpdate String
    | PSHiddenColumnsListUpdate String
    | PSHiddenColumnsPropsToggle
    | PSHiddenColumnsRelationsToggle
    | PSColumnOrderUpdate ColumnOrder
    | PSColumnBasicTypesToggle


type HelpMsg
    = HOpen String
    | HClose
    | HToggle String


toastSuccess : String -> Msg
toastSuccess message =
    ToastAdd (Just 8000) (Simple { color = Tw.green, icon = CheckCircle, title = message, message = "" })


toastInfo : String -> Msg
toastInfo message =
    ToastAdd (Just 8000) (Simple { color = Tw.blue, icon = InformationCircle, title = message, message = "" })


toastWarning : String -> Msg
toastWarning message =
    ToastAdd (Just 8000) (Simple { color = Tw.yellow, icon = ExclamationCircle, title = message, message = "" })


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


prompt : String -> Html Msg -> String -> (String -> Msg) -> Msg
prompt title content input message =
    PromptOpen
        { color = Tw.blue
        , icon = QuestionMarkCircle
        , title = title
        , message = content
        , confirm = "Ok"
        , cancel = "Cancel"
        , onConfirm = message >> T.send
        }
        input


resetCanvas : Msg
resetCanvas =
    ResetCanvas |> confirm "Reset canvas?" (text "You will lose your current canvas state.")
