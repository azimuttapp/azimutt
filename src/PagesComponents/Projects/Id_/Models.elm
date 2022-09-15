module PagesComponents.Projects.Id_.Models exposing (AmlSidebar, AmlSidebarMsg(..), ConfirmDialog, ContextMenu, FindPathMsg(..), HelpDialog, HelpMsg(..), LayoutDialog, LayoutMsg(..), Model, Msg(..), NavbarModel, NotesDialog, NotesMsg(..), ProjectSettingsDialog, ProjectSettingsMsg(..), PromptDialog, SchemaAnalysisDialog, SchemaAnalysisMsg(..), SearchModel, SharingDialog, SharingMsg(..), VirtualRelation, VirtualRelationMsg(..), confirm, prompt, simplePrompt)

import Components.Atoms.Icon exposing (Icon(..))
import DataSources.AmlMiner.AmlAdapter exposing (AmlSchemaError)
import Dict exposing (Dict)
import Html exposing (Html, text)
import Libs.Html.Events exposing (PointerEvent, WheelEvent)
import Libs.Models exposing (ZoomDelta)
import Libs.Models.Delta exposing (Delta)
import Libs.Models.DragId exposing (DragId)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw exposing (Color)
import Libs.Task as T
import Models.Area as Area
import Models.ColumnOrder exposing (ColumnOrder)
import Models.ErdProps exposing (ErdProps)
import Models.Organization exposing (Organization)
import Models.Position as Position
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.FindPathSettings exposing (FindPathSettings)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectName exposing (ProjectName)
import Models.Project.ProjectStorage exposing (ProjectStorage)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.SourceName exposing (SourceName)
import Models.Project.TableId exposing (TableId)
import Models.RelationStyle exposing (RelationStyle)
import PagesComponents.Projects.Id_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Projects.Id_.Components.EmbedSourceParsingDialog as EmbedSourceParsingDialog
import PagesComponents.Projects.Id_.Components.ProjectUploadDialog as ProjectUploadDialog exposing (Model, Msg)
import PagesComponents.Projects.Id_.Components.SourceUpdateDialog as SourceUpdateDialog
import PagesComponents.Projects.Id_.Models.CursorMode exposing (CursorMode)
import PagesComponents.Projects.Id_.Models.DragState exposing (DragState)
import PagesComponents.Projects.Id_.Models.EmbedKind exposing (EmbedKind)
import PagesComponents.Projects.Id_.Models.EmbedMode exposing (EmbedModeId)
import PagesComponents.Projects.Id_.Models.Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Projects.Id_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.FindPathDialog exposing (FindPathDialog)
import PagesComponents.Projects.Id_.Models.HideColumns exposing (HideColumns)
import PagesComponents.Projects.Id_.Models.Notes exposing (Notes, NotesRef)
import PagesComponents.Projects.Id_.Models.PositionHint exposing (PositionHint)
import PagesComponents.Projects.Id_.Models.ProjectInfo exposing (ProjectInfo)
import PagesComponents.Projects.Id_.Models.ShowColumns exposing (ShowColumns)
import Ports exposing (JsMsg)
import Services.Toasts as Toasts
import Shared exposing (Confirm, Prompt)


type alias Model =
    { conf : ErdConf
    , navbar : NavbarModel
    , erdElem : ErdProps
    , loaded : Bool
    , erd : Maybe Erd
    , projects : List ProjectInfo
    , hoverTable : Maybe TableId
    , hoverColumn : Maybe ColumnRef
    , cursorMode : CursorMode
    , selectionBox : Maybe Area.Canvas
    , newLayout : Maybe LayoutDialog
    , editNotes : Maybe NotesDialog
    , amlSidebar : Maybe AmlSidebar
    , detailsSidebar : Maybe DetailsSidebar.Model
    , virtualRelation : Maybe VirtualRelation
    , findPath : Maybe FindPathDialog
    , schemaAnalysis : Maybe SchemaAnalysisDialog
    , sharing : Maybe SharingDialog
    , upload : Maybe ProjectUploadDialog.Model
    , settings : Maybe ProjectSettingsDialog
    , sourceUpdate : Maybe (SourceUpdateDialog.Model Msg)
    , embedSourceParsing : Maybe (EmbedSourceParsingDialog.Model Msg)
    , help : Maybe HelpDialog

    -- global attrs
    , openedDropdown : HtmlId
    , openedPopover : HtmlId
    , contextMenu : Maybe ContextMenu
    , dragging : Maybe DragState
    , toasts : Toasts.Model
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


type alias LayoutDialog =
    { id : HtmlId, from : Maybe LayoutName, name : LayoutName }


type alias NotesDialog =
    { id : HtmlId, ref : NotesRef, notes : Notes }


type alias AmlSidebar =
    { id : HtmlId, selected : Maybe SourceId, errors : List AmlSchemaError }


type alias VirtualRelation =
    { src : Maybe ColumnRef, mouse : Position.Viewport }


type alias SchemaAnalysisDialog =
    { id : HtmlId, opened : HtmlId }


type alias SharingDialog =
    { id : HtmlId, kind : EmbedKind, content : String, layout : LayoutName, mode : EmbedModeId }


type alias ProjectSettingsDialog =
    { id : HtmlId }


type alias HelpDialog =
    { id : HtmlId, openedSection : String }


type alias ContextMenu =
    { content : Html Msg, position : Position.Viewport, show : Bool }


type alias ConfirmDialog =
    { id : HtmlId, content : Confirm Msg }


type alias PromptDialog =
    { id : HtmlId, content : Prompt Msg, input : String }


type Msg
    = ToggleMobileMenu
    | SearchUpdated String
    | TriggerSaveProject
    | SaveProject Organization
    | MoveProjectTo ProjectStorage
    | RenameProject ProjectName
    | ShowTable TableId (Maybe PositionHint)
    | ShowTables (List TableId) (Maybe PositionHint)
    | ShowAllTables
    | HideTable TableId
    | ShowRelatedTables TableId
    | HideRelatedTables TableId
    | ToggleColumns TableId
    | ShowColumn ColumnRef
    | HideColumn ColumnRef
    | ShowColumns TableId ShowColumns
    | HideColumns TableId HideColumns
    | SortColumns TableId ColumnOrder
    | ToggleHiddenColumns TableId
    | SelectTable TableId Bool
    | SelectAllTables
    | TableMove TableId Delta
    | TablePosition TableId Position.CanvasGrid
    | TableOrder TableId Int
    | TableColor TableId Color
    | MoveColumn ColumnRef Int
    | ToggleHoverTable TableId Bool
    | ToggleHoverColumn ColumnRef Bool
    | CreateUserSource SourceName
    | CreateUserSourceWithId Source
    | CreateRelation ColumnRef ColumnRef
    | LayoutMsg LayoutMsg
    | NotesMsg NotesMsg
    | AmlSidebarMsg AmlSidebarMsg
    | DetailsSidebarMsg DetailsSidebar.Msg
    | VirtualRelationMsg VirtualRelationMsg
    | FindPathMsg FindPathMsg
    | SchemaAnalysisMsg SchemaAnalysisMsg
    | SharingMsg SharingMsg
    | ProjectUploadMsg ProjectUploadDialog.Msg
    | ProjectSettingsMsg ProjectSettingsMsg
    | EmbedSourceParsingMsg EmbedSourceParsingDialog.Msg
    | SourceParsed Source
    | HelpMsg HelpMsg
    | CursorMode CursorMode
    | FitContent
    | Fullscreen (Maybe HtmlId)
    | OnWheel WheelEvent
    | Zoom ZoomDelta
      -- global messages
    | Focus HtmlId
    | DropdownToggle HtmlId
    | DropdownOpen HtmlId
    | DropdownClose
    | PopoverSet HtmlId
    | ContextMenuCreate (Html Msg) PointerEvent
    | ContextMenuShow
    | ContextMenuClose
    | DragStart DragId Position.Viewport
    | DragMove Position.Viewport
    | DragEnd Position.Viewport
    | DragCancel
    | Toast Toasts.Msg
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
    = LOpen (Maybe LayoutName)
    | LEdit LayoutName
    | LCreate (Maybe LayoutName) LayoutName
    | LCancel
    | LLoad LayoutName
    | LDelete LayoutName


type NotesMsg
    = NOpen NotesRef
    | NEdit Notes
    | NSave NotesRef Notes
    | NCancel


type AmlSidebarMsg
    = AOpen
    | AClose
    | AToggle
    | AChangeSource (Maybe SourceId)
    | AUpdateSource SourceId String


type VirtualRelationMsg
    = VRCreate (Maybe ColumnRef)
    | VRUpdate ColumnRef Position.Viewport
    | VRMove Position.Viewport
    | VRCancel


type FindPathMsg
    = FPOpen (Maybe TableId) (Maybe TableId)
    | FPToggleSettings
    | FPUpdateFrom String
    | FPUpdateTo String
    | FPSearch
    | FPCompute (Dict TableId ErdTable) (List ErdRelation) TableId TableId FindPathSettings
    | FPToggleResult Int
    | FPSettingsUpdate FindPathSettings
    | FPClose


type SchemaAnalysisMsg
    = SAOpen
    | SASectionToggle HtmlId
    | SAClose


type SharingMsg
    = SOpen
    | SClose
    | SKindUpdate EmbedKind
    | SContentUpdate String
    | SLayoutUpdate LayoutName
    | SModeUpdate EmbedModeId


type ProjectSettingsMsg
    = PSOpen
    | PSClose
    | PSSourceToggle Source
    | PSSourceDelete Source
    | PSSourceUpdate SourceUpdateDialog.Msg
    | PSSourceSet Source
    | PSDefaultSchemaUpdate SchemaName
    | PSSchemaToggle SchemaName
    | PSRemoveViewsToggle
    | PSRemovedTablesUpdate String
    | PSHiddenColumnsListUpdate String
    | PSHiddenColumnsMaxUpdate String
    | PSHiddenColumnsPropsToggle
    | PSHiddenColumnsRelationsToggle
    | PSColumnOrderUpdate ColumnOrder
    | PSRelationStyleUpdate RelationStyle
    | PSColumnBasicTypesToggle
    | PSCollapseTableOnShowToggle


type HelpMsg
    = HOpen String
    | HClose
    | HToggle String


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


simplePrompt : String -> (String -> Msg) -> Msg
simplePrompt label message =
    PromptOpen
        { color = Tw.blue
        , icon = QuestionMarkCircle
        , title = label
        , message = text ""
        , confirm = "Ok"
        , cancel = "Cancel"
        , onConfirm = message >> T.send
        }
        ""
