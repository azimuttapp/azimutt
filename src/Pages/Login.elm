module Pages.Login exposing (Model, Msg, page)

import Conf
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
page _ _ =
    Page.advanced
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


init : ( Model, Effect Msg )
init =
    ( {}, Effect.none )



-- UPDATE


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
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
