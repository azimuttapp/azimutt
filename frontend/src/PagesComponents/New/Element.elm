module PagesComponents.New.Element exposing (init)

import Models.OrganizationId exposing (OrganizationId)
import Page
import PagesComponents.New.Init as Init
import PagesComponents.New.Models as Models
import PagesComponents.New.Subscriptions as Subscriptions
import PagesComponents.New.Updates as Updates
import PagesComponents.New.Views as Views
import Request
import Shared


init : Maybe OrganizationId -> Shared.Model -> Request.With params -> Page.With Model Msg
init urlOrganization shared req =
    Page.element
        { init = Init.init urlOrganization shared.params
        , update = Updates.update req shared.params shared.now shared.projects urlOrganization
        , view = Views.view shared req.url urlOrganization
        , subscriptions = Subscriptions.subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg
