module PagesComponents.App.Models exposing (Confirm, DragId, Error, Errors, Hover, Model, Msg(..), Search, Switch, TimeInfo, initConfirm, initHover, initSwitch, initTimeInfo)

import Dict exposing (Dict)
import Draggable
import FileValue exposing (File)
import Html exposing (Html, text)
import Libs.Html.Events exposing (WheelEvent)
import Libs.Models exposing (FileUrl, HtmlId, ZoomDelta)
import Libs.Position exposing (Position)
import Libs.Size exposing (Size)
import Libs.Task as T
import Models.Project exposing (ColumnRef, FindPath, FindPathSettings, LayoutName, Project, Relation, Table, TableId)
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
    , confirm : Confirm
    , sizes : Dict HtmlId Size
    , dragId : Maybe DragId
    , drag : Draggable.State DragId
    , hover : Hover
    }


type Msg
    = TimeChanged Time.Posix
    | ZoneChanged Time.Zone
    | ChangeProject
    | FileDragOver File (List File)
    | FileDragLeave
    | FileDropped File (List File)
    | FileSelected File
    | LoadFile FileUrl
    | DeleteProject Project
    | UseProject Project
    | ChangedSearch Search
    | SelectTable TableId
    | HideTable TableId
    | ShowTable TableId
    | TableOrder TableId Int
    | ShowTables (List TableId)
    | HideTables (List TableId)
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
    | DragMsg (Draggable.Msg DragId)
    | StartDragging DragId
    | StopDragging
    | OnDragBy Draggable.Delta
    | FindPath (Maybe TableId) (Maybe TableId)
    | FindPathFrom (Maybe TableId)
    | FindPathTo (Maybe TableId)
    | FindPathSearch
    | FindPathCompute (Dict TableId Table) (List Relation) TableId TableId FindPathSettings
    | UpdateFindPathSettings FindPathSettings
    | NewLayout LayoutName
    | CreateLayout LayoutName
    | LoadLayout LayoutName
    | UpdateLayout LayoutName
    | DeleteLayout LayoutName
    | OpenConfirm Confirm
    | OnConfirm Bool (Cmd Msg)
    | JsMessage JsMsg
    | Noop


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
