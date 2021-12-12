module Pages.Projects.Id_ exposing (Model, Msg, page)

import Components.Atoms.Icon exposing (Icon(..))
import Components.Molecules.Toast exposing (Content(..))
import Gen.Params.Projects.Id_ exposing (Params)
import Html.Styled as Styled exposing (text)
import Libs.Bool as B
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.TwColor exposing (TwColor(..))
import Libs.Task as T
import Models.Project.TableId as TableId
import Page
import PagesComponents.Projects.Id_.Models as Models exposing (Msg(..), toastSuccess)
import PagesComponents.Projects.Id_.View exposing (viewProject)
import Ports
import Request
import Shared
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init shared req
        , update = update
        , view = view shared
        , subscriptions = subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : Shared.Model -> Request.With Params -> ( Model, Cmd Msg )
init _ req =
    ( { projectId = req.params.id
      , navbar = { mobileMenuOpen = False, search = "" }
      , openedDropdown = ""
      , confirm = { color = Red, icon = X, title = "", message = text "", confirm = "", cancel = "", onConfirm = T.send Noop, isOpen = False }
      , toastCpt = 0
      , toasts = []
      }
    , Cmd.batch [ Ports.loadProjects ]
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleMobileMenu ->
            ( { model | navbar = model.navbar |> (\n -> { n | mobileMenuOpen = not n.mobileMenuOpen }) }, Cmd.none )

        ToggleDropdown id ->
            ( { model | openedDropdown = B.cond (model.openedDropdown == id) "" id }, Cmd.none )

        SearchUpdated search ->
            ( { model | navbar = model.navbar |> (\n -> { n | search = search }) }, Cmd.none )

        ShowTable id ->
            ( model, T.send (toastSuccess ("ShowTable: " ++ TableId.toString id)) )

        HideTable id ->
            ( model, T.send (toastSuccess ("HideTable: " ++ TableId.toString id)) )

        ResetCanvas ->
            ( model, T.send (toastSuccess "ResetCanvas") )

        ShowAllTables ->
            ( model, T.send (toastSuccess "ShowAllTables") )

        HideAllTables ->
            ( model, T.send (toastSuccess "HideAllTables") )

        LayoutMsg ->
            ( model, T.send (toastSuccess "LayoutMsg") )

        VirtualRelationMsg ->
            ( model, T.send (toastSuccess "VirtualRelationMsg") )

        FindPathMsg ->
            ( model, T.send (toastSuccess "FindPathMsg") )

        ToastAdd millis toast ->
            model.toastCpt |> String.fromInt |> (\key -> ( { model | toastCpt = model.toastCpt + 1, toasts = { key = key, content = toast, isOpen = False } :: model.toasts }, T.sendAfter 1 (ToastShow millis key) ))

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

        Noop ->
            ( model, T.send (toastSuccess "Noop") )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = shared |> Shared.projects |> L.find (\p -> p.id == model.projectId) |> M.mapOrElse (\p -> p.name ++ " - Azimutt") "Azimutt - Explore your database schema"
    , body = model |> viewProject shared |> List.map Styled.toUnstyled
    }
