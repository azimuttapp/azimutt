module PagesComponents.App.Models exposing (Confirm, CursorMode(..), DragId, DragState, Error, Errors, FindPathMsg(..), Hover, Model, Msg(..), Search, Switch, TimeInfo, VirtualRelation, VirtualRelationMsg(..), initConfirm, initHover, initSwitch, initTimeInfo)

import Dict exposing (Dict)
import FileValue exposing (File)
import Html exposing (Html, text)
import Libs.Area exposing (Area)
import Libs.Delta exposing (Delta)
import Libs.DomInfo exposing (DomInfo)
import Libs.Html.Events exposing (WheelEvent)
import Libs.Models exposing (HtmlId, ZoomDelta)
import Libs.Position exposing (Position)
import Libs.Task as T
import Models.Project exposing (ColumnRef, FindPath, FindPathSettings, LayoutName, Project, Relation, SampleName, Table, TableId)
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
    | ChangeProject
    | FileDragOver File (List File)
    | FileDragLeave
    | FileDropped File (List File)
    | FileSelected File
    | LoadSample SampleName
      -- | LoadFile FileUrl
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
    | DragStart DragId Position
    | DragMove Position
    | DragEnd Position
    | CursorMode CursorMode
    | FindPathMsg FindPathMsg
    | VirtualRelationMsg VirtualRelationMsg
    | NewLayout LayoutName
    | CreateLayout LayoutName
    | LoadLayout LayoutName
    | UpdateLayout LayoutName
    | DeleteLayout LayoutName
    | UnloadLayout
    | OpenConfirm Confirm
    | OnConfirm Bool (Cmd Msg)
    | JsMessage JsMsg
    | Noop


type FindPathMsg
    = Init (Maybe TableId) (Maybe TableId)
    | UpdateFrom (Maybe TableId)
    | UpdateTo (Maybe TableId)
    | Search
    | Compute (Dict TableId Table) (List Relation) TableId TableId FindPathSettings
    | SettingsUpdate FindPathSettings


type VirtualRelationMsg
    = Create
    | Update ColumnRef Position
    | Move Position
    | Cancel


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
