module PagesComponents.App.Models exposing (Confirm, CursorMode(..), DragId, DragState, Error, Errors, FindPathMsg(..), Hover, LayoutMsg(..), Model, Msg(..), Search, SourceMsg(..), Switch, TimeInfo, VirtualRelation, VirtualRelationMsg(..), initConfirm, initHover, initSwitch, initTimeInfo)

import Dict exposing (Dict)
import FileValue exposing (File)
import Html exposing (Html, text)
import Libs.Area exposing (Area)
import Libs.Delta exposing (Delta)
import Libs.DomInfo exposing (DomInfo)
import Libs.Html.Events exposing (WheelEvent)
import Libs.Models exposing (FileContent, FileUrl, SizeChange, ZoomDelta)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Position exposing (Position)
import Libs.Task as T
import Models.Project exposing (FindPath, FindPathSettings, Project, ProjectId, Relation, SampleName, SourceId, SourceInfo, Table)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.TableId exposing (TableId)
import Ports exposing (JsMsg)
import Time


type alias Model =
    { time : TimeInfo
    , switch : Switch
    , storedProjects : List Project
    , project : Maybe Project
    , search : Search
    , newLayout : Maybe LayoutName
    , findPath : Maybe FindPath
    , virtualRelation : Maybe VirtualRelation
    , confirm : Confirm
    , domInfos : Dict HtmlId DomInfo
    , cursorMode : CursorMode
    , selection : Maybe Area
    , dragState : Maybe DragState
    , hover : Hover
    }


type alias VirtualRelation =
    { src : Maybe ColumnRef, mouse : Position }


type CursorMode
    = Drag
    | Select


type alias DragState =
    { id : DragId, init : Position, last : Position, delta : Delta }


type Msg
    = TimeChanged Time.Posix
    | ZoneChanged Time.Zone
    | SizesChanged (List SizeChange)
    | ChangeProject
    | ProjectsLoaded (List Project)
    | SourceMsg SourceMsg
    | DeleteProject Project
    | UseProject Project
    | ChangedSearch Search
    | SelectTable TableId Bool
    | SelectAllTables
    | HideTable TableId
    | ShowTable TableId
    | TableOrder TableId Int
    | ShowTables (List TableId)
      -- | HideTables (List TableId)
    | InitializedTable TableId Position
    | HideAllTables
    | ShowAllTables
    | HideColumn ColumnRef
    | ShowColumn ColumnRef
    | SortColumns TableId String
    | HideColumns TableId String
    | ShowColumns TableId String
    | HoverTable (Maybe TableId)
    | HoverColumn (Maybe ColumnRef)
    | OnWheel WheelEvent
    | Zoom ZoomDelta
    | FitContent
    | ResetCanvas
    | DragStart DragId Position
    | DragMove Position
    | DragEnd Position
    | CursorMode CursorMode
    | FindPathMsg FindPathMsg
    | VirtualRelationMsg VirtualRelationMsg
    | LayoutMsg LayoutMsg
    | OpenConfirm Confirm
    | OnConfirm Bool (Cmd Msg)
    | JsMessage JsMsg
    | Noop


type SourceMsg
    = FileDragOver File (List File)
    | FileDragLeave
    | LoadLocalFile (Maybe ProjectId) (Maybe SourceId) File
    | LoadRemoteFile (Maybe ProjectId) (Maybe SourceId) FileUrl
    | LoadSample SampleName
    | FileLoaded ProjectId SourceInfo FileContent
    | ToggleSource SourceId
    | DeleteSource SourceId


type LayoutMsg
    = LNew LayoutName
    | LCreate LayoutName
    | LLoad LayoutName
    | LUnload
    | LUpdate LayoutName
    | LDelete LayoutName


type FindPathMsg
    = FPInit (Maybe TableId) (Maybe TableId)
    | FPUpdateFrom (Maybe TableId)
    | FPUpdateTo (Maybe TableId)
    | FPSearch
    | FPCompute (Dict TableId Table) (List Relation) TableId TableId FindPathSettings
    | FPSettingsUpdate FindPathSettings


type VirtualRelationMsg
    = VRCreate
    | VRUpdate ColumnRef Position
    | VRMove Position
    | VRCancel


type alias TimeInfo =
    { zone : Time.Zone, now : Time.Posix }


type alias Switch =
    { loading : Bool }


type alias Confirm =
    { content : Html Msg, cmd : Cmd Msg }


type alias Hover =
    { table : Maybe TableId, column : Maybe ColumnRef }


type alias Search =
    String


type alias DragId =
    HtmlId


type alias Error =
    String


type alias Errors =
    List Error


initTimeInfo : TimeInfo
initTimeInfo =
    { zone = Time.utc, now = Time.millisToPosix 0 }


initSwitch : Switch
initSwitch =
    { loading = False }


initConfirm : Confirm
initConfirm =
    { content = text "No text", cmd = T.send Noop }


initHover : Hover
initHover =
    { table = Nothing, column = Nothing }
