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
import Shared
import Time
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page _ _ =
    Page.element
        { init = init
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


init : ( Model, Cmd msg )
init =
    ( { projects = []
      , editor = "function hello() {\n\talert('Hello world!');\n}"
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
        , Ports.loadProjects
        ]
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EditorChanged value ->
            ( { model | editor = value }, Cmd.none )

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
    Ports.onJsMessage JsMessage



-- VIEW


view : Model -> View Msg
view model =
    { title = title, body = viewHome model }
