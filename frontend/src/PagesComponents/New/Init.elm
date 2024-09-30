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
import Services.JsonSource as JsonSource
import Services.PrismaSource as PrismaSource
import Services.ProjectSource as ProjectSource
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts


init : Maybe OrganizationId -> Dict String String -> ( Model, Cmd Msg )
init urlOrganization params =
    ( { selectedMenu = "New project"
      , mobileMenuOpen = False
      , openedCollapse = ""
      , samples = []
      , selectedTab = TabDatabase
      , databaseSource = Nothing
      , sqlSource = Nothing
      , prismaSource = Nothing
      , jsonSource = Nothing
      , projectSource = Nothing
      , sampleSource = Nothing
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
         , Backend.getSamples GotSamples
         ]
            ++ ((params |> Dict.get "database" |> Maybe.map (\value -> [ InitTab TabDatabase |> T.send, DatabaseSourceMsg (DatabaseSource.GetSchema value) |> T.sendAfter 1 ]))
                    |> Maybe.orElse (params |> Dict.get "sql" |> Maybe.map (\value -> [ InitTab TabSql |> T.send, SqlSourceMsg (SqlSource.GetRemoteFile value) |> T.sendAfter 1 ]))
                    |> Maybe.orElse (params |> Dict.get "prisma" |> Maybe.map (\value -> [ InitTab TabPrisma |> T.send, PrismaSourceMsg (PrismaSource.GetRemoteFile value) |> T.sendAfter 1 ]))
                    |> Maybe.orElse (params |> Dict.get "json" |> Maybe.map (\value -> [ InitTab TabJson |> T.send, JsonSourceMsg (JsonSource.GetRemoteFile value) |> T.sendAfter 1 ]))
                    |> Maybe.orElse (params |> Dict.get "empty" |> Maybe.map (\_ -> [ InitTab TabEmptyProject |> T.send ]))
                    |> Maybe.orElse (params |> Dict.get "project" |> Maybe.map (\value -> [ InitTab TabProject |> T.send, ProjectSourceMsg (ProjectSource.GetRemoteFile value) |> T.sendAfter 1 ]))
                    |> Maybe.orElse (params |> Dict.get "sample" |> Maybe.map (\_ -> [ InitTab TabSamples |> T.send ]))
                    |> Maybe.withDefault [ InitTab TabDatabase |> T.send ]
               )
        )
    )
