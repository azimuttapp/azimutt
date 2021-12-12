module PagesComponents.Projects.Id_.Models exposing (Model, Msg(..), NavbarModel, confirm, toastError, toastInfo, toastSuccess, toastWarning)

import Components.Atoms.Icon exposing (Icon(..))
import Components.Molecules.Toast as Toast exposing (Content(..))
import Html.Styled exposing (Html)
import Libs.Models exposing (Millis)
import Libs.Models.TwColor exposing (TwColor(..))
import Libs.Task as T
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.TableId exposing (TableId)
import Shared exposing (Confirm)


type alias Model =
    { projectId : ProjectId
    , navbar : NavbarModel
    , openedDropdown : String
    , confirm : Confirm Msg
    , toastCpt : Int
    , toasts : List Toast.Model
    }


type alias NavbarModel =
    { mobileMenuOpen : Bool
    , search : String
    }


type Msg
    = ToggleMobileMenu
    | ToggleDropdown String
    | SearchUpdated String
    | ShowTable TableId
    | HideTable TableId
    | ShowAllTables
    | HideAllTables
    | ResetCanvas
    | LayoutMsg
    | VirtualRelationMsg
    | FindPathMsg
    | ToastAdd (Maybe Millis) Toast.Content
    | ToastShow (Maybe Millis) String
    | ToastHide String
    | ToastRemove String
    | ConfirmOpen (Confirm Msg)
    | ConfirmAnswer Bool (Cmd Msg)
    | Noop


toastSuccess : String -> Msg
toastSuccess message =
    ToastAdd (Just 8000) (Simple { color = Green, icon = CheckCircle, title = message, message = "" })


toastInfo : String -> Msg
toastInfo message =
    ToastAdd (Just 8000) (Simple { color = Blue, icon = InformationCircle, title = message, message = "" })


toastWarning : String -> Msg
toastWarning message =
    ToastAdd (Just 8000) (Simple { color = Yellow, icon = ExclamationCircle, title = message, message = "" })


toastError : String -> Msg
toastError message =
    ToastAdd Nothing (Simple { color = Red, icon = Exclamation, title = message, message = "" })


confirm : String -> Html Msg -> Msg -> Msg
confirm title content message =
    ConfirmOpen
        { color = Blue
        , icon = QuestionMarkCircle
        , title = title
        , message = content
        , confirm = "Yes!"
        , cancel = "Nope"
        , onConfirm = T.send message
        , isOpen = True
        }
