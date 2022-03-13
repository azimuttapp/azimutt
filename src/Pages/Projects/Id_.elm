module Pages.Projects.Id_ exposing (Model, Msg, page)

import Conf
import Dict
import Gen.Params.Projects.Id_ exposing (Params)
import Gen.Route as Route
import Models.Project.ProjectId exposing (ProjectId)
import Models.ScreenProps as ScreenProps
import Page
import PagesComponents.Projects.Id_.Models as Models exposing (CursorMode(..), Msg)
import PagesComponents.Projects.Id_.Models.ErdConf as ErdConf
import PagesComponents.Projects.Id_.Subscriptions as Subscriptions
import PagesComponents.Projects.Id_.Updates as Updates
import PagesComponents.Projects.Id_.Views as Views
import Ports
import Request
import Shared exposing (StoredProjects(..))


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init req.params.id
        , update = Updates.update (Just req.params.id) Nothing shared.now
        , view = Views.view shared
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
      , sourceParsing = Nothing
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
            , canonical = Just { route = Route.Projects__Id_ { id = id }, query = Dict.empty }
            , html = Just "h-full"
            , body = Just "h-full"
            }
        , Ports.trackPage "app"
        , Ports.listenHotkeys Conf.hotkeys
        , Ports.loadProjects
        ]
    )
