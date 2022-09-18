module Pages.Organization_.Project_ exposing (Model, Msg, page)

import Conf
import Dict
import Gen.Params.Organization_.Project_ exposing (Params)
import Gen.Route as Route
import Models.ErdProps as ErdProps
import Page
import PagesComponents.Organization_.Project_.Models as Models exposing (Msg)
import PagesComponents.Organization_.Project_.Models.CursorMode as CursorMode
import PagesComponents.Organization_.Project_.Models.ErdConf as ErdConf
import PagesComponents.Organization_.Project_.Subscriptions as Subscriptions
import PagesComponents.Organization_.Project_.Updates as Updates
import PagesComponents.Organization_.Project_.Views as Views
import Ports
import Request
import Services.Toasts as Toasts
import Shared exposing (StoredProjects(..))



-- TODO: if fail to load local project, propose to delete it


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init req.params
        , update = Updates.update Nothing shared.conf.env shared.now shared.organizations
        , view = Views.view (Request.pushRoute Route.Projects req) req.url shared
        , subscriptions = Subscriptions.subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : Params -> ( Model, Cmd Msg )
init params =
    ( { conf = ErdConf.default
      , navbar = { mobileMenuOpen = False, search = { text = "", active = 0 } }
      , erdElem = ErdProps.zero
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
      , detailsSidebar = Nothing
      , virtualRelation = Nothing
      , findPath = Nothing
      , schemaAnalysis = Nothing
      , sharing = Nothing
      , upload = Nothing
      , save = Nothing
      , settings = Nothing
      , sourceUpdate = Nothing
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
            , canonical = Just { route = Route.Organization___Project_ params, query = Dict.empty }
            , html = Just "h-full"
            , body = Just "h-full overflow-hidden"
            }
        , Ports.trackPage "app"
        , Ports.listenHotkeys Conf.hotkeys

        -- , Ports.loadProject id
        , Ports.getProject params.organization params.project
        , Ports.listProjects
        ]
    )
