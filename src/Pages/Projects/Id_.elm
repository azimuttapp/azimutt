module Pages.Projects.Id_ exposing (Model, Msg, page)

import Browser.Events
import Components.Molecules.Modal as Modal
import Components.Molecules.Toast exposing (Content(..))
import Conf
import Dict
import Gen.Params.Projects.Id_ exposing (Params)
import Html.Events.Extra.Mouse as Mouse
import Html.Styled as Styled
import Json.Decode as Decode exposing (Decoder)
import Libs.Bool as B
import Libs.Json.Decode as D
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position as Position
import Libs.Task as T
import Models.Project as Project
import Models.Project.Relation as Relation
import Models.ScreenProps as ScreenProps
import Page
import PagesComponents.Projects.Id_.Models as Models exposing (CursorMode(..), Msg(..), ProjectSettingsMsg(..), VirtualRelationMsg(..), toastError, toastInfo, toastSuccess, toastWarning)
import PagesComponents.Projects.Id_.Models.DragState as DragState
import PagesComponents.Projects.Id_.Models.Erd as Erd
import PagesComponents.Projects.Id_.Models.ErdTableProps as ErdTableProps
import PagesComponents.Projects.Id_.Updates exposing (updateSizes)
import PagesComponents.Projects.Id_.Updates.Canvas exposing (fitCanvas, handleWheel, zoomCanvas)
import PagesComponents.Projects.Id_.Updates.Drag exposing (handleDrag)
import PagesComponents.Projects.Id_.Updates.FindPath exposing (handleFindPath)
import PagesComponents.Projects.Id_.Updates.Help exposing (handleHelp)
import PagesComponents.Projects.Id_.Updates.Hotkey exposing (handleHotkey)
import PagesComponents.Projects.Id_.Updates.Layout exposing (handleLayout)
import PagesComponents.Projects.Id_.Updates.ProjectSettings exposing (handleProjectSettings)
import PagesComponents.Projects.Id_.Updates.Table exposing (hideAllTables, hideColumn, hideColumns, hideTable, hoverColumn, hoverNextColumn, hoverTable, showAllTables, showColumn, showColumns, showTable, showTables, sortColumns)
import PagesComponents.Projects.Id_.Updates.VirtualRelation exposing (handleVirtualRelation)
import PagesComponents.Projects.Id_.View exposing (viewProject)
import Ports exposing (JsMsg(..))
import Request
import Services.Lenses exposing (mapCanvas, mapEachProjectMLayoutTables, mapErdM, mapErdMCmd, mapHiddenColumns, mapLayout, mapList, mapMobileMenuOpen, mapNavbar, mapOpenedDialogs, mapOpenedDropdown, mapProjectM, mapProjectMLayout, mapProjectMLayoutTable, mapSearch, mapSelected, mapShowHiddenColumns, mapTableProps, mapTables, mapToasts, setActive, setCanvas, setConfirm, setCursorMode, setDragging, setHiddenTables, setIsOpen, setTables, setText, setToastIdx, setUsedLayout)
import Services.SQLSource as SQLSource
import Shared exposing (StoredProjects(..))
import Time
import Track
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init
        , update = update req
        , view = view shared
        , subscriptions = subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : ( Model, Cmd Msg )
init =
    ( { navbar = { mobileMenuOpen = False, search = { text = "", active = 0 } }
      , screen = ScreenProps.zero
      , projects = Loading
      , project = Nothing
      , erd = Nothing
      , hoverTable = Nothing
      , hoverColumn = Nothing
      , cursorMode = CursorSelect
      , selectionBox = Nothing
      , newLayout = Nothing
      , virtualRelation = Nothing
      , findPath = Nothing
      , settings = Nothing
      , sourceUpload = Nothing
      , help = Nothing
      , openedDropdown = ""
      , dragging = Nothing
      , toastIdx = 0
      , toasts = []
      , confirm = Nothing
      , openedDialogs = []
      }
    , Cmd.batch
        [ Ports.loadProjects
        , Ports.trackPage "app"
        , Ports.listenHotkeys Conf.hotkeys
        ]
    )



-- UPDATE


update : Request.With Params -> Msg -> Model -> ( Model, Cmd Msg )
update req msg model =
    case msg of
        ToggleMobileMenu ->
            ( model |> mapNavbar (mapMobileMenuOpen not), Cmd.none )

        SearchUpdated search ->
            ( model |> mapNavbar (mapSearch (setText search >> setActive 0)), Cmd.none )

        SaveProject ->
            ( model, Cmd.batch (model.erd |> Maybe.map Erd.unpack |> M.mapOrElse (\p -> [ Ports.saveProject p, T.send (toastSuccess "Project saved"), Ports.track (Track.updateProject p) ]) [ T.send (toastWarning "No project to save") ]) )

        ShowTable id ->
            model |> mapErdMCmd (showTable id)

        ShowTables ids ->
            model |> mapErdMCmd (showTables ids)

        ShowAllTables ->
            model |> mapErdMCmd showAllTables

        HideTable id ->
            ( model |> mapErdM (hideTable id), Cmd.none )

        HideAllTables ->
            ( model |> mapErdM hideAllTables, Cmd.none )

        ShowColumn { table, column } ->
            ( model |> mapProjectMLayout (showColumn table column), Cmd.none )

        HideColumn { table, column } ->
            ( model |> mapProjectMLayout (hideColumn table column) |> hoverNextColumn table column, Cmd.none )

        ShowColumns id kind ->
            ( model |> mapProjectM (showColumns id kind), Cmd.none )

        HideColumns id kind ->
            ( model |> mapProjectM (hideColumns id kind), Cmd.none )

        ToggleHiddenColumns id ->
            ( model |> mapProjectMLayoutTable id (mapHiddenColumns not) |> mapErdM (mapTableProps (Dict.update id (Maybe.map (mapShowHiddenColumns not)))), Cmd.none )

        SelectTable tableId ctrl ->
            ( model
                |> mapEachProjectMLayoutTables (\p -> p |> mapSelected (\s -> B.cond (p.id == tableId) (not s) (B.cond ctrl s False)))
                |> mapErdM (mapTableProps (Dict.map (\id p -> p |> ErdTableProps.setSelected (B.cond (id == tableId) (not p.selected) (B.cond ctrl p.selected False)))))
            , Cmd.none
            )

        TableOrder id index ->
            ( model |> mapProjectMLayout (mapTables (\tables -> tables |> L.moveBy .id id (List.length tables - 1 - index))), Cmd.none )

        SortColumns id kind ->
            ( model |> mapProjectM (sortColumns id kind), Cmd.none )

        ToggleHoverTable table on ->
            ( { model | hoverTable = B.cond on (Just table) Nothing } |> mapErdM (mapTableProps (hoverTable table on)), Cmd.none )

        ToggleHoverColumn column on ->
            ( { model | hoverColumn = B.cond on (Just column) Nothing } |> mapErdM (\e -> e |> mapTableProps (hoverColumn column on e)), Cmd.none )

        ResetCanvas ->
            ( model |> mapProjectM (setUsedLayout Nothing >> mapLayout (setTables [] >> setHiddenTables [] >> setCanvas { position = { left = 0, top = 0 }, zoom = 1 })), Cmd.none )

        LayoutMsg message ->
            model |> handleLayout message

        VirtualRelationMsg message ->
            model |> handleVirtualRelation message

        FindPathMsg message ->
            model |> handleFindPath message

        ProjectSettingsMsg message ->
            model |> handleProjectSettings message

        HelpMsg message ->
            model |> handleHelp message

        CursorMode mode ->
            ( model |> setCursorMode mode, Cmd.none )

        FitContent ->
            ( model |> mapProjectMLayout (fitCanvas model.screen), Cmd.none )

        OnWheel event ->
            ( model |> mapProjectMLayout (mapCanvas (handleWheel event)), Cmd.none )

        Zoom delta ->
            ( model |> mapProjectMLayout (mapCanvas (zoomCanvas delta model.screen)), Cmd.none )

        Focus id ->
            ( model, Ports.focus id )

        DropdownToggle id ->
            ( model |> mapOpenedDropdown (\d -> B.cond (d == id) "" id), Cmd.none )

        DragStart id pos ->
            model.dragging
                |> M.mapOrElse (\d -> ( model, T.send (toastInfo ("Already dragging " ++ d.id)) ))
                    ( { id = id, init = pos, last = pos } |> (\d -> model |> setDragging (Just d) |> handleDrag d False), Cmd.none )

        DragMove pos ->
            ( model.dragging
                |> Maybe.map (DragState.setLast pos)
                |> M.mapOrElse (\d -> model |> setDragging (Just d) |> handleDrag d False) model
            , Cmd.none
            )

        DragEnd pos ->
            ( model.dragging
                |> Maybe.map (DragState.setLast pos)
                |> M.mapOrElse (\d -> model |> setDragging Nothing |> handleDrag d True) model
            , Cmd.none
            )

        DragCancel ->
            ( model |> setDragging Nothing, Cmd.none )

        ToastAdd millis toast ->
            model.toastIdx |> String.fromInt |> (\key -> ( model |> setToastIdx (model.toastIdx + 1) |> mapToasts (\t -> { key = key, content = toast, isOpen = False } :: t), T.sendAfter 1 (ToastShow millis key) ))

        ToastShow millis key ->
            ( model |> mapToasts (mapList .key key (setIsOpen True)), millis |> M.mapOrElse (\delay -> T.sendAfter delay (ToastHide key)) Cmd.none )

        ToastHide key ->
            ( model |> mapToasts (mapList .key key (setIsOpen False)), T.sendAfter 300 (ToastRemove key) )

        ToastRemove key ->
            ( model |> mapToasts (List.filter (\t -> t.key /= key)), Cmd.none )

        ConfirmOpen confirm ->
            ( model |> setConfirm (Just { id = Conf.ids.confirmDialog, content = confirm }), T.sendAfter 1 (ModalOpen Conf.ids.confirmDialog) )

        ConfirmAnswer answer cmd ->
            ( model |> setConfirm Nothing, B.cond answer cmd Cmd.none )

        ModalOpen id ->
            ( model |> mapOpenedDialogs (\dialogs -> id :: dialogs), Ports.autofocusWithin id )

        ModalClose message ->
            ( model |> mapOpenedDialogs (List.drop 1), T.sendAfter Modal.closeDuration message )

        JsMessage message ->
            model |> handleJsMessage req message

        Noop _ ->
            ( model, Cmd.none )


handleJsMessage : Request.With Params -> JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage req message model =
    case message of
        GotSizes sizes ->
            model |> updateSizes sizes

        GotProjects ( errors, projects ) ->
            ( { model
                | projects = Loaded (projects |> List.sortBy (\p -> negate (Time.posixToMillis p.updatedAt)))
                , project = model.project |> M.orElse (projects |> L.find (\p -> p.id == req.params.id))
                , erd = model.erd |> M.orElse (projects |> L.find (\p -> p.id == req.params.id) |> Maybe.map (Erd.create projects))
              }
            , Cmd.batch
                ((model.project
                    |> M.mapOrElse (\_ -> [])
                        [ Ports.observeSize Conf.ids.erd
                        , Ports.observeTablesSize (projects |> L.find (\p -> p.id == req.params.id) |> M.mapOrElse (.layout >> .tables) [] |> List.map .id)
                        ]
                 )
                    ++ (errors
                            |> List.concatMap
                                (\( name, err ) ->
                                    [ Ports.toastError ("Unable to read project " ++ name ++ ": " ++ D.errorToHtml err)
                                    , Ports.trackJsonError "decode-project" err
                                    ]
                                )
                       )
                )
            )

        GotLocalFile now projectId sourceId file content ->
            ( model, T.send (SQLSource.gotLocalFile now projectId sourceId file content |> PSSQLSourceMsg |> ProjectSettingsMsg) )

        GotRemoteFile now projectId sourceId url content sample ->
            ( model, T.send (SQLSource.gotRemoteFile now projectId sourceId url content sample |> PSSQLSourceMsg |> ProjectSettingsMsg) )

        GotSourceId now sourceId src ref ->
            ( model |> mapProjectM (Project.addUserSource sourceId Dict.empty [ Relation.virtual src ref sourceId ] now), T.send (toastInfo "Created a user source to add the relation.") )

        GotHotkey hotkey ->
            handleHotkey model hotkey

        Error err ->
            ( model, Cmd.batch [ T.send (toastError ("Unable to decode JavaScript message: " ++ D.errorToHtml err)), Ports.trackJsonError "js-message" err ] )



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
            ++ (model.virtualRelation |> M.mapOrElse (\_ -> [ Browser.Events.onMouseMove (Mouse.eventDecoder |> Decode.map (.pagePos >> Position.fromTuple >> VRMove >> VirtualRelationMsg)) ]) [])
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
