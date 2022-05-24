module Pages.Profile exposing (Model, Msg, page)

import Conf
import Dict
import Gen.Params.Profile exposing (Params)
import Gen.Route as Route
import Libs.Maybe as Maybe
import Page
import PagesComponents.Profile.Models as Models exposing (Msg(..))
import PagesComponents.Profile.View exposing (viewProfile)
import Ports exposing (JsMsg)
import Request
import Shared
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared _ =
    Page.element
        { init = init shared
        , update = update
        , view = view shared
        , subscriptions = subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


title : Shared.Model -> String
title shared =
    shared.user |> Maybe.mapOrElse (\u -> u.name ++ " - Azimutt") Conf.constants.defaultTitle


init : Shared.Model -> ( Model, Cmd Msg )
init shared =
    ( {}
    , Cmd.batch
        [ Ports.setMeta
            { title = Just (title shared)
            , description = Just (shared.user |> Maybe.andThen .bio |> Maybe.withDefault Conf.constants.defaultDescription)
            , canonical = Just { route = Route.Profile, query = Dict.empty }
            , html = Nothing
            , body = Nothing
            }
        , Ports.trackPage "profile"
        ]
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        JsMessage message ->
            model |> handleJsMessage message

        Noop _ ->
            ( model, Cmd.none )


handleJsMessage : JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage msg model =
    case msg of
        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.onJsMessage JsMessage



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = title shared
    , body = model |> viewProfile shared
    }
