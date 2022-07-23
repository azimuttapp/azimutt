module Pages.Embed exposing (Model, Msg, page)

import Conf
import Dict exposing (Dict)
import Gen.Params.Embed exposing (Params)
import Gen.Route as Route
import Http
import Libs.Dict as Dict
import Libs.Http as Http
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Task as T
import Models.Project as Project
import Models.ScreenProps as ScreenProps
import Page
import PagesComponents.Projects.Id_.Components.EmbedSourceParsingDialog as EmbedSourceParsingDialog
import PagesComponents.Projects.Id_.Models as Models exposing (Msg(..))
import PagesComponents.Projects.Id_.Models.CursorMode as CursorMode
import PagesComponents.Projects.Id_.Models.EmbedKind as EmbedKind
import PagesComponents.Projects.Id_.Models.EmbedMode as EmbedMode
import PagesComponents.Projects.Id_.Models.ErdConf as ErdConf exposing (ErdConf)
import PagesComponents.Projects.Id_.Subscriptions as Subscriptions
import PagesComponents.Projects.Id_.Updates as Updates
import PagesComponents.Projects.Id_.Views as Views
import Ports exposing (JsMsg(..))
import Request
import Services.DatabaseSource as DatabaseSource
import Services.JsonSource as JsonSource
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts
import Shared


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    let
        query : QueryString
        query =
            parseQueryString req.query
    in
    Page.element
        { init = init query
        , update = Updates.update req query.layout shared.now shared.conf.backendUrl
        , view = Views.view (Request.pushRoute Route.NotFound req) req.url shared
        , subscriptions = Subscriptions.subscriptions
        }


type alias QueryString =
    { databaseSource : Maybe String
    , sqlSource : Maybe String
    , jsonSource : Maybe String
    , projectId : Maybe String
    , projectUrl : Maybe String
    , layout : Maybe String
    , mode : String
    }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : QueryString -> ( Model, Cmd Msg )
init query =
    ( { conf = initConf query.mode
      , navbar = { mobileMenuOpen = False, search = { text = "", active = 0 } }
      , screen = ScreenProps.zero
      , loaded = [ query.databaseSource, query.sqlSource, query.jsonSource, query.projectId, query.projectUrl ] |> List.all (\a -> a == Nothing)
      , erd = Nothing
      , projects = []
      , hoverTable = Nothing
      , hoverColumn = Nothing
      , cursorMode = CursorMode.Select
      , selectionBox = Nothing
      , newLayout = Nothing
      , editNotes = Nothing
      , amlSidebar = Nothing
      , virtualRelation = Nothing
      , findPath = Nothing
      , schemaAnalysis = Nothing
      , sharing = Nothing
      , upload = Nothing
      , settings = Nothing
      , sourceUpload = Nothing
      , embedSourceParsing = EmbedSourceParsingDialog.init SourceParsed ModalClose Noop query.databaseSource query.sqlSource query.jsonSource
      , help = Nothing
      , openedDropdown = ""
      , openedPopover = ""
      , contextMenu = Nothing
      , dragging = Nothing
      , toasts = Toasts.init
      , confirm = Nothing
      , prompt = Nothing
      , openedDialogs = []
      }
    , Cmd.batch
        ([ Ports.setMeta
            { title = Just (Views.title Nothing)
            , description = Just Conf.constants.defaultDescription
            , canonical = Just { route = Route.Embed, query = query |> serializeQueryString }
            , html = Just "h-full"
            , body = Just "h-full overflow-hidden"
            }
         , Ports.trackPage "embed"
         , Ports.listenHotkeys Conf.hotkeys
         ]
            ++ ((query.databaseSource |> Maybe.map (\url -> [ T.send (url |> DatabaseSource.GetSchema |> EmbedSourceParsingDialog.EmbedDatabaseSource |> EmbedSourceParsingMsg), T.sendAfter 1 (ModalOpen Conf.ids.sourceParsingDialog) ]))
                    |> Maybe.orElse (query.sqlSource |> Maybe.map (\url -> [ T.send (url |> SqlSource.GetRemoteFile |> EmbedSourceParsingDialog.EmbedSqlSource |> EmbedSourceParsingMsg), T.sendAfter 1 (ModalOpen Conf.ids.sourceParsingDialog) ]))
                    |> Maybe.orElse (query.jsonSource |> Maybe.map (\url -> [ T.send (url |> JsonSource.GetRemoteFile |> EmbedSourceParsingDialog.EmbedJsonSource |> EmbedSourceParsingMsg), T.sendAfter 1 (ModalOpen Conf.ids.sourceParsingDialog) ]))
                    |> Maybe.orElse (query.projectUrl |> Maybe.map (\url -> [ Http.get { url = url, expect = Http.decodeJson (Result.toMaybe >> GotProject >> JsMessage) Project.decode } ]))
                    |> Maybe.orElse (query.projectId |> Maybe.map (\id -> [ Ports.loadProject id ]))
                    |> Maybe.withDefault []
               )
        )
    )


initConf : String -> ErdConf
initConf mode =
    EmbedMode.all |> List.findBy .id mode |> Maybe.mapOrElse .conf ErdConf.embedDefault


parseQueryString : Dict String String -> QueryString
parseQueryString query =
    { databaseSource = query |> Dict.get EmbedKind.databaseSource
    , sqlSource = query |> Dict.get EmbedKind.sqlSource |> Maybe.orElse (query |> Dict.get EmbedKind.sourceUrl)
    , jsonSource = query |> Dict.get EmbedKind.jsonSource
    , projectId = query |> Dict.get EmbedKind.projectId
    , projectUrl = query |> Dict.get EmbedKind.projectUrl
    , layout = query |> Dict.get "layout"
    , mode = query |> Dict.getOrElse EmbedMode.key EmbedMode.default
    }


serializeQueryString : QueryString -> Dict String String
serializeQueryString query =
    Dict.fromList
        ([ ( EmbedKind.databaseSource, query.databaseSource )
         , ( EmbedKind.sqlSource, query.sqlSource )
         , ( EmbedKind.jsonSource, query.jsonSource )
         , ( EmbedKind.projectId, query.projectId )
         , ( EmbedKind.projectUrl, query.projectUrl )
         , ( "layout", query.layout )
         , ( EmbedMode.key, Just query.mode )
         ]
            |> List.filterMap (\( key, maybeValue ) -> maybeValue |> Maybe.map (\value -> ( key, value )))
        )
