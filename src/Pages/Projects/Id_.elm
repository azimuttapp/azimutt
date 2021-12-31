module Pages.Projects.Id_ exposing (Model, Msg, page)

import Browser.Events
import Components.Atoms.Icon exposing (Icon(..))
import Components.Molecules.Toast exposing (Content(..))
import Conf
import Gen.Params.Projects.Id_ exposing (Params)
import Html.Events.Extra.Mouse as Mouse
import Html.Styled as Styled exposing (text)
import Json.Decode as Decode exposing (Decoder)
import Libs.Bool as B
import Libs.Json.Decode as D
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color as Color
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position as Position
import Libs.Task as T
import Page
import PagesComponents.App.Updates.Helpers exposing (setAllTableProps, setCanvas, setCurrentLayout, setLayout, setProject, setProjectWithCmd, setTableProps, setTables)
import PagesComponents.Projects.Id_.Models as Models exposing (CursorMode(..), Msg(..), toastError, toastInfo, toastSuccess)
import PagesComponents.Projects.Id_.Updates exposing (updateSizes)
import PagesComponents.Projects.Id_.Updates.Canvas exposing (fitCanvas, handleWheel, zoomCanvas)
import PagesComponents.Projects.Id_.Updates.Drag exposing (handleDrag)
import PagesComponents.Projects.Id_.Updates.Hotkey exposing (handleHotkey)
import PagesComponents.Projects.Id_.Updates.Table exposing (hideAllTables, hideColumn, hideColumns, hideTable, hoverNextColumn, showAllTables, showColumn, showColumns, showTable, showTables, sortColumns)
import PagesComponents.Projects.Id_.View exposing (viewProject)
import Ports exposing (JsMsg(..), autofocus, listenHotkeys, observeSize, observeTablesSize, trackJsonError, trackPage)
import Request
import Shared
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init shared req
        , update = update req
        , view = view shared
        , subscriptions = subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : Shared.Model -> Request.With Params -> ( Model, Cmd Msg )
init shared req =
    ( { project = Nothing
      , navbar = { mobileMenuOpen = False, search = { text = "", active = 0 } }
      , hoverTable = Nothing
      , hoverColumn = Nothing
      , cursorMode = CursorSelect
      , selectionBox = Nothing
      , virtualRelation = Nothing
      , openedDropdown = ""
      , dragging = Nothing
      , toastIdx = 0
      , toasts = []
      , confirm = { color = Color.red, icon = X, title = "", message = text "", confirm = "", cancel = "", onConfirm = T.send (Noop "confirm init"), isOpen = False }
      }
    , Cmd.batch
        ((shared |> Shared.projects |> L.find (\p -> p.id == req.params.id) |> M.mapOrElse (\p -> [ T.send (LoadProject p) ]) [])
            ++ [ listenHotkeys Conf.hotkeys
               , trackPage "app"
               ]
        )
    )



-- UPDATE


update : Request.With Params -> Msg -> Model -> ( Model, Cmd Msg )
update req msg model =
    case msg of
        ToggleMobileMenu ->
            ( { model | navbar = model.navbar |> (\n -> { n | mobileMenuOpen = not n.mobileMenuOpen }) }, Cmd.none )

        SearchUpdated search ->
            ( { model | navbar = model.navbar |> (\n -> { n | search = n.search |> (\s -> { s | text = search, active = 0 }) }) }, Cmd.none )

        LoadProject project ->
            ( { model | project = Just project }, Cmd.batch [ observeSize Conf.ids.erd, observeTablesSize (project.layout.tables |> List.map .id) ] )

        ShowTable id ->
            model |> setProjectWithCmd (showTable id)

        ShowTables ids ->
            model |> setProjectWithCmd (showTables ids)

        ShowAllTables ->
            model |> setProjectWithCmd showAllTables

        HideTable id ->
            ( model |> setCurrentLayout (hideTable id), Cmd.none )

        HideAllTables ->
            ( model |> setCurrentLayout hideAllTables, Cmd.none )

        ShowColumn { table, column } ->
            ( model |> setCurrentLayout (showColumn table column), Cmd.none )

        HideColumn { table, column } ->
            ( model |> setCurrentLayout (hideColumn table column) |> hoverNextColumn table column, Cmd.none )

        ShowColumns id kind ->
            ( model |> setProject (showColumns id kind), Cmd.none )

        HideColumns id kind ->
            ( model |> setProject (hideColumns id kind), Cmd.none )

        ToggleHiddenColumns id ->
            ( model |> setTableProps id (\t -> { t | hiddenColumns = not t.hiddenColumns }), Cmd.none )

        SelectTable id ctrl ->
            ( model |> setAllTableProps (\t -> { t | selected = B.cond (t.id == id) (not t.selected) (B.cond ctrl t.selected False) }), Cmd.none )

        TableOrder id index ->
            ( model |> setCurrentLayout (setTables (\tables -> tables |> L.moveBy .id id (List.length tables - 1 - index))), Cmd.none )

        SortColumns id kind ->
            ( model |> setProject (sortColumns id kind), Cmd.none )

        ToggleHoverTable table on ->
            ( { model | hoverTable = B.cond on (Just table) Nothing }, Cmd.none )

        ToggleHoverColumn column on ->
            ( { model | hoverColumn = B.cond on (Just column) Nothing }, Cmd.none )

        ResetCanvas ->
            ( model |> setProject (\p -> { p | usedLayout = Nothing } |> setLayout (\l -> { l | tables = [], hiddenTables = [], canvas = p.layout.canvas |> (\c -> { c | position = { left = 0, top = 0 }, zoom = 1 }) })), Cmd.none )

        LayoutMsg ->
            -- FIXME
            ( model, T.send (toastSuccess "LayoutMsg") )

        VirtualRelationMsg ->
            -- FIXME
            ( model, T.send (toastSuccess "VirtualRelationMsg") )

        FindPathMsg ->
            -- FIXME
            ( model, T.send (toastSuccess "FindPathMsg") )

        CursorMode mode ->
            ( { model | cursorMode = mode }, Cmd.none )

        FitContent ->
            ( model |> setCurrentLayout fitCanvas, Cmd.none )

        OnWheel event ->
            ( model |> setCurrentLayout (setCanvas (handleWheel event)), Cmd.none )

        Zoom delta ->
            ( model |> setCurrentLayout (setCanvas (zoomCanvas delta)), Cmd.none )

        DropdownToggle id ->
            ( { model | openedDropdown = B.cond (model.openedDropdown == id) "" id }, Cmd.none )

        DragStart id pos ->
            model.dragging
                |> M.mapOrElse (\d -> ( model, T.send (toastInfo ("Already dragging " ++ d.id)) ))
                    ( { id = id, init = pos, last = pos } |> (\d -> { model | dragging = Just d } |> handleDrag d False), Cmd.none )

        DragMove pos ->
            ( model.dragging
                |> Maybe.map (\d -> B.cond ((d.init |> Position.distance pos) > 10) { d | last = pos } { d | last = d.init })
                |> M.mapOrElse (\d -> { model | dragging = Just d } |> handleDrag d False) model
            , Cmd.none
            )

        DragEnd pos ->
            ( model.dragging
                |> Maybe.map (\d -> B.cond ((d.init |> Position.distance pos) > 10) { d | last = pos } { d | last = d.init })
                |> M.mapOrElse (\d -> { model | dragging = Nothing } |> handleDrag d True) model
            , Cmd.none
            )

        DragCancel ->
            ( { model | dragging = Nothing }, Cmd.none )

        ToastAdd millis toast ->
            model.toastIdx |> String.fromInt |> (\key -> ( { model | toastIdx = model.toastIdx + 1, toasts = { key = key, content = toast, isOpen = False } :: model.toasts }, T.sendAfter 1 (ToastShow millis key) ))

        ToastShow millis key ->
            ( { model | toasts = model.toasts |> List.map (\t -> B.cond (t.key == key) { t | isOpen = True } t) }, millis |> M.mapOrElse (\delay -> T.sendAfter delay (ToastHide key)) Cmd.none )

        ToastHide key ->
            ( { model | toasts = model.toasts |> List.map (\t -> B.cond (t.key == key) { t | isOpen = False } t) }, T.sendAfter 300 (ToastRemove key) )

        ToastRemove key ->
            ( { model | toasts = model.toasts |> List.filter (\t -> t.key /= key) }, Cmd.none )

        ConfirmOpen confirm ->
            ( { model | confirm = { confirm | isOpen = True } }, autofocus Conf.ids.confirm )

        ConfirmAnswer answer cmd ->
            ( { model | confirm = model.confirm |> (\c -> { c | isOpen = False }) }, B.cond answer cmd Cmd.none )

        JsMessage message ->
            model |> handleJsMessage req message

        Noop text ->
            ( model, T.send (toastSuccess ("Noop: " ++ text)) )


handleJsMessage : Request.With Params -> JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage req message model =
    case message of
        GotSizes sizes ->
            model |> updateSizes sizes

        GotProjects ( errors, projects ) ->
            ( model, Cmd.batch ((projects |> L.find (\p -> p.id == req.params.id) |> M.mapOrElse (\p -> [ T.send (LoadProject p) ]) []) ++ (errors |> List.concatMap (\( name, err ) -> [ T.send (toastError ("Unable to read project <b>" ++ name ++ "</b>:<br>" ++ D.errorToHtml err)), trackJsonError "decode-project" err ]))) )

        --GotLocalFile now projectId sourceId file content ->
        --    -- send (SourceMsg (FileLoaded projectId (SourceInfo sourceId (lastSegment file.name) (localSource file) True Nothing now now) content))
        --    ( model, T.send (Noop "GotLocalFile not handled") )
        --
        --GotRemoteFile now projectId sourceId url content sample ->
        --    -- send (SourceMsg (FileLoaded projectId (SourceInfo sourceId (lastSegment url) (remoteSource url content) True sample now now) content))
        --    ( model, T.send (Noop "GotRemoteFile not handled") )
        --
        --GotSourceId now sourceId src ref ->
        --    -- send (SourceMsg (CreateSource (Source sourceId "User" UserDefined Array.empty Dict.empty [ Relation.virtual src ref sourceId ] True Nothing now now) "Relation added to newly create <b>User</b> source."))
        --    ( model, T.send (Noop "GotSourceId not handled") )
        GotHotkey hotkey ->
            handleHotkey model hotkey

        Error err ->
            ( model, Cmd.batch [ T.send (toastError ("Unable to decode JavaScript message:<br>" ++ D.errorToHtml err)), trackJsonError "js-message" err ] )

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ Ports.onJsMessage JsMessage ]
            ++ B.cond (model.openedDropdown == "") [] [ Browser.Events.onClick (targetIdDecoder |> Decode.map (\id -> B.cond (id == model.openedDropdown) (Noop "dropdown opened twice") (DropdownToggle id))) ]
            ++ (model.dragging
                    |> M.mapOrElse
                        (\_ ->
                            [ Browser.Events.onMouseMove (Mouse.eventDecoder |> Decode.map (.pagePos >> Position.fromTuple >> DragMove))
                            , Browser.Events.onMouseUp (Mouse.eventDecoder |> Decode.map (.pagePos >> Position.fromTuple >> DragEnd))
                            ]
                        )
                        []
               )
        )


targetIdDecoder : Decoder HtmlId
targetIdDecoder =
    Decode.field "target"
        (Decode.oneOf
            [ Decode.at [ "id" ] Decode.string |> D.filter (\id -> id /= "")
            , Decode.at [ "parentElement", "id" ] Decode.string |> D.filter (\id -> id /= "")
            , Decode.at [ "parentElement", "parentElement", "id" ] Decode.string |> D.filter (\id -> id /= "")
            , Decode.at [ "parentElement", "parentElement", "parentElement", "id" ] Decode.string |> D.filter (\id -> id /= "")
            , Decode.at [ "parentElement", "parentElement", "parentElement", "parentElement", "id" ] Decode.string |> D.filter (\id -> id /= "")
            , Decode.at [ "parentElement", "parentElement", "parentElement", "parentElement", "parentElement", "id" ] Decode.string |> D.filter (\id -> id /= "")
            , Decode.succeed ""
            ]
        )



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = model.project |> M.mapOrElse (\p -> p.name ++ " - Azimutt") "Azimutt - Explore your database schema"
    , body = model |> viewProject shared |> List.map Styled.toUnstyled
    }
