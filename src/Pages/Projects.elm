module Pages.Projects exposing (Model, Msg, page)

import Browser.Navigation as Navigation
import Components.Molecules.Dropdown as Dropdown
import Conf
import Dict
import Gen.Params.Projects exposing (Params)
import Gen.Route as Route
import Libs.Bool as B
import Libs.Task as T
import Page
import PagesComponents.Projects.Models as Models exposing (Msg(..))
import PagesComponents.Projects.View exposing (viewProjects)
import Ports exposing (JsMsg(..))
import Request
import Services.Lenses exposing (mapToastsCmd)
import Services.Toasts as Toasts
import Shared exposing (StoredProjects(..))
import View exposing (View)



-- legacy page to access unregistered local projects
-- remove it by Jan. 2023


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init
        , update = update req
        , view = view shared req
        , subscriptions = subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


title : String
title =
    Conf.constants.defaultTitle


init : ( Model, Cmd Msg )
init =
    ( { selectedMenu = "Dashboard"
      , mobileMenuOpen = False
      , openedDropdown = ""
      , toasts = Toasts.init
      , confirm = Nothing
      , modalOpened = False
      }
    , Cmd.batch
        [ Ports.setMeta
            { title = Just title
            , description = Just Conf.constants.defaultDescription
            , canonical = Just { route = Route.Projects, query = Dict.empty }
            , html = Just "h-full bg-gray-100"
            , body = Just "h-full"
            }
        , Ports.trackPage "dashboard"
        , Ports.getLegacyProjects -- to update legacyProjects in Shared
        ]
    )



-- UPDATE


update : Request.With Params -> Msg -> Model -> ( Model, Cmd Msg )
update req msg model =
    case msg of
        SelectMenu menu ->
            ( { model | selectedMenu = menu }, Cmd.none )

        DeleteProject project ->
            ( model, Ports.deleteProject project Nothing )

        DropdownToggle id ->
            ( model |> Dropdown.update id, Cmd.none )

        Toast message ->
            model |> mapToastsCmd (Toasts.update Toast message)

        ConfirmOpen confirm ->
            ( { model | confirm = Just confirm }, T.sendAfter 1 ModalOpen )

        ConfirmAnswer answer cmd ->
            ( { model | confirm = Nothing }, B.cond answer cmd Cmd.none )

        ModalOpen ->
            ( { model | modalOpened = True }, Ports.autofocusWithin Conf.ids.modal )

        ModalClose message ->
            ( { model | modalOpened = False }, T.sendAfter Conf.ui.closeDuration message )

        NavigateTo url ->
            ( model, Navigation.pushUrl req.key url )

        JsMessage message ->
            model |> handleJsMessage message

        Noop _ ->
            ( model, Cmd.none )


handleJsMessage : JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage msg model =
    case msg of
        GotLegacyProjects _ ->
            -- do nothing, handled in Shared
            ( model, Cmd.none )

        ProjectDeleted _ ->
            -- do nothing, handled in Shared
            ( model, Cmd.none )

        GotToast level message ->
            ( model, message |> Toasts.create level |> Toast |> T.send )

        GotSizes _ ->
            -- useless here but avoid waring toast
            ( model, Cmd.none )

        _ ->
            ( model, Ports.unhandledJsMsgError msg |> Toasts.create "warning" |> Toast |> T.send )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch (Ports.onJsMessage JsMessage :: Dropdown.subs model DropdownToggle (Noop "dropdown already opened"))



-- VIEW


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = title, body = model |> viewProjects shared req.url Nothing }
