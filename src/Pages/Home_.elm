module Pages.Home_ exposing (Model, Msg, page)

import Conf
import Dict
import Gen.Params.Home_ exposing (Params)
import Gen.Route as Route
import Page
import PagesComponents.Home_.Models as Models exposing (Msg(..))
import PagesComponents.Home_.View exposing (viewHome)
import Ports exposing (JsMsg(..))
import Request
import Shared exposing (StoredProjects(..))
import Time
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared _ =
    Page.element
        { init = init shared
        , update = update
        , view = view
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


init : Shared.Model -> ( Model, Cmd msg )
init shared =
    ( { projects =
            case shared.projects of
                Loading ->
                    []

                Loaded projects ->
                    projects
      }
    , Cmd.batch
        [ Ports.setMeta
            { title = Just title
            , description = Just Conf.constants.defaultDescription
            , canonical = Just { route = Route.Home_, query = Dict.empty }
            , html = Just ""
            , body = Just ""
            }
        , Ports.trackPage "home"
        , Ports.listProjects
        ]
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        JsMessage message ->
            model |> handleJsMessage message


handleJsMessage : JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage msg model =
    case msg of
        GotProjects ( _, projects ) ->
            ( { model | projects = projects |> List.sortBy (\p -> negate (Time.posixToMillis p.updatedAt)) }, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.onJsMessage Nothing JsMessage



-- VIEW


view : Model -> View msg
view model =
    { title = title, body = viewHome model }
