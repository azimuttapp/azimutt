module Pages.Projects.Id_ exposing (Model, Msg, page)

import Conf
import Dict
import Gen.Params.Projects.Id_ exposing (Params)
import Gen.Route as Route
import Models.Project.ProjectId exposing (ProjectId)
import Models.ScreenProps as ScreenProps
import Page
import PagesComponents.Projects.Id_.Models as Models exposing (Msg)
import PagesComponents.Projects.Id_.Models.CursorMode as CursorMode
import PagesComponents.Projects.Id_.Models.ErdConf as ErdConf
import PagesComponents.Projects.Id_.Subscriptions as Subscriptions
import PagesComponents.Projects.Id_.Updates as Updates
import PagesComponents.Projects.Id_.Views as Views
import Ports
import Request
import Services.Toasts as Toasts
import Shared exposing (StoredProjects(..))


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init req.params.id
        , update = Updates.update req Nothing shared.now shared.conf.backendUrl
        , view = Views.view (Request.pushRoute Route.Projects req) req.url shared
        , subscriptions = Subscriptions.subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : ProjectId -> ( Model, Cmd Msg )
init id =
    ( { conf = ErdConf.default
      , navbar = { mobileMenuOpen = False, search = { text = "", active = 0 } }
      , screen = ScreenProps.zero
      , loaded = False
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
      , embedSourceParsing = Nothing
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
        [ Ports.setMeta
            { title = Just (Views.title Nothing)
            , description = Just Conf.constants.defaultDescription
            , canonical = Just { route = Route.Projects__Id_ { id = id }, query = Dict.empty }
            , html = Just "h-full"
            , body = Just "h-full overflow-hidden"
            }
        , Ports.trackPage "app"
        , Ports.listenHotkeys Conf.hotkeys
        , Ports.loadProject id
        , Ports.listProjects
        ]
    )
