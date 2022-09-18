module PagesComponents.Create.Init exposing (init)

import Conf
import Dict
import Gen.Route as Route
import Libs.Maybe as Maybe
import Models.OrganizationId exposing (OrganizationId)
import PagesComponents.Create.Models exposing (Model, Msg)
import PagesComponents.Create.Views as Views
import Ports
import Services.Toasts as Toasts


init : Maybe OrganizationId -> ( Model, Cmd Msg )
init urlOrganization =
    ( { projects = []
      , databaseSource = Nothing
      , sqlSource = Nothing
      , jsonSource = Nothing
      , projectName = Conf.constants.newProjectName
      , toasts = Toasts.init
      }
    , Cmd.batch
        [ Ports.setMeta
            { title = Just Views.title
            , description = Just Conf.constants.defaultDescription
            , canonical = Just { route = urlOrganization |> Maybe.mapOrElse (\id -> Route.Organization___Create { organization = id }) Route.Create, query = Dict.empty }
            , html = Just "h-full"
            , body = Just "h-full"
            }
        , Ports.trackPage "create-project"
        , Ports.listProjects
        ]
    )
