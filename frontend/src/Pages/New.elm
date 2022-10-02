module Pages.New exposing (Model, Msg, page)

import Gen.Params.New exposing (Params)
import Models.OrganizationId exposing (OrganizationId)
import Page
import PagesComponents.New.Init as Init
import PagesComponents.New.Models as Models exposing (Msg, Tab(..))
import PagesComponents.New.Subscriptions as Subscriptions
import PagesComponents.New.Updates as Updates
import PagesComponents.New.Views as Views
import Request
import Shared


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    let
        urlOrganization : Maybe OrganizationId
        urlOrganization =
            Nothing
    in
    Page.element
        { init = Init.init urlOrganization req.query
        , update = Updates.update req shared.conf.env shared.now urlOrganization
        , view = Views.view shared req.url urlOrganization
        , subscriptions = Subscriptions.subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg
