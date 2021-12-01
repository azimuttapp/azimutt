module Pages.Projects exposing (Model, Msg, page)

import Browser.Navigation as Navigation
import Components.Atoms.Icon exposing (Icon(..))
import Gen.Params.Projects exposing (Params)
import Html.Styled as Styled exposing (text)
import Libs.Bool as B
import Libs.Maybe as M
import Libs.Models.TwColor exposing (TwColor(..))
import Libs.Task as T
import Page
import PagesComponents.Projects.Models as Models exposing (Msg(..))
import PagesComponents.Projects.View exposing (viewProjects)
import Ports
import Request
import Shared
import Tracking
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init
        , update = update req
        , view = view shared
        , subscriptions = subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : ( Model, Cmd Msg )
init =
    ( { selectedMenu = "Dashboard"
      , mobileMenuOpen = False
      , confirm = { color = Red, icon = X, title = "", message = text "", confirm = "", cancel = "", onConfirm = T.send Noop, isOpen = False }
      , toastCpt = 0
      , toasts = []
      }
    , Cmd.batch [ Ports.loadProjects ]
    )



-- UPDATE


update : Request.With Params -> Msg -> Model -> ( Model, Cmd Msg )
update req msg model =
    case msg of
        SelectMenu menu ->
            ( { model | selectedMenu = menu }, Cmd.none )

        ToggleMobileMenu ->
            ( { model | mobileMenuOpen = not model.mobileMenuOpen }, Cmd.none )

        DeleteProject project ->
            ( model, Cmd.batch [ Ports.dropProject project, Ports.track (Tracking.events.deleteProject project) ] )

        ToastAdd millis toast ->
            model.toastCpt |> String.fromInt |> (\key -> ( { model | toastCpt = model.toastCpt + 1, toasts = { key = key, content = toast, isOpen = False } :: model.toasts }, T.sendAfter 100 (ToastShow millis key) ))

        ToastShow millis key ->
            ( { model | toasts = model.toasts |> List.map (\t -> B.cond (t.key == key) { t | isOpen = True } t) }, millis |> M.mapOrElse (\delay -> T.sendAfter delay (ToastHide key)) Cmd.none )

        ToastHide key ->
            ( { model | toasts = model.toasts |> List.map (\t -> B.cond (t.key == key) { t | isOpen = False } t) }, T.sendAfter 300 (ToastRemove key) )

        ToastRemove key ->
            ( { model | toasts = model.toasts |> List.filter (\t -> t.key /= key) }, Cmd.none )

        ConfirmOpen confirm ->
            ( { model | confirm = { confirm | isOpen = True } }, Cmd.none )

        ConfirmAnswer answer cmd ->
            ( { model | confirm = model.confirm |> (\c -> { c | isOpen = False }) }, B.cond answer cmd Cmd.none )

        NavigateTo url ->
            ( model, Navigation.pushUrl req.key url )

        Noop ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "Azimutt - Explore your database schema"
    , body = model |> viewProjects shared |> List.map Styled.toUnstyled
    }
