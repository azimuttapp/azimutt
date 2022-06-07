module Pages.Projects exposing (Model, Msg, page)

import Browser.Navigation as Navigation
import Components.Molecules.Dropdown as Dropdown
import Conf
import Dict
import Gen.Params.Projects exposing (Params)
import Gen.Route as Route
import Libs.Bool as B
import Libs.Task as T
import Models.Project.ProjectStorage as ProjectStorage
import Page
import PagesComponents.Projects.Id_.Models.ProjectInfo exposing (ProjectInfo)
import PagesComponents.Projects.Models as Models exposing (Msg(..))
import PagesComponents.Projects.View exposing (viewProjects)
import Ports exposing (JsMsg(..))
import Request
import Services.Lenses exposing (mapToastsCmd)
import Services.Toasts as Toasts
import Shared exposing (StoredProjects(..))
import Time
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init shared
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


init : Shared.Model -> ( Model, Cmd Msg )
init shared =
    ( { selectedMenu = "Dashboard"
      , mobileMenuOpen = False
      , projects = shared.projects
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
        , Ports.listProjects
        ]
    )



-- UPDATE


update : Request.With Params -> Msg -> Model -> ( Model, Cmd Msg )
update req msg model =
    case msg of
        SelectMenu menu ->
            ( { model | selectedMenu = menu }, Cmd.none )

        Logout ->
            ( model |> mapProjects (List.filter (\p -> p.storage == ProjectStorage.Browser)), Ports.logout )

        DeleteProject project ->
            ( model, Ports.dropProject project )

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
        GotProjects ( _, projects ) ->
            ( { model | projects = Loaded (projects |> List.sortBy (\p -> negate (Time.posixToMillis p.updatedAt))) }, Cmd.none )

        ProjectDropped projectId ->
            ( model |> mapProjects (List.filter (\p -> p.id /= projectId)), Cmd.none )

        GotToast level message ->
            ( model, Toasts.create Toast level message )

        GotLogin _ ->
            -- handled in shared update
            ( model, Cmd.none )

        GotLogout ->
            -- handled in shared update
            ( model, Cmd.none )

        GotSizes _ ->
            -- useless here
            ( model, Cmd.none )

        _ ->
            ( model, Toasts.create Toast "warning" (Ports.unhandledJsMsgError msg) )


mapProjects : (List ProjectInfo -> List ProjectInfo) -> Model -> Model
mapProjects f model =
    case model.projects of
        Loading ->
            model

        Loaded projects ->
            { model | projects = Loaded (f projects) }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ Ports.onJsMessage JsMessage ]
            ++ Dropdown.subs model DropdownToggle (Noop "dropdown already opened")
        )



-- VIEW


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = title, body = model |> viewProjects req.url shared }
