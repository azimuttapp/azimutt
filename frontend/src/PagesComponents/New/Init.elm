module PagesComponents.New.Init exposing (init)

import Conf
import Dict exposing (Dict)
import Gen.Route as Route
import Libs.Maybe as Maybe
import Libs.Task as T
import Models.OrganizationId exposing (OrganizationId)
import PagesComponents.New.Models exposing (Model, Msg(..), Tab(..))
import PagesComponents.New.Views as Views
import Ports
import Services.Backend as Backend
import Services.DatabaseSource as DatabaseSource
import Services.ImportProject as ImportProject
import Services.JsonSource as JsonSource
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts


init : Maybe OrganizationId -> Dict String String -> ( Model, Cmd Msg )
init urlOrganization query =
    ( { selectedMenu = "New project"
      , mobileMenuOpen = False
      , openedCollapse = ""
      , projects = []
      , selectedTab = TabDatabase
      , databaseSource = Nothing
      , sqlSource = Nothing
      , jsonSource = Nothing
      , importProject = Nothing
      , sampleProject = Nothing
      , openedDropdown = ""
      , toasts = Toasts.init
      , confirm = Nothing
      , openedDialogs = []
      }
    , Cmd.batch
        ([ Ports.setMeta
            { title = Just Views.title
            , description = Just Conf.constants.defaultDescription
            , canonical = Just { route = urlOrganization |> Maybe.mapOrElse (\id -> Route.Organization___New { organization = id }) Route.New, query = Dict.empty }
            , html = Just "h-full bg-gray-100"
            , body = Just "h-full"
            }
         , Ports.trackPage "new-project"
         , Ports.getLegacyProjects
         ]
            ++ ((query |> Dict.get "database" |> Maybe.map (\value -> [ T.send (InitTab TabDatabase), T.sendAfter 1 (DatabaseSourceMsg (DatabaseSource.GetSchema value)) ]))
                    |> Maybe.orElse (query |> Dict.get "sql" |> Maybe.map (\value -> [ T.send (InitTab TabSql), T.sendAfter 1 (SqlSourceMsg (SqlSource.GetRemoteFile value)) ]))
                    |> Maybe.orElse (query |> Dict.get "json" |> Maybe.map (\value -> [ T.send (InitTab TabJson), T.sendAfter 1 (JsonSourceMsg (JsonSource.GetRemoteFile value)) ]))
                    |> Maybe.orElse (query |> Dict.get "empty" |> Maybe.map (\_ -> [ T.send (InitTab TabEmptyProject) ]))
                    |> Maybe.orElse (query |> Dict.get "project" |> Maybe.map (\value -> [ T.send (InitTab TabProject), T.sendAfter 1 (ImportProjectMsg (ImportProject.GetRemoteFile value Nothing)) ]))
                    |> Maybe.orElse (query |> Dict.get "sample" |> Maybe.map (\value -> T.send (InitTab TabSamples) :: (Backend.schemaSamples |> Dict.get value |> Maybe.mapOrElse (\s -> [ T.sendAfter 1 (SampleProjectMsg (ImportProject.GetRemoteFile s.url (Just s.key))) ]) [])))
                    |> Maybe.withDefault [ T.send (InitTab TabDatabase) ]
               )
        )
    )
