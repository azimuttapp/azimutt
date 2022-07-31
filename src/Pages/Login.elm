module Pages.Login exposing (Model, Msg, page)

import Conf
import Dict
import Effect exposing (Effect)
import Gen.Params.Login exposing (Params)
import Gen.Route as Route
import Libs.Task as T
import Page
import PagesComponents.Login.Models as Models exposing (Msg(..))
import PagesComponents.Login.View exposing (viewLogin)
import Ports exposing (JsMsg(..))
import Request
import Services.Lenses exposing (mapToastsCmd)
import Services.Toasts as Toasts
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
    ( { email = ""
      , redirect = req.query |> Dict.get "redirect"
      , toasts = Toasts.init
      }
    , Effect.fromCmd
        (Cmd.batch
            [ Ports.setMeta
                { title = Just title
                , description = Just Conf.constants.defaultDescription
                , canonical = Just { route = Route.Login, query = Dict.empty }
                , html = Just ""
                , body = Just ""
                }
            , Ports.trackPage "login"
            ]
        )
    )



-- UPDATE


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        UpdateEmail email ->
            ( { model | email = email }, Effect.none )

        Login info ->
            ( model, Effect.fromCmd (Ports.login info model.redirect) )

        Toast message ->
            model |> mapToastsCmd (Toasts.update Toast message) |> Tuple.mapSecond Effect.fromCmd

        JsMessage message ->
            model |> handleJsMessage message |> Tuple.mapSecond Effect.fromCmd


handleJsMessage : JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage msg model =
    case msg of
        GotToast level message ->
            ( model, message |> Toasts.create level |> Toast |> T.send )

        GotSizes _ ->
            -- useless here but avoid waring toast
            ( model, Cmd.none )

        _ ->
            ( model, Ports.unhandledJsMsgError msg |> Toasts.create "warning" |> Toast |> T.send )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.onJsMessage Nothing JsMessage



-- VIEW


view : Model -> View Msg
view model =
    { title = title, body = viewLogin model }
