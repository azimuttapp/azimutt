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
import Shared exposing (StoredProjects(..))
import Time
import Track
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


title : String
title =
    Conf.constants.defaultTitle


init : ( Model, Cmd Msg )
init =
    ( { selectedMenu = "Dashboard"
      , mobileMenuOpen = False
      , projects = Loading
      , openedDropdown = ""
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
        , Ports.loadProjects
        ]
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
            ( model, Cmd.batch [ Ports.dropProject project, Ports.track (Track.deleteProject project) ] )

        DropdownToggle id ->
            ( model |> Dropdown.update id, Cmd.none )

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
        GotProjects ( _, projects ) ->
            ( { model | projects = Loaded (projects |> List.sortBy (\p -> negate (Time.posixToMillis p.updatedAt))) }, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ Ports.onJsMessage JsMessage ]
            ++ Dropdown.subscriptions model DropdownToggle (Noop "dropdown already opened")
        )



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = title, body = model |> viewProjects shared }
