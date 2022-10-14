module Pages.Organization_.Project_ exposing (Model, Msg, page)

import Conf
import Dict exposing (Dict)
import Gen.Params.Organization_.Project_ exposing (Params)
import Gen.Route as Route
import Libs.Bool as Bool
import Libs.Task as T
import Models.ErdProps as ErdProps
import Models.OrganizationId exposing (OrganizationId)
import Page
import PagesComponents.Organization_.Project_.Models as Models exposing (Msg(..))
import PagesComponents.Organization_.Project_.Models.CursorMode as CursorMode
import PagesComponents.Organization_.Project_.Models.ErdConf as ErdConf
import PagesComponents.Organization_.Project_.Subscriptions as Subscriptions
import PagesComponents.Organization_.Project_.Updates as Updates
import PagesComponents.Organization_.Project_.Views as Views
import Ports
import Request
import Services.Toasts as Toasts
import Shared exposing (StoredProjects(..))



-- FIXME: if fail to load local project, propose to delete it


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    let
        urlOrganization : Maybe OrganizationId
        urlOrganization =
            Just req.params.organization
    in
    Page.element
        { init = init req.params req.query
        , update = Updates.update Nothing shared.now urlOrganization shared.organizations shared.projects
        , view = Views.view (Request.pushRoute Route.Projects req) req.url urlOrganization shared
        , subscriptions = Subscriptions.subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : Params -> Dict String String -> ( Model, Cmd Msg )
init params query =
    ( { conf = ErdConf.default
      , navbar = { mobileMenuOpen = False, search = { text = "", active = 0 } }
      , erdElem = ErdProps.zero
      , loaded = False
      , dirty = False
      , erd = Nothing
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
      , modal = Nothing
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
        , Ports.getLegacyProjects
        , Ports.getProject params.organization params.project
        , Bool.cond (query |> Dict.member "save") (T.sendAfter 500 TriggerSaveProject) Cmd.none
        ]
    )
