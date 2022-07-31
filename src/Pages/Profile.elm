module Pages.Profile exposing (Model, Msg, page)

import Conf
import Dict
import Gen.Params.Profile exposing (Params)
import Gen.Route as Route
import Libs.Maybe as Maybe
import Libs.Task as T
import Page
import PagesComponents.Profile.Models as Models exposing (Msg(..))
import PagesComponents.Profile.View exposing (viewProfile)
import Ports exposing (JsMsg(..))
import Request
import Services.Lenses exposing (mapToastsCmd, mapUserM, setBio, setCompany, setGithub, setLocation, setName, setTwitter, setUsername, setWebsite)
import Services.Toasts as Toasts
import Shared
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init shared
        , update = update shared req
        , view = view shared req
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
    ( { mobileMenuOpen = False
      , profileDropdownOpen = False
      , user = shared.user
      , updating = False
      , toasts = Toasts.init
      }
    , Cmd.batch
        [ Ports.setMeta
            { title = Just (title shared)
            , description = Just (shared.user |> Maybe.andThen .bio |> Maybe.withDefault Conf.constants.defaultDescription)
            , canonical = Just { route = Route.Profile, query = Dict.empty }
            , html = Just ""
            , body = Just "antialiased font-sans bg-gray-100"
            }
        , Ports.trackPage "profile"
        ]
    )



-- UPDATE


update : Shared.Model -> Request.With Params -> Msg -> Model -> ( Model, Cmd Msg )
update shared req msg model =
    case msg of
        ToggleMobileMenu ->
            ( { model | mobileMenuOpen = not model.mobileMenuOpen }, Cmd.none )

        ToggleProfileDropdown ->
            ( { model | profileDropdownOpen = not model.profileDropdownOpen }, Cmd.none )

        UpdateUsername username ->
            ( model |> mapUserM (setUsername username), Cmd.none )

        UpdateBio bio ->
            ( model |> mapUserM (setBio (Just bio |> Maybe.filter (\b -> b |> String.isEmpty |> not))), Cmd.none )

        UpdateName name ->
            ( model |> mapUserM (setName name), Cmd.none )

        UpdateWebsite website ->
            ( model |> mapUserM (setWebsite (Just website |> Maybe.filter (\b -> b |> String.isEmpty |> not))), Cmd.none )

        UpdateLocation location ->
            ( model |> mapUserM (setLocation (Just location |> Maybe.filter (\b -> b |> String.isEmpty |> not))), Cmd.none )

        UpdateCompany company ->
            ( model |> mapUserM (setCompany (Just company |> Maybe.filter (\b -> b |> String.isEmpty |> not))), Cmd.none )

        UpdateGithub github ->
            ( model |> mapUserM (setGithub (Just github |> Maybe.filter (\b -> b |> String.isEmpty |> not))), Cmd.none )

        UpdateTwitter twitter ->
            ( model |> mapUserM (setTwitter (Just twitter |> Maybe.filter (\b -> b |> String.isEmpty |> not))), Cmd.none )

        UpdateUser user ->
            ( { model | updating = True }, Ports.updateUser user )

        ResetUser ->
            ( { model | user = shared.user }, Cmd.none )

        DeleteAccount ->
            ( model, Cmd.none )

        DoLogout ->
            ( model, Cmd.batch [ Ports.logout, Request.pushRoute Route.Projects req ] )

        Toast message ->
            model |> mapToastsCmd (Toasts.update Toast message)

        JsMessage message ->
            model |> handleJsMessage message

        Noop _ ->
            ( model, Cmd.none )


handleJsMessage : JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage msg model =
    case msg of
        GotLogin user ->
            ( { model | user = Just user, updating = False }, Cmd.none )

        GotToast level message ->
            ( model, message |> Toasts.create level |> Toast |> T.send )

        _ ->
            ( model, Ports.unhandledJsMsgError msg |> Toasts.create "warning" |> Toast |> T.send )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.onJsMessage Nothing JsMessage



-- VIEW


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = title shared
    , body = model |> viewProfile req.url shared
    }
