module PagesComponents.Create.Element exposing (init)

import Dict exposing (Dict)
import Models.OrganizationId exposing (OrganizationId)
import Page
import PagesComponents.Create.Init as Init
import PagesComponents.Create.Models as Models
import PagesComponents.Create.Subscriptions as Subscriptions
import PagesComponents.Create.Updates as Updates
import PagesComponents.Create.Views as Views
import Request
import Shared


init : Maybe OrganizationId -> Shared.Model -> Request.With params -> Page.With Model Msg
init urlOrganization shared req =
    let
        hash : Dict String String
        hash =
            req.url.fragment |> Maybe.map (\h -> Dict.fromList [ ( "database", h ) ]) |> Maybe.withDefault Dict.empty

        params : Dict String String
        params =
            hash |> Dict.union shared.params |> Dict.union req.query
    in
    Page.element
        { init = Init.init urlOrganization
        , update = Updates.update req params shared.now shared.projects shared.projectsLoaded urlOrganization
        , view = Views.view
        , subscriptions = Subscriptions.subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg
