module Services.Toasts exposing (Model, Msg, create, error, info, init, success, update, view, warning)

import Components.Atoms.Icon exposing (Icon(..))
import Components.Molecules.Toast as Toast exposing (Content(..))
import Html exposing (Html, div)
import Html.Attributes exposing (class)
import Libs.Models exposing (Millis)
import Libs.Tailwind as Tw
import Libs.Task as T
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import Services.Lenses exposing (mapIndex, mapList, mapToasts, setIsOpen)



{-
   To integrate this, add the following codes in following places:
    - Model:  `toasts : Toasts.Model`
    - Msg:    `Toast Toasts.Msg`
    - init:   `toasts = Toasts.init`
    - update: `Toast message -> model |> mapToastsCmd (Toasts.update Toast message)`
    - js msg: `GotToast level message -> (model, Toasts.create Toast level message)`
    - view:   `Lazy.lazy2 Toasts.view Toast model.toasts`
-}


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


create : String -> String -> Msg
create level message =
    case level of
        "success" ->
            success message

        "info" ->
            info message

        "warning" ->
            warning message

        _ ->
            error message


success : String -> Msg
success message =
    ToastAdd (Just 8000) (Simple { color = Tw.green, icon = CheckCircle, title = message, message = "" })


info : String -> Msg
info message =
    ToastAdd (Just 8000) (Simple { color = Tw.blue, icon = InformationCircle, title = message, message = "" })


warning : String -> Msg
warning message =
    ToastAdd (Just 8000) (Simple { color = Tw.yellow, icon = ExclamationCircle, title = message, message = "" })


error : String -> Msg
error message =
    ToastAdd Nothing (Simple { color = Tw.red, icon = Exclamation, title = message, message = "" })


update : (Msg -> msg) -> Msg -> Model -> ( Model, Extra msg )
update wrap msg model =
    case msg of
        ToastAdd millis toast ->
            model.index |> String.fromInt |> (\key -> ( model |> mapIndex (\i -> i + 1) |> mapToasts (\t -> { key = key, content = toast, isOpen = False } :: t), key |> ToastShow millis |> wrap |> T.sendAfter 1 |> Extra.cmd ))

        ToastShow millis key ->
            ( model |> mapToasts (mapList .key key (setIsOpen True)), millis |> Maybe.map (\delay -> key |> ToastHide |> wrap |> T.sendAfter delay) |> Extra.cmdM )

        ToastHide key ->
            ( model |> mapToasts (mapList .key key (setIsOpen False)), key |> ToastRemove |> wrap |> T.sendAfter 300 |> Extra.cmd )

        ToastRemove key ->
            ( model |> mapToasts (List.filter (\t -> t.key /= key)), Extra.none )


view : (Msg -> msg) -> Model -> Html msg
view wrap model =
    div [ class "az-toasts" ] [ Toast.container model.toasts (ToastHide >> wrap) ]
