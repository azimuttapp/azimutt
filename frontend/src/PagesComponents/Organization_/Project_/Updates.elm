module PagesComponents.Organization_.Project_.Updates exposing (update)

import Components.Molecules.Dropdown as Dropdown
import Components.Slices.ProPlan as ProPlan
import Components.Slices.QueryPane as QueryPane
import Conf
import Dict
import Json.Decode as Decode
import Json.Encode as Encode
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.Json.Decode as Decode
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models exposing (SizeChange)
import Libs.Models.Delta exposing (Delta)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Nel as Nel
import Libs.Task as T
import Libs.Time as Time
import Models.Area as Area
import Models.Organization exposing (Organization)
import Models.Position as Position
import Models.Project as Project
import Models.Project.ColumnId as ColumnId
import Models.Project.ColumnPath as ColumnPath
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.Source as Source
import Models.Project.SourceId as SourceId
import Models.Project.SourceKind as SourceKind
import Models.Project.TableId as TableId
import Models.ProjectInfo exposing (ProjectInfo)
import Models.ProjectRef exposing (ProjectRef)
import Models.Size as Size
import Models.SourceInfo as SourceInfo
import Models.UrlInfos exposing (UrlInfos)
import PagesComponents.Organization_.Project_.Components.AmlSidebar as AmlSidebar
import PagesComponents.Organization_.Project_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Organization_.Project_.Components.EmbedSourceParsingDialog as EmbedSourceParsingDialog
import PagesComponents.Organization_.Project_.Components.ExportDialog as ExportDialog
import PagesComponents.Organization_.Project_.Components.ProjectSaveDialog as ProjectSaveDialog
import PagesComponents.Organization_.Project_.Components.ProjectSharing as ProjectSharing
import PagesComponents.Organization_.Project_.Components.SourceUpdateDialog as SourceUpdateDialog
import PagesComponents.Organization_.Project_.Models exposing (AmlSidebar, Model, Msg(..), ProjectSettingsMsg(..), SchemaAnalysisMsg(..))
import PagesComponents.Organization_.Project_.Models.CursorMode as CursorMode
import PagesComponents.Organization_.Project_.Models.DragState as DragState
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdColumnProps as ErdColumnProps
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout as ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import PagesComponents.Organization_.Project_.Models.MemoId as MemoId
import PagesComponents.Organization_.Project_.Models.PositionHint exposing (PositionHint(..))
import PagesComponents.Organization_.Project_.Updates.Canvas exposing (arrangeTables, fitCanvas, handleWheel, zoomCanvas)
import PagesComponents.Organization_.Project_.Updates.Drag exposing (handleDrag)
import PagesComponents.Organization_.Project_.Updates.FindPath exposing (handleFindPath)
import PagesComponents.Organization_.Project_.Updates.Groups exposing (handleGroups)
import PagesComponents.Organization_.Project_.Updates.Help exposing (handleHelp)
import PagesComponents.Organization_.Project_.Updates.Hotkey exposing (handleHotkey)
import PagesComponents.Organization_.Project_.Updates.Layout exposing (handleLayout)
import PagesComponents.Organization_.Project_.Updates.Memo exposing (handleMemo)
import PagesComponents.Organization_.Project_.Updates.Notes exposing (handleNotes)
import PagesComponents.Organization_.Project_.Updates.Project exposing (createProject, moveProject, triggerSaveProject, updateProject)
import PagesComponents.Organization_.Project_.Updates.ProjectSettings exposing (handleProjectSettings)
import PagesComponents.Organization_.Project_.Updates.Source as Source
import PagesComponents.Organization_.Project_.Updates.Table exposing (goToTable, hideColumn, hideColumns, hideRelatedTables, hideTable, hoverColumn, hoverNextColumn, mapTablePropOrSelected, showAllTables, showColumn, showColumns, showRelatedTables, showTable, showTables, sortColumns, toggleNestedColumn)
import PagesComponents.Organization_.Project_.Updates.Tags exposing (handleTags)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirty, setDirtyCmd)
import PagesComponents.Organization_.Project_.Updates.VirtualRelation exposing (handleVirtualRelation)
import PagesComponents.Organization_.Project_.Views as Views
import PagesComponents.Organization_.Project_.Views.Modals.NewLayout as NewLayout
import Ports exposing (JsMsg(..))
import Random
import Services.Backend as Backend
import Services.DatabaseSource as DatabaseSource
import Services.JsonSource as JsonSource
import Services.Lenses exposing (mapAmlSidebarM, mapCanvas, mapColumns, mapContextMenuM, mapDetailsSidebarCmd, mapEmbedSourceParsingMCmd, mapErdM, mapErdMCmd, mapExportDialogCmd, mapHoverTable, mapMemos, mapMobileMenuOpen, mapNavbar, mapOpened, mapOpenedDialogs, mapOrganizationM, mapPlan, mapPosition, mapProject, mapPromptM, mapProps, mapQueryPaneCmd, mapSaveCmd, mapSchemaAnalysisM, mapSearch, mapSelected, mapSharingCmd, mapShowHiddenColumns, mapTables, mapTablesCmd, mapToastsCmd, setActive, setCanvas, setCollapsed, setColor, setColors, setConfirm, setContextMenu, setCurrentLayout, setCursorMode, setDragging, setHoverColumn, setHoverTable, setInput, setLast, setLayoutOnLoad, setModal, setName, setOpenedDropdown, setOpenedPopover, setPosition, setPrompt, setSchemaAnalysis, setSelected, setShow, setSize, setTables, setText)
import Services.PrismaSource as PrismaSource
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts
import Set
import Time
import Track


update : Maybe LayoutName -> Time.Zone -> Time.Posix -> UrlInfos -> List Organization -> List ProjectInfo -> Msg -> Model -> ( Model, Cmd Msg )
update urlLayout zone now urlInfos organizations projects msg model =
    case msg of
        ToggleMobileMenu ->
            ( model |> mapNavbar (mapMobileMenuOpen not), Cmd.none )

        SearchUpdated search ->
            ( model |> mapNavbar (mapSearch (setText search >> setActive 0)), Cmd.none )

        SearchClicked kind table ->
            ( model, Cmd.batch [ ShowTable table Nothing |> T.send, Track.searchClicked kind model.erd ] )

        TriggerSaveProject ->
            model |> triggerSaveProject urlInfos organizations

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
            if model.erd |> Maybe.mapOrElse (Erd.currentLayout >> .tables) [] |> List.any (\t -> t.id == id) then
                ( model, GoToTable id |> T.send )

            else
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

        ToggleNestedColumn table path open ->
            model |> mapErdM (toggleNestedColumn now table path open) |> setDirty

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
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapTables (List.updateBy .id id (mapProps (mapPosition (Position.moveGrid delta)))))) |> setDirty

        TablePosition id position ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapTables (List.updateBy .id id (mapProps (setPosition position))))) |> setDirty

        TableOrder id index ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapTables (\tables -> tables |> List.moveBy .id id (List.length tables - 1 - index)))) |> setDirty

        TableColor id color ->
            let
                project : ProjectRef
                project =
                    model.erd |> Erd.getProjectRefM urlInfos
            in
            if model.erd |> Erd.canChangeColor then
                model |> mapErdMCmd (\erd -> erd |> Erd.mapCurrentLayoutCmd now (mapTablesCmd (mapTablePropOrSelected erd.settings.defaultSchema id (mapProps (setColor color))))) |> setDirtyCmd

            else
                ( model, Cmd.batch [ ProPlan.colorsModalBody project ProPlanColors ProPlan.colorsInit |> CustomModalOpen |> T.send, Track.planLimit .tableColor model.erd ] )

        MoveColumn column position ->
            model |> mapErdM (\erd -> erd |> Erd.mapCurrentLayoutWithTime now (mapTables (List.updateBy .id column.table (mapColumns (ErdColumnProps.mapAt (column.column |> ColumnPath.parent) (List.moveBy .name (column.column |> Nel.last) position)))))) |> setDirty

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
            model |> NewLayout.update ModalOpen Toast CustomModalOpen now urlInfos message

        LayoutMsg message ->
            model |> handleLayout message

        GroupMsg message ->
            model |> handleGroups now urlInfos message

        NotesMsg message ->
            model |> handleNotes message

        TagsMsg message ->
            model |> handleTags message

        MemoMsg message ->
            model |> handleMemo now urlInfos message

        AmlSidebarMsg message ->
            model |> AmlSidebar.update now message

        DetailsSidebarMsg message ->
            model.erd |> Maybe.mapOrElse (\erd -> model |> mapDetailsSidebarCmd (DetailsSidebar.update Noop NotesMsg TagsMsg erd message)) ( model, Cmd.none )

        QueryPaneMsg message ->
            model.erd |> Maybe.mapOrElse (\erd -> model |> mapQueryPaneCmd (QueryPane.update QueryPaneMsg erd message)) ( model, Cmd.none )

        VirtualRelationMsg message ->
            model |> handleVirtualRelation message

        FindPathMsg message ->
            model |> handleFindPath message

        SchemaAnalysisMsg SAOpen ->
            ( model |> setSchemaAnalysis (Just { id = Conf.ids.schemaAnalysisDialog, opened = "" }), Cmd.batch [ T.sendAfter 1 (ModalOpen Conf.ids.schemaAnalysisDialog), Track.dbAnalysisOpened model.erd ] )

        SchemaAnalysisMsg (SASectionToggle section) ->
            ( model |> mapSchemaAnalysisM (mapOpened (\opened -> B.cond (opened == section) "" section)), Cmd.none )

        SchemaAnalysisMsg SAClose ->
            ( model |> setSchemaAnalysis Nothing, Cmd.none )

        ExportDialogMsg message ->
            model.erd |> Maybe.mapOrElse (\erd -> model |> mapExportDialogCmd (ExportDialog.update ExportDialogMsg ModalOpen urlInfos erd message)) ( model, Cmd.none )

        SharingMsg message ->
            model |> mapSharingCmd (ProjectSharing.update SharingMsg ModalOpen Toast zone now model.erd message)

        ProjectSaveMsg message ->
            model |> mapSaveCmd (ProjectSaveDialog.update ModalOpen message)

        ProjectSettingsMsg message ->
            model |> handleProjectSettings now message

        EmbedSourceParsingMsg message ->
            model |> mapEmbedSourceParsingMCmd (EmbedSourceParsingDialog.update EmbedSourceParsingMsg now (model.erd |> Maybe.map .project) message)

        SourceParsed source ->
            ( model, source |> Project.create projects source.name |> Ok |> Just |> GotProject "load" |> JsMessage |> T.send )

        ProPlanColors _ ProPlan.EnableTableChangeColor ->
            ( model |> mapErdM (mapProject (mapOrganizationM (mapPlan (setColors True)))), Ports.fireworks )

        ProPlanColors state message ->
            state |> ProPlan.colorsUpdate ProPlanColors message |> Tuple.mapFirst (\s -> { model | modal = model.modal |> Maybe.map (\m -> { m | content = ProPlan.colorsModalBody (model.erd |> Erd.getProjectRefM urlInfos) ProPlanColors s }) })

        HelpMsg message ->
            model |> handleHelp message

        CursorMode mode ->
            ( model |> setCursorMode mode, Cmd.none )

        FitToScreen ->
            model |> mapErdMCmd (fitCanvas model.erdElem)

        ArrangeTables ->
            model |> mapErdMCmd (arrangeTables now model.erdElem) |> setDirtyCmd

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
            model |> handleJsMessage now urlLayout message

        Batch messages ->
            ( model, Cmd.batch (messages |> List.map T.send) )

        Send cmd ->
            ( model, cmd )

        Noop _ ->
            ( model, Cmd.none )


handleJsMessage : Time.Posix -> Maybe LayoutName -> JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage now urlLayout msg model =
    case msg of
        GotSizes sizes ->
            model |> updateSizes sizes

        GotProject context res ->
            case res of
                Nothing ->
                    ( { model | loaded = True }, Cmd.none )

                Just (Err err) ->
                    ( { model | loaded = True }, Cmd.batch [ "Unable to read project: " ++ Decode.errorToHtml err |> Toasts.error |> Toast |> T.send, Track.jsonError "decode-project" err ] )

                Just (Ok project) ->
                    model |> updateErd urlLayout context project

        ProjectDeleted _ ->
            -- handled in Shared
            ( model, Cmd.none )

        GotLocalFile kind file content ->
            if kind == SqlSource.kind then
                ( model, SourceId.generator |> Random.generate (\sourceId -> content |> SqlSource.GotFile (SourceInfo.sqlLocal now sourceId file) |> SourceUpdateDialog.SqlSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg) )

            else if kind == PrismaSource.kind then
                ( model, SourceId.generator |> Random.generate (\sourceId -> content |> PrismaSource.GotFile (SourceInfo.prismaLocal now sourceId file) |> SourceUpdateDialog.PrismaSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg) )

            else if kind == JsonSource.kind then
                ( model, SourceId.generator |> Random.generate (\sourceId -> content |> JsonSource.GotFile (SourceInfo.jsonLocal now sourceId file) |> SourceUpdateDialog.JsonSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg) )

            else
                ( model, "Unhandled local file kind '" ++ kind ++ "'" |> Toasts.error |> Toast |> T.send )

        GotDatabaseSchema schema ->
            if model.embedSourceParsing == Nothing then
                ( model, schema |> DatabaseSource.GotSchema |> SourceUpdateDialog.DatabaseSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg |> T.send )

            else
                ( model, schema |> DatabaseSource.GotSchema |> EmbedSourceParsingDialog.EmbedDatabaseSource |> EmbedSourceParsingMsg |> T.send )

        GotTableStats source stats ->
            ( { model | tableStats = model.tableStats |> Dict.update stats.id (Maybe.withDefault Dict.empty >> Dict.insert (SourceId.toString source) (Ok stats) >> Just) }, Cmd.none )

        GotTableStatsError source table error ->
            ( { model | tableStats = model.tableStats |> Dict.update table (Maybe.withDefault Dict.empty >> Dict.insert (SourceId.toString source) (Err error) >> Just) }, Cmd.none )

        GotColumnStats source stats ->
            ( { model | columnStats = model.columnStats |> Dict.update stats.id (Maybe.withDefault Dict.empty >> Dict.insert (SourceId.toString source) (Ok stats) >> Just) }, Cmd.none )

        GotColumnStatsError source column error ->
            ( { model | columnStats = model.columnStats |> Dict.update (ColumnId.fromRef column) (Maybe.withDefault Dict.empty >> Dict.insert (SourceId.toString source) (Err error) >> Just) }, Cmd.none )

        GotDatabaseQueryResults results ->
            ( model, results |> Ok |> QueryPane.GotResults |> QueryPaneMsg |> T.send )

        GotDatabaseQueryError error ->
            ( model, error |> Err |> QueryPane.GotResults |> QueryPaneMsg |> T.send )

        GotPrismaSchema schema ->
            if model.embedSourceParsing == Nothing then
                ( model, Ok schema |> PrismaSource.GotSchema |> SourceUpdateDialog.PrismaSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg |> T.send )

            else
                ( model, Ok schema |> PrismaSource.GotSchema |> EmbedSourceParsingDialog.EmbedPrismaSource |> EmbedSourceParsingMsg |> T.send )

        GotPrismaSchemaError error ->
            if model.embedSourceParsing == Nothing then
                ( model, Err error |> PrismaSource.GotSchema |> SourceUpdateDialog.PrismaSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg |> T.send )

            else
                ( model, Err error |> PrismaSource.GotSchema |> EmbedSourceParsingDialog.EmbedPrismaSource |> EmbedSourceParsingMsg |> T.send )

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
            ( model, T.send FitToScreen )

        Error json err ->
            ( model, Cmd.batch [ "Unable to decode JavaScript message: " ++ Decode.errorToString err ++ " in " ++ Encode.encode 0 json |> Toasts.error |> Toast |> T.send, Track.jsonError "js_message" err ] )


updateSizes : List SizeChange -> Model -> ( Model, Cmd Msg )
updateSizes changes model =
    let
        erdChanged : Model
        erdChanged =
            changes |> List.findBy .id "erd" |> Maybe.mapOrElse (\c -> { model | erdElem = { position = c.position, size = c.size } }) model

        erdViewport : Area.Canvas
        erdViewport =
            erdChanged.erd |> Erd.viewportM erdChanged.erdElem

        newModel : Model
        newModel =
            erdChanged
                |> mapErdM
                    (\erd ->
                        erd
                            |> Erd.mapCurrentLayout
                                (\l ->
                                    l
                                        |> mapMemos (updateMemos l.canvas.zoom changes)
                                        |> mapTables (updateTables l.canvas.zoom erdViewport changes)
                                )
                    )
    in
    newModel
        |> mapErdMCmd
            (\e ->
                if e.layoutOnLoad /= "" && newModel.erdElem.size /= Size.zeroViewport && (e |> Erd.currentLayout |> .tables |> List.length) > 0 then
                    if e.layoutOnLoad == "fit" then
                        e |> fitCanvas newModel.erdElem

                    else if e.layoutOnLoad == "arrange" then
                        e |> arrangeTables Time.zero newModel.erdElem

                    else
                        ( e, Cmd.none )

                else
                    ( e, Cmd.none )
            )


updateMemos : ZoomLevel -> List SizeChange -> List Memo -> List Memo
updateMemos zoom changes memos =
    changes |> List.foldl (\c mms -> mms |> List.map (\memo -> B.cond (c.id == MemoId.toHtmlId memo.id) (memo |> setSize (c.size |> Size.viewportToCanvas zoom)) memo)) memos


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
    if table.props.size == Size.zeroCanvas && table.props.position == Position.zeroGrid then
        table |> mapProps (setSize newSize >> setPosition (computeInitialPosition tables erdViewport newSize change.seeds table.props.positionHint))

    else
        table |> mapProps (setSize newSize)


computeInitialPosition : List ErdTableLayout -> Area.Canvas -> Size.Canvas -> Delta -> Maybe PositionHint -> Position.Grid
computeInitialPosition tables erdViewport newSize _ hint =
    hint
        |> Maybe.mapOrElse
            (\h ->
                case h of
                    PlaceLeft position ->
                        position |> Position.moveGrid { dx = (Size.extractCanvas newSize).width + 50 |> negate, dy = 0 } |> moveDownIfExists tables newSize

                    PlaceRight position size ->
                        position |> Position.moveGrid { dx = (Size.extractCanvas size).width + 50, dy = 0 } |> moveDownIfExists tables newSize

                    PlaceAt position ->
                        position
            )
            -- EXPERIMENT: always show new tables at the center
            --(if tables |> List.filter (\t -> t.props.size /= Size.zeroCanvas) |> List.isEmpty then
            --    newSize |> placeAtCenter erdViewport
            --
            -- else
            --    newSize |> placeAtRandom erdViewport seeds
            --)
            (newSize |> placeAtCenter erdViewport)


placeAtCenter : Area.Canvas -> Size.Canvas -> Position.Grid
placeAtCenter erdViewport newSize =
    let
        ( canvasCenter, tableCenter ) =
            ( erdViewport |> Area.centerCanvas
            , Area.zeroCanvas |> setSize newSize |> Area.centerCanvas
            )
    in
    canvasCenter |> Position.moveCanvas (Position.zeroCanvas |> Position.diffCanvas tableCenter) |> Position.onGrid



--placeAtRandom : Area.Canvas -> Delta -> Size.Canvas -> Position.CanvasGrid
--placeAtRandom erdViewport seeds newSize =
--    erdViewport.position
--        |> Position.moveCanvas (erdViewport.size |> Size.diffCanvas newSize |> Delta.max 0 |> Delta.multD seeds)
--        |> Position.onGrid


moveDownIfExists : List ErdTableLayout -> Size.Canvas -> Position.Grid -> Position.Grid
moveDownIfExists tables size position =
    if tables |> List.any (\t -> t.props.position == position || isSameTopRight t.props { position = position, size = size }) then
        position |> Position.moveGrid { dx = 0, dy = Conf.ui.tableHeaderHeight } |> moveDownIfExists tables size

    else
        position


isSameTopRight : { x | position : Position.Grid, size : Size.Canvas } -> { y | position : Position.Grid, size : Size.Canvas } -> Bool
isSameTopRight a b =
    let
        ( aPos, bPos ) =
            ( a.position |> Position.extractGrid, b.position |> Position.extractGrid )

        ( aSize, bSize ) =
            ( a.size |> Size.extractCanvas, b.size |> Size.extractCanvas )
    in
    aPos.top == bPos.top && aPos.left + aSize.width == bPos.left + bSize.width


updateErd : Maybe LayoutName -> String -> Project.Project -> Model -> ( Model, Cmd Msg )
updateErd urlLayout context project model =
    -- context: load, draft, create, update
    let
        erd : Erd
        erd =
            (project |> Erd.create)
                |> (\e ->
                        if context == "load" then
                            -- set current layout if given in url and loading context
                            urlLayout
                                |> Maybe.filter (\name -> project.layouts |> Dict.member name)
                                |> Maybe.mapOrElse (\name -> e |> setCurrentLayout name) e
                                |> setLayoutOnLoad "fit"
                                |> showAllTablesIfNeeded

                        else if context == "create" || context == "update" then
                            -- keep current layout & layout position (`create` is an update from the `draft` context)
                            e
                                |> setCurrentLayout (model.erd |> Maybe.withDefault e |> .currentLayout)
                                |> Erd.mapCurrentLayout (\l -> l |> setCanvas (model.erd |> Maybe.withDefault e |> Erd.currentLayout |> .canvas))

                        else
                            e
                   )

        amlSidebar : Maybe AmlSidebar
        amlSidebar =
            -- if sidebar is present do nothing, if not, all sources are AML and it's not embed, then open it
            model.amlSidebar
                |> Maybe.orElse (B.maybe (model.conf.update && (project.sources |> List.all (\s -> s.kind == SourceKind.AmlEditor))) (AmlSidebar.init Nothing (Just erd)))
    in
    ( { model | loaded = True, dirty = False, erd = Just erd, amlSidebar = amlSidebar }
    , Cmd.batch
        ([ Ports.observeSize Conf.ids.erd
         , Ports.observeLayout (erd |> Erd.currentLayout)
         , Ports.setMeta { title = Just (Views.title (Just erd)), description = Nothing, canonical = Nothing, html = Nothing, body = Nothing }
         , Ports.projectDirty False
         ]
            ++ B.cond (model.save == Nothing) [] [ ProjectSaveDialog.Close |> ProjectSaveMsg |> ModalClose |> T.send, Ports.confettiPride ]
            ++ B.cond (context == "load") [ Track.projectLoaded project ] []
        )
    )


showAllTablesIfNeeded : Erd -> Erd
showAllTablesIfNeeded erd =
    if erd.currentLayout == Conf.constants.defaultLayout && (erd |> Erd.currentLayout |> .tables |> List.isEmpty) && Dict.size erd.tables < Conf.constants.fewTablesLimit then
        erd
            |> Erd.mapCurrentLayout (setTables (erd.tables |> Dict.values |> List.map (\t -> t |> ErdTableLayout.init erd.settings Set.empty (erd.relationsByTable |> Dict.getOrElse t.id []) erd.settings.collapseTableColumns Nothing)))
            |> setLayoutOnLoad "arrange"

    else
        erd
