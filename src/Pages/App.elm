module Pages.App exposing (Model, Msg, page)

import Browser.Events
import Conf exposing (conf, schemaSamples)
import Dict
import Gen.Params.App exposing (Params)
import Html.Events.Extra.Mouse as Mouse
import Json.Decode as Decode
import Libs.Bool as B
import Libs.List as L
import Libs.Position as Position
import Libs.Task exposing (send, sendAfter)
import Models.Project exposing (FindPathState(..))
import Page
import PagesComponents.App.Commands.GetTime exposing (getTime)
import PagesComponents.App.Commands.GetZone exposing (getZone)
import PagesComponents.App.Models as Models exposing (CursorMode(..), DragState, Model, Msg(..), VirtualRelation, VirtualRelationMsg(..), initConfirm, initHover, initSwitch, initTimeInfo)
import PagesComponents.App.Updates exposing (moveTable, removeElement, updateSizes)
import PagesComponents.App.Updates.Canvas exposing (fitCanvas, handleWheel, zoomCanvas)
import PagesComponents.App.Updates.Drag exposing (dragEnd, dragMove, dragStart)
import PagesComponents.App.Updates.FindPath exposing (computeFindPath)
import PagesComponents.App.Updates.Helpers exposing (decodeErrorToHtml, setCanvas, setCurrentLayout, setProject, setProjectWithCmd, setSchema, setSchemaWithCmd, setSettings, setSwitch, setTableInList, setTables, setTime)
import PagesComponents.App.Updates.Layout exposing (createLayout, deleteLayout, loadLayout, unloadLayout, updateLayout)
import PagesComponents.App.Updates.Project exposing (createProjectFromFile, createProjectFromUrl, useProject)
import PagesComponents.App.Updates.Table exposing (hideAllTables, hideColumn, hideColumns, hideTable, hoverNextColumn, showAllTables, showColumn, showColumns, showTable, showTables, sortColumns)
import PagesComponents.App.Updates.VirtualRelation exposing (updateVirtualRelation)
import PagesComponents.App.View exposing (viewApp)
import PagesComponents.Containers as Containers
import Ports exposing (JsMsg(..), activateTooltipsAndPopovers, click, dropProject, hideOffcanvas, listenHotkeys, loadFile, loadProjects, observeSize, onJsMessage, readFile, saveProject, showModal, toastError, toastInfo, toastWarning, track, trackJsonError, trackPage)
import Request
import Shared
import Time
import Tracking exposing (events)
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
        JsMessage (SizesChanged sizes) ->
            updateSizes sizes model

        TimeChanged time ->
            ( model |> setTime (\t -> { t | now = time }), Cmd.none )

        ZoneChanged zone ->
            ( model |> setTime (\t -> { t | zone = zone }), Cmd.none )

        ChangeProject ->
            ( model, Cmd.batch [ hideOffcanvas conf.ids.menu, showModal conf.ids.projectSwitchModal, loadProjects ] )

        JsMessage (ProjectsLoaded ( errors, projects )) ->
            ( { model | storedProjects = projects }, Cmd.batch (errors |> List.concatMap (\( name, err ) -> [ toastError ("Unable to read project <b>" ++ name ++ "</b>:<br>" ++ decodeErrorToHtml err), trackJsonError "decode-project" err ])) )

        FileDragOver _ _ ->
            ( model, Cmd.none )

        FileDragLeave ->
            ( model, Cmd.none )

        FileDropped file _ ->
            ( model |> setSwitch (\s -> { s | loading = True }), readFile file )

        FileSelected file ->
            ( model |> setSwitch (\s -> { s | loading = True }), readFile file )

        JsMessage (FileRead now projectId sourceId file content) ->
            model |> createProjectFromFile now projectId sourceId file content

        LoadSample name ->
            ( model, schemaSamples |> Dict.get name |> Maybe.map (\( _, url ) -> loadFile url (Just name)) |> Maybe.withDefault (toastError ("Sample <b>" ++ name ++ "</b> not found")) )

        -- LoadFile url ->
        --     ( model, loadFile url Nothing )
        JsMessage (FileLoaded now projectId sourceId url content sample) ->
            model |> createProjectFromUrl now projectId sourceId url content sample

        DeleteProject project ->
            ( { model | storedProjects = model.storedProjects |> List.filter (\p -> not (p.id == project.id)) }, Cmd.batch [ dropProject project, track (events.deleteProject project) ] )

        UseProject project ->
            model |> useProject project

        ChangedSearch search ->
            ( { model | search = search }, Cmd.none )

        SelectTable id ctrl ->
            ( model |> setCurrentLayout (setTables (List.map (\t -> { t | selected = B.cond (t.id == id) (not t.selected) (B.cond ctrl t.selected False) }))), Cmd.none )

        SelectAllTables ->
            ( model |> setCurrentLayout (setTables (List.map (\t -> { t | selected = True }))), Cmd.none )

        HideTable id ->
            ( model |> setCurrentLayout (hideTable id), Cmd.none )

        ShowTable id ->
            model |> setProjectWithCmd (setSchemaWithCmd (showTable id))

        TableOrder id index ->
            ( model |> setCurrentLayout (setTables (\tables -> tables |> L.moveBy .id id (List.length tables - 1 - index))), Cmd.none )

        ShowTables ids ->
            model |> setProjectWithCmd (setSchemaWithCmd (showTables ids))

        --HideTables ids ->
        --    ( model |> setCurrentLayout (hideTables ids), Cmd.none )
        InitializedTable id position ->
            ( model |> setCurrentLayout (setTableInList .id id (\t -> { t | position = position })), Cmd.none )

        HideAllTables ->
            ( model |> setCurrentLayout hideAllTables, Cmd.none )

        ShowAllTables ->
            model |> setProjectWithCmd (setSchemaWithCmd showAllTables)

        HideColumn { table, column } ->
            ( model |> hoverNextColumn table column |> setCurrentLayout (hideColumn table column), Cmd.none )

        ShowColumn { table, column } ->
            ( model |> setCurrentLayout (showColumn table column), activateTooltipsAndPopovers )

        SortColumns id kind ->
            ( model |> setProject (setSchema (sortColumns id kind)), activateTooltipsAndPopovers )

        HideColumns id kind ->
            ( model |> setProject (setSchema (hideColumns id kind)), Cmd.none )

        ShowColumns id kind ->
            ( model |> setProject (setSchema (showColumns id kind)), activateTooltipsAndPopovers )

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

        DragStart id pos ->
            model |> dragStart id pos

        DragMove pos ->
            model |> dragMove pos

        DragEnd pos ->
            model |> dragEnd pos

        CursorMode mode ->
            ( { model | cursorMode = mode }, Cmd.none )

        FindPath from to ->
            ( { model | findPath = Just { from = from, to = to, result = Empty } }, Cmd.batch [ showModal conf.ids.findPathModal, track events.openFindPath ] )

        FindPathFrom from ->
            ( { model | findPath = model.findPath |> Maybe.map (\m -> { m | from = from }) }, Cmd.none )

        FindPathTo to ->
            ( { model | findPath = model.findPath |> Maybe.map (\m -> { m | to = to }) }, Cmd.none )

        FindPathSearch ->
            model.findPath
                |> Maybe.andThen (\fp -> Maybe.map3 (\p from to -> ( p, from, to )) model.project fp.from fp.to)
                |> Maybe.map (\( p, from, to ) -> ( { model | findPath = model.findPath |> Maybe.map (\m -> { m | result = Searching }) }, sendAfter 300 (FindPathCompute p.schema.tables p.schema.relations from to p.settings.findPath) ))
                |> Maybe.withDefault ( model, Cmd.none )

        FindPathCompute tables relations from to settings ->
            computeFindPath tables relations from to settings |> (\result -> ( { model | findPath = model.findPath |> Maybe.map (\m -> { m | result = Found result }) }, Cmd.batch [ activateTooltipsAndPopovers, track (events.findPathResult result) ] ))

        UpdateFindPathSettings settings ->
            ( model |> setProject (setSettings (\s -> { s | findPath = settings })), Cmd.none )

        VirtualRelationMsg m ->
            ( updateVirtualRelation m model, Cmd.none )

        NewLayout name ->
            ( { model | newLayout = B.cond (String.length name == 0) Nothing (Just name) }, Cmd.none )

        CreateLayout name ->
            { model | newLayout = Nothing } |> setProjectWithCmd (createLayout name)

        LoadLayout name ->
            model |> setProjectWithCmd (loadLayout name)

        UpdateLayout name ->
            model |> setProjectWithCmd (updateLayout name)

        DeleteLayout name ->
            model |> setProjectWithCmd (deleteLayout name)

        UnloadLayout ->
            ( model |> setProject unloadLayout, Cmd.none )

        OpenConfirm confirm ->
            ( { model | confirm = confirm }, showModal conf.ids.confirm )

        OnConfirm answer cmd ->
            ( { model | confirm = initConfirm }, B.cond answer cmd Cmd.none )

        JsMessage (HotkeyUsed "focus-search") ->
            ( model, click conf.ids.searchInput )

        JsMessage (HotkeyUsed "remove") ->
            ( model, removeElement model.hover )

        JsMessage (HotkeyUsed "move-forward") ->
            ( model, model.project |> Maybe.map (\p -> p.schema.layout) |> Maybe.map (moveTable 1 model.hover) |> Maybe.withDefault Cmd.none )

        JsMessage (HotkeyUsed "move-backward") ->
            ( model, model.project |> Maybe.map (\p -> p.schema.layout) |> Maybe.map (moveTable -1 model.hover) |> Maybe.withDefault Cmd.none )

        JsMessage (HotkeyUsed "move-to-top") ->
            ( model, model.project |> Maybe.map (\p -> p.schema.layout) |> Maybe.map (moveTable 1000 model.hover) |> Maybe.withDefault Cmd.none )

        JsMessage (HotkeyUsed "move-to-back") ->
            ( model, model.project |> Maybe.map (\p -> p.schema.layout) |> Maybe.map (moveTable -1000 model.hover) |> Maybe.withDefault Cmd.none )

        JsMessage (HotkeyUsed "select-all") ->
            ( model, send SelectAllTables )

        JsMessage (HotkeyUsed "find-path") ->
            ( model, send (FindPath Nothing Nothing) )

        JsMessage (HotkeyUsed "create-virtual-relation") ->
            ( model, send (VirtualRelationMsg Create) )

        JsMessage (HotkeyUsed "save") ->
            ( model, model.project |> Maybe.map (\p -> Cmd.batch [ saveProject p, toastInfo "Project saved", track (events.updateProject p) ]) |> Maybe.withDefault (toastWarning "No project to save") )

        JsMessage (HotkeyUsed "cancel") ->
            ( model, model.virtualRelation |> Maybe.map (\_ -> send (VirtualRelationMsg Cancel)) |> Maybe.withDefault Cmd.none )

        JsMessage (HotkeyUsed "help") ->
            ( model, showModal conf.ids.helpModal )

        JsMessage (HotkeyUsed hotkey) ->
            ( model, toastInfo ("Shortcut <b>" ++ hotkey ++ "</b> is not implemented yet :(") )

        JsMessage (Error err) ->
            ( model, Cmd.batch [ toastError ("Unable to decode JavaScript message:<br>" ++ decodeErrorToHtml err), trackJsonError "js-message" err ] )

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
            [ Browser.Events.onMouseMove (Decode.map (.pagePos >> Position.fromTuple >> Move >> VirtualRelationMsg) Mouse.eventDecoder) ]



-- VIEW


view : Model -> View Msg
view model =
    { title = model.project |> Maybe.map (\p -> p.name ++ " - Azimutt") |> Maybe.withDefault "Azimutt - Explore your database schema"
    , body = Containers.root (viewApp model)
    }
