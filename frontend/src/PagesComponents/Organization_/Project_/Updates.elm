module PagesComponents.Organization_.Project_.Updates exposing (update)

import Components.Molecules.Dropdown as Dropdown
import Components.Slices.ProPlan as ProPlan
import Conf
import Json.Decode as Decode
import Json.Encode as Encode
import Libs.Bool as B
import Libs.Json.Decode as Decode
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models exposing (SizeChange)
import Libs.Models.Delta as Delta exposing (Delta)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Task as T
import Models.Area as Area
import Models.Organization as Organization exposing (Organization)
import Models.OrganizationId exposing (OrganizationId)
import Models.Position as Position
import Models.Project as Project
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.Source as Source
import Models.Project.SourceId as SourceId
import Models.Project.SourceKind as SourceKind
import Models.Project.TableId as TableId
import Models.ProjectInfo exposing (ProjectInfo)
import Models.Size as Size
import Models.SourceInfo as SourceInfo
import PagesComponents.Organization_.Project_.Components.AmlSidebar as AmlSidebar
import PagesComponents.Organization_.Project_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Organization_.Project_.Components.EmbedSourceParsingDialog as EmbedSourceParsingDialog
import PagesComponents.Organization_.Project_.Components.ProjectSaveDialog as ProjectSaveDialog
import PagesComponents.Organization_.Project_.Components.SourceUpdateDialog as SourceUpdateDialog
import PagesComponents.Organization_.Project_.Models exposing (AmlSidebar, Model, Msg(..), ProjectSettingsMsg(..), SchemaAnalysisMsg(..))
import PagesComponents.Organization_.Project_.Models.CursorMode as CursorMode
import PagesComponents.Organization_.Project_.Models.DragState as DragState
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.PositionHint exposing (PositionHint(..))
import PagesComponents.Organization_.Project_.Updates.Canvas exposing (fitCanvas, handleWheel, zoomCanvas)
import PagesComponents.Organization_.Project_.Updates.Drag exposing (handleDrag)
import PagesComponents.Organization_.Project_.Updates.FindPath exposing (handleFindPath)
import PagesComponents.Organization_.Project_.Updates.Help exposing (handleHelp)
import PagesComponents.Organization_.Project_.Updates.Hotkey exposing (handleHotkey)
import PagesComponents.Organization_.Project_.Updates.Layout exposing (handleLayout)
import PagesComponents.Organization_.Project_.Updates.Notes exposing (handleNotes)
import PagesComponents.Organization_.Project_.Updates.Project exposing (createProject, moveProject, triggerSaveProject, updateProject)
import PagesComponents.Organization_.Project_.Updates.ProjectSettings exposing (handleProjectSettings)
import PagesComponents.Organization_.Project_.Updates.Sharing exposing (handleSharing)
import PagesComponents.Organization_.Project_.Updates.Source as Source
import PagesComponents.Organization_.Project_.Updates.Table exposing (goToTable, hideColumn, hideColumns, hideRelatedTables, hideTable, hoverColumn, hoverNextColumn, mapTablePropOrSelected, showAllTables, showColumn, showColumns, showRelatedTables, showTable, showTables, sortColumns)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirty, setDirtyCmd)
import PagesComponents.Organization_.Project_.Updates.VirtualRelation exposing (handleVirtualRelation)
import PagesComponents.Organization_.Project_.Views as Views
import PagesComponents.Organization_.Project_.Views.Modals.NewLayout as NewLayout
import Ports exposing (JsMsg(..))
import Random
import Services.Backend as Backend
import Services.JsonSource as JsonSource
import Services.Lenses exposing (mapAmlSidebarM, mapCanvas, mapColumns, mapConf, mapContextMenuM, mapDetailsSidebarCmd, mapEmbedSourceParsingMCmd, mapErdM, mapErdMCmd, mapHoverTable, mapMobileMenuOpen, mapNavbar, mapOpened, mapOpenedDialogs, mapPosition, mapProject, mapPromptM, mapProps, mapSaveCmd, mapSchemaAnalysisM, mapSearch, mapSelected, mapShowHiddenColumns, mapTables, mapTablesCmd, mapToastsCmd, setActive, setCollapsed, setColor, setConfirm, setContextMenu, setCursorMode, setDragging, setHoverColumn, setHoverTable, setInput, setLast, setModal, setName, setOpenedDropdown, setOpenedPopover, setPosition, setPrompt, setSchemaAnalysis, setSelected, setShow, setSize, setText)
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts
import Time
import Track


update : Maybe LayoutName -> Time.Posix -> Maybe OrganizationId -> List Organization -> List ProjectInfo -> Msg -> Model -> ( Model, Cmd Msg )
update currentLayout now urlOrganization organizations projects msg model =
    case msg of
        ToggleMobileMenu ->
            ( model |> mapNavbar (mapMobileMenuOpen not), Cmd.none )

        SearchUpdated search ->
            ( model |> mapNavbar (mapSearch (setText search >> setActive 0)), Cmd.none )

        TriggerSaveProject ->
            model |> triggerSaveProject urlOrganization organizations

        CreateProject name organization storage ->
            model |> createProject name organization storage

        UpdateProject ->
            model |> updateProject

        MoveProjectTo storage ->
            model |> moveProject storage

        RenameProject name ->
            model |> mapErdM (mapProject (setName name)) |> setDirty

        DeleteProject project ->
            ( model, Ports.deleteProject project ((project.organization |> Maybe.map .id) |> Backend.organizationUrl |> Just) )

        GoToTable id ->
            model |> mapErdMCmd (goToTable now id model.erdElem) |> setDirtyCmd

        ShowTable id hint ->
            model |> mapErdMCmd (showTable now id hint) |> setDirtyCmd

        ShowTables ids hint ->
            model |> mapErdMCmd (showTables now ids hint) |> setDirtyCmd

        ShowAllTables ->
            model |> mapErdMCmd (showAllTables now) |> setDirtyCmd

        HideTable id ->
            model |> mapErdM (hideTable now id) |> mapHoverTable (\h -> B.cond (h == Just id) Nothing h) |> setDirty

        ShowRelatedTables id ->
            model |> mapErdMCmd (showRelatedTables id) |> setDirtyCmd

        HideRelatedTables id ->
            model |> mapErdMCmd (hideRelatedTables id) |> setDirtyCmd

        ToggleColumns id ->
            let
                collapsed : Bool
                collapsed =
                    model.erd |> Maybe.andThen (Erd.currentLayout >> .tables >> List.findBy .id id) |> Maybe.mapOrElse (.props >> .collapsed) False
            in
            model |> mapErdMCmd (\erd -> erd |> Erd.mapCurrentLayoutCmd now (mapTablesCmd (mapTablePropOrSelected erd.settings.defaultSchema id (mapProps (setCollapsed (not collapsed)))))) |> setDirtyCmd

        ShowColumn { table, column } ->
            model |> mapErdM (showColumn now table column) |> setDirty

        HideColumn { table, column } ->
            model |> mapErdM (hideColumn now table column) |> hoverNextColumn table column |> setDirty

        ShowColumns id kind ->
            model |> mapErdMCmd (showColumns now id kind) |> setDirtyCmd

        HideColumns id kind ->
            model |> mapErdMCmd (hideColumns now id kind) |> setDirtyCmd

        SortColumns id kind ->
            model |> mapErdMCmd (sortColumns now id kind) |> setDirtyCmd

        ToggleHiddenColumns id ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapTables (List.updateBy .id id (mapProps (mapShowHiddenColumns not))))) |> setDirty

        SelectTable tableId ctrl ->
            if model.dragging |> Maybe.any DragState.hasMoved then
                ( model, Cmd.none )

            else
                model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapTables (List.map (\t -> t |> mapProps (mapSelected (\s -> B.cond (t.id == tableId) (not s) (B.cond ctrl s False))))))) |> setDirty

        SelectAllTables ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapTables (List.map (mapProps (setSelected True))))) |> setDirty

        TableMove id delta ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapTables (List.updateBy .id id (mapProps (mapPosition (Position.moveCanvasGrid delta)))))) |> setDirty

        TablePosition id position ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapTables (List.updateBy .id id (mapProps (setPosition position))))) |> setDirty

        TableOrder id index ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapTables (\tables -> tables |> List.moveBy .id id (List.length tables - 1 - index)))) |> setDirty

        TableColor id color ->
            let
                organization : Organization
                organization =
                    model.erd |> Maybe.andThen (.project >> .organization) |> Maybe.withDefault Organization.zero
            in
            if organization.plan.colors then
                model |> mapErdMCmd (\erd -> erd |> Erd.mapCurrentLayoutCmd now (mapTablesCmd (mapTablePropOrSelected erd.settings.defaultSchema id (mapProps (setColor color))))) |> setDirtyCmd

            else
                ( model, ProPlan.colorsModalBody organization |> CustomModalOpen |> T.send )

        MoveColumn column position ->
            model |> mapErdM (\erd -> erd |> Erd.mapCurrentLayoutWithTime now (mapTables (List.updateBy .id column.table (mapColumns (List.moveBy .name column.column position))))) |> setDirty

        ToggleHoverTable table on ->
            ( model |> setHoverTable (B.cond on (Just table) Nothing), Cmd.none )

        ToggleHoverColumn column on ->
            ( model |> setHoverColumn (B.cond on (Just column) Nothing) |> mapErdM (\e -> e |> Erd.mapCurrentLayoutWithTime now (mapTables (hoverColumn column on e))), Cmd.none )

        CreateUserSource name ->
            ( model, SourceId.generator |> Random.generate (Source.aml name now >> CreateUserSourceWithId) )

        CreateUserSourceWithId source ->
            model
                |> mapErdM (Erd.mapSources (List.add source))
                |> (\updated -> updated |> mapAmlSidebarM (AmlSidebar.setSource (updated.erd |> Maybe.andThen (.sources >> List.last))))
                |> AmlSidebar.setOtherSourcesTableIdsCache (Just source.id)
                |> setDirty

        CreateRelation src ref ->
            model |> mapErdMCmd (Source.createRelation now src ref) |> setDirtyCmd

        NewLayoutMsg message ->
            model |> NewLayout.update ModalOpen Toast now message

        LayoutMsg message ->
            model |> handleLayout message

        NotesMsg message ->
            model |> handleNotes message

        AmlSidebarMsg message ->
            model |> AmlSidebar.update now message

        DetailsSidebarMsg message ->
            model.erd |> Maybe.mapOrElse (\erd -> model |> mapDetailsSidebarCmd (DetailsSidebar.update erd message)) ( model, Cmd.none )

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

        ProjectSaveMsg message ->
            model |> mapSaveCmd (ProjectSaveDialog.update ModalOpen message)

        ProjectSettingsMsg message ->
            model |> handleProjectSettings now message

        EmbedSourceParsingMsg message ->
            model |> mapEmbedSourceParsingMCmd (EmbedSourceParsingDialog.update EmbedSourceParsingMsg now message)

        SourceParsed source ->
            ( model, Project.create projects source.name source |> Ok |> Just |> GotProject |> JsMessage |> T.send )

        HelpMsg message ->
            model |> handleHelp message

        CursorMode mode ->
            ( model |> setCursorMode mode, Cmd.none )

        FitContent ->
            model |> mapErdMCmd (fitCanvas now model.erdElem) |> setDirtyCmd

        Fullscreen id ->
            ( model, Ports.fullscreen id )

        OnWheel event ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapCanvas (handleWheel event model.erdElem))) |> setDirty

        Zoom delta ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapCanvas (zoomCanvas delta model.erdElem))) |> setDirty

        Focus id ->
            ( model, Ports.focus id )

        DropdownToggle id ->
            ( model |> Dropdown.update id, Cmd.none )

        DropdownOpen id ->
            ( model |> setOpenedDropdown id, Cmd.none )

        DropdownClose ->
            ( model |> setOpenedDropdown "", Cmd.none )

        PopoverSet id ->
            ( model |> setOpenedPopover id, Cmd.none )

        ContextMenuCreate content event ->
            ( model |> setContextMenu (Just { content = content, position = event.clientPos, show = False }), T.sendAfter 1 ContextMenuShow )

        ContextMenuShow ->
            ( model |> mapContextMenuM (setShow True), Cmd.none )

        ContextMenuClose ->
            ( model |> setContextMenu Nothing, Cmd.none )

        DragStart id pos ->
            model.dragging
                |> Maybe.mapOrElse (\d -> ( model, "Already dragging " ++ d.id |> Toasts.info |> Toast |> T.send ))
                    ({ id = id, init = pos, last = pos } |> (\d -> model |> setDragging (Just d) |> handleDrag now d False))

        DragMove pos ->
            model.dragging
                |> Maybe.map (setLast pos)
                |> Maybe.mapOrElse (\d -> model |> setDragging (Just d) |> handleDrag now d False) ( model, Cmd.none )

        DragEnd pos ->
            model.dragging
                |> Maybe.map (setLast pos)
                |> Maybe.mapOrElse (\d -> model |> setDragging Nothing |> handleDrag now d True) ( model, Cmd.none )

        DragCancel ->
            ( model |> setDragging Nothing, Cmd.none )

        Toast message ->
            model |> mapToastsCmd (Toasts.update Toast message)

        CustomModalOpen content ->
            ( model |> setModal (Just { id = Conf.ids.customDialog, content = content }), T.sendAfter 1 (ModalOpen Conf.ids.customDialog) )

        CustomModalClose ->
            ( model |> setModal Nothing, Cmd.none )

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
            model |> handleJsMessage now currentLayout message

        Batch messages ->
            ( model, Cmd.batch (messages |> List.map T.send) )

        Send cmd ->
            ( model, cmd )

        Noop _ ->
            ( model, Cmd.none )


handleJsMessage : Time.Posix -> Maybe LayoutName -> JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage now currentLayout msg model =
    case msg of
        GotSizes sizes ->
            model |> updateSizes sizes

        GotProject res ->
            case res of
                Nothing ->
                    ( { model | loaded = True }, Cmd.none )

                Just (Err err) ->
                    ( { model | loaded = True }, Cmd.batch [ "Unable to read project: " ++ Decode.errorToHtml err |> Toasts.error |> Toast |> T.send, Ports.trackJsonError "decode-project" err ] )

                Just (Ok project) ->
                    let
                        erd : Erd
                        erd =
                            currentLayout |> Maybe.mapOrElse (\l -> { project | usedLayout = l }) project |> Erd.create

                        amlSidebar : Maybe AmlSidebar
                        amlSidebar =
                            B.maybe (project.sources |> List.all (\s -> s.kind == SourceKind.AmlEditor)) (AmlSidebar.init Nothing (Just erd))
                    in
                    ( { model | loaded = True, dirty = False, erd = Just erd, amlSidebar = amlSidebar }
                    , Cmd.batch
                        ([ Ports.observeSize Conf.ids.erd
                         , Ports.observeTablesSize (erd |> Erd.currentLayout |> .tables |> List.map .id)
                         , Ports.setMeta { title = Just (Views.title (Just erd)), description = Nothing, canonical = Nothing, html = Nothing, body = Nothing }
                         , Ports.projectDirty False
                         ]
                            ++ B.cond (model.save == Nothing) [] [ ProjectSaveDialog.Close |> ProjectSaveMsg |> ModalClose |> T.send, Ports.confettiPride ]
                        )
                    )

        GotLegacyProjects _ ->
            -- handled in Shared
            ( model, Cmd.none )

        ProjectDeleted _ ->
            -- handled in Shared
            ( model, Cmd.none )

        GotLocalFile kind file content ->
            if kind == SqlSource.kind then
                ( model, SourceId.generator |> Random.generate (\sourceId -> content |> SqlSource.GotFile (SourceInfo.sqlLocal now sourceId file) |> SourceUpdateDialog.SqlSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg) )

            else if kind == JsonSource.kind then
                ( model, SourceId.generator |> Random.generate (\sourceId -> content |> JsonSource.GotFile (SourceInfo.jsonLocal now sourceId file) |> SourceUpdateDialog.JsonSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg) )

            else
                ( model, "Unhandled local file kind '" ++ kind ++ "'" |> Toasts.error |> Toast |> T.send )

        GotHotkey hotkey ->
            handleHotkey now model hotkey

        GotKeyHold key start ->
            if key == "Space" && model.conf.move then
                if start then
                    ( model |> setCursorMode CursorMode.Drag, Cmd.none )

                else
                    ( model |> setCursorMode CursorMode.Select, Cmd.none )

            else
                ( model, Cmd.none )

        GotToast level message ->
            ( model, message |> Toasts.create level |> Toast |> T.send )

        GotTableShow id hint ->
            ( model, T.send (ShowTable id (hint |> Maybe.map PlaceAt)) )

        GotTableHide id ->
            ( model, T.send (HideTable id) )

        GotTableToggleColumns id ->
            ( model, T.send (ToggleColumns id) )

        GotTablePosition id pos ->
            ( model, T.send (TablePosition id pos) )

        GotTableMove id delta ->
            ( model, T.send (TableMove id delta) )

        GotTableSelect id ->
            ( model, T.send (SelectTable id False) )

        GotTableColor id color ->
            ( model, T.send (TableColor id color) )

        GotColumnShow ref ->
            ( model, T.send (ShowColumn ref) )

        GotColumnHide ref ->
            ( model, T.send (HideColumn ref) )

        GotColumnMove ref index ->
            ( model, T.send (MoveColumn ref index) )

        GotFitToScreen ->
            ( model, T.send FitContent )

        Error json err ->
            ( model, Cmd.batch [ "Unable to decode JavaScript message: " ++ Decode.errorToString err ++ " in " ++ Encode.encode 0 json |> Toasts.error |> Toast |> T.send, Ports.trackJsonError "js-message" err ] )


updateSizes : List SizeChange -> Model -> ( Model, Cmd Msg )
updateSizes changes model =
    let
        erdChanged : Model
        erdChanged =
            changes |> List.findBy .id "erd" |> Maybe.mapOrElse (\c -> { model | erdElem = { position = c.position, size = c.size } }) model

        erdViewport : Area.Canvas
        erdViewport =
            erdChanged.erd |> Erd.viewportM erdChanged.erdElem

        tablesChanged : Model
        tablesChanged =
            erdChanged |> mapErdM (\erd -> erd |> Erd.mapCurrentLayout (\l -> l |> mapTables (updateTables l.canvas.zoom erdViewport changes)))
    in
    if model.conf.fitOnLoad then
        ( tablesChanged |> mapConf (\c -> { c | fitOnLoad = False }), T.send FitContent )

    else
        ( tablesChanged, Cmd.none )


updateTables : ZoomLevel -> Area.Canvas -> List SizeChange -> List ErdTableLayout -> List ErdTableLayout
updateTables zoom erdViewport changes tables =
    changes |> List.foldl (\c tbls -> tbls |> List.map (\tbl -> B.cond (c.id == TableId.toHtmlId tbl.id) (updateTable zoom tbls erdViewport tbl c) tbl)) tables


updateTable : ZoomLevel -> List ErdTableLayout -> Area.Canvas -> ErdTableLayout -> SizeChange -> ErdTableLayout
updateTable zoom tables erdViewport table change =
    let
        newSize : Size.Canvas
        newSize =
            change.size |> Size.viewportToCanvas zoom
    in
    if table.props.size == Size.zeroCanvas && table.props.position == Position.zeroCanvasGrid then
        table |> mapProps (setSize newSize >> setPosition (computeInitialPosition tables erdViewport newSize change.seeds table.props.positionHint))

    else
        table |> mapProps (setSize newSize)


computeInitialPosition : List ErdTableLayout -> Area.Canvas -> Size.Canvas -> Delta -> Maybe PositionHint -> Position.CanvasGrid
computeInitialPosition tables erdViewport newSize seeds hint =
    hint
        |> Maybe.mapOrElse
            (\h ->
                case h of
                    PlaceLeft position ->
                        position |> Position.moveCanvasGrid { dx = (Size.extractCanvas newSize).width + 50 |> negate, dy = 0 } |> moveDownIfExists tables newSize

                    PlaceRight position size ->
                        position |> Position.moveCanvasGrid { dx = (Size.extractCanvas size).width + 50, dy = 0 } |> moveDownIfExists tables newSize

                    PlaceAt position ->
                        position
            )
            (if tables |> List.filter (\t -> t.props.size /= Size.zeroCanvas) |> List.isEmpty then
                newSize |> placeAtCenter erdViewport

             else
                newSize |> placeAtRandom erdViewport seeds
            )


placeAtCenter : Area.Canvas -> Size.Canvas -> Position.CanvasGrid
placeAtCenter erdViewport newSize =
    let
        ( canvasCenter, tableCenter ) =
            ( erdViewport |> Area.centerCanvas
            , Area.zeroCanvas |> setSize newSize |> Area.centerCanvas
            )
    in
    canvasCenter |> Position.moveCanvas (Position.zeroCanvas |> Position.diffCanvas tableCenter) |> Position.onGrid


placeAtRandom : Area.Canvas -> Delta -> Size.Canvas -> Position.CanvasGrid
placeAtRandom erdViewport seeds newSize =
    erdViewport.position
        |> Position.moveCanvas (erdViewport.size |> Size.diffCanvas newSize |> Delta.max 0 |> Delta.multD seeds)
        |> Position.onGrid


moveDownIfExists : List ErdTableLayout -> Size.Canvas -> Position.CanvasGrid -> Position.CanvasGrid
moveDownIfExists tables size position =
    if tables |> List.any (\t -> t.props.position == position || isSameTopRight t.props { position = position, size = size }) then
        position |> Position.moveCanvasGrid { dx = 0, dy = Conf.ui.tableHeaderHeight } |> moveDownIfExists tables size

    else
        position


isSameTopRight : { x | position : Position.CanvasGrid, size : Size.Canvas } -> { y | position : Position.CanvasGrid, size : Size.Canvas } -> Bool
isSameTopRight a b =
    let
        ( aPos, bPos ) =
            ( a.position |> Position.extractCanvasGrid, b.position |> Position.extractCanvasGrid )

        ( aSize, bSize ) =
            ( a.size |> Size.extractCanvas, b.size |> Size.extractCanvas )
    in
    aPos.top == bPos.top && aPos.left + aSize.width == bPos.left + bSize.width
