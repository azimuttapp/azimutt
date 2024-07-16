module PagesComponents.Organization_.Project_.Updates exposing (update)

import Components.Molecules.Dropdown as Dropdown
import Components.Organisms.TableRow as TableRow
import Components.Slices.DataExplorer as DataExplorer
import Components.Slices.DataExplorerDetails as DataExplorerDetails
import Components.Slices.DataExplorerQuery as DataExplorerQuery
import Components.Slices.LlmGenerateSqlBody as LlmGenerateSqlBody
import Components.Slices.PlanDialog as PlanDialog
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
import Models.Area as Area
import Models.Feature as Feature
import Models.Organization as Organization exposing (Organization)
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
import Models.UrlInfos exposing (UrlInfos)
import PagesComponents.Organization_.Project_.Components.AmlSidebar as AmlSidebar
import PagesComponents.Organization_.Project_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Organization_.Project_.Components.EmbedSourceParsingDialog as EmbedSourceParsingDialog
import PagesComponents.Organization_.Project_.Components.ExportDialog as ExportDialog
import PagesComponents.Organization_.Project_.Components.LlmGenerateSqlDialog as LlmGenerateSqlDialog
import PagesComponents.Organization_.Project_.Components.ProjectSaveDialog as ProjectSaveDialog
import PagesComponents.Organization_.Project_.Components.ProjectSharing as ProjectSharing
import PagesComponents.Organization_.Project_.Components.SourceUpdateDialog as SourceUpdateDialog
import PagesComponents.Organization_.Project_.Models exposing (AmlSidebar, AmlSidebarMsg(..), LayoutMsg(..), Model, Msg(..), ProjectSettingsMsg(..), SchemaAnalysisMsg(..))
import PagesComponents.Organization_.Project_.Models.CursorMode as CursorMode
import PagesComponents.Organization_.Project_.Models.DragState as DragState
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdColumnProps as ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Organization_.Project_.Models.ErdLayout as ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import PagesComponents.Organization_.Project_.Models.MemoId as MemoId
import PagesComponents.Organization_.Project_.Models.PositionHint exposing (PositionHint(..))
import PagesComponents.Organization_.Project_.Updates.Canvas exposing (arrangeTables, fitCanvas, handleWheel, squashViewHistory, zoomCanvas)
import PagesComponents.Organization_.Project_.Updates.Drag exposing (handleDrag)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
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
import PagesComponents.Organization_.Project_.Updates.Table exposing (goToTable, hideColumn, hideColumns, hideRelatedTables, hideTable, hoverColumn, hoverNextColumn, mapTablePropOrSelected, mapTablePropOrSelectedTE, showAllTables, showColumn, showColumns, showRelatedTables, showTable, showTables, sortColumns, toggleNestedColumn, unHideTable)
import PagesComponents.Organization_.Project_.Updates.TableRow exposing (deleteTableRow, mapTableRowOrSelected, moveToTableRow, showTableRow, unDeleteTableRow)
import PagesComponents.Organization_.Project_.Updates.Tags exposing (handleTags)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirty, setDirtyM)
import PagesComponents.Organization_.Project_.Updates.VirtualRelation exposing (handleVirtualRelation)
import PagesComponents.Organization_.Project_.Views as Views
import PagesComponents.Organization_.Project_.Views.Modals.NewLayout as NewLayout
import Ports exposing (JsMsg(..))
import Random
import Services.Backend as Backend
import Services.DatabaseSource as DatabaseSource
import Services.JsonSource as JsonSource
import Services.Lenses exposing (mapAmlSidebarM, mapCanvasT, mapColorT, mapColumnsT, mapContextMenuM, mapDataExplorerT, mapDetailsSidebarT, mapEmbedSourceParsingMT, mapErdM, mapErdMT, mapErdMTM, mapErdMTW, mapExportDialogT, mapHoverTable, mapLlmGenerateSqlT, mapMemos, mapMemosT, mapMobileMenuOpen, mapModalMF, mapNavbar, mapOpened, mapOpenedDialogs, mapOrganizationM, mapPlan, mapPosition, mapPositionT, mapProject, mapProjectT, mapPromptM, mapProps, mapPropsT, mapSaveT, mapSchemaAnalysisM, mapSearch, mapSharingT, mapShowHiddenColumns, mapTableRows, mapTableRowsT, mapTables, mapTablesL, mapTablesT, mapToastsT, setActive, setCanvas, setCollapsed, setColors, setColumns, setConfirm, setContentF, setContextMenu, setCurrentLayout, setCursorMode, setDragging, setHoverTable, setHoverTableRow, setInput, setLast, setLayoutOnLoad, setModal, setName, setOpenedDropdown, setOpenedPopover, setPosition, setPrompt, setSchemaAnalysis, setShow, setSize, setText)
import Services.PrismaSource as PrismaSource
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts
import Time
import Track


update : Maybe LayoutName -> Time.Zone -> Time.Posix -> UrlInfos -> List Organization -> List ProjectInfo -> Msg -> Model -> ( Model, Extra Msg )
update urlLayout zone now urlInfos organizations projects msg model =
    let
        projectRef : ProjectRef
        projectRef =
            model.erd |> Erd.getProjectRef urlInfos organizations
    in
    case msg of
        ToggleMobileMenu ->
            ( model |> mapNavbar (mapMobileMenuOpen not), Extra.none )

        SearchUpdated search ->
            ( model |> mapNavbar (mapSearch (setText search >> setActive 0)), Extra.none )

        SearchClicked kind table ->
            ( model, Extra.cmdL [ ShowTable table Nothing "search" |> T.send, Track.searchClicked kind model.erd ] )

        TriggerSaveProject ->
            model |> triggerSaveProject urlInfos organizations

        CreateProject name organization storage ->
            model |> createProject name organization storage

        UpdateProject ->
            model |> updateProject

        MoveProjectTo storage ->
            model |> moveProject storage

        RenameProject name ->
            model |> mapErdMT (mapProjectT (\p -> ( p |> setName name, Extra.history ( RenameProject p.name, RenameProject name ) ))) |> setDirtyM

        DeleteProject project ->
            ( model
            , Ports.deleteProject project ((project.organization |> Maybe.map .id) |> Backend.organizationUrl |> Just)
                :: (model.erd |> Maybe.filter (\erd -> erd.project.id == project.id) |> Maybe.mapOrElse (.sources >> List.map (.id >> Ports.deleteSource)) [])
                |> Extra.cmdL
            )

        GoToTable id ->
            model |> mapErdMT (goToTable now id model.erdElem) |> setDirtyM

        ShowTable id hint from ->
            if projectRef |> Organization.canShowTables 1 (model.erd |> Erd.countLayoutTables) then
                if model.erd |> Maybe.mapOrElse (Erd.currentLayout >> .tables) [] |> List.any (\t -> t.id == id) then
                    ( model, GoToTable id |> Extra.msg )

                else
                    model |> mapErdMT (showTable now id hint from) |> setDirtyM

            else
                ( model, Extra.cmdL [ PlanDialog.layoutTablesModalBody projectRef |> CustomModalOpen |> T.send, Track.planLimit Feature.layoutTables model.erd ] )

        ShowTables ids hint from ->
            if projectRef |> Organization.canShowTables (ids |> List.length) (model.erd |> Erd.countLayoutTables) then
                model |> mapErdMT (showTables now ids hint from) |> setDirtyM

            else
                ( model, Extra.cmdL [ PlanDialog.layoutTablesModalBody projectRef |> CustomModalOpen |> T.send, Track.planLimit Feature.layoutTables model.erd ] )

        ShowAllTables from ->
            if projectRef |> Organization.canShowTables (model.erd |> Maybe.mapOrElse (.tables >> Dict.size) 0) (model.erd |> Erd.countLayoutTables) then
                model |> mapErdMT (showAllTables now from) |> setDirtyM

            else
                ( model, Extra.cmdL [ PlanDialog.layoutTablesModalBody projectRef |> CustomModalOpen |> T.send, Track.planLimit Feature.layoutTables model.erd ] )

        HideTable id ->
            model |> mapErdMT (hideTable now id) |> Tuple.mapFirst (mapHoverTable (Maybe.filter (\( t, _ ) -> t /= id))) |> setDirtyM

        UnHideTable_ index table ->
            if model.erd |> Maybe.mapOrElse (Erd.currentLayout >> .tables) [] |> List.any (\t -> t.id == table.id) then
                ( model, GoToTable table.id |> Extra.msg )

            else
                model |> mapErdMT (unHideTable now index table) |> setDirtyM

        ShowRelatedTables id ->
            if projectRef |> Organization.canShowTables 1 (model.erd |> Erd.countLayoutTables) then
                model |> mapErdMT (showRelatedTables now id) |> setDirtyM

            else
                ( model, Extra.cmdL [ PlanDialog.layoutTablesModalBody projectRef |> CustomModalOpen |> T.send, Track.planLimit Feature.layoutTables model.erd ] )

        HideRelatedTables id ->
            model |> mapErdMT (hideRelatedTables now id) |> setDirtyM

        ToggleTableCollapse id ->
            model
                |> mapErdMTM
                    (\erd ->
                        erd
                            |> Erd.mapCurrentLayoutTWithTime now
                                (mapTablesT
                                    (\tables ->
                                        let
                                            collapsed : Bool
                                            collapsed =
                                                tables |> List.findBy .id id |> Maybe.mapOrElse (.props >> .collapsed) False |> not
                                        in
                                        tables |> mapTablePropOrSelected erd.settings.defaultSchema id (mapProps (setCollapsed collapsed))
                                    )
                                )
                    )
                |> setDirtyM
                |> Extra.addHistoryT ( ToggleTableCollapse id, ToggleTableCollapse id )

        ShowColumn index column ->
            model |> mapErdMT (showColumn now index column) |> setDirtyM

        HideColumn column ->
            model |> mapErdMT (hideColumn now column) |> Tuple.mapFirst (hoverNextColumn column) |> setDirtyM

        ShowColumns id kind ->
            model |> mapErdMT (showColumns now id kind) |> setDirtyM

        HideColumns id kind ->
            model |> mapErdMT (hideColumns now id kind) |> setDirtyM

        SortColumns id kind ->
            model |> mapErdMT (sortColumns now id kind) |> setDirtyM

        SetColumns_ id columns ->
            -- no undo action as triggered only from undo ^^
            ( model |> mapErdM (Erd.mapCurrentLayout (mapTablesL .id id (setColumns columns))), Extra.none ) |> setDirty

        ToggleNestedColumn table path open ->
            ( model |> mapErdM (toggleNestedColumn now table path open), Extra.history ( ToggleNestedColumn table path (not open), ToggleNestedColumn table path open ) ) |> setDirty

        ToggleHiddenColumns id ->
            ( model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapTables (List.mapBy .id id (mapProps (mapShowHiddenColumns not))))), Extra.history ( ToggleHiddenColumns id, ToggleHiddenColumns id ) ) |> setDirty

        SelectItem htmlId ctrl ->
            if model.dragging |> Maybe.any DragState.hasMoved then
                ( model, Extra.none )

            else
                model |> mapErdMTM (Erd.mapCurrentLayoutTWithTime now (\l -> ( l |> ErdLayout.mapSelected (\i s -> B.cond (i.id == htmlId) (not s) (B.cond ctrl s False)), Extra.history ( SelectItems_ (ErdLayout.getSelected l), msg ) ))) |> setDirtyM

        SelectItems_ htmlIds ->
            model |> mapErdMTM (Erd.mapCurrentLayoutTWithTime now (\l -> ( l |> ErdLayout.setSelected htmlIds, Extra.history ( SelectItems_ (ErdLayout.getSelected l), msg ) ))) |> setDirtyM

        SelectAll ->
            model |> mapErdMTM (Erd.mapCurrentLayoutTWithTime now (\l -> ( l |> ErdLayout.mapSelected (\_ _ -> True), Extra.history ( SelectItems_ (ErdLayout.getSelected l), msg ) ))) |> setDirtyM

        CanvasPosition position ->
            model |> mapErdMTM (Erd.mapCurrentLayoutTWithTime now (mapCanvasT (mapPositionT (\p -> ( position, Extra.history ( CanvasPosition p, msg ) ))))) |> Extra.defaultT

        TableMove id delta ->
            ( model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapTables (List.mapBy .id id (mapProps (mapPosition (Position.moveGrid delta)))))), Extra.history ( TableMove id (Delta.negate delta), msg ) ) |> setDirty

        TablePosition id position ->
            model |> mapErdMTM (Erd.mapCurrentLayoutTWithTime now (mapTablesT (List.mapByTE .id id (mapPropsT (mapPositionT (\p -> ( position, Extra.history ( TablePosition id p, msg ) ))))))) |> setDirtyM

        TableRowPosition id position ->
            model |> mapErdMTM (Erd.mapCurrentLayoutTWithTime now (mapTableRowsT (List.mapByTE .id id (mapPositionT (\p -> ( position, Extra.history ( TableRowPosition id p, msg ) )))))) |> setDirtyM

        MemoPosition id position ->
            model |> mapErdMTM (Erd.mapCurrentLayoutTWithTime now (mapMemosT (List.mapByTE .id id (mapPositionT (\p -> ( position, Extra.history ( MemoPosition id p, msg ) )))))) |> setDirtyM

        TableOrder id index ->
            model
                |> mapErdMTM
                    (Erd.mapCurrentLayoutTWithTime now
                        (mapTablesT
                            (\tables ->
                                (List.length tables - 1 - max index 0)
                                    |> (\newPos ->
                                            (tables |> List.findIndexBy .id id)
                                                |> Maybe.filter (\pos -> pos /= newPos)
                                                |> Maybe.map (\pos -> ( tables |> List.moveIndex pos newPos, Extra.history ( TableOrder id (List.length tables - 1 - pos), msg ) ))
                                                |> Maybe.withDefault ( tables, Extra.none )
                                       )
                            )
                        )
                    )
                |> setDirtyM

        TableColor id color extendToSelected ->
            if Organization.canChangeColor projectRef then
                model |> mapErdMTM (\erd -> erd |> Erd.mapCurrentLayoutTWithTime now (mapTablesT (mapTablePropOrSelectedTE erd.settings.defaultSchema extendToSelected id (\t -> t |> mapPropsT (mapColorT (\c -> ( color, Extra.history ( TableColor t.id c False, TableColor t.id color False ) ))))))) |> setDirtyM

            else
                ( model, Extra.cmdL [ PlanDialog.colorsModalBody projectRef PlanDialogColors PlanDialog.colorsInit |> CustomModalOpen |> T.send, Track.planLimit Feature.colors model.erd ] )

        MoveColumn column position ->
            model
                |> mapErdMTM
                    (\erd ->
                        erd
                            |> Erd.mapCurrentLayoutTWithTime now
                                (mapTablesT
                                    (List.mapByTE .id
                                        column.table
                                        (mapColumnsT
                                            (ErdColumnProps.mapAtTE
                                                (column.column |> ColumnPath.parent)
                                                (\cols ->
                                                    (cols |> List.findIndexBy .name (column.column |> Nel.last))
                                                        |> Maybe.filter (\pos -> pos /= position)
                                                        |> Maybe.map (\pos -> ( cols |> List.moveIndex pos position, Extra.history ( MoveColumn column pos, msg ) ))
                                                        |> Maybe.withDefault ( cols, Extra.none )
                                                )
                                            )
                                        )
                                    )
                                )
                    )
                |> setDirtyM

        HoverTable ( table, col ) on ->
            ( model |> setHoverTable (B.cond on (Just ( table, col )) (col |> Maybe.map (\_ -> ( table, Nothing )))) |> mapErdM (\e -> e |> Erd.mapCurrentLayoutWithTime now (mapTables (hoverColumn ( table, col ) on e))), Extra.none )

        HoverTableRow ( table, col ) on ->
            ( model |> setHoverTableRow (B.cond on (Just ( table, col )) (col |> Maybe.map (\_ -> ( table, Nothing )))), Extra.none )

        CreateUserSource name ->
            ( model, SourceId.generator |> Random.generate (Source.aml name now >> CreateUserSourceWithId) |> Extra.cmd )

        CreateUserSourceWithId source ->
            ( model
                |> mapErdM (Erd.mapSources (List.insert source))
                |> (\newModel -> newModel |> mapAmlSidebarM (AmlSidebar.setSource (newModel.erd |> Maybe.andThen (.sources >> List.last))))
                |> AmlSidebar.setOtherSourcesTableIdsCache (Just source.id)
            , Extra.history ( Batch [ ProjectSettingsMsg (PSSourceDelete source.id), AmlSidebarMsg (AChangeSource (model.amlSidebar |> Maybe.andThen (.selected >> Maybe.map Tuple.first))) ], msg )
            )
                |> setDirty

        CreateRelations rels ->
            model |> mapErdMT (Source.createRelations now rels) |> setDirtyM

        RemoveRelations_ source rels ->
            model |> mapErdMT (Source.deleteRelations source rels) |> setDirtyM

        IgnoreRelation col ->
            model |> mapErdMT (Erd.mapIgnoredRelationsT (Dict.updateT col.table (\cols -> ( cols |> Maybe.mapOrElse (List.insert col.column) [ col.column ] >> List.uniqueBy ColumnPath.toString >> Just, Extra.history ( UnIgnoreRelation_ col, msg ) )))) |> Extra.defaultT

        UnIgnoreRelation_ col ->
            model |> mapErdMT (Erd.mapIgnoredRelationsT (Dict.updateT col.table (\cols -> ( cols |> Maybe.map (List.filter (\c -> c /= col.column)), Extra.history ( IgnoreRelation col, msg ) )))) |> Extra.defaultT

        NewLayoutMsg message ->
            model |> NewLayout.update NewLayoutMsg Batch ModalOpen Toast CustomModalOpen (LLoad "" >> LayoutMsg) (LDelete >> LayoutMsg) now projectRef message

        LayoutMsg message ->
            model |> handleLayout message

        FitToScreen ->
            model |> mapErdMT (fitCanvas model.erdElem) |> Extra.defaultT

        SetView_ canvas ->
            model |> mapErdMTM (Erd.mapCurrentLayoutTWithTime now (mapCanvasT (\c -> ( canvas, Extra.history ( SetView_ c, SetView_ canvas ) )))) |> Extra.defaultT

        ArrangeTables ->
            model |> mapErdMT (arrangeTables now model.erdElem) |> Extra.defaultT

        SetLayout_ layout ->
            model |> mapErdMTM (Erd.mapCurrentLayoutT (\l -> ( layout, Extra.new (Ports.observeLayout layout) ( SetLayout_ l, SetLayout_ layout ) ))) |> setDirtyM

        GroupMsg message ->
            model |> handleGroups now projectRef message

        NotesMsg message ->
            model |> handleNotes message

        TagsMsg message ->
            model |> handleTags message

        MemoMsg message ->
            model |> handleMemo now urlInfos message

        ShowTableRow source query previous hint from ->
            (model.erd |> Maybe.andThen (Erd.currentLayout >> .tableRows >> List.find (\r -> r.source == source.id && r.table == query.table && r.primaryKey == query.primaryKey)))
                |> Maybe.map (\r -> model |> mapErdMT (moveToTableRow now model.erdElem r) |> Extra.defaultT)
                |> Maybe.withDefault (model |> mapErdMT (showTableRow now source query previous hint from) |> setDirtyM)

        DeleteTableRow id ->
            model |> mapErdMTM (Erd.mapCurrentLayoutTWithTime now (deleteTableRow id)) |> setDirtyM

        UnDeleteTableRow_ index tableRow ->
            model |> mapErdMTM (Erd.mapCurrentLayoutTWithTime now (unDeleteTableRow index tableRow)) |> setDirtyM

        TableRowMsg id message ->
            model |> mapErdMTM (\e -> e |> Erd.mapCurrentLayoutTWithTime now (mapTableRowsT (mapTableRowOrSelected id message (TableRow.update (TableRowMsg id) DropdownToggle Toast (DeleteTableRow id) (UnDeleteTableRow_ 0) now e.project e.sources model.openedDropdown message)))) |> setDirtyM

        AmlSidebarMsg message ->
            model |> AmlSidebar.update now message

        DetailsSidebarMsg message ->
            model.erd |> Maybe.mapOrElse (\erd -> model |> mapDetailsSidebarT (DetailsSidebar.update Noop NotesMsg TagsMsg erd message)) ( model, Extra.none )

        DataExplorerMsg message ->
            model.erd |> Maybe.mapOrElse (\erd -> model |> mapDataExplorerT (DataExplorer.update DataExplorerMsg Toast (LlmGenerateSqlDialog.Open >> LlmGenerateSqlDialogMsg) erd.project erd.sources message)) ( model, Extra.none )

        VirtualRelationMsg message ->
            model |> handleVirtualRelation message

        FindPathMsg message ->
            model |> handleFindPath message

        LlmGenerateSqlDialogMsg message ->
            model.erd |> Maybe.mapOrElse (\erd -> model |> mapLlmGenerateSqlT (LlmGenerateSqlDialog.update ModalOpen PromptOpen (PSLlmKeyUpdate >> ProjectSettingsMsg) erd message)) ( model, Extra.none )

        SchemaAnalysisMsg SAOpen ->
            ( model |> setSchemaAnalysis (Just { id = Conf.ids.schemaAnalysisDialog, opened = "" }), Extra.cmdL [ T.sendAfter 1 (ModalOpen Conf.ids.schemaAnalysisDialog), Track.dbAnalysisOpened model.erd ] )

        SchemaAnalysisMsg (SASectionToggle section) ->
            ( model |> mapSchemaAnalysisM (mapOpened (\opened -> B.cond (opened == section) "" section)), Extra.none )

        SchemaAnalysisMsg SAClose ->
            ( model |> setSchemaAnalysis Nothing, Extra.none )

        ExportDialogMsg message ->
            model.erd |> Maybe.mapOrElse (\erd -> model |> mapExportDialogT (ExportDialog.update ExportDialogMsg ModalOpen projectRef erd message)) ( model, Extra.none )

        SharingMsg message ->
            model |> mapSharingT (ProjectSharing.update SharingMsg ModalOpen Toast zone now projectRef model.erd message)

        ProjectSaveMsg message ->
            model |> mapSaveT (ProjectSaveDialog.update ModalOpen message)

        ProjectSettingsMsg message ->
            model |> handleProjectSettings now message

        EmbedSourceParsingMsg message ->
            model |> mapEmbedSourceParsingMT (EmbedSourceParsingDialog.update EmbedSourceParsingMsg now (model.erd |> Maybe.map .project) message) |> Extra.defaultT

        SourceParsed source ->
            ( model, source |> Project.create projects source.name |> Ok |> Just |> GotProject "load" |> JsMessage |> Extra.msg )

        PlanDialogColors _ PlanDialog.EnableTableChangeColor ->
            ( model |> mapErdM (mapProject (mapOrganizationM (mapPlan (setColors True)))), Ports.fireworks |> Extra.cmd )

        PlanDialogColors state message ->
            state |> PlanDialog.colorsUpdate PlanDialogColors message |> Tuple.mapFirst (\s -> model |> mapModalMF (setContentF (PlanDialog.colorsModalBody projectRef PlanDialogColors s)))

        HelpMsg message ->
            model |> handleHelp message

        CursorMode mode ->
            ( model |> setCursorMode mode, Extra.none )

        Fullscreen id ->
            ( model, Ports.fullscreen id |> Extra.cmd )

        OnWheel event ->
            model |> mapErdMTM (Erd.mapCurrentLayoutTWithTime now (mapCanvasT (handleWheel event model.erdElem))) |> setDirtyM |> squashViewHistory

        Zoom delta ->
            model |> mapErdMTM (Erd.mapCurrentLayoutTWithTime now (mapCanvasT (zoomCanvas delta model.erdElem))) |> setDirtyM |> squashViewHistory

        Focus id ->
            ( model, Ports.focus id |> Extra.cmd )

        DropdownToggle id ->
            ( model |> Dropdown.update id, Extra.none )

        DropdownOpen id ->
            ( model |> setOpenedDropdown id, Extra.none )

        DropdownClose ->
            ( model |> setOpenedDropdown "", Extra.none )

        PopoverOpen id ->
            ( model |> setOpenedPopover id, Extra.none )

        ContextMenuCreate content event ->
            ( model |> setContextMenu (Just { content = content, position = event.clientPos, show = False }), ContextMenuShow |> T.sendAfter 1 |> Extra.cmd )

        ContextMenuShow ->
            ( model |> mapContextMenuM (setShow True), Extra.none )

        ContextMenuClose ->
            ( model |> setContextMenu Nothing, Extra.none )

        DragStart id pos ->
            model.dragging
                |> Maybe.mapOrElse (\d -> ( model, "Already dragging " ++ d.id |> Toasts.info |> Toast |> Extra.msg ))
                    ({ id = id, init = pos, last = pos } |> (\d -> model |> setDragging (Just d) |> handleDrag now d False False))

        DragMove pos ->
            model.dragging
                |> Maybe.map (setLast pos)
                |> Maybe.mapOrElse (\d -> model |> setDragging (Just d) |> handleDrag now d False False) ( model, Extra.none )

        DragEnd cancel pos ->
            model.dragging
                |> Maybe.map (setLast pos)
                |> Maybe.mapOrElse (\d -> model |> setDragging Nothing |> handleDrag now d True cancel) ( model, Extra.none )

        DragCancel ->
            ( model |> setDragging Nothing, Extra.none )

        Toast message ->
            model |> mapToastsT (Toasts.update Toast message)

        ConfirmOpen confirm ->
            ( model |> setConfirm (Just { id = Conf.ids.confirmDialog, content = confirm }), ModalOpen Conf.ids.confirmDialog |> T.sendAfter 1 |> Extra.cmd )

        ConfirmAnswer answer cmd ->
            ( model |> setConfirm Nothing, B.cond answer (Extra.cmd cmd) Extra.none )

        PromptOpen prompt input ->
            ( model |> setPrompt (Just { id = Conf.ids.promptDialog, content = prompt, input = input }), ModalOpen Conf.ids.promptDialog |> T.sendAfter 1 |> Extra.cmd )

        PromptUpdate input ->
            ( model |> mapPromptM (setInput input), Extra.none )

        PromptAnswer cmd ->
            ( model |> setPrompt Nothing, Extra.cmd cmd )

        ModalOpen id ->
            ( model |> mapOpenedDialogs (\dialogs -> id :: dialogs), Ports.autofocusWithin id |> Extra.cmd )

        ModalClose message ->
            ( model |> mapOpenedDialogs (List.drop 1), message |> T.sendAfter Conf.ui.closeDuration |> Extra.cmd )

        CustomModalOpen content ->
            ( model |> setModal (Just { id = Conf.ids.customDialog, content = content }), ModalOpen Conf.ids.customDialog |> T.sendAfter 1 |> Extra.cmd )

        CustomModalClose ->
            ( model |> setModal Nothing, Extra.none )

        Undo ->
            case model.history of
                [] ->
                    ( model, "Can't undo, action history is empty" |> Toasts.info |> Toast |> Extra.msg )

                ( back, next ) :: history ->
                    update urlLayout zone now urlInfos organizations projects back { model | history = history, future = ( back, next ) :: model.future } |> Tuple.mapSecond Extra.dropHistory

        Redo ->
            case model.future of
                [] ->
                    ( model, "Can't redo, no future action" |> Toasts.info |> Toast |> Extra.msg )

                ( back, next ) :: future ->
                    update urlLayout zone now urlInfos organizations projects next { model | history = ( back, next ) :: model.history, future = future } |> Tuple.mapSecond Extra.dropHistory

        JsMessage message ->
            model |> handleJsMessage now urlLayout message |> Tuple.mapSecond Extra.cmd

        Batch messages ->
            messages |> List.foldl (\curMsg ( curModel, curExtra ) -> update urlLayout zone now urlInfos organizations projects curMsg curModel |> Tuple.mapSecond (Extra.combine curExtra)) ( model, Extra.none )

        Send cmd ->
            ( model, Extra.cmd cmd )

        Noop _ ->
            ( model, Extra.none )


handleJsMessage : Time.Posix -> Maybe LayoutName -> JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage now urlLayout msg model =
    case msg of
        GotSizes sizes ->
            model |> updateSizes sizes

        GotProject context res ->
            case res of
                Nothing ->
                    ( { model | loaded = True, saving = False }, Cmd.none )

                Just (Err err) ->
                    ( { model | loaded = True, saving = False }, Cmd.batch [ "Unable to read project: " ++ Decode.errorToHtml err |> Toasts.error |> Toast |> T.send, Track.jsonError "decode-project" err ] )

                Just (Ok project) ->
                    { model | saving = False } |> updateErd urlLayout context project

        ProjectDeleted _ ->
            -- handled in Shared
            ( model, Cmd.none )

        GotLocalFile kind file content ->
            if kind == SqlSource.kind then
                ( model, SourceId.generator |> Random.generate (\sourceId -> SqlSource.GotLocalFile sourceId file content |> SourceUpdateDialog.SqlSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg) )

            else if kind == PrismaSource.kind then
                ( model, SourceId.generator |> Random.generate (\sourceId -> PrismaSource.GotLocalFile sourceId file content |> SourceUpdateDialog.PrismaSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg) )

            else if kind == JsonSource.kind then
                ( model, SourceId.generator |> Random.generate (\sourceId -> JsonSource.GotLocalFile sourceId file content |> SourceUpdateDialog.JsonSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg) )

            else
                ( model, "Unhandled local file kind '" ++ kind ++ "'" |> Toasts.error |> Toast |> T.send )

        GotDatabaseSchema schema ->
            if model.embedSourceParsing == Nothing then
                ( model, Ok schema |> DatabaseSource.GotSchema |> SourceUpdateDialog.DatabaseSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg |> T.send )

            else
                ( model, Ok schema |> DatabaseSource.GotSchema |> EmbedSourceParsingDialog.EmbedDatabaseSource |> EmbedSourceParsingMsg |> T.send )

        GotDatabaseSchemaError error ->
            if model.embedSourceParsing == Nothing then
                ( model, Err error |> DatabaseSource.GotSchema |> SourceUpdateDialog.DatabaseSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg |> T.send )

            else
                ( model, Err error |> DatabaseSource.GotSchema |> EmbedSourceParsingDialog.EmbedDatabaseSource |> EmbedSourceParsingMsg |> T.send )

        GotTableStats source stats ->
            ( { model | tableStats = model.tableStats |> Dict.update stats.id (Maybe.withDefault Dict.empty >> Dict.insert (SourceId.toString source) (Ok stats) >> Just) }, Cmd.none )

        GotTableStatsError source table error ->
            ( { model | tableStats = model.tableStats |> Dict.update table (Maybe.withDefault Dict.empty >> Dict.insert (SourceId.toString source) (Err error) >> Just) }, Cmd.none )

        GotColumnStats source stats ->
            ( { model | columnStats = model.columnStats |> Dict.update stats.id (Maybe.withDefault Dict.empty >> Dict.insert (SourceId.toString source) (Ok stats) >> Just) }, Cmd.none )

        GotColumnStatsError source column error ->
            ( { model | columnStats = model.columnStats |> Dict.update (ColumnId.fromRef column) (Maybe.withDefault Dict.empty >> Dict.insert (SourceId.toString source) (Err error) >> Just) }, Cmd.none )

        GotDatabaseQueryResult result ->
            model |> handleDatabaseQueryResponse result

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
            if model.saving then
                ( model, Cmd.none )

            else
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
            ( model, ShowTable id (hint |> Maybe.map PlaceAt) "port" |> T.send )

        GotTableHide id ->
            ( model, HideTable id |> T.send )

        GotTableToggleColumns id ->
            ( model, ToggleTableCollapse id |> T.send )

        GotTablePosition id pos ->
            ( model, TablePosition id pos |> T.send )

        GotTableMove id delta ->
            ( model, TableMove id delta |> T.send )

        GotTableSelect id ->
            ( model, SelectItem (TableId.toHtmlId id) False |> T.send )

        GotTableColor id color ->
            ( model, TableColor id color True |> T.send )

        GotColumnShow ref ->
            ( model, ShowColumn 1000 ref |> T.send )

        GotColumnHide ref ->
            ( model, HideColumn ref |> T.send )

        GotColumnMove ref index ->
            ( model, MoveColumn ref index |> T.send )

        GotFitToScreen ->
            ( model, FitToScreen |> T.send )

        GotLlmSqlGenerated query ->
            ( model, Ok query |> LlmGenerateSqlBody.SqlGenerated |> LlmGenerateSqlDialog.BodyMsg |> LlmGenerateSqlDialogMsg |> T.send )

        GotLlmSqlGeneratedError err ->
            ( model, Err err |> LlmGenerateSqlBody.SqlGenerated |> LlmGenerateSqlDialog.BodyMsg |> LlmGenerateSqlDialogMsg |> T.send )

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
                        e |> fitCanvas newModel.erdElem |> Extra.unpackT

                    else if e.layoutOnLoad == "arrange" then
                        e |> arrangeTables Time.zero newModel.erdElem |> Extra.unpackT

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
    -- FIXME: auto-layout is too ugly :/
    --if erd.currentLayout == Conf.constants.defaultLayout && (erd |> Erd.currentLayout |> ErdLayout.isEmpty) && Dict.size erd.tables < Conf.constants.fewTablesLimit then
    --    erd
    --        |> Erd.mapCurrentLayout (setTables (erd.tables |> Dict.values |> List.map (\t -> t |> ErdTableLayout.init erd.settings Set.empty (erd.relationsByTable |> Dict.getOrElse t.id []) erd.settings.collapseTableColumns Nothing)))
    --        |> setLayoutOnLoad "arrange"
    --else
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
