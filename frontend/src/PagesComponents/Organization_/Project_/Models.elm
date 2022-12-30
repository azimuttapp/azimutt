module PagesComponents.Organization_.Project_.Models exposing (AmlSidebar, AmlSidebarMsg(..), ConfirmDialog, ContextMenu, FindPathMsg(..), HelpDialog, HelpMsg(..), LayoutMsg(..), MemoEdit, MemoMsg(..), ModalDialog, Model, Msg(..), NavbarModel, NotesDialog, NotesMsg(..), ProjectSettingsDialog, ProjectSettingsMsg(..), PromptDialog, SchemaAnalysisDialog, SchemaAnalysisMsg(..), SearchModel, SharingDialog, SharingMsg(..), VirtualRelation, VirtualRelationMsg(..), confirm, confirmDanger, prompt, simplePrompt)

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
import Models.Project.ColumnId exposing (ColumnId)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.ColumnStats exposing (ColumnStats)
import Models.Project.FindPathSettings exposing (FindPathSettings)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectName exposing (ProjectName)
import Models.Project.ProjectStorage exposing (ProjectStorage)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId exposing (SourceId, SourceIdStr)
import Models.Project.SourceName exposing (SourceName)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableStats exposing (TableStats)
import Models.ProjectInfo exposing (ProjectInfo)
import Models.RelationStyle exposing (RelationStyle)
import PagesComponents.Organization_.Project_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Organization_.Project_.Components.EmbedSourceParsingDialog as EmbedSourceParsingDialog
import PagesComponents.Organization_.Project_.Components.ProjectSaveDialog as ProjectSaveDialog
import PagesComponents.Organization_.Project_.Components.SourceUpdateDialog as SourceUpdateDialog
import PagesComponents.Organization_.Project_.Models.CursorMode exposing (CursorMode)
import PagesComponents.Organization_.Project_.Models.DragState exposing (DragState)
import PagesComponents.Organization_.Project_.Models.EmbedKind exposing (EmbedKind)
import PagesComponents.Organization_.Project_.Models.EmbedMode exposing (EmbedModeId)
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.FindPathDialog exposing (FindPathDialog)
import PagesComponents.Organization_.Project_.Models.HideColumns exposing (HideColumns)
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import PagesComponents.Organization_.Project_.Models.MemoId exposing (MemoId)
import PagesComponents.Organization_.Project_.Models.Notes exposing (Notes, NotesRef)
import PagesComponents.Organization_.Project_.Models.PositionHint exposing (PositionHint)
import PagesComponents.Organization_.Project_.Models.ShowColumns exposing (ShowColumns)
import PagesComponents.Organization_.Project_.Views.Modals.NewLayout as NewLayout
import Ports exposing (JsMsg)
import Services.Toasts as Toasts
import Set exposing (Set)
import Shared exposing (Confirm, Prompt)


type alias Model =
    { conf : ErdConf
    , navbar : NavbarModel
    , erdElem : ErdProps
    , loaded : Bool
    , dirty : Bool
    , erd : Maybe Erd
    , tableStats : Dict TableId (Dict SourceIdStr TableStats)
    , columnStats : Dict ColumnId (Dict SourceIdStr ColumnStats)
    , hoverTable : Maybe TableId
    , hoverColumn : Maybe ColumnRef
    , cursorMode : CursorMode
    , selectionBox : Maybe Area.Canvas
    , newLayout : Maybe NewLayout.Model
    , editNotes : Maybe NotesDialog
    , editMemo : Maybe MemoEdit
    , amlSidebar : Maybe AmlSidebar
    , detailsSidebar : Maybe DetailsSidebar.Model
    , virtualRelation : Maybe VirtualRelation
    , findPath : Maybe FindPathDialog
    , schemaAnalysis : Maybe SchemaAnalysisDialog
    , sharing : Maybe SharingDialog
    , save : Maybe ProjectSaveDialog.Model
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
    , modal : Maybe ModalDialog
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


type alias NotesDialog =
    { id : HtmlId, ref : NotesRef, notes : Notes }


type alias MemoEdit =
    { id : MemoId, content : String }


type alias AmlSidebar =
    { id : HtmlId, selected : Maybe SourceId, errors : List AmlSchemaError, otherSourcesTableIdsCache : Set TableId }


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


type alias ModalDialog =
    { id : HtmlId, content : Msg -> String -> Html Msg }


type alias ConfirmDialog =
    { id : HtmlId, content : Confirm Msg }


type alias PromptDialog =
    { id : HtmlId, content : Prompt Msg, input : String }


type Msg
    = ToggleMobileMenu
    | SearchUpdated String
    | TriggerSaveProject
    | CreateProject ProjectName Organization ProjectStorage
    | UpdateProject
    | MoveProjectTo ProjectStorage
    | RenameProject ProjectName
    | DeleteProject ProjectInfo
    | GoToTable TableId
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
    | NewLayoutMsg NewLayout.Msg
    | LayoutMsg LayoutMsg
    | NotesMsg NotesMsg
    | MemoMsg MemoMsg
    | AmlSidebarMsg AmlSidebarMsg
    | DetailsSidebarMsg DetailsSidebar.Msg
    | VirtualRelationMsg VirtualRelationMsg
    | FindPathMsg FindPathMsg
    | SchemaAnalysisMsg SchemaAnalysisMsg
    | SharingMsg SharingMsg
    | ProjectSaveMsg ProjectSaveDialog.Msg
    | ProjectSettingsMsg ProjectSettingsMsg
    | EmbedSourceParsingMsg EmbedSourceParsingDialog.Msg
    | SourceParsed Source
    | HelpMsg HelpMsg
    | CursorMode CursorMode
    | FitContent
    | ArrangeTables
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
    | CustomModalOpen (Msg -> String -> Html Msg)
    | CustomModalClose
    | ConfirmOpen (Confirm Msg)
    | ConfirmAnswer Bool (Cmd Msg)
    | PromptOpen (Prompt Msg) String
    | PromptUpdate String
    | PromptAnswer (Cmd Msg)
    | ModalOpen HtmlId
    | ModalClose Msg
    | JsMessage JsMsg
    | Batch (List Msg)
    | Send (Cmd Msg)
    | Noop String


type LayoutMsg
    = LLoad LayoutName
    | LDelete LayoutName


type MemoMsg
    = MCreate PointerEvent
    | MEdit Memo
    | MUpdate String
    | MSave
    | MCancel


type NotesMsg
    = NOpen NotesRef
    | NEdit Notes
    | NSave NotesRef Notes
    | NCancel


type AmlSidebarMsg
    = AOpen (Maybe SourceId)
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


confirmDanger : String -> Html Msg -> Msg -> Msg
confirmDanger title content message =
    ConfirmOpen
        { color = Tw.red
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
