module Pages.App exposing (Model, Msg, page)

import Conf exposing (conf)
import Dict
import Draggable
import Gen.Params.App exposing (Params)
import Libs.Bool as B
import Libs.List as L
import Libs.Task exposing (sendAfter)
import Models.Project exposing (FindPathState(..))
import Page
import PagesComponents.App.Commands.GetTime exposing (getTime)
import PagesComponents.App.Commands.GetZone exposing (getZone)
import PagesComponents.App.Models as Models exposing (Model, Msg(..), initConfirm, initHover, initSwitch, initTimeInfo)
import PagesComponents.App.Updates exposing (dragConfig, dragItem, moveTable, removeElement, updateSizes)
import PagesComponents.App.Updates.Canvas exposing (fitCanvas, handleWheel, zoomCanvas)
import PagesComponents.App.Updates.FindPath exposing (computeFindPath)
import PagesComponents.App.Updates.Helpers exposing (decodeErrorToHtml, setCanvas, setLayout, setListTable, setProject, setProjectWithCmd, setSchema, setSchemaWithCmd, setSettings, setSwitch, setTables, setTime)
import PagesComponents.App.Updates.Layout exposing (createLayout, deleteLayout, loadLayout, updateLayout)
import PagesComponents.App.Updates.Project exposing (createProjectFromFile, createProjectFromUrl, useProject)
import PagesComponents.App.Updates.Table exposing (hideAllTables, hideColumn, hideColumns, hideTable, hideTables, hoverNextColumn, showAllTables, showColumn, showColumns, showTable, showTables, sortColumns)
import PagesComponents.App.View exposing (viewApp)
import PagesComponents.Containers as Containers
import Ports exposing (JsMsg(..), activateTooltipsAndPopovers, click, dropProject, hideOffcanvas, listenHotkeys, loadFile, loadProjects, observeSize, onJsMessage, readFile, saveProject, showModal, toastError, toastInfo, toastWarning, trackJsonError, trackPage, trackProjectEvent)
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
      , confirm = initConfirm
      , sizes = Dict.empty
      , dragId = Nothing
      , drag = Draggable.init
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

        LoadFile url ->
            ( model, loadFile url )

        JsMessage (FileLoaded now projectId sourceId url content) ->
            model |> createProjectFromUrl now projectId sourceId url content

        DeleteProject project ->
            ( { model | storedProjects = model.storedProjects |> List.filter (\p -> not (p.id == project.id)) }, Cmd.batch [ dropProject project, trackProjectEvent "drop" project ] )

        UseProject project ->
            model |> useProject project

        ChangedSearch search ->
            ( { model | search = search }, Cmd.none )

        SelectTable id ->
            ( model |> setProject (setSchema (setLayout (setTables (List.map (\t -> { t | selected = B.cond (t.id == id) (not t.selected) False }))))), Cmd.none )

        HideTable id ->
            ( model |> setProject (setSchema (setLayout (hideTable id))), Cmd.none )

        ShowTable id ->
            model |> setProjectWithCmd (setSchemaWithCmd (showTable id))

        TableOrder id index ->
            ( model |> setProject (setSchema (setLayout (setTables (\tables -> tables |> L.moveBy .id id (List.length tables - 1 - index))))), Cmd.none )

        ShowTables ids ->
            model |> setProjectWithCmd (setSchemaWithCmd (showTables ids))

        HideTables ids ->
            ( model |> setProject (setSchema (setLayout (hideTables ids))), Cmd.none )

        InitializedTable id position ->
            ( model |> setProject (setSchema (setLayout (setListTable .id id (\t -> { t | position = position })))), Cmd.none )

        HideAllTables ->
            ( model |> setProject (setSchema (setLayout hideAllTables)), Cmd.none )

        ShowAllTables ->
            model |> setProjectWithCmd (setSchemaWithCmd showAllTables)

        HideColumn { table, column } ->
            ( model |> hoverNextColumn table column |> setProject (setSchema (setLayout (hideColumn table column))), Cmd.none )

        ShowColumn { table, column } ->
            ( model |> setProject (setSchema (setLayout (showColumn table column))), activateTooltipsAndPopovers )

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
            ( model |> setProject (setSchema (setLayout (setCanvas (handleWheel event)))), Cmd.none )

        Zoom delta ->
            ( model |> setProject (setSchema (setLayout (setCanvas (zoomCanvas model.sizes delta)))), Cmd.none )

        FitContent ->
            ( model |> setProject (setSchema (setLayout (fitCanvas model.sizes))), Cmd.none )

        DragMsg dragMsg ->
            model |> Draggable.update dragConfig dragMsg

        StartDragging id ->
            ( { model | dragId = Just id }, Cmd.none )

        StopDragging ->
            ( { model | dragId = Nothing }, Cmd.none )

        OnDragBy delta ->
            dragItem model delta

        FindPath from to ->
            ( { model | findPath = Just { from = from, to = to, result = Empty } }, showModal conf.ids.findPathModal )

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
            computeFindPath tables relations from to settings |> (\result -> ( { model | findPath = model.findPath |> Maybe.map (\m -> { m | result = Found result }) }, Cmd.none ))

        UpdateFindPathSettings settings ->
            ( model |> setProject (setSettings (\s -> { s | findPath = settings })), Cmd.none )

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

        OpenConfirm confirm ->
            ( { model | confirm = confirm }, showModal conf.ids.confirm )

        OnConfirm answer cmd ->
            ( { model | confirm = initConfirm }, B.cond answer cmd Cmd.none )

        JsMessage (HotkeyUsed "focus-search") ->
            ( model, click conf.ids.searchInput )

        JsMessage (HotkeyUsed "remove") ->
            ( model, model.project |> Maybe.map (\p -> p.schema.layout) |> Maybe.map (removeElement model.hover) |> Maybe.withDefault Cmd.none )

        JsMessage (HotkeyUsed "move-forward") ->
            ( model, model.project |> Maybe.map (\p -> p.schema.layout) |> Maybe.map (moveTable 1 model.hover) |> Maybe.withDefault Cmd.none )

        JsMessage (HotkeyUsed "move-backward") ->
            ( model, model.project |> Maybe.map (\p -> p.schema.layout) |> Maybe.map (moveTable -1 model.hover) |> Maybe.withDefault Cmd.none )

        JsMessage (HotkeyUsed "move-to-top") ->
            ( model, model.project |> Maybe.map (\p -> p.schema.layout) |> Maybe.map (moveTable 1000 model.hover) |> Maybe.withDefault Cmd.none )

        JsMessage (HotkeyUsed "move-to-back") ->
            ( model, model.project |> Maybe.map (\p -> p.schema.layout) |> Maybe.map (moveTable -1000 model.hover) |> Maybe.withDefault Cmd.none )

        JsMessage (HotkeyUsed "save") ->
            ( model, model.project |> Maybe.map (\p -> Cmd.batch [ saveProject p, toastInfo "Project saved", trackProjectEvent "save" p ]) |> Maybe.withDefault (toastWarning "No project to save") )

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
        [ Draggable.subscriptions DragMsg model.drag
        , Time.every (10 * 1000) TimeChanged
        , onJsMessage JsMessage
        ]



-- VIEW


view : Model -> View Msg
view model =
    { title = "Azimutt"
    , body = Containers.root (viewApp model)
    }
