module Pages.Organization_.Project_ exposing (Model, Msg, page)

import Browser.Navigation as Navigation
import Conf
import Dict exposing (Dict)
import Gen.Params.Organization_.Project_ exposing (Params)
import Gen.Route as Route
import Libs.Bool as Bool
import Libs.Task as T
import Models.ErdProps as ErdProps
import Models.ProjectTokenId exposing (ProjectTokenId)
import Page
import PagesComponents.Organization_.Project_.Models as Models exposing (Msg(..))
import PagesComponents.Organization_.Project_.Models.CursorMode as CursorMode
import PagesComponents.Organization_.Project_.Models.ErdConf as ErdConf
import PagesComponents.Organization_.Project_.Subscriptions as Subscriptions
import PagesComponents.Organization_.Project_.Updates as Updates
import PagesComponents.Organization_.Project_.Views as Views
import Ports
import Request
import Services.Backend as Backend
import Services.Toasts as Toasts
import Shared


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    let
        ( urlOrganization, urlProject ) =
            ( Just req.params.organization, Just req.params.project )

        ( urlLayout, urlToken, urlSave ) =
            ( req.query |> Dict.get "layout", req.query |> Dict.get "token", req.query |> Dict.member "save" )
    in
    Page.element
        { init = init req.params urlToken urlSave
        , update = Updates.update urlLayout shared.zone shared.now urlOrganization shared.organizations shared.projects
        , view = Views.view (Navigation.load (Backend.organizationUrl urlOrganization)) req.url urlOrganization urlProject shared
        , subscriptions = Subscriptions.subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : Params -> Maybe ProjectTokenId -> Bool -> ( Model, Cmd Msg )
init params token save =
    ( { conf = ErdConf.project token
      , navbar = { mobileMenuOpen = False, search = { text = "", active = 0 } }
      , erdElem = ErdProps.zero
      , loaded = False
      , dirty = False
      , erd = Nothing
      , tableStats = Dict.empty
      , columnStats = Dict.empty
      , hoverTable = Nothing
      , hoverColumn = Nothing
      , cursorMode = CursorMode.Select
      , selectionBox = Nothing
      , newLayout = Nothing
      , editNotes = Nothing
      , editMemo = Nothing
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
        , Ports.listenHotkeys Conf.hotkeys
        , Ports.getProject params.organization params.project token
        , Bool.cond save (T.sendAfter 1000 TriggerSaveProject) Cmd.none
        ]
    )
