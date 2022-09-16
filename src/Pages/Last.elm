module Pages.Last exposing (Model, Msg, page)

import Components.Atoms.Loader as Loader
import Conf
import Dict
import Gen.Params.Last exposing (Params)
import Gen.Route as Route
import Html.Lazy as Lazy
import Libs.Maybe as Maybe
import Libs.Task as T
import Page
import Ports exposing (JsMsg(..))
import Request
import Services.Lenses exposing (mapToastsCmd)
import Services.Sort as Sort
import Services.Toasts as Toasts
import Shared
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page _ req =
    Page.element
        { init = init
        , update = update req
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    { toasts : Toasts.Model }


type Msg
    = Toast Toasts.Msg
    | JsMessage JsMsg



-- INIT


title : String
title =
    "Azimutt is loading..."


init : ( Model, Cmd Msg )
init =
    ( { toasts = Toasts.init }
    , Cmd.batch
        [ Ports.setMeta
            { title = Just title
            , description = Just Conf.constants.defaultDescription
            , canonical = Just { route = Route.Last, query = Dict.empty }
            , html = Just "h-full"
            , body = Just "h-full"
            }
        , Ports.trackPage "last-project"
        , Ports.listProjects
        ]
    )



-- UPDATE


update : Request.With Params -> Msg -> Model -> ( Model, Cmd Msg )
update req msg model =
    case msg of
        Toast message ->
            model |> mapToastsCmd (Toasts.update Toast message)

        JsMessage message ->
            model |> handleJsMessage req message


handleJsMessage : Request.With Params -> JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage req msg model =
    case msg of
        GotProjects ( _, projects ) ->
            ( model
            , Request.pushRoute
                (projects
                    |> Sort.lastUpdatedFirst
                    |> List.head
                    |> Maybe.mapOrElse (\p -> Route.Organization___Project_ { organization = Conf.constants.tmpOrg, project = p.id }) Route.Projects
                )
                req
            )

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
    { title = title, body = [ Loader.fullScreen, Lazy.lazy2 Toasts.view Toast model.toasts ] }
