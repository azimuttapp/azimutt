module Pages.Login exposing (Model, Msg, page)

import Conf
import Dict
import Effect exposing (Effect)
import Gen.Params.Login exposing (Params)
import Page
import PagesComponents.Login.Models as Models exposing (Msg(..))
import PagesComponents.Login.View exposing (viewLogin)
import Ports
import Request
import Shared
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page _ req =
    Page.advanced
        { init = init req
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


init : Request.With Params -> ( Model, Effect Msg )
init req =
    ( { redirect = req.query |> Dict.get "redirect" }, Effect.none )



-- UPDATE


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        GithubLogin ->
            ( model, Effect.fromCmd (Ports.login model.redirect) )

        JsMessage _ ->
            ( model, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.onJsMessage JsMessage



-- VIEW


view : Model -> View Msg
view model =
    { title = title, body = viewLogin model }
