module Pages.Embed exposing (Model, Msg, page)

import Conf
import Dict exposing (Dict)
import Gen.Params.Embed exposing (Params)
import Gen.Route as Route
import Http
import Libs.Http as Http
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.FileUrl exposing (FileUrl)
import Libs.Task as T
import Models.OrganizationId as OrganizationId
import Models.Project as Project
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectId exposing (ProjectId)
import Models.ProjectTokenId exposing (ProjectTokenId)
import Models.UrlInfos exposing (UrlInfos)
import Page
import PagesComponents.Organization_.Project_.Components.EmbedSourceParsingDialog as EmbedSourceParsingDialog
import PagesComponents.Organization_.Project_.Models as Models exposing (Msg(..), emptyModel)
import PagesComponents.Organization_.Project_.Models.EmbedKind as EmbedKind
import PagesComponents.Organization_.Project_.Models.EmbedMode as EmbedMode exposing (EmbedModeId)
import PagesComponents.Organization_.Project_.Models.ErdConf as ErdConf
import PagesComponents.Organization_.Project_.Subscriptions as Subscriptions
import PagesComponents.Organization_.Project_.Updates as Updates
import PagesComponents.Organization_.Project_.Views as Views
import Ports exposing (JsMsg(..))
import Request
import Services.DatabaseSource as DatabaseSource
import Services.JsonSource as JsonSource
import Services.PrismaSource as PrismaSource
import Services.SqlSource as SqlSource
import Shared


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    let
        query : QueryString
        query =
            parseQueryString req.query

        urlInfos : UrlInfos
        urlInfos =
            { organization = Nothing, project = query.projectId }
    in
    Page.element
        { init = init query
        , update = Updates.update query.layout shared.zone shared.now urlInfos shared.conf.basePath shared.organizations shared.projects
        , view = Views.view (Request.pushRoute Route.NotFound req) req.url urlInfos shared
        , subscriptions = Subscriptions.subscriptions
        }


type alias QueryString =
    { projectId : Maybe ProjectId
    , projectUrl : Maybe FileUrl
    , databaseSource : Maybe DatabaseUrl
    , sqlSource : Maybe FileUrl
    , prismaSource : Maybe FileUrl
    , jsonSource : Maybe FileUrl
    , layout : Maybe LayoutName
    , mode : Maybe EmbedModeId
    , token : Maybe ProjectTokenId
    }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : QueryString -> ( Model, Cmd Msg )
init query =
    ( { emptyModel
        | conf = query.mode |> Maybe.andThen (\mode -> EmbedMode.all |> List.findBy .id mode) |> Maybe.mapOrElse .conf ErdConf.embedDefault
        , loaded = [ query.projectId, query.projectUrl, query.databaseSource, query.sqlSource, query.jsonSource ] |> List.all (\a -> a == Nothing)
        , embedSourceParsing = EmbedSourceParsingDialog.init SourceParsed ModalClose Noop query.databaseSource query.sqlSource query.prismaSource query.jsonSource
      }
    , Cmd.batch
        ([ Ports.setMeta
            { title = Just (Views.title Nothing)
            , description = Just Conf.constants.defaultDescription
            , canonical = Just { route = Route.Embed, query = query |> serializeQueryString }
            , html = Just "h-full"
            , body = Just "h-full overflow-hidden"
            }
         , Ports.listenHotkeys Conf.hotkeys
         ]
            -- org id is not used to get the project ^^
            ++ ((query.projectId |> Maybe.map (\id -> [ Ports.getProject OrganizationId.zero id query.token ]))
                    |> Maybe.orElse (query.projectUrl |> Maybe.map (\url -> [ Http.get { url = url, expect = Http.decodeJson (Result.toMaybe >> GotProject "load" >> JsMessage) Project.decode } ]))
                    |> Maybe.orElse (query.databaseSource |> Maybe.map (\url -> [ T.send (url |> DatabaseSource.GetSchema |> EmbedSourceParsingDialog.EmbedDatabaseSource |> EmbedSourceParsingMsg), T.sendAfter 1 (ModalOpen Conf.ids.sourceParsingDialog) ]))
                    |> Maybe.orElse (query.sqlSource |> Maybe.map (\url -> [ T.send (url |> SqlSource.GetRemoteFile |> EmbedSourceParsingDialog.EmbedSqlSource |> EmbedSourceParsingMsg), T.sendAfter 1 (ModalOpen Conf.ids.sourceParsingDialog) ]))
                    |> Maybe.orElse (query.prismaSource |> Maybe.map (\url -> [ T.send (url |> PrismaSource.GetRemoteFile |> EmbedSourceParsingDialog.EmbedPrismaSource |> EmbedSourceParsingMsg), T.sendAfter 1 (ModalOpen Conf.ids.sourceParsingDialog) ]))
                    |> Maybe.orElse (query.jsonSource |> Maybe.map (\url -> [ T.send (url |> JsonSource.GetRemoteFile |> EmbedSourceParsingDialog.EmbedJsonSource |> EmbedSourceParsingMsg), T.sendAfter 1 (ModalOpen Conf.ids.sourceParsingDialog) ]))
                    |> Maybe.withDefault []
               )
        )
    )


parseQueryString : Dict String String -> QueryString
parseQueryString query =
    { projectId = query |> Dict.get EmbedKind.projectId
    , projectUrl = query |> Dict.get EmbedKind.projectUrl
    , databaseSource = query |> Dict.get EmbedKind.databaseSource
    , sqlSource = query |> Dict.get EmbedKind.sqlSource |> Maybe.orElse (query |> Dict.get EmbedKind.sourceUrl)
    , prismaSource = query |> Dict.get EmbedKind.prismaSource
    , jsonSource = query |> Dict.get EmbedKind.jsonSource
    , layout = query |> Dict.get "layout"
    , mode = query |> Dict.get EmbedMode.key
    , token = query |> Dict.get "token"
    }


serializeQueryString : QueryString -> Dict String String
serializeQueryString query =
    Dict.fromList
        ([ ( EmbedKind.projectId, query.projectId )
         , ( EmbedKind.projectUrl, query.projectUrl )
         , ( EmbedKind.databaseSource, query.databaseSource )
         , ( EmbedKind.sqlSource, query.sqlSource )
         , ( EmbedKind.prismaSource, query.prismaSource )
         , ( EmbedKind.jsonSource, query.jsonSource )
         , ( "layout", query.layout )
         , ( EmbedMode.key, query.mode )
         ]
            |> List.filterMap (\( key, maybeValue ) -> maybeValue |> Maybe.map (\value -> ( key, value )))
        )
