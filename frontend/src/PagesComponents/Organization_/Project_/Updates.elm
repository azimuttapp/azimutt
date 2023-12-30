module PagesComponents.Organization_.Project_.Updates exposing (update)

import Components.Molecules.Dropdown as Dropdown
import Components.Organisms.TableRow as TableRow
import Components.Slices.DataExplorer as DataExplorer
import Components.Slices.DataExplorerDetails as DataExplorerDetails
import Components.Slices.DataExplorerQuery as DataExplorerQuery
import Components.Slices.ProPlan as ProPlan
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
import Libs.Models.Delta as Delta exposing (Delta)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Nel as Nel
import Libs.Task as T
import Libs.Time as Time
import Libs.Tuple as Tuple
import Libs.Tuple3 as Tuple3
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
import Models.Project.TableRow as TableRow exposing (TableRow)
import Models.ProjectInfo exposing (ProjectInfo)
import Models.ProjectRef exposing (ProjectRef)
import Models.QueryResult exposing (QueryResult)
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
import PagesComponents.Organization_.Project_.Models exposing (AmlSidebar, AmlSidebarMsg(..), LayoutMsg(..), Model, Msg(..), ProjectSettingsMsg(..), SchemaAnalysisMsg(..))
import PagesComponents.Organization_.Project_.Models.CursorMode as CursorMode
import PagesComponents.Organization_.Project_.Models.DragState as DragState
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdColumnProps as ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Organization_.Project_.Models.ErdLayout as ErdLayout exposing (ErdLayout)
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
import PagesComponents.Organization_.Project_.Updates.Table exposing (goToTable, hideColumn, hideColumns, hideRelatedTables, hideTable, hoverColumn, hoverNextColumn, mapTablePropOrSelected, mapTablePropOrSelectedTL, showAllTables, showColumn, showColumns, showRelatedTables, showTable, showTables, sortColumns, toggleNestedColumn, unHideTable)
import PagesComponents.Organization_.Project_.Updates.TableRow exposing (deleteTableRow, mapTableRowOrSelected, moveToTableRow, showTableRow, unDeleteTableRow)
import PagesComponents.Organization_.Project_.Updates.Tags exposing (handleTags)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirty, setHDirty, setHDirtyCmd, setHDirtyCmdM, setHL, setHLCmd, setHLDirty, setHLDirtyCmd)
import PagesComponents.Organization_.Project_.Updates.VirtualRelation exposing (handleVirtualRelation)
import PagesComponents.Organization_.Project_.Views as Views
import PagesComponents.Organization_.Project_.Views.Modals.NewLayout as NewLayout
import Ports exposing (JsMsg(..))
import Random
import Services.Backend as Backend
import Services.DatabaseSource as DatabaseSource
import Services.JsonSource as JsonSource
import Services.Lenses exposing (mapAmlSidebarM, mapCanvas, mapCanvasT, mapColorT, mapColumnsT, mapContextMenuM, mapDataExplorerT, mapDetailsSidebarT, mapEmbedSourceParsingMTW, mapErdM, mapErdMT, mapErdMTM, mapErdMTW, mapExportDialogT, mapHoverTable, mapMemos, mapMemosT, mapMobileMenuOpen, mapNavbar, mapOpened, mapOpenedDialogs, mapOrganizationM, mapPlan, mapPosition, mapPositionT, mapProject, mapProjectT, mapPromptM, mapProps, mapPropsT, mapSaveT, mapSchemaAnalysisM, mapSearch, mapSharingT, mapShowHiddenColumns, mapTableRows, mapTableRowsT, mapTables, mapTablesL, mapTablesT, mapToastsT, setActive, setCanvas, setCollapsed, setColors, setColumns, setConfirm, setContextMenu, setCurrentLayout, setCursorMode, setDragging, setHoverTable, setHoverTableRow, setInput, setLast, setLayoutOnLoad, setModal, setName, setOpenedDropdown, setOpenedPopover, setPosition, setPrompt, setSchemaAnalysis, setShow, setSize, setTables, setText)
import Services.PrismaSource as PrismaSource
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts
import Set
import Time
import Track


update : Maybe LayoutName -> Time.Zone -> Time.Posix -> UrlInfos -> List Organization -> List ProjectInfo -> Msg -> Model -> ( Model, Cmd Msg, List ( Msg, Msg ) )
update urlLayout zone now urlInfos organizations projects msg model =
    case msg of
        ToggleMobileMenu ->
            ( model |> mapNavbar (mapMobileMenuOpen not), Cmd.none, [] )

        SearchUpdated search ->
            ( model |> mapNavbar (mapSearch (setText search >> setActive 0)), Cmd.none, [] )

        SearchClicked kind table ->
            ( model, Cmd.batch [ ShowTable table Nothing "search" |> T.send, Track.searchClicked kind model.erd ], [] )

        TriggerSaveProject ->
            model |> triggerSaveProject urlInfos organizations

        CreateProject name organization storage ->
            model |> createProject name organization storage

        UpdateProject ->
            model |> updateProject

        MoveProjectTo storage ->
            model |> moveProject storage

        RenameProject name ->
            model |> mapErdMT (mapProjectT (\p -> ( p |> setName name, [ ( RenameProject p.name, RenameProject name ) ] ))) |> setHLDirty

        DeleteProject project ->
            ( model, Ports.deleteProject project ((project.organization |> Maybe.map .id) |> Backend.organizationUrl |> Just), [] )

        GoToTable id ->
            model |> mapErdMT (goToTable now id model.erdElem) |> setHLDirtyCmd

        ShowTable id hint from ->
            if model.erd |> Maybe.mapOrElse (Erd.currentLayout >> .tables) [] |> List.any (\t -> t.id == id) then
                ( model, GoToTable id |> T.send, [] )

            else
                model |> mapErdMT (showTable now id hint from) |> setHLDirtyCmd

        ShowTables ids hint from ->
            model |> mapErdMT (showTables now ids hint from) |> setHLDirtyCmd

        ShowAllTables from ->
            model |> mapErdMT (showAllTables now from) |> setHLDirtyCmd

        HideTable id ->
            model |> mapErdMT (hideTable now id) |> Tuple.mapFirst (mapHoverTable (Maybe.filter (\( t, _ ) -> t /= id))) |> setHLDirty

        UnHideTable_ index table ->
            if model.erd |> Maybe.mapOrElse (Erd.currentLayout >> .tables) [] |> List.any (\t -> t.id == table.id) then
                ( model, GoToTable table.id |> T.send, [] )

            else
                model |> mapErdMTW (unHideTable now index table) Cmd.none |> setHDirtyCmd [ ( HideTable table.id, msg ) ]

        ShowRelatedTables id ->
            model |> mapErdMT (showRelatedTables now id) |> setHLDirtyCmd

        HideRelatedTables id ->
            model |> mapErdMT (hideRelatedTables now id) |> setHLDirtyCmd

        ToggleTableCollapse id ->
            let
                collapsed : Bool
                collapsed =
                    model.erd |> Maybe.andThen (Erd.currentLayout >> .tables >> List.findBy .id id) |> Maybe.mapOrElse (.props >> .collapsed) False
            in
            model
                |> mapErdMTM (\erd -> erd |> Erd.mapCurrentLayoutTWithTime now (mapTablesT (mapTablePropOrSelected erd.settings.defaultSchema id (mapProps (setCollapsed (not collapsed))))))
                |> setHDirtyCmdM [ ( ToggleTableCollapse id, ToggleTableCollapse id ) ]

        ShowColumn index column ->
            model |> mapErdMT (showColumn now index column) |> setHLDirty

        HideColumn column ->
            model |> mapErdMT (hideColumn now column) |> Tuple.mapFirst (hoverNextColumn column) |> setHLDirty

        ShowColumns id kind ->
            model |> mapErdMT (showColumns now id kind) |> setHLDirtyCmd

        HideColumns id kind ->
            model |> mapErdMT (hideColumns now id kind) |> setHLDirtyCmd

        SortColumns id kind ->
            model |> mapErdMT (sortColumns now id kind) |> setHLDirtyCmd

        SetColumns_ id columns ->
            -- no undo action as triggered only from undo ^^
            model |> mapErdM (Erd.mapCurrentLayout (mapTablesL .id id (setColumns columns))) |> setHDirty []

        ToggleNestedColumn table path open ->
            model |> mapErdM (toggleNestedColumn now table path open) |> setHDirty [ ( ToggleNestedColumn table path (not open), ToggleNestedColumn table path open ) ]

        ToggleHiddenColumns id ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapTables (List.mapBy .id id (mapProps (mapShowHiddenColumns not))))) |> setHDirty [ ( ToggleHiddenColumns id, ToggleHiddenColumns id ) ]

        SelectItem htmlId ctrl ->
            if model.dragging |> Maybe.any DragState.hasMoved then
                ( model, Cmd.none, [] )

            else
                model |> mapErdMT (Erd.mapCurrentLayoutTLWithTime now (\l -> ( l |> ErdLayout.mapSelected (\i s -> B.cond (i.id == htmlId) (not s) (B.cond ctrl s False)), [ ( SelectItems_ (ErdLayout.getSelected l), msg ) ] ))) |> setHLDirty

        SelectItems_ htmlIds ->
            model |> mapErdMT (Erd.mapCurrentLayoutTLWithTime now (\l -> ( l |> ErdLayout.setSelected htmlIds, [ ( SelectItems_ (ErdLayout.getSelected l), msg ) ] ))) |> setHLDirty

        SelectAll ->
            model |> mapErdMT (Erd.mapCurrentLayoutTLWithTime now (\l -> ( l |> ErdLayout.mapSelected (\_ _ -> True), [ ( SelectItems_ (ErdLayout.getSelected l), msg ) ] ))) |> setHLDirty

        CanvasPosition_ position ->
            model |> mapErdMTM (Erd.mapCurrentLayoutTWithTime now (mapCanvasT (mapPositionT (\p -> ( position, [ ( CanvasPosition_ p, msg ) ] ))))) |> setHL

        TableMove id delta ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapTables (List.mapBy .id id (mapProps (mapPosition (Position.moveGrid delta)))))) |> setHDirty [ ( TableMove id (Delta.negate delta), msg ) ]

        TablePosition id position ->
            model |> mapErdMT (Erd.mapCurrentLayoutTLWithTime now (mapTablesT (List.mapByT .id id (mapPropsT (mapPositionT (\p -> ( position, ( TablePosition id p, msg ) ))))))) |> setHLDirty

        TableRowPosition_ id position ->
            model |> mapErdMT (Erd.mapCurrentLayoutTLWithTime now (mapTableRowsT (List.mapByT .id id (mapPositionT (\p -> ( position, ( TableRowPosition_ id p, msg ) )))))) |> setHLDirty

        MemoPosition_ id position ->
            model |> mapErdMT (Erd.mapCurrentLayoutTLWithTime now (mapMemosT (List.mapByT .id id (mapPositionT (\p -> ( position, ( MemoPosition_ id p, msg ) )))))) |> setHLDirty

        TableOrder id index ->
            model
                |> mapErdMT
                    (Erd.mapCurrentLayoutTLWithTime now
                        (mapTablesT
                            (\tables ->
                                (List.length tables - 1 - max index 0)
                                    |> (\newPos ->
                                            (tables |> List.findIndexBy .id id)
                                                |> Maybe.filter (\pos -> pos /= newPos)
                                                |> Maybe.map (\pos -> ( tables |> List.moveIndex pos newPos, [ ( TableOrder id (List.length tables - 1 - pos), msg ) ] ))
                                                |> Maybe.withDefault ( tables, [] )
                                       )
                            )
                        )
                    )
                |> setHLDirty

        TableColor id color extendToSelected ->
            let
                project : ProjectRef
                project =
                    model.erd |> Erd.getProjectRefM urlInfos
            in
            if model.erd |> Erd.canChangeColor then
                model |> mapErdMTM (\erd -> erd |> Erd.mapCurrentLayoutTWithTime now (mapTablesT (mapTablePropOrSelectedTL erd.settings.defaultSchema extendToSelected id (\t -> t |> mapPropsT (mapColorT (\c -> ( color, [ ( TableColor t.id c False, TableColor t.id color False ) ] ))))))) |> setHLDirtyCmd

            else
                ( model, Cmd.batch [ ProPlan.colorsModalBody project ProPlanColors ProPlan.colorsInit |> CustomModalOpen |> T.send, Track.planLimit .tableColor model.erd ], [] )

        MoveColumn column position ->
            model
                |> mapErdMT
                    (\erd ->
                        erd
                            |> Erd.mapCurrentLayoutTLWithTime now
                                (mapTablesT
                                    (List.mapByTL .id
                                        column.table
                                        (mapColumnsT
                                            (ErdColumnProps.mapAtTL
                                                (column.column |> ColumnPath.parent)
                                                (\cols ->
                                                    (cols |> List.findIndexBy .name (column.column |> Nel.last))
                                                        |> Maybe.filter (\pos -> pos /= position)
                                                        |> Maybe.map (\pos -> ( cols |> List.moveIndex pos position, [ ( MoveColumn column pos, msg ) ] ))
                                                        |> Maybe.withDefault ( cols, [] )
                                                )
                                            )
                                        )
                                    )
                                )
                    )
                |> setHLDirty

        HoverTable ( table, col ) on ->
            ( model |> setHoverTable (B.cond on (Just ( table, col )) (col |> Maybe.map (\_ -> ( table, Nothing )))) |> mapErdM (\e -> e |> Erd.mapCurrentLayoutWithTime now (mapTables (hoverColumn ( table, col ) on e))), Cmd.none, [] )

        HoverTableRow ( table, col ) on ->
            ( model |> setHoverTableRow (B.cond on (Just ( table, col )) (col |> Maybe.map (\_ -> ( table, Nothing )))), Cmd.none, [] )

        CreateUserSource name ->
            ( model, SourceId.generator |> Random.generate (Source.aml name now >> CreateUserSourceWithId), [] )

        CreateUserSourceWithId source ->
            model
                |> mapErdM (Erd.mapSources (List.insert source))
                |> (\newModel -> newModel |> mapAmlSidebarM (AmlSidebar.setSource (newModel.erd |> Maybe.andThen (.sources >> List.last))))
                |> AmlSidebar.setOtherSourcesTableIdsCache (Just source.id)
                |> setHDirty [ ( Batch [ ProjectSettingsMsg (PSSourceDelete source), AmlSidebarMsg (AChangeSource (model.amlSidebar |> Maybe.andThen .selected)) ], msg ) ]

        CreateRelations rels ->
            model |> mapErdMT (Source.createRelations now rels) |> setHLDirtyCmd

        RemoveRelations_ source rels ->
            model |> mapErdMT (Source.deleteRelations source rels) |> setHLDirtyCmd

        IgnoreRelation col ->
            model |> mapErdMT (Erd.mapIgnoredRelationsT (Dict.updateT col.table (\cols -> ( cols |> Maybe.mapOrElse (List.insert col.column) [ col.column ] >> List.uniqueBy ColumnPath.toString >> Just, [ ( UnIgnoreRelation_ col, msg ) ] )))) |> setHLDirty

        UnIgnoreRelation_ col ->
            model |> mapErdMT (Erd.mapIgnoredRelationsT (Dict.updateT col.table (\cols -> ( cols |> Maybe.map (List.filter (\c -> c /= col.column)), [ ( IgnoreRelation col, msg ) ] )))) |> setHLDirty

        NewLayoutMsg message ->
            model |> NewLayout.update NewLayoutMsg Batch ModalOpen Toast CustomModalOpen (LLoad "" >> LayoutMsg) (LDelete >> LayoutMsg) now urlInfos message

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

        ShowTableRow source query previous hint from ->
            (model.erd |> Maybe.andThen (Erd.currentLayout >> .tableRows >> List.find (\r -> r.source == source.id && r.table == query.table && r.primaryKey == query.primaryKey)))
                |> Maybe.map (\r -> model |> mapErdMTM (moveToTableRow now model.erdElem r) |> setHLCmd)
                |> Maybe.withDefault (model |> mapErdMT (showTableRow now source query previous hint from) |> setHLDirtyCmd)

        DeleteTableRow id ->
            model |> mapErdMTM (Erd.mapCurrentLayoutTWithTime now (deleteTableRow id)) |> setHLDirtyCmd

        UnDeleteTableRow_ index tableRow ->
            model |> mapErdMTM (Erd.mapCurrentLayoutTWithTime now (unDeleteTableRow index tableRow)) |> setHLDirtyCmd

        TableRowMsg id message ->
            model |> mapErdMTM (\e -> e |> Erd.mapCurrentLayoutTWithTime now (mapTableRowsT (mapTableRowOrSelected id message (TableRow.update (TableRowMsg id) DropdownToggle Toast now e.project e.sources model.openedDropdown message)))) |> setHLDirtyCmd

        AmlSidebarMsg message ->
            model |> AmlSidebar.update now message |> Tuple.append []

        DetailsSidebarMsg message ->
            model.erd |> Maybe.mapOrElse (\erd -> model |> mapDetailsSidebarT (DetailsSidebar.update Noop NotesMsg TagsMsg erd message)) ( model, Cmd.none ) |> Tuple.append []

        DataExplorerMsg message ->
            model.erd |> Maybe.mapOrElse (\erd -> model |> mapDataExplorerT (DataExplorer.update DataExplorerMsg Toast erd.project erd.sources message)) ( model, Cmd.none ) |> Tuple.append []

        VirtualRelationMsg message ->
            model |> handleVirtualRelation message |> Tuple.append []

        FindPathMsg message ->
            model |> handleFindPath message |> Tuple.append []

        SchemaAnalysisMsg SAOpen ->
            ( model |> setSchemaAnalysis (Just { id = Conf.ids.schemaAnalysisDialog, opened = "" }), Cmd.batch [ T.sendAfter 1 (ModalOpen Conf.ids.schemaAnalysisDialog), Track.dbAnalysisOpened model.erd ] ) |> Tuple.append []

        SchemaAnalysisMsg (SASectionToggle section) ->
            ( model |> mapSchemaAnalysisM (mapOpened (\opened -> B.cond (opened == section) "" section)), Cmd.none ) |> Tuple.append []

        SchemaAnalysisMsg SAClose ->
            ( model |> setSchemaAnalysis Nothing, Cmd.none ) |> Tuple.append []

        ExportDialogMsg message ->
            model.erd |> Maybe.mapOrElse (\erd -> model |> mapExportDialogT (ExportDialog.update ExportDialogMsg ModalOpen urlInfos erd message)) ( model, Cmd.none ) |> Tuple.append []

        SharingMsg message ->
            model |> mapSharingT (ProjectSharing.update SharingMsg ModalOpen Toast zone now model.erd message) |> Tuple.append []

        ProjectSaveMsg message ->
            model |> mapSaveT (ProjectSaveDialog.update ModalOpen message) |> Tuple.append []

        ProjectSettingsMsg message ->
            model |> handleProjectSettings now message |> Tuple.append []

        EmbedSourceParsingMsg message ->
            model |> mapEmbedSourceParsingMTW (EmbedSourceParsingDialog.update EmbedSourceParsingMsg now (model.erd |> Maybe.map .project) message) Cmd.none |> Tuple.append []

        SourceParsed source ->
            ( model, source |> Project.create projects source.name |> Ok |> Just |> GotProject "load" |> JsMessage |> T.send ) |> Tuple.append []

        ProPlanColors _ ProPlan.EnableTableChangeColor ->
            ( model |> mapErdM (mapProject (mapOrganizationM (mapPlan (setColors True)))), Ports.fireworks ) |> Tuple.append []

        ProPlanColors state message ->
            state |> ProPlan.colorsUpdate ProPlanColors message |> Tuple.mapFirst (\s -> { model | modal = model.modal |> Maybe.map (\m -> { m | content = ProPlan.colorsModalBody (model.erd |> Erd.getProjectRefM urlInfos) ProPlanColors s }) }) |> Tuple.append []

        HelpMsg message ->
            model |> handleHelp message |> Tuple.append []

        CursorMode mode ->
            ( model |> setCursorMode mode, Cmd.none ) |> Tuple.append []

        FitToScreen ->
            model |> mapErdMTW (fitCanvas model.erdElem) Cmd.none |> Tuple.append []

        ArrangeTables ->
            model |> mapErdMTW (arrangeTables now model.erdElem) Cmd.none |> setHDirtyCmd []

        Fullscreen id ->
            ( model, Ports.fullscreen id ) |> Tuple.append []

        OnWheel event ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapCanvas (handleWheel event model.erdElem))) |> setDirty |> Tuple.append []

        Zoom delta ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapCanvas (zoomCanvas delta model.erdElem))) |> setDirty |> Tuple.append []

        Focus id ->
            ( model, Ports.focus id ) |> Tuple.append []

        DropdownToggle id ->
            ( model |> Dropdown.update id, Cmd.none ) |> Tuple.append []

        DropdownOpen id ->
            ( model |> setOpenedDropdown id, Cmd.none ) |> Tuple.append []

        DropdownClose ->
            ( model |> setOpenedDropdown "", Cmd.none ) |> Tuple.append []

        PopoverOpen id ->
            ( model |> setOpenedPopover id, Cmd.none ) |> Tuple.append []

        ContextMenuCreate content event ->
            ( model |> setContextMenu (Just { content = content, position = event.clientPos, show = False }), T.sendAfter 1 ContextMenuShow ) |> Tuple.append []

        ContextMenuShow ->
            ( model |> mapContextMenuM (setShow True), Cmd.none ) |> Tuple.append []

        ContextMenuClose ->
            ( model |> setContextMenu Nothing, Cmd.none ) |> Tuple.append []

        DragStart id pos ->
            model.dragging
                |> Maybe.mapOrElse (\d -> ( model, "Already dragging " ++ d.id |> Toasts.info |> Toast |> T.send, [] ))
                    ({ id = id, init = pos, last = pos } |> (\d -> model |> setDragging (Just d) |> handleDrag now d False False))

        DragMove pos ->
            model.dragging
                |> Maybe.map (setLast pos)
                |> Maybe.mapOrElse (\d -> model |> setDragging (Just d) |> handleDrag now d False False) ( model, Cmd.none, [] )

        DragEnd cancel pos ->
            model.dragging
                |> Maybe.map (setLast pos)
                |> Maybe.mapOrElse (\d -> model |> setDragging Nothing |> handleDrag now d True cancel) ( model, Cmd.none, [] )

        DragCancel ->
            ( model |> setDragging Nothing, Cmd.none ) |> Tuple.append []

        Toast message ->
            model |> mapToastsT (Toasts.update Toast message) |> Tuple.append []

        ConfirmOpen confirm ->
            ( model |> setConfirm (Just { id = Conf.ids.confirmDialog, content = confirm }), T.sendAfter 1 (ModalOpen Conf.ids.confirmDialog) ) |> Tuple.append []

        ConfirmAnswer answer cmd ->
            ( model |> setConfirm Nothing, B.cond answer cmd Cmd.none ) |> Tuple.append []

        PromptOpen prompt input ->
            ( model |> setPrompt (Just { id = Conf.ids.promptDialog, content = prompt, input = input }), T.sendAfter 1 (ModalOpen Conf.ids.promptDialog) ) |> Tuple.append []

        PromptUpdate input ->
            ( model |> mapPromptM (setInput input), Cmd.none ) |> Tuple.append []

        PromptAnswer cmd ->
            ( model |> setPrompt Nothing, cmd ) |> Tuple.append []

        ModalOpen id ->
            ( model |> mapOpenedDialogs (\dialogs -> id :: dialogs), Ports.autofocusWithin id ) |> Tuple.append []

        ModalClose message ->
            ( model |> mapOpenedDialogs (List.drop 1), T.sendAfter Conf.ui.closeDuration message ) |> Tuple.append []

        CustomModalOpen content ->
            ( model |> setModal (Just { id = Conf.ids.customDialog, content = content }), T.sendAfter 1 (ModalOpen Conf.ids.customDialog) ) |> Tuple.append []

        CustomModalClose ->
            ( model |> setModal Nothing, Cmd.none ) |> Tuple.append []

        Undo ->
            case model.history of
                [] ->
                    ( model, "Can't undo, action history is empty" |> Toasts.info |> Toast |> T.send, [] )

                ( back, next ) :: history ->
                    update urlLayout zone now urlInfos organizations projects back { model | history = history, future = ( back, next ) :: model.future } |> Tuple3.mapThird (\_ -> [])

        Redo ->
            case model.future of
                [] ->
                    ( model, "Can't redo, no future action" |> Toasts.info |> Toast |> T.send, [] )

                ( back, next ) :: future ->
                    update urlLayout zone now urlInfos organizations projects next { model | history = ( back, next ) :: model.history, future = future } |> Tuple3.mapThird (\_ -> [])

        JsMessage message ->
            model |> handleJsMessage now urlLayout message

        Batch messages ->
            messages
                |> List.foldl
                    (\curMsg ( curModel, curCmd, curHist ) ->
                        update urlLayout zone now urlInfos organizations projects curMsg curModel
                            |> (\( newModel, newCmd, newHist ) -> ( newModel, Cmd.batch [ curCmd, newCmd ], curHist ++ newHist ))
                    )
                    ( model, Cmd.none, [] )

        Send cmd ->
            ( model, cmd, [] )

        Noop _ ->
            ( model, Cmd.none, [] )


handleJsMessage : Time.Posix -> Maybe LayoutName -> JsMsg -> Model -> ( Model, Cmd Msg, List ( Msg, Msg ) )
handleJsMessage now urlLayout msg model =
    case msg of
        GotSizes sizes ->
            model |> updateSizes sizes |> Tuple.append []

        GotProject context res ->
            case res of
                Nothing ->
                    ( { model | loaded = True, saving = False }, Cmd.none ) |> Tuple.append []

                Just (Err err) ->
                    ( { model | loaded = True, saving = False }, Cmd.batch [ "Unable to read project: " ++ Decode.errorToHtml err |> Toasts.error |> Toast |> T.send, Track.jsonError "decode-project" err ] ) |> Tuple.append []

                Just (Ok project) ->
                    { model | saving = False } |> updateErd urlLayout context project |> Tuple.append []

        ProjectDeleted _ ->
            -- handled in Shared
            ( model, Cmd.none, [] )

        GotLocalFile kind file content ->
            if kind == SqlSource.kind then
                ( model, SourceId.generator |> Random.generate (\sourceId -> content |> SqlSource.GotFile (SourceInfo.sqlLocal now sourceId file) |> SourceUpdateDialog.SqlSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg) ) |> Tuple.append []

            else if kind == PrismaSource.kind then
                ( model, SourceId.generator |> Random.generate (\sourceId -> content |> PrismaSource.GotFile (SourceInfo.prismaLocal now sourceId file) |> SourceUpdateDialog.PrismaSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg) ) |> Tuple.append []

            else if kind == JsonSource.kind then
                ( model, SourceId.generator |> Random.generate (\sourceId -> content |> JsonSource.GotFile (SourceInfo.jsonLocal now sourceId file) |> SourceUpdateDialog.JsonSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg) ) |> Tuple.append []

            else
                ( model, "Unhandled local file kind '" ++ kind ++ "'" |> Toasts.error |> Toast |> T.send ) |> Tuple.append []

        GotDatabaseSchema schema ->
            if model.embedSourceParsing == Nothing then
                ( model, Ok schema |> DatabaseSource.GotSchema |> SourceUpdateDialog.DatabaseSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg |> T.send ) |> Tuple.append []

            else
                ( model, Ok schema |> DatabaseSource.GotSchema |> EmbedSourceParsingDialog.EmbedDatabaseSource |> EmbedSourceParsingMsg |> T.send ) |> Tuple.append []

        GotDatabaseSchemaError error ->
            if model.embedSourceParsing == Nothing then
                ( model, Err error |> DatabaseSource.GotSchema |> SourceUpdateDialog.DatabaseSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg |> T.send ) |> Tuple.append []

            else
                ( model, Err error |> DatabaseSource.GotSchema |> EmbedSourceParsingDialog.EmbedDatabaseSource |> EmbedSourceParsingMsg |> T.send ) |> Tuple.append []

        GotTableStats source stats ->
            ( { model | tableStats = model.tableStats |> Dict.update stats.id (Maybe.withDefault Dict.empty >> Dict.insert (SourceId.toString source) (Ok stats) >> Just) }, Cmd.none ) |> Tuple.append []

        GotTableStatsError source table error ->
            ( { model | tableStats = model.tableStats |> Dict.update table (Maybe.withDefault Dict.empty >> Dict.insert (SourceId.toString source) (Err error) >> Just) }, Cmd.none ) |> Tuple.append []

        GotColumnStats source stats ->
            ( { model | columnStats = model.columnStats |> Dict.update stats.id (Maybe.withDefault Dict.empty >> Dict.insert (SourceId.toString source) (Ok stats) >> Just) }, Cmd.none ) |> Tuple.append []

        GotColumnStatsError source column error ->
            ( { model | columnStats = model.columnStats |> Dict.update (ColumnId.fromRef column) (Maybe.withDefault Dict.empty >> Dict.insert (SourceId.toString source) (Err error) >> Just) }, Cmd.none ) |> Tuple.append []

        GotDatabaseQueryResult result ->
            model |> handleDatabaseQueryResponse result |> Tuple.append []

        GotPrismaSchema schema ->
            if model.embedSourceParsing == Nothing then
                ( model, Ok schema |> PrismaSource.GotSchema |> SourceUpdateDialog.PrismaSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg |> T.send ) |> Tuple.append []

            else
                ( model, Ok schema |> PrismaSource.GotSchema |> EmbedSourceParsingDialog.EmbedPrismaSource |> EmbedSourceParsingMsg |> T.send ) |> Tuple.append []

        GotPrismaSchemaError error ->
            if model.embedSourceParsing == Nothing then
                ( model, Err error |> PrismaSource.GotSchema |> SourceUpdateDialog.PrismaSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg |> T.send ) |> Tuple.append []

            else
                ( model, Err error |> PrismaSource.GotSchema |> EmbedSourceParsingDialog.EmbedPrismaSource |> EmbedSourceParsingMsg |> T.send ) |> Tuple.append []

        GotHotkey hotkey ->
            if model.saving then
                ( model, Cmd.none ) |> Tuple.append []

            else
                handleHotkey now model hotkey |> Tuple.append []

        GotKeyHold key start ->
            if key == "Space" && model.conf.move then
                if start then
                    ( model |> setCursorMode CursorMode.Drag, Cmd.none ) |> Tuple.append []

                else
                    ( model |> setCursorMode CursorMode.Select, Cmd.none ) |> Tuple.append []

            else
                ( model, Cmd.none ) |> Tuple.append []

        GotToast level message ->
            ( model, message |> Toasts.create level |> Toast |> T.send ) |> Tuple.append []

        GotTableShow id hint ->
            ( model, T.send (ShowTable id (hint |> Maybe.map PlaceAt) "port") ) |> Tuple.append []

        GotTableHide id ->
            ( model, T.send (HideTable id) ) |> Tuple.append []

        GotTableToggleColumns id ->
            ( model, T.send (ToggleTableCollapse id) ) |> Tuple.append []

        GotTablePosition id pos ->
            ( model, T.send (TablePosition id pos) ) |> Tuple.append []

        GotTableMove id delta ->
            ( model, T.send (TableMove id delta) ) |> Tuple.append []

        GotTableSelect id ->
            ( model, T.send (SelectItem (TableId.toHtmlId id) False) ) |> Tuple.append []

        GotTableColor id color ->
            ( model, T.send (TableColor id color True) ) |> Tuple.append []

        GotColumnShow ref ->
            ( model, T.send (ShowColumn 1000 ref) ) |> Tuple.append []

        GotColumnHide ref ->
            ( model, T.send (HideColumn ref) ) |> Tuple.append []

        GotColumnMove ref index ->
            ( model, T.send (MoveColumn ref index) ) |> Tuple.append []

        GotFitToScreen ->
            ( model, T.send FitToScreen ) |> Tuple.append []

        Error json err ->
            ( model, Cmd.batch [ "Unable to decode JavaScript message: " ++ Decode.errorToString err ++ " in " ++ Encode.encode 0 json |> Toasts.error |> Toast |> T.send, Track.jsonError "js_message" err ] ) |> Tuple.append []


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
                    (Erd.mapCurrentLayout
                        (\l ->
                            l
                                |> mapMemos (updateMemos l.canvas.zoom changes)
                                |> mapTableRows (updateTableRows l.canvas.zoom erdViewport changes)
                                |> mapTables (updateTables l.canvas.zoom erdViewport changes)
                        )
                    )
    in
    newModel
        |> mapErdMTW
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
            Cmd.none


updateMemos : ZoomLevel -> List SizeChange -> List Memo -> List Memo
updateMemos zoom changes memos =
    changes
        |> List.foldl
            (\c ->
                List.map
                    (\memo ->
                        if c.id == MemoId.toHtmlId memo.id then
                            memo |> setSize (c.size |> Size.viewportToCanvas zoom)

                        else
                            memo
                    )
            )
            memos


updateTableRows : ZoomLevel -> Area.Canvas -> List SizeChange -> List TableRow -> List TableRow
updateTableRows zoom erdViewport changes rows =
    changes
        |> List.foldl
            (\c ->
                List.map
                    (\row ->
                        if c.id == TableRow.toHtmlId row.id then
                            updateTableRow zoom erdViewport row c

                        else
                            row
                    )
            )
            rows


updateTableRow : ZoomLevel -> Area.Canvas -> TableRow -> SizeChange -> TableRow
updateTableRow zoom erdViewport row change =
    let
        size : Size.Canvas
        size =
            change.size |> Size.viewportToCanvas zoom
    in
    if row.size == Size.zeroCanvas && row.position == Position.zeroGrid then
        row |> setSize size |> setPosition (tableRowInitialPosition erdViewport size row.positionHint)

    else
        row |> setSize size


tableRowInitialPosition : Area.Canvas -> Size.Canvas -> Maybe PositionHint -> Position.Grid
tableRowInitialPosition erdViewport newSize hint =
    hint
        |> Maybe.mapOrElse
            (\h ->
                case h of
                    PlaceLeft position ->
                        position |> Position.moveGrid { dx = (Size.extractCanvas newSize).width + 50 |> negate, dy = 0 }

                    PlaceRight position size ->
                        position |> Position.moveGrid { dx = (Size.extractCanvas size).width + 50, dy = 0 }

                    PlaceAt position ->
                        position
            )
            (newSize |> placeAtCenter erdViewport)


updateTables : ZoomLevel -> Area.Canvas -> List SizeChange -> List ErdTableLayout -> List ErdTableLayout
updateTables zoom erdViewport changes tables =
    changes
        |> List.foldl
            (\c currentTables ->
                currentTables
                    |> List.map
                        (\table ->
                            if c.id == TableId.toHtmlId table.id then
                                updateTable zoom currentTables erdViewport table c

                            else
                                table
                        )
            )
            tables


updateTable : ZoomLevel -> List ErdTableLayout -> Area.Canvas -> ErdTableLayout -> SizeChange -> ErdTableLayout
updateTable zoom tables erdViewport table change =
    let
        size : Size.Canvas
        size =
            change.size |> Size.viewportToCanvas zoom
    in
    if table.props.size == Size.zeroCanvas && table.props.position == Position.zeroGrid then
        table |> mapProps (setSize size >> setPosition (tableInitialPosition tables erdViewport size change.seeds table.props.positionHint))

    else
        table |> mapProps (setSize size)


tableInitialPosition : List ErdTableLayout -> Area.Canvas -> Size.Canvas -> Delta -> Maybe PositionHint -> Position.Grid
tableInitialPosition tables erdViewport newSize _ hint =
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
        position |> Position.moveGrid { dx = 0, dy = Conf.ui.table.headerHeight } |> moveDownIfExists tables size

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
    if erd.currentLayout == Conf.constants.defaultLayout && (erd |> Erd.currentLayout |> ErdLayout.isEmpty) && Dict.size erd.tables < Conf.constants.fewTablesLimit then
        erd
            |> Erd.mapCurrentLayout (setTables (erd.tables |> Dict.values |> List.map (\t -> t |> ErdTableLayout.init erd.settings Set.empty (erd.relationsByTable |> Dict.getOrElse t.id []) erd.settings.collapseTableColumns Nothing)))
            |> setLayoutOnLoad "arrange"

    else
        erd


handleDatabaseQueryResponse : QueryResult -> Model -> ( Model, Cmd Msg )
handleDatabaseQueryResponse result model =
    case result.context |> String.split "/" of
        "data-explorer-query" :: idStr :: [] ->
            ( model, idStr |> String.toInt |> Maybe.map (\id -> DataExplorerQuery.GotResult result |> DataExplorer.QueryMsg id |> DataExplorerMsg |> T.send) |> Maybe.withDefault ("Invalid data explorer query context: " ++ result.context |> Toasts.warning |> Toast |> T.send) )

        "data-explorer-details" :: idStr :: [] ->
            ( model, idStr |> String.toInt |> Maybe.map (\id -> DataExplorerDetails.GotResult result |> DataExplorer.DetailsMsg id |> DataExplorerMsg |> T.send) |> Maybe.withDefault ("Invalid data explorer details context: " ++ result.context |> Toasts.warning |> Toast |> T.send) )

        "table-row" :: idStr :: [] ->
            ( model, idStr |> String.toInt |> Maybe.map (\id -> TableRow.GotResult result |> TableRowMsg id |> T.send) |> Maybe.withDefault ("Invalid table row context: " ++ result.context |> Toasts.warning |> Toast |> T.send) )

        "table-row" :: idStr :: column :: [] ->
            ( model, idStr |> String.toInt |> Maybe.map (\id -> TableRow.GotIncomingRows (ColumnPath.fromString column) result |> TableRowMsg id |> T.send) |> Maybe.withDefault ("Invalid incoming table row context: " ++ result.context |> Toasts.warning |> Toast |> T.send) )

        _ ->
            ( model, "Unknown db query context: " ++ result.context |> Toasts.warning |> Toast |> T.send )
