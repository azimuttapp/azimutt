module PagesComponents.Projects.Id_.Models exposing (CursorMode(..), DragState, Model, Msg(..), NavbarModel, VirtualRelation, confirm, toastError, toastInfo, toastSuccess, toastWarning)

import Components.Atoms.Icon exposing (Icon(..))
import Components.Molecules.Toast as Toast exposing (Content(..))
import Html.Styled exposing (Html)
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
import Models.Project.TableId exposing (TableId)
import Ports exposing (JsMsg)
import Shared exposing (Confirm)


type alias Model =
    { project : Maybe Project
    , navbar : NavbarModel
    , hoverTable : Maybe TableId
    , hoverColumn : Maybe ColumnRef
    , cursorMode : CursorMode
    , selectionBox : Maybe Area
    , virtualRelation : Maybe VirtualRelation

    -- global attrs
    , openedDropdown : HtmlId
    , dragging : Maybe DragState
    , toastIdx : Int
    , toasts : List Toast.Model
    , confirm : Confirm Msg
    }


type alias NavbarModel =
    { mobileMenuOpen : Bool
    , search : { text : String, active : Int }
    }


type alias VirtualRelation =
    { src : Maybe ColumnRef, mouse : Position }


type CursorMode
    = CursorDrag
    | CursorSelect


type alias DragState =
    { id : DragId, init : Position, last : Position }


type Msg
    = ToggleMobileMenu
    | SearchUpdated String
    | LoadProject Project
    | ShowTable TableId
    | ShowTables (List TableId)
    | HideTable TableId
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
    | ShowAllTables
    | HideAllTables
    | ResetCanvas
    | LayoutMsg
    | VirtualRelationMsg
    | FindPathMsg
    | CursorMode CursorMode
    | FitContent
    | OnWheel WheelEvent
    | Zoom ZoomDelta
      -- global messages
    | DropdownToggle HtmlId
    | DragStart DragId Position
    | DragMove Position
    | DragEnd Position
    | ToastAdd (Maybe Millis) Toast.Content
    | ToastShow (Maybe Millis) String
    | ToastHide String
    | ToastRemove String
    | ConfirmOpen (Confirm Msg)
    | ConfirmAnswer Bool (Cmd Msg)
    | JsMessage JsMsg
    | Noop String


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
        , isOpen = True
        }
