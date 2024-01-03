module Pages.NotFound exposing (Model, Msg, page)

import Components.Slices.NotFound as NotFound
import Conf
import Dict
import Gen.Params.NotFound exposing (Params)
import Gen.Route as Route
import Html exposing (Html)
import Html.Lazy as Lazy
import Libs.Task as T
import Page
import PagesComponents.Organization_.Project_.Updates.Extra as Extra
import Ports exposing (JsMsg(..))
import Request exposing (Request)
import Services.Backend as Backend
import Services.Lenses exposing (mapToastsT)
import Services.Toasts as Toasts
import Shared
import Track
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page _ req =
    Page.element
        { init = init req
        , update = update
        , view = view
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
    let
        url : String
        url =
            req.url.path |> addPrefixed "?" req.url.query |> addPrefixed "#" req.url.fragment
    in
    ( { url = url
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
        , Track.notFound url
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
            model |> mapToastsT (Toasts.update Toast message) |> Extra.unpackT

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


view : Model -> View Msg
view model =
    { title = title, body = model |> viewNotFound }


viewNotFound : Model -> List (Html Msg)
viewNotFound model =
    [ NotFound.simple
        { brand =
            { img = { src = Backend.resourceUrl "/logo_dark.svg", alt = "Azimutt" }
            , link = { url = Backend.homeUrl, text = "Azimutt" }
            }
        , header = "404 error"
        , title = "Page not found."
        , message = "Sorry, we couldn't find the page you’re looking for."
        , links = [ { url = Backend.homeUrl, text = "Go back home" } ]
        , footer =
            [ { url = Conf.constants.azimuttDiscussions, text = "Contact Support" }
            , { url = Conf.constants.azimuttTwitter, text = "Twitter" }
            , { url = Backend.blogUrl, text = "Blog" }
            ]
        }
    , Lazy.lazy2 Toasts.view Toast model.toasts
    ]
