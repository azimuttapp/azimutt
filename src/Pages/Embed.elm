module Pages.Embed exposing (Model, Msg, page)

import Conf
import Dict exposing (Dict)
import Gen.Params.Embed exposing (Params)
import Gen.Route as Route
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Task as T
import Models.ScreenProps as ScreenProps
import Page
import PagesComponents.Projects.Id_.Models as Models exposing (CursorMode(..), Msg(..), SourceParsingDialog)
import PagesComponents.Projects.Id_.Models.EmbedMode as EmbedMode
import PagesComponents.Projects.Id_.Models.ErdConf as ErdConf exposing (ErdConf)
import PagesComponents.Projects.Id_.Subscriptions as Subscriptions
import PagesComponents.Projects.Id_.Updates as Updates
import PagesComponents.Projects.Id_.Views as Views
import Ports
import Random
import Request
import Services.SqlSourceUpload as SqlSourceUpload
import Services.Toasts as Toasts
import Shared
import Time


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    let
        query : QueryString
        query =
            parseQueryString req.query
    in
    Page.element
        { init = init shared.now query
        , update = Updates.update req query.layout shared.now
        , view = Views.view (Request.pushRoute Route.NotFound req) req.url shared
        , subscriptions = Subscriptions.subscriptions
        }


type alias QueryString =
    { projectUrl : Maybe String
    , sourceUrl : Maybe String
    , layout : Maybe String
    , mode : String
    }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : Time.Posix -> QueryString -> ( Model, Cmd Msg )
init now query =
    ( { seed = Random.initialSeed (now |> Time.posixToMillis)
      , conf = initConf query.mode
      , navbar = { mobileMenuOpen = False, search = { text = "", active = 0 } }
      , screen = ScreenProps.zero
      , loaded = query.projectUrl == Nothing && query.sourceUrl == Nothing
      , erd = Nothing
      , projects = []
      , hoverTable = Nothing
      , hoverColumn = Nothing
      , cursorMode = CursorSelect
      , selectionBox = Nothing
      , newLayout = Nothing
      , editNotes = Nothing
      , virtualRelation = Nothing
      , findPath = Nothing
      , schemaAnalysis = Nothing
      , sharing = Nothing
      , upload = Nothing
      , settings = Nothing
      , sourceUpload = Nothing
      , sourceParsing =
            (query.projectUrl |> Maybe.map (\_ -> Nothing))
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
            , body = Just "h-full"
            }
         , Ports.trackPage "embed"
         , Ports.listenHotkeys Conf.hotkeys
         ]
            ++ ((query.projectUrl |> Maybe.map (\url -> [ Ports.loadRemoteProject url ]))
                    |> Maybe.orElse (query.sourceUrl |> Maybe.map (\url -> [ T.send (SourceParsing (SqlSourceUpload.SelectRemoteFile url)), T.sendAfter 1 (ModalOpen Conf.ids.sourceParsingDialog) ]))
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
    , parsing =
        SqlSourceUpload.init
            Nothing
            Nothing
            (\( projectId, parser, source ) ->
                if parser |> SqlSourceUpload.hasErrors then
                    Noop "embed-parse-source-has-errors"

                else
                    ModalClose (SourceParsed projectId source)
            )
    }


parseQueryString : Dict String String -> QueryString
parseQueryString query =
    { projectUrl = query |> Dict.get "project-url" |> Maybe.orElse (query |> Dict.get "project_url")
    , sourceUrl = query |> Dict.get "source-url"
    , layout = query |> Dict.get "layout"
    , mode = query |> Dict.getOrElse "mode" EmbedMode.default
    }


serializeQueryString : QueryString -> Dict String String
serializeQueryString query =
    Dict.fromList
        ([ ( "project-url", query.projectUrl )
         , ( "source-url", query.sourceUrl )
         , ( "layout", query.layout )
         , ( "mode", Just query.mode )
         ]
            |> List.filterMap (\( key, maybeValue ) -> maybeValue |> Maybe.map (\value -> ( key, value )))
        )
