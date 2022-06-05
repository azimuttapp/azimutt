module Services.Toasts exposing (Model, Msg, create, error, info, init, success, update, view, warning)

import Components.Atoms.Icon exposing (Icon(..))
import Components.Molecules.Toast as Toast exposing (Content(..))
import Html exposing (Html, div)
import Html.Attributes exposing (class)
import Libs.Maybe as Maybe
import Libs.Models exposing (Millis)
import Libs.Tailwind as Tw
import Libs.Task as T
import Services.Lenses exposing (mapIndex, mapList, mapToasts, setIsOpen)


type alias Model =
    { index : Int
    , toasts : List Toast.Model
    }


type Msg
    = ToastAdd (Maybe Millis) Toast.Content
    | ToastShow (Maybe Millis) String
    | ToastHide String
    | ToastRemove String


init : Model
init =
    { index = 0, toasts = [] }


create : (Msg -> msg) -> String -> String -> Cmd msg
create wrap level message =
    case level of
        "success" ->
            success wrap message

        "info" ->
            info wrap message

        "warning" ->
            warning wrap message

        _ ->
            error wrap message


success : (Msg -> msg) -> String -> Cmd msg
success wrap message =
    ToastAdd (Just 8000) (Simple { color = Tw.green, icon = CheckCircle, title = message, message = "" }) |> wrap |> T.send


info : (Msg -> msg) -> String -> Cmd msg
info wrap message =
    ToastAdd (Just 8000) (Simple { color = Tw.blue, icon = InformationCircle, title = message, message = "" }) |> wrap |> T.send


warning : (Msg -> msg) -> String -> Cmd msg
warning wrap message =
    ToastAdd (Just 8000) (Simple { color = Tw.yellow, icon = ExclamationCircle, title = message, message = "" }) |> wrap |> T.send


error : (Msg -> msg) -> String -> Cmd msg
error wrap message =
    ToastAdd Nothing (Simple { color = Tw.red, icon = Exclamation, title = message, message = "" }) |> wrap |> T.send


update : (Msg -> msg) -> Msg -> Model -> ( Model, Cmd msg )
update wrap msg model =
    case msg of
        ToastAdd millis toast ->
            model.index |> String.fromInt |> (\key -> ( model |> mapIndex (\i -> i + 1) |> mapToasts (\t -> { key = key, content = toast, isOpen = False } :: t), T.sendAfter 1 (key |> ToastShow millis |> wrap) ))

        ToastShow millis key ->
            ( model |> mapToasts (mapList .key key (setIsOpen True)), millis |> Maybe.mapOrElse (\delay -> T.sendAfter delay (key |> ToastHide |> wrap)) Cmd.none )

        ToastHide key ->
            ( model |> mapToasts (mapList .key key (setIsOpen False)), key |> ToastRemove |> wrap |> T.sendAfter 300 )

        ToastRemove key ->
            ( model |> mapToasts (List.filter (\t -> t.key /= key)), Cmd.none )


view : (Msg -> msg) -> Model -> Html msg
view wrap model =
    div [ class "az-toasts" ] [ Toast.container model.toasts (ToastHide >> wrap) ]
