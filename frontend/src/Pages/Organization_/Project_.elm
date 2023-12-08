module Pages.Organization_.Project_ exposing (Model, Msg, page)

import Browser.Navigation as Navigation
import Conf
import Dict exposing (Dict)
import Gen.Params.Organization_.Project_ exposing (Params)
import Gen.Route as Route
import Libs.Bool as Bool
import Libs.Task as T
import Models.ProjectTokenId exposing (ProjectTokenId)
import Models.UrlInfos exposing (UrlInfos)
import Page
import PagesComponents.Organization_.Project_.Models as Models exposing (Msg(..), emptyModel)
import PagesComponents.Organization_.Project_.Models.ErdConf as ErdConf
import PagesComponents.Organization_.Project_.Subscriptions as Subscriptions
import PagesComponents.Organization_.Project_.Updates as Updates
import PagesComponents.Organization_.Project_.Views as Views
import Ports
import Request
import Services.Backend as Backend
import Shared


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    let
        urlInfos : UrlInfos
        urlInfos =
            { organization = Just req.params.organization, project = Just req.params.project }

        ( urlLayout, urlToken, urlSave ) =
            ( req.query |> Dict.get "layout", req.query |> Dict.get "token", req.query |> Dict.member "save" )
    in
    Page.element
        { init = init req.params urlToken urlSave
        , update = Updates.update "project" urlLayout shared.zone shared.now urlInfos shared.organizations shared.projects
        , view = Views.view (Navigation.load (Backend.organizationUrl urlInfos.organization)) req.url urlInfos shared
        , subscriptions = Subscriptions.subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : Params -> Maybe ProjectTokenId -> Bool -> ( Model, Cmd Msg )
init params token save =
    ( { emptyModel | conf = ErdConf.project token }
    , Cmd.batch
        [ Ports.setMeta
            { title = Just (Views.title Nothing)
            , description = Just Conf.constants.defaultDescription
            , canonical = Just { route = Route.Organization___Project_ params, query = Dict.empty }
            , html = Just "h-full"
            , body = Just "h-full overflow-hidden"
            }
        , Ports.listenHotkeys Conf.hotkeys
        , Ports.getProject params.organization params.project token
        , Bool.cond save (T.sendAfter 1000 TriggerSaveProject) Cmd.none
        ]
    )
