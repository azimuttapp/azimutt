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
import PagesComponents.Projects.Id_.Models as Models exposing (CursorMode(..), Msg(..))
import PagesComponents.Projects.Id_.Models.EmbedMode as EmbedMode
import PagesComponents.Projects.Id_.Models.ErdConf as ErdConf exposing (ErdConf)
import PagesComponents.Projects.Id_.Subscriptions as Subscriptions
import PagesComponents.Projects.Id_.Updates as Updates
import PagesComponents.Projects.Id_.Views as Views
import Ports
import Request
import Shared


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init req.query
        , update = Updates.update Nothing (req.query |> Dict.get "layout") shared.now
        , view = Views.view shared
        , subscriptions = Subscriptions.subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : Dict String String -> ( Model, Cmd Msg )
init query =
    ( { conf = query |> Dict.getOrElse "mode" "static" |> initConf
      , navbar = { mobileMenuOpen = False, search = { text = "", active = 0 } }
      , screen = ScreenProps.zero
      , loaded = False
      , erd = Nothing
      , hoverTable = Nothing
      , hoverColumn = Nothing
      , cursorMode = CursorSelect
      , selectionBox = Nothing
      , newLayout = Nothing
      , virtualRelation = Nothing
      , findPath = Nothing
      , schemaAnalysis = Nothing
      , sharing = Nothing
      , settings = Nothing
      , sourceUpload = Nothing
      , help = Nothing
      , openedDropdown = ""
      , openedPopover = ""
      , contextMenu = Nothing
      , dragging = Nothing
      , toastIdx = 0
      , toasts = []
      , confirm = Nothing
      , prompt = Nothing
      , openedDialogs = []
      }
    , Cmd.batch
        [ Ports.setMeta
            { title = Just (Views.title Nothing)
            , description = Just Conf.constants.defaultDescription
            , canonical = Just Route.Embed
            , html = Just "h-full"
            , body = Just "h-full"
            }
        , Ports.trackPage "embed"
        , (query |> Dict.get "project_url" |> Maybe.map Ports.loadRemoteProject)
            |> Maybe.withDefault (T.send (Noop "load embed"))
        , Ports.listenHotkeys Conf.hotkeys
        ]
    )


initConf : String -> ErdConf
initConf mode =
    EmbedMode.all |> List.findBy .id mode |> Maybe.mapOrElse .conf ErdConf.embedDefault
