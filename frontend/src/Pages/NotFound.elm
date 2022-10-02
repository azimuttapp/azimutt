module Pages.NotFound exposing (Model, Msg, page)

import Components.Slices.NotFound as NotFound
import Conf
import Dict
import Gen.Params.NotFound exposing (Params)
import Gen.Route as Route
import Html exposing (Html)
import Html.Lazy as Lazy
import Libs.Models.Env exposing (Env)
import Libs.Task as T
import Page
import Ports exposing (JsMsg(..))
import Request exposing (Request)
import Services.Backend as Backend
import Services.Lenses exposing (mapToastsCmd)
import Services.Toasts as Toasts
import Shared
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init req
        , update = update
        , view = view shared.conf.env
        , subscriptions = subscriptions
        }


type alias Model =
    { url : String
    , toasts : Toasts.Model
    }


type Msg
    = Toast Toasts.Msg
    | JsMessage JsMsg



-- INIT


title : String
title =
    "Page not found - Azimutt"


init : Request -> ( Model, Cmd Msg )
init req =
    ( { url = req.url.path |> addPrefixed "?" req.url.query |> addPrefixed "#" req.url.fragment
      , toasts = Toasts.init
      }
    , Cmd.batch
        [ Ports.setMeta
            { title = Just title
            , description = Just Conf.constants.defaultDescription
            , canonical = Just { route = Route.NotFound, query = Dict.empty }
            , html = Just "h-full"
            , body = Just "h-full"
            }
        , Ports.trackPage "not-found"
        ]
    )


addPrefixed : String -> Maybe String -> String -> String
addPrefixed prefix maybeSegment starter =
    case maybeSegment of
        Nothing ->
            starter

        Just segment ->
            starter ++ prefix ++ segment



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Toast message ->
            model |> mapToastsCmd (Toasts.update Toast message)

        JsMessage message ->
            model |> handleJsMessage message


handleJsMessage : JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage msg model =
    case msg of
        GotToast level message ->
            ( model, message |> Toasts.create level |> Toast |> T.send )

        _ ->
            ( model, Ports.unhandledJsMsgError msg |> Toasts.create "warning" |> Toast |> T.send )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.onJsMessage JsMessage



-- VIEW


view : Env -> Model -> View Msg
view env model =
    { title = title, body = model |> viewNotFound env }


viewNotFound : Env -> Model -> List (Html Msg)
viewNotFound env model =
    [ NotFound.simple
        { brand =
            { img = { src = Backend.resourceUrl "/logo.png", alt = "Azimutt" }
            , link = { url = Backend.homeUrl env, text = "Azimutt" }
            }
        , header = "404 error"
        , title = "Page not found."
        , message = "Sorry, we couldn't find the page you’re looking for."
        , links = [ { url = Backend.homeUrl env, text = "Go back home" } ]
        , footer =
            [ { url = Conf.constants.azimuttDiscussions, text = "Contact Support" }
            , { url = Conf.constants.azimuttTwitter, text = "Twitter" }
            , { url = Backend.blogUrl, text = "Blog" }
            ]
        }
    , Lazy.lazy2 Toasts.view Toast model.toasts
    ]