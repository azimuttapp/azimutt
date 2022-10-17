module Pages.Organization_.Create exposing (Model, Msg, page)

import Gen.Params.Organization_.Create exposing (Params)
import Models.OrganizationId exposing (OrganizationId)
import Page
import PagesComponents.Create.Init as Init
import PagesComponents.Create.Models as Models
import PagesComponents.Create.Subscriptions as Subscriptions
import PagesComponents.Create.Updates as Updates
import PagesComponents.Create.Views as Views
import Request
import Shared


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    let
        urlOrganization : Maybe OrganizationId
        urlOrganization =
            Just req.params.organization
    in
    Page.element
        { init = Init.init urlOrganization
        , update = Updates.update req shared.now urlOrganization
        , view = Views.view
        , subscriptions = Subscriptions.subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg
