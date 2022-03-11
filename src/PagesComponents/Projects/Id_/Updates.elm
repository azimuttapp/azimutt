module PagesComponents.Projects.Id_.Updates exposing (update)

import Conf
import Dict exposing (Dict)
import Libs.Area as Area exposing (Area, AreaLike)
import Libs.Bool as B
import Libs.Delta as Delta
import Libs.Dict as Dict
import Libs.Json.Decode as Decode
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models exposing (SizeChange)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size exposing (Size)
import Libs.Task as T
import Models.Project exposing (Project)
import Models.Project.CanvasProps as CanvasProps
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.Source as Source
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models exposing (CursorMode(..), Model, Msg(..), ProjectSettingsMsg(..), SchemaAnalysisMsg(..), toastError, toastInfo, toastSuccess, toastWarning)
import PagesComponents.Projects.Id_.Models.DragState as DragState
import PagesComponents.Projects.Id_.Models.Erd as Erd
import PagesComponents.Projects.Id_.Models.ErdTableProps as ErdTableProps exposing (ErdTableProps)
import PagesComponents.Projects.Id_.Models.PositionHint exposing (PositionHint(..))
import PagesComponents.Projects.Id_.Updates.Canvas exposing (fitCanvas, handleWheel, zoomCanvas)
import PagesComponents.Projects.Id_.Updates.Drag exposing (handleDrag)
import PagesComponents.Projects.Id_.Updates.FindPath exposing (handleFindPath)
import PagesComponents.Projects.Id_.Updates.Help exposing (handleHelp)
import PagesComponents.Projects.Id_.Updates.Hotkey exposing (handleHotkey)
import PagesComponents.Projects.Id_.Updates.Layout exposing (handleLayout)
import PagesComponents.Projects.Id_.Updates.ProjectSettings exposing (handleProjectSettings)
import PagesComponents.Projects.Id_.Updates.Sharing exposing (handleSharing)
import PagesComponents.Projects.Id_.Updates.Source as Source
import PagesComponents.Projects.Id_.Updates.Table exposing (hideAllTables, hideColumn, hideColumns, hideTable, hoverColumn, hoverNextColumn, hoverTable, showAllTables, showColumn, showColumns, showTable, showTables, sortColumns)
import PagesComponents.Projects.Id_.Updates.VirtualRelation exposing (handleVirtualRelation)
import Ports exposing (JsMsg(..))
import Services.Lenses exposing (mapCanvas, mapConf, mapContextMenuM, mapErdM, mapErdMCmd, mapList, mapMobileMenuOpen, mapNavbar, mapOpened, mapOpenedDialogs, mapOpenedDropdown, mapProject, mapPromptM, mapSchemaAnalysisM, mapScreen, mapSearch, mapShownTables, mapTableProps, mapToasts, mapTop, setActive, setCanvas, setConfirm, setContextMenu, setCursorMode, setDragging, setInput, setIsOpen, setName, setOpenedPopover, setPosition, setPrompt, setSchemaAnalysis, setShow, setShownTables, setSize, setTableProps, setText, setToastIdx, setUsedLayout)
import Services.SqlSourceUpload as SqlSourceUpload
import Time
import Track


update : Maybe ProjectId -> Maybe LayoutName -> Time.Posix -> Msg -> Model -> ( Model, Cmd Msg )
update currentProject currentLayout now msg model =
    case msg of
        ToggleMobileMenu ->
            ( model |> mapNavbar (mapMobileMenuOpen not), Cmd.none )

        SearchUpdated search ->
            ( model |> mapNavbar (mapSearch (setText search >> setActive 0)), Cmd.none )

        SaveProject ->
            if model.conf.save then
                ( model, Cmd.batch (model.erd |> Maybe.map Erd.unpack |> Maybe.mapOrElse (\p -> [ Ports.saveProject p, T.send (toastSuccess "Project saved"), Ports.track (Track.updateProject p) ]) [ T.send (toastWarning "No project to save") ]) )

            else
                ( model, Cmd.none )

        RenameProject name ->
            ( model |> mapErdM (mapProject (setName name)), Cmd.none )

        ShowTable id hint ->
            model |> mapErdMCmd (showTable id hint)

        ShowTables ids hint ->
            model |> mapErdMCmd (showTables ids hint)

        ShowAllTables ->
            model |> mapErdMCmd showAllTables

        HideTable id ->
            ( model |> mapErdM (hideTable id), Cmd.none )

        HideAllTables ->
            ( model |> mapErdM hideAllTables, Cmd.none )

        ShowColumn { table, column } ->
            ( model |> mapErdM (showColumn table column), Cmd.none )

        HideColumn { table, column } ->
            ( model |> mapErdM (hideColumn table column) |> hoverNextColumn table column, Cmd.none )

        ShowColumns id kind ->
            ( model |> mapErdM (showColumns id kind), Cmd.none )

        HideColumns id kind ->
            ( model |> mapErdM (hideColumns id kind), Cmd.none )

        ToggleHiddenColumns id ->
            ( model |> mapErdM (mapTableProps (Dict.alter id (ErdTableProps.mapShowHiddenColumns not))), Cmd.none )

        SelectTable tableId ctrl ->
            if model.dragging |> Maybe.any DragState.hasMoved then
                ( model, Cmd.none )

            else
                ( model |> mapErdM (mapTableProps (Dict.map (\id -> ErdTableProps.mapSelected (\s -> B.cond (id == tableId) (not s) (B.cond ctrl s False))))), Cmd.none )

        TableMove id delta ->
            ( model |> mapErdM (mapTableProps (\tables -> tables |> Dict.map (\_ t -> B.cond (t.id == id) (t |> ErdTableProps.mapPosition (\p -> delta |> Delta.move p)) t))), Cmd.none )

        TableOrder id index ->
            ( model |> mapErdM (mapShownTables (\tables -> tables |> List.move id (List.length tables - 1 - index))), Cmd.none )

        SortColumns id kind ->
            ( model |> mapErdM (sortColumns id kind), Cmd.none )

        MoveColumn column position ->
            ( model |> mapErdM (mapTableProps (Dict.alter column.table (ErdTableProps.mapShownColumns (List.moveBy identity column.column position)))), Cmd.none )

        ToggleHoverTable table on ->
            ( { model | hoverTable = B.cond on (Just table) Nothing } |> mapErdM (mapTableProps (hoverTable table on)), Cmd.none )

        ToggleHoverColumn column on ->
            ( { model | hoverColumn = B.cond on (Just column) Nothing } |> mapErdM (\e -> e |> mapTableProps (hoverColumn column on e)), Cmd.none )

        CreateRelation src ref ->
            model |> mapErdMCmd (Source.addRelation src ref)

        ResetCanvas ->
            ( model |> mapErdM (setCanvas CanvasProps.zero >> setShownTables [] >> setTableProps Dict.empty >> setUsedLayout Nothing), Cmd.none )

        LayoutMsg message ->
            model |> handleLayout now message

        VirtualRelationMsg message ->
            model |> handleVirtualRelation message

        FindPathMsg message ->
            model |> handleFindPath message

        SchemaAnalysisMsg SAOpen ->
            ( model |> setSchemaAnalysis (Just { id = Conf.ids.schemaAnalysisDialog, opened = "" }), Cmd.batch [ T.sendAfter 1 (ModalOpen Conf.ids.schemaAnalysisDialog), Ports.track Track.openSchemaAnalysis ] )

        SchemaAnalysisMsg (SASectionToggle section) ->
            ( model |> mapSchemaAnalysisM (mapOpened (\opened -> B.cond (opened == section) "" section)), Cmd.none )

        SchemaAnalysisMsg SAClose ->
            ( model |> setSchemaAnalysis Nothing, Cmd.none )

        SharingMsg message ->
            model |> handleSharing message

        ProjectSettingsMsg message ->
            model |> handleProjectSettings message

        HelpMsg message ->
            model |> handleHelp message

        CursorMode mode ->
            ( model |> setCursorMode mode, Cmd.none )

        FitContent ->
            ( model |> mapErdM (fitCanvas model.screen), Cmd.none )

        Fullscreen maybeId ->
            ( model, Ports.fullscreen maybeId )

        OnWheel event ->
            ( model |> mapErdM (mapCanvas (handleWheel event)), Cmd.none )

        Zoom delta ->
            ( model |> mapErdM (mapCanvas (zoomCanvas delta model.screen)), Cmd.none )

        Focus id ->
            ( model, Ports.focus id )

        DropdownToggle id ->
            ( model |> mapOpenedDropdown (\d -> B.cond (d == id) "" id), Cmd.none )

        PopoverSet id ->
            ( model |> setOpenedPopover id, Cmd.none )

        ContextMenuCreate content event ->
            ( model |> setContextMenu (Just { content = content, position = event.position, show = False }), T.sendAfter 1 ContextMenuShow )

        ContextMenuShow ->
            ( model |> mapContextMenuM (setShow True), Cmd.none )

        ContextMenuClose ->
            ( model |> setContextMenu Nothing, Cmd.none )

        DragStart id pos ->
            model.dragging
                |> Maybe.mapOrElse (\d -> ( model, T.send (toastInfo ("Already dragging " ++ d.id)) ))
                    ( { id = id, init = pos, last = pos } |> (\d -> model |> setDragging (Just d) |> handleDrag d False), Cmd.none )

        DragMove pos ->
            ( model.dragging
                |> Maybe.map (DragState.setLast pos)
                |> Maybe.mapOrElse (\d -> model |> setDragging (Just d) |> handleDrag d False) model
            , Cmd.none
            )

        DragEnd pos ->
            ( model.dragging
                |> Maybe.map (DragState.setLast pos)
                |> Maybe.mapOrElse (\d -> model |> setDragging Nothing |> handleDrag d True) model
            , Cmd.none
            )

        DragCancel ->
            ( model |> setDragging Nothing, Cmd.none )

        ToastAdd millis toast ->
            model.toastIdx |> String.fromInt |> (\key -> ( model |> setToastIdx (model.toastIdx + 1) |> mapToasts (\t -> { key = key, content = toast, isOpen = False } :: t), T.sendAfter 1 (ToastShow millis key) ))

        ToastShow millis key ->
            ( model |> mapToasts (mapList .key key (setIsOpen True)), millis |> Maybe.mapOrElse (\delay -> T.sendAfter delay (ToastHide key)) Cmd.none )

        ToastHide key ->
            ( model |> mapToasts (mapList .key key (setIsOpen False)), T.sendAfter 300 (ToastRemove key) )

        ToastRemove key ->
            ( model |> mapToasts (List.filter (\t -> t.key /= key)), Cmd.none )

        ConfirmOpen confirm ->
            ( model |> setConfirm (Just { id = Conf.ids.confirmDialog, content = confirm }), T.sendAfter 1 (ModalOpen Conf.ids.confirmDialog) )

        ConfirmAnswer answer cmd ->
            ( model |> setConfirm Nothing, B.cond answer cmd Cmd.none )

        PromptOpen prompt input ->
            ( model |> setPrompt (Just { id = Conf.ids.promptDialog, content = prompt, input = input }), T.sendAfter 1 (ModalOpen Conf.ids.promptDialog) )

        PromptUpdate input ->
            ( model |> mapPromptM (setInput input), Cmd.none )

        PromptAnswer cmd ->
            ( model |> setPrompt Nothing, cmd )

        ModalOpen id ->
            ( model |> mapOpenedDialogs (\dialogs -> id :: dialogs), Ports.autofocusWithin id )

        ModalClose message ->
            ( model |> mapOpenedDialogs (List.drop 1), T.sendAfter Conf.ui.closeDuration message )

        JsMessage message ->
            model |> handleJsMessage currentProject currentLayout message

        Send cmd ->
            ( model, cmd )

        Noop _ ->
            ( model, Cmd.none )


handleJsMessage : Maybe ProjectId -> Maybe LayoutName -> JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage currentProject currentLayout msg model =
    case msg of
        GotSizes sizes ->
            model |> updateSizes sizes

        GotProjects ( errors, projects ) ->
            let
                project : Maybe Project
                project =
                    currentProject
                        |> Maybe.mapOrElse (\id -> projects |> List.find (\p -> p.id == id)) (projects |> List.head)
                        |> Maybe.map (\p -> currentLayout |> Maybe.mapOrElse (\l -> { p | usedLayout = Just l, layout = p.layouts |> Dict.getOrElse l p.layout }) p)
            in
            ( { model | loaded = True, erd = model.erd |> Maybe.orElse (project |> Maybe.map (Erd.create projects)) }
            , Cmd.batch
                ((model.erd
                    |> Maybe.mapOrElse (\_ -> [])
                        [ Ports.observeSize Conf.ids.erd
                        , Ports.observeTablesSize (project |> Maybe.mapOrElse (.layout >> .tables) [] |> List.map .id)
                        ]
                 )
                    ++ (errors
                            |> List.concatMap
                                (\( name, err ) ->
                                    [ T.send (toastError ("Unable to read project " ++ name ++ ": " ++ Decode.errorToHtml err))
                                    , Ports.trackJsonError "decode-project" err
                                    ]
                                )
                       )
                )
            )

        GotLocalFile now projectId sourceId file content ->
            ( model, T.send (SqlSourceUpload.gotLocalFile now projectId sourceId file content |> PSSqlSourceMsg |> ProjectSettingsMsg) )

        GotRemoteFile now projectId sourceId url content sample ->
            ( model, T.send (SqlSourceUpload.gotRemoteFile now projectId sourceId url content sample |> PSSqlSourceMsg |> ProjectSettingsMsg) )

        GotSourceId now sourceId src ref ->
            ( model |> mapErdM (Erd.mapSources (\sources -> sources ++ [ Source.user sourceId Dict.empty [] now ]))
            , Cmd.batch [ T.send (toastInfo "Created a user source to add the relation."), T.send (CreateRelation src ref) ]
            )

        GotHotkey hotkey ->
            handleHotkey model hotkey

        GotKeyHold key start ->
            if key == "Space" && model.conf.move then
                if start then
                    ( model |> setCursorMode CursorDrag, Cmd.none )

                else
                    ( model |> setCursorMode CursorSelect, Cmd.none )

            else
                ( model, Cmd.none )

        GotToast level message ->
            case level of
                "success" ->
                    ( model, T.send (toastSuccess message) )

                "info" ->
                    ( model, T.send (toastInfo message) )

                "warning" ->
                    ( model, T.send (toastWarning message) )

                _ ->
                    ( model, T.send (toastError message) )

        Error err ->
            ( model, Cmd.batch [ T.send (toastError ("Unable to decode JavaScript message: " ++ Decode.errorToHtml err)), Ports.trackJsonError "js-message" err ] )


updateSizes : List SizeChange -> Model -> ( Model, Cmd Msg )
updateSizes changes model =
    let
        modelWithSizes : Model
        modelWithSizes =
            changes |> List.sortBy (\c -> B.cond (c.id == Conf.ids.erd) 0 1) |> List.foldl updateSize model
    in
    if model.conf.fitOnLoad then
        ( modelWithSizes |> mapConf (\c -> { c | fitOnLoad = False }), T.send FitContent )

    else
        ( modelWithSizes, Cmd.none )


updateSize : SizeChange -> Model -> Model
updateSize change model =
    if change.id == Conf.ids.erd then
        model |> mapScreen (setPosition change.position >> setSize change.size)

    else
        ( TableId.fromHtmlId change.id, model.erd |> Maybe.mapOrElse (.canvas >> CanvasProps.viewport model.screen) Area.zero )
            |> (\( tableId, viewport ) -> model |> mapErdM (mapTableProps (\props -> props |> Dict.alter tableId (updateTable props viewport change))))


updateTable : Dict TableId ErdTableProps -> Area -> SizeChange -> ErdTableProps -> ErdTableProps
updateTable allProps viewport change props =
    if props.size == Size.zero && props.position == Position.zero then
        props
            |> ErdTableProps.setSize change.size
            |> ErdTableProps.setPosition (computeInitialPosition allProps viewport change props.positionHint)

    else
        props |> ErdTableProps.setSize change.size


computeInitialPosition : Dict TableId ErdTableProps -> Area -> SizeChange -> Maybe PositionHint -> Position
computeInitialPosition allProps viewport change hint =
    hint
        |> Maybe.mapOrElse
            (\h ->
                case h of
                    PlaceLeft position ->
                        position |> Position.sub { left = change.size.width + 50, top = 0 } |> moveDownIfExists (allProps |> Dict.values) change.size

                    PlaceRight position size ->
                        position |> Position.add { left = size.width + 50, top = 0 } |> moveDownIfExists (allProps |> Dict.values) change.size
            )
            (if allProps |> Dict.filter (\_ p -> p.size /= Size.zero) |> Dict.isEmpty then
                viewport |> Area.center |> Position.sub (change |> Area.center) |> mapTop (max viewport.position.top)

             else
                { left = viewport.position.left + change.seeds.left * max 0 (viewport.size.width - change.size.width)
                , top = viewport.position.top + change.seeds.top * max 0 (viewport.size.height - change.size.height)
                }
            )


moveDownIfExists : List ErdTableProps -> Size -> Position -> Position
moveDownIfExists allProps size position =
    if allProps |> List.any (\p -> p.position == position || isSameTopRight p (Area position size)) then
        position |> Position.add { left = 0, top = Conf.ui.tableHeaderHeight } |> moveDownIfExists allProps size

    else
        position


isSameTopRight : AreaLike x -> AreaLike y -> Bool
isSameTopRight a b =
    a.position.top == b.position.top && a.position.left + a.size.width == b.position.left + b.size.width
