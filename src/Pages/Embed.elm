module Pages.Embed exposing (Model, Msg, page)

import Conf
import Dict exposing (Dict)
import Gen.Params.Embed exposing (Params)
import Gen.Route as Route
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Result as Result
import Libs.Task as T
import Models.ScreenProps as ScreenProps
import Page
import PagesComponents.Projects.Id_.Models as Models exposing (Msg(..), SourceParsingDialog)
import PagesComponents.Projects.Id_.Models.CursorMode as CursorMode
import PagesComponents.Projects.Id_.Models.EmbedKind as EmbedKind
import PagesComponents.Projects.Id_.Models.EmbedMode as EmbedMode
import PagesComponents.Projects.Id_.Models.ErdConf as ErdConf exposing (ErdConf)
import PagesComponents.Projects.Id_.Subscriptions as Subscriptions
import PagesComponents.Projects.Id_.Updates as Updates
import PagesComponents.Projects.Id_.Views as Views
import Ports
import Request
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
    { projectId : Maybe String
    , projectUrl : Maybe String
    , sourceUrl : Maybe String
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
      , loaded = query.projectId == Nothing && query.projectUrl == Nothing && query.sourceUrl == Nothing
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
      , sourceParsing =
            (query.projectId |> Maybe.map (\_ -> Nothing))
                |> Maybe.orElse (query.projectUrl |> Maybe.map (\_ -> Nothing))
                |> Maybe.orElse (query.sourceUrl |> Maybe.map (\_ -> Just initSourceParsing))
                |> Maybe.withDefault Nothing
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
            ++ ((query.projectId |> Maybe.map (\id -> [ Ports.loadProject id ]))
                    |> Maybe.orElse (query.projectUrl |> Maybe.map (\url -> [ Ports.loadRemoteProject url ]))
                    |> Maybe.orElse (query.sourceUrl |> Maybe.map (\url -> [ T.send (EmbedSourceParsing (SqlSource.GetRemoteFile url)), T.sendAfter 1 (ModalOpen Conf.ids.sourceParsingDialog) ]))
                    |> Maybe.withDefault []
               )
        )
    )


initConf : String -> ErdConf
initConf mode =
    EmbedMode.all |> List.findBy .id mode |> Maybe.mapOrElse .conf ErdConf.embedDefault


initSourceParsing : SourceParsingDialog
initSourceParsing =
    { id = Conf.ids.sourceParsingDialog
    , sqlSource =
        SqlSource.init
            Conf.schema.default
            Nothing
            (\( parser, source ) ->
                if parser |> Maybe.any SqlSource.hasErrors then
                    Noop "embed-parse-sql-has-errors"

                else
                    source |> Result.fold (\_ -> Noop "embed-load-sql-has-errors") (SourceParsed >> ModalClose)
            )
    }


parseQueryString : Dict String String -> QueryString
parseQueryString query =
    { projectId = query |> Dict.get EmbedKind.projectId
    , projectUrl = query |> Dict.get EmbedKind.projectUrl
    , sourceUrl = query |> Dict.get EmbedKind.sourceUrl
    , layout = query |> Dict.get "layout"
    , mode = query |> Dict.getOrElse "mode" EmbedMode.default
    }


serializeQueryString : QueryString -> Dict String String
serializeQueryString query =
    Dict.fromList
        ([ ( EmbedKind.projectId, query.projectId )
         , ( EmbedKind.projectUrl, query.projectUrl )
         , ( EmbedKind.sourceUrl, query.sourceUrl )
         , ( "layout", query.layout )
         , ( "mode", Just query.mode )
         ]
            |> List.filterMap (\( key, maybeValue ) -> maybeValue |> Maybe.map (\value -> ( key, value )))
        )
