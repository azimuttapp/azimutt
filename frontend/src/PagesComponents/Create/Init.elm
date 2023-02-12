module PagesComponents.Create.Init exposing (init)

import Conf
import Dict
import Gen.Route as Route
import Libs.Maybe as Maybe
import Libs.Task as T
import Models.OrganizationId exposing (OrganizationId)
import PagesComponents.Create.Models exposing (Model, Msg(..))
import PagesComponents.Create.Views as Views
import Ports
import Services.Toasts as Toasts


init : Maybe OrganizationId -> ( Model, Cmd Msg )
init urlOrganization =
    ( { databaseSource = Nothing
      , sqlSource = Nothing
      , jsonSource = Nothing
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
        , T.send InitProject
        ]
    )
