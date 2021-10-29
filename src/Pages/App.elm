module Pages.App exposing (Model, Msg, page)

import Browser.Events
import Conf exposing (conf)
import Dict
import Gen.Params.App exposing (Params)
import Html.Events.Extra.Mouse as Mouse
import Json.Decode as Decode
import Libs.Bool as B
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Position as Position
import Page
import PagesComponents.App.Commands.GetTime exposing (getTime)
import PagesComponents.App.Commands.GetZone exposing (getZone)
import PagesComponents.App.Models as Models exposing (CursorMode(..), DragState, Model, Msg(..), SourceMsg(..), VirtualRelation, VirtualRelationMsg(..), initConfirm, initHover, initSwitch, initTimeInfo)
import PagesComponents.App.Updates exposing (updateSizes)
import PagesComponents.App.Updates.Canvas exposing (fitCanvas, handleWheel, resetCanvas, zoomCanvas)
import PagesComponents.App.Updates.Drag exposing (dragEnd, dragMove, dragStart)
import PagesComponents.App.Updates.FindPath exposing (handleFindPath)
import PagesComponents.App.Updates.Helpers exposing (setCanvas, setCurrentLayout, setProject, setProjectWithCmd, setTableInList, setTables, setTime)
import PagesComponents.App.Updates.Layout exposing (handleLayout)
import PagesComponents.App.Updates.PortMsg exposing (handlePortMsg)
import PagesComponents.App.Updates.Project exposing (deleteProject, useProject)
import PagesComponents.App.Updates.Settings exposing (handleSettings)
import PagesComponents.App.Updates.Source exposing (handleSource)
import PagesComponents.App.Updates.Table exposing (hideAllTables, hideColumn, hideColumns, hideTable, hoverNextColumn, showAllTables, showColumn, showColumns, showTable, showTables, sortColumns)
import PagesComponents.App.Updates.VirtualRelation exposing (handleVirtualRelation)
import PagesComponents.App.View exposing (viewApp)
import PagesComponents.Helpers as Helpers
import Ports exposing (JsMsg(..), activateTooltipsAndPopovers, click, hideOffcanvas, listenHotkeys, loadProjects, observeSize, onJsMessage, showModal, trackPage)
import Request
import Shared
import Time
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page _ _ =
    Page.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : ( Model, Cmd Msg )
init =
    ( { time = initTimeInfo
      , switch = initSwitch
      , storedProjects = []
      , project = Nothing
      , search = ""
      , newLayout = Nothing
      , findPath = Nothing
      , virtualRelation = Nothing
      , confirm = initConfirm
      , domInfos = Dict.empty
      , cursorMode = Select
      , selection = Nothing
      , dragState = Nothing
      , hover = initHover
      }
    , Cmd.batch
        [ observeSize conf.ids.erd
        , showModal conf.ids.projectSwitchModal
        , loadProjects
        , getZone
        , getTime
        , listenHotkeys conf.hotkeys
        , trackPage "app"
        ]
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- each case should be one line or call a function in Update file
        TimeChanged time ->
            ( model |> setTime (\t -> { t | now = time }), Cmd.none )

        ZoneChanged zone ->
            ( model |> setTime (\t -> { t | zone = zone }), Cmd.none )

        SizesChanged sizes ->
            model |> updateSizes sizes

        SourceMsg m ->
            model |> handleSource m

        ChangeProject ->
            ( model, Cmd.batch [ hideOffcanvas conf.ids.menu, showModal conf.ids.projectSwitchModal, loadProjects ] )

        ProjectsLoaded projects ->
            ( { model | storedProjects = projects }, Cmd.none )

        UseProject project ->
            model |> useProject project

        DeleteProject project ->
            model |> deleteProject project

        ChangedSearch search ->
            ( { model | search = search }, Cmd.none )

        SelectTable id ctrl ->
            ( model |> setCurrentLayout (setTables (List.map (\t -> { t | selected = B.cond (t.id == id) (not t.selected) (B.cond ctrl t.selected False) }))), Cmd.none )

        SelectAllTables ->
            ( model |> setCurrentLayout (setTables (List.map (\t -> { t | selected = True }))), Cmd.none )

        HideTable id ->
            ( model |> setCurrentLayout (hideTable id), Cmd.none )

        ShowTable id ->
            model |> setProjectWithCmd (showTable id)

        TableOrder id index ->
            ( model |> setCurrentLayout (setTables (\tables -> tables |> L.moveBy .id id (List.length tables - 1 - index))), Cmd.none )

        ShowTables ids ->
            model |> setProjectWithCmd (showTables ids)

        --HideTables ids ->
        --    ( model |> setCurrentLayout (hideTables ids), Cmd.none )
        InitializedTable id position ->
            ( model |> setCurrentLayout (setTableInList .id id (\t -> { t | position = position })), Cmd.none )

        HideAllTables ->
            ( model |> setCurrentLayout hideAllTables, Cmd.none )

        ShowAllTables ->
            model |> setProjectWithCmd showAllTables

        HideColumn { table, column } ->
            ( model |> hoverNextColumn table column |> setCurrentLayout (hideColumn table column), Cmd.none )

        ShowColumn { table, column } ->
            ( model |> setCurrentLayout (showColumn table column), activateTooltipsAndPopovers )

        SortColumns id kind ->
            ( model |> setProject (sortColumns id kind), activateTooltipsAndPopovers )

        HideColumns id kind ->
            ( model |> setProject (hideColumns id kind), Cmd.none )

        ShowColumns id kind ->
            ( model |> setProject (showColumns id kind), activateTooltipsAndPopovers )

        HoverTable t ->
            ( { model | hover = model.hover |> (\h -> { h | table = t }) }, Cmd.none )

        HoverColumn c ->
            ( { model | hover = model.hover |> (\h -> { h | column = c }) }, Cmd.none )

        OnWheel event ->
            ( model |> setCurrentLayout (setCanvas (handleWheel event)), Cmd.none )

        Zoom delta ->
            ( model |> setCurrentLayout (setCanvas (zoomCanvas model.domInfos delta)), Cmd.none )

        FitContent ->
            ( model |> setCurrentLayout (fitCanvas model.domInfos), Cmd.none )

        ResetCanvas ->
            ( model |> setProject resetCanvas, click conf.ids.searchInput )

        DragStart id pos ->
            model |> dragStart id pos

        DragMove pos ->
            model |> dragMove pos

        DragEnd pos ->
            model |> dragEnd pos

        CursorMode mode ->
            ( { model | cursorMode = mode }, Cmd.none )

        LayoutMsg m ->
            model |> handleLayout m

        FindPathMsg m ->
            model |> handleFindPath m

        VirtualRelationMsg m ->
            model |> handleVirtualRelation m

        SettingsMsg m ->
            model |> handleSettings m

        OpenConfirm confirm ->
            ( { model | confirm = confirm }, showModal conf.ids.confirm )

        OnConfirm answer cmd ->
            ( { model | confirm = initConfirm }, B.cond answer cmd Cmd.none )

        JsMessage m ->
            ( model, model |> handlePortMsg m )

        Noop ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ Time.every (10 * 1000) TimeChanged
         , onJsMessage JsMessage
         ]
            ++ dragSubscriptions model.dragState
            ++ virtualRelationSubscription model.virtualRelation
        )


dragSubscriptions : Maybe DragState -> List (Sub Msg)
dragSubscriptions drag =
    case drag of
        Nothing ->
            []

        Just _ ->
            [ Browser.Events.onMouseMove (Decode.map (.pagePos >> Position.fromTuple >> DragMove) Mouse.eventDecoder)
            , Browser.Events.onMouseUp (Decode.map (.pagePos >> Position.fromTuple >> DragEnd) Mouse.eventDecoder)
            ]


virtualRelationSubscription : Maybe VirtualRelation -> List (Sub Msg)
virtualRelationSubscription virtualRelation =
    case virtualRelation |> Maybe.map .src of
        Nothing ->
            []

        Just _ ->
            [ Browser.Events.onMouseMove (Decode.map (.pagePos >> Position.fromTuple >> VRMove >> VirtualRelationMsg) Mouse.eventDecoder) ]



-- VIEW


view : Model -> View Msg
view model =
    { title = model.project |> M.mapOrElse (\p -> p.name ++ " - Azimutt") "Azimutt - Explore your database schema"
    , body = Helpers.root (viewApp model)
    }
