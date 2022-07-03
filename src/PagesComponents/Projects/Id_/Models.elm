module PagesComponents.Projects.Id_.Models exposing (AmlSidebar, AmlSidebarMsg(..), ConfirmDialog, ContextMenu, FindPathMsg(..), HelpDialog, HelpMsg(..), LayoutDialog, LayoutMsg(..), Model, Msg(..), NavbarModel, NotesDialog, NotesMsg(..), ProjectSettingsDialog, ProjectSettingsMsg(..), PromptDialog, SchemaAnalysisDialog, SchemaAnalysisMsg(..), SearchModel, SharingDialog, SharingMsg(..), SourceParsingDialog, SourceUploadDialog, VirtualRelation, VirtualRelationMsg(..), confirm, prompt, simplePrompt)

import Components.Atoms.Icon exposing (Icon(..))
import DataSources.AmlParser.AmlAdapter exposing (AmlSchemaError)
import Dict exposing (Dict)
import Html exposing (Html, text)
import Libs.Area exposing (Area)
import Libs.Delta exposing (Delta)
import Libs.Html.Events exposing (PointerEvent, WheelEvent)
import Libs.Models exposing (ZoomDelta)
import Libs.Models.DragId exposing (DragId)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position exposing (Position)
import Libs.Tailwind as Tw exposing (Color)
import Libs.Task as T
import Models.ColumnOrder exposing (ColumnOrder)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.FindPathSettings exposing (FindPathSettings)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.ProjectName exposing (ProjectName)
import Models.Project.ProjectStorage exposing (ProjectStorage)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.SourceName exposing (SourceName)
import Models.Project.TableId exposing (TableId)
import Models.RelationStyle exposing (RelationStyle)
import Models.ScreenProps exposing (ScreenProps)
import PagesComponents.Projects.Id_.Components.ProjectUploadDialog as ProjectUploadDialog exposing (Model, Msg)
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
import Random
import Services.SqlSourceUpload exposing (SqlSourceUpload, SqlSourceUploadMsg)
import Services.Toasts as Toasts
import Shared exposing (Confirm, Prompt)


type alias Model =
    { seed : Random.Seed
    , conf : ErdConf
    , navbar : NavbarModel
    , screen : ScreenProps
    , loaded : Bool
    , erd : Maybe Erd
    , projects : List ProjectInfo
    , hoverTable : Maybe TableId
    , hoverColumn : Maybe ColumnRef
    , cursorMode : CursorMode
    , selectionBox : Maybe Area
    , newLayout : Maybe LayoutDialog
    , editNotes : Maybe NotesDialog
    , amlSidebar : Maybe AmlSidebar
    , virtualRelation : Maybe VirtualRelation
    , findPath : Maybe FindPathDialog
    , schemaAnalysis : Maybe SchemaAnalysisDialog
    , sharing : Maybe SharingDialog
    , upload : Maybe ProjectUploadDialog.Model
    , settings : Maybe ProjectSettingsDialog
    , sourceUpload : Maybe SourceUploadDialog
    , sourceParsing : Maybe SourceParsingDialog
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
    { src : Maybe ColumnRef, mouse : Position }


type alias SchemaAnalysisDialog =
    { id : HtmlId, opened : HtmlId }


type alias SharingDialog =
    { id : HtmlId, kind : EmbedKind, content : String, layout : LayoutName, mode : EmbedModeId }


type alias ProjectSettingsDialog =
    { id : HtmlId }


type alias SourceUploadDialog =
    { id : HtmlId, parsing : SqlSourceUpload Msg }


type alias SourceParsingDialog =
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
    | TableMove TableId Delta
    | TablePosition TableId Position
    | TableOrder TableId Int
    | TableColor TableId Color
    | MoveColumn ColumnRef Int
    | ToggleHoverTable TableId Bool
    | ToggleHoverColumn ColumnRef Bool
    | CreateUserSource SourceName
    | CreateRelation ColumnRef ColumnRef
    | LayoutMsg LayoutMsg
    | NotesMsg NotesMsg
    | AmlSidebarMsg AmlSidebarMsg
    | VirtualRelationMsg VirtualRelationMsg
    | FindPathMsg FindPathMsg
    | SchemaAnalysisMsg SchemaAnalysisMsg
    | SharingMsg SharingMsg
    | ProjectUploadDialogMsg ProjectUploadDialog.Msg
    | ProjectSettingsMsg ProjectSettingsMsg
    | SourceParsing SqlSourceUploadMsg
    | SourceParsed ProjectId Source
    | HelpMsg HelpMsg
    | CursorMode CursorMode
    | FitContent
    | Fullscreen (Maybe HtmlId)
    | OnWheel WheelEvent
    | Zoom ZoomDelta
      -- global messages
    | Logout
    | Focus HtmlId
    | DropdownToggle HtmlId
    | DropdownOpen HtmlId
    | DropdownClose
    | PopoverSet HtmlId
    | ContextMenuCreate (Html Msg) PointerEvent
    | ContextMenuShow
    | ContextMenuClose
    | DragStart DragId Position
    | DragMove Position
    | DragEnd Position
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
    = VRCreate
    | VRUpdate ColumnRef Position
    | VRMove Position
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
    | PSSourceUploadOpen (Maybe Source)
    | PSSourceUploadClose
    | PSSqlSourceMsg SqlSourceUploadMsg
    | PSSourceRefresh Source
    | PSSourceAdd Source
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
