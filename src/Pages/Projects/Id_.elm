module Pages.Projects.Id_ exposing (Model, Msg, page)

import Conf
import Gen.Params.Projects.Id_ exposing (Params)
import Models.ScreenProps as ScreenProps
import Page
import PagesComponents.Projects.Id_.Models as Models exposing (CursorMode(..), Msg)
import PagesComponents.Projects.Id_.Subscriptions as Subscriptions
import PagesComponents.Projects.Id_.Updates as Updates
import PagesComponents.Projects.Id_.Views as Views
import Ports
import Request
import Shared exposing (StoredProjects(..))


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init
        , update = Updates.update (Just req.params.id) shared.now
        , view = Views.view shared
        , subscriptions = Subscriptions.subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : ( Model, Cmd Msg )
init =
    ( { conf =
            { fitOnLoad = False
            , allowSave = True
            , showNavbar = True
            , showCommands = True
            , allowFullscreen = False
            , drag = True
            , selectionBox = True
            , tableActions = True
            , columnActions = True
            }
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
        [ Ports.setClasses { html = "h-full", body = "h-full" }
        , Ports.trackPage "app"
        , Ports.loadProjects
        , Ports.listenHotkeys Conf.hotkeys
        ]
    )
