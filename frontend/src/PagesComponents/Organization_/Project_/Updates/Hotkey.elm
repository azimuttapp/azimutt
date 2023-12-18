module PagesComponents.Organization_.Project_.Updates.Hotkey exposing (handleHotkey)

import Components.Organisms.TableRow as TableRow
import Components.Slices.DataExplorer as DataExplorer
import Components.Slices.DataExplorerQuery as DataExplorerQuery
import Components.Slices.NewLayoutBody as NewLayoutBody
import Conf
import Libs.Bool as Bool
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.Delta exposing (Delta)
import Libs.Task as T
import Libs.Tuple as Tuple
import Models.Area as Area
import Models.Project.CanvasProps as CanvasProps
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableRow as TableRow exposing (TableRow, TableRowColumn)
import PagesComponents.Organization_.Project_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Organization_.Project_.Components.ExportDialog as ExportDialog
import PagesComponents.Organization_.Project_.Components.ProjectSaveDialog as ProjectSaveDialog
import PagesComponents.Organization_.Project_.Components.ProjectSharing as ProjectSharing
import PagesComponents.Organization_.Project_.Components.SourceUpdateDialog as SourceUpdateDialog
import PagesComponents.Organization_.Project_.Models exposing (AmlSidebarMsg(..), FindPathMsg(..), GroupMsg(..), HelpMsg(..), MemoMsg(..), Model, Msg(..), ProjectSettingsMsg(..), SchemaAnalysisMsg(..), VirtualRelationMsg(..))
import PagesComponents.Organization_.Project_.Models.Erd as Erd
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.MemoId as MemoId exposing (MemoId)
import PagesComponents.Organization_.Project_.Models.NotesMsg exposing (NotesMsg(..))
import PagesComponents.Organization_.Project_.Views.Modals.NewLayout as NewLayout
import Ports
import Services.Lenses exposing (mapActive, mapNavbar, mapSearch)
import Services.Toasts as Toasts
import Time


handleHotkey : Time.Posix -> Model -> String -> ( Model, Cmd Msg )
handleHotkey _ model hotkey =
    case hotkey of
        "search-open" ->
            ( model, Ports.focus Conf.ids.searchInput )

        "search-up" ->
            ( model |> mapNavbar (mapSearch (mapActive (\a -> a - 1))), Ports.scrollTo (Conf.ids.searchInput ++ "-active-item") "end" )

        "search-down" ->
            ( model |> mapNavbar (mapSearch (mapActive (\a -> a + 1))), Ports.scrollTo (Conf.ids.searchInput ++ "-active-item") "end" )

        "search-confirm" ->
            ( model, Cmd.batch [ Ports.mouseDown (Conf.ids.searchInput ++ "-active-item"), Ports.blur Conf.ids.searchInput ] )

        "notes" ->
            ( model, notesElement model )

        "new-memo" ->
            ( model, createMemo model )

        "create-group" ->
            ( model, createGroup model )

        "collapse" ->
            ( model, collapseElement model )

        "expand" ->
            ( model, expandElement model )

        "shrink" ->
            ( model, shrinkElement model )

        "show" ->
            ( model, showElement model )

        "hide" ->
            ( model, hideElement model )

        "save" ->
            if model.conf.save then
                ( model, T.send TriggerSaveProject )

            else
                ( model, "Can't save in read-only mode" |> Toasts.warning |> Toast |> T.send )

        "move-up" ->
            ( model, model |> moveTables { dx = 0, dy = -10 } |> Maybe.orElse (model |> upDetails) |> Maybe.withDefault Cmd.none )

        "move-right" ->
            ( model, model |> moveTables { dx = 10, dy = 0 } |> Maybe.orElse (model |> nextDetails) |> Maybe.withDefault Cmd.none )

        "move-down" ->
            ( model, model |> moveTables { dx = 0, dy = 10 } |> Maybe.withDefault Cmd.none )

        "move-left" ->
            ( model, model |> moveTables { dx = -10, dy = 0 } |> Maybe.orElse (model |> prevDetails) |> Maybe.withDefault Cmd.none )

        "move-forward" ->
            ( model, moveTablesOrder 1 model )

        "move-backward" ->
            ( model, moveTablesOrder -1 model )

        "move-to-top" ->
            ( model, moveTablesOrder 1000 model )

        "move-to-back" ->
            ( model, moveTablesOrder -1000 model )

        "select-all" ->
            ( model, T.send SelectAll )

        "create-layout" ->
            ( model, NewLayoutBody.Create |> NewLayout.Open |> NewLayoutMsg |> T.send )

        "create-virtual-relation" ->
            ( model, T.send (VirtualRelationMsg (model.virtualRelation |> Maybe.mapOrElse (\_ -> VRCancel) (VRCreate (model |> currentColumn)))) )

        "find-path" ->
            ( model, T.send (FindPathMsg (model.findPath |> Maybe.mapOrElse (\_ -> FPClose) (FPOpen model.hoverTable Nothing))) )

        "reset-zoom" ->
            ( model, T.send (Zoom (1 - (model.erd |> Maybe.mapOrElse (Erd.currentLayout >> .canvas >> .zoom) 0))) )

        "fit-to-screen" ->
            ( model, T.send FitToScreen )

        "undo" ->
            -- TODO: implement undo
            ( model, "Undo action not handled yet" |> Toasts.info |> Toast |> T.send )

        "redo" ->
            -- TODO: implement redo
            ( model, "Redo action not handled yet" |> Toasts.info |> Toast |> T.send )

        "cancel" ->
            ( model, cancelElement model )

        "help" ->
            ( model, T.send (HelpMsg (model.help |> Maybe.mapOrElse (\_ -> HClose) (HOpen ""))) )

        _ ->
            ( model, "Unhandled hotkey '" ++ hotkey ++ "'" |> Toasts.warning |> Toast |> T.send )


notesElement : Model -> Cmd Msg
notesElement model =
    (model |> currentColumnRow |> Maybe.andThen (getColumnRow model) |> Maybe.map (\( r, c ) -> NOpen r.table (Just c.path) |> NotesMsg |> T.send))
        |> Maybe.orElse (model |> currentTableRow |> Maybe.andThen (getTableRow model) |> Maybe.map (\r -> NOpen r.table Nothing |> NotesMsg |> T.send))
        |> Maybe.orElse (model |> currentColumn |> Maybe.map (\r -> NOpen r.table (Just r.column) |> NotesMsg |> T.send))
        |> Maybe.orElse (model |> currentTable |> Maybe.map (\r -> NOpen r Nothing |> NotesMsg |> T.send))
        |> Maybe.withDefault ("Can't find an element with notes :(" |> Toasts.info |> Toast |> T.send)


createMemo : Model -> Cmd Msg
createMemo model =
    model.erd |> Maybe.mapOrElse (\erd -> erd |> Erd.currentLayout |> .canvas |> CanvasProps.viewport model.erdElem |> Area.centerCanvas |> MCreate |> MemoMsg |> T.send) Cmd.none


createGroup : Model -> Cmd Msg
createGroup model =
    model.erd |> Maybe.mapOrElse (\erd -> erd |> Erd.currentLayout |> .tables |> List.filter (\t -> t.props.selected) |> List.map .id |> GCreate |> GroupMsg |> T.send) Cmd.none


collapseElement : Model -> Cmd Msg
collapseElement model =
    (model |> currentTableRow |> Maybe.andThen (getTableRow model) |> Maybe.map (\r -> Bool.cond r.collapsed TableRow.Expand TableRow.Collapse |> TableRowMsg r.id |> T.send))
        |> Maybe.orElse (model |> currentTable |> Maybe.map (ToggleTableCollapse >> T.send))
        |> Maybe.withDefault ("Can't find an element to collapse :(" |> Toasts.info |> Toast |> T.send)


expandElement : Model -> Cmd Msg
expandElement model =
    (model |> currentTable |> Maybe.map (ShowRelatedTables >> T.send))
        |> Maybe.withDefault ("Can't find an element to expand :(" |> Toasts.info |> Toast |> T.send)


shrinkElement : Model -> Cmd Msg
shrinkElement model =
    (model |> currentTable |> Maybe.map (HideRelatedTables >> T.send))
        |> Maybe.withDefault ("Can't find an element to shrink :(" |> Toasts.info |> Toast |> T.send)


showElement : Model -> Cmd Msg
showElement model =
    (model |> currentColumnRow |> Maybe.map (\( id, col ) -> TableRow.ShowColumn (ColumnPath.toString col) |> TableRowMsg id |> T.send))
        |> Maybe.orElse (model |> currentColumn |> Maybe.map (ShowColumn >> T.send))
        |> Maybe.orElse (model |> currentTable |> Maybe.map (\t -> ShowTable t Nothing "hotkey" |> T.send))
        |> Maybe.withDefault ("Can't find an element to show :(" |> Toasts.info |> Toast |> T.send)


hideElement : Model -> Cmd Msg
hideElement model =
    (model |> currentColumnRow |> Maybe.map (\( id, col ) -> TableRow.HideColumn (ColumnPath.toString col) |> TableRowMsg id |> T.send))
        |> Maybe.orElse (model |> currentTableRow |> Maybe.map (DeleteTableRow >> T.send))
        |> Maybe.orElse (model |> currentColumn |> Maybe.map (HideColumn >> T.send))
        |> Maybe.orElse (model |> currentTable |> Maybe.map (HideTable >> T.send))
        |> Maybe.orElse (model |> selectedItems |> Maybe.map (\( tables, rows, memos ) -> Cmd.batch ((tables |> List.map (HideTable >> T.send)) ++ (rows |> List.map (DeleteTableRow >> T.send)) ++ (memos |> List.map (MDelete >> MemoMsg >> T.send)))))
        |> Maybe.withDefault ("Can't find an element to hide :(" |> Toasts.info |> Toast |> T.send)


currentTable : Model -> Maybe TableId
currentTable model =
    model.hoverTable


currentColumn : Model -> Maybe ColumnRef
currentColumn model =
    model.hoverColumn


currentColumnRow : Model -> Maybe ( TableRow.Id, ColumnPath )
currentColumnRow model =
    model.hoverTableRow |> Maybe.andThen (\( id, col ) -> col |> Maybe.map (\c -> ( id, c )))


selectedItems : Model -> Maybe ( List TableId, List TableRow.Id, List MemoId )
selectedItems model =
    model.erd
        |> Maybe.map Erd.currentLayout
        |> Maybe.map
            (\l ->
                ( l.tables |> List.filter (.props >> .selected) |> List.map .id
                , l.tableRows |> List.filter .selected |> List.map .id
                , l.memos |> List.filter .selected |> List.map .id
                )
            )
        |> Maybe.filter (\( tables, rows, memos ) -> List.nonEmpty tables || List.nonEmpty rows || List.nonEmpty memos)


currentTableRow : Model -> Maybe TableRow.Id
currentTableRow model =
    model.hoverTableRow |> Maybe.map Tuple.first


getTableRow : Model -> TableRow.Id -> Maybe TableRow
getTableRow model id =
    model.erd |> Maybe.andThen (Erd.currentLayout >> .tableRows >> List.findBy .id id)


getColumnRow : Model -> ( TableRow.Id, ColumnPath ) -> Maybe ( TableRow, TableRowColumn )
getColumnRow model ( id, col ) =
    getTableRow model id |> Maybe.andThen (\r -> r |> TableRow.stateSuccess |> Maybe.andThen (.columns >> List.findBy .path col) |> Maybe.map (\v -> ( r, v )))


cancelElement : Model -> Cmd Msg
cancelElement model =
    -- FIXME: keep a list of cancel actions so they can be canceled in order, but they need to be removed when not cancelable anymore :/
    (model.contextMenu |> Maybe.map (\_ -> ContextMenuClose))
        |> Maybe.orElse (model.confirm |> Maybe.map (\c -> ModalClose (ConfirmAnswer False c.content.onConfirm)))
        |> Maybe.orElse (model.prompt |> Maybe.map (\_ -> ModalClose (PromptAnswer Cmd.none)))
        |> Maybe.orElse (model.modal |> Maybe.map (\_ -> ModalClose CustomModalClose))
        |> Maybe.orElse (model.virtualRelation |> Maybe.map (\_ -> VirtualRelationMsg VRCancel))
        |> Maybe.orElse (model.dragging |> Maybe.map (\_ -> DragCancel))
        |> Maybe.orElse (model.exportDialog |> Maybe.map (\_ -> ModalClose (ExportDialogMsg ExportDialog.Close)))
        |> Maybe.orElse (model.newLayout |> Maybe.map (\_ -> ModalClose (NewLayoutMsg NewLayout.Cancel)))
        |> Maybe.orElse (model.editNotes |> Maybe.map (\_ -> ModalClose (NotesMsg NCancel)))
        |> Maybe.orElse (model.save |> Maybe.map (\_ -> ModalClose (ProjectSaveMsg ProjectSaveDialog.Close)))
        |> Maybe.orElse (model.schemaAnalysis |> Maybe.map (\_ -> ModalClose (SchemaAnalysisMsg SAClose)))
        |> Maybe.orElse (model.findPath |> Maybe.map (\_ -> ModalClose (FindPathMsg FPClose)))
        |> Maybe.orElse (model.sourceUpdate |> Maybe.map (\_ -> ModalClose (SourceUpdateDialog.Close |> PSSourceUpdate |> ProjectSettingsMsg)))
        |> Maybe.orElse (model.sharing |> Maybe.map (\_ -> ModalClose (SharingMsg ProjectSharing.Close)))
        |> Maybe.orElse (model.help |> Maybe.map (\_ -> ModalClose (HelpMsg HClose)))
        |> Maybe.orElse (model.settings |> Maybe.map (\_ -> ModalClose (ProjectSettingsMsg PSClose)))
        |> Maybe.orElse (model.erd |> Maybe.andThen (Erd.currentLayout >> .tables >> List.find (.props >> .selected)) |> Maybe.map (\t -> SelectItem (TableId.toHtmlId t.id) False))
        |> Maybe.orElse (model.erd |> Maybe.andThen (Erd.currentLayout >> .tableRows >> List.find .selected) |> Maybe.map (\r -> SelectItem (TableRow.toHtmlId r.id) False))
        |> Maybe.orElse (model.erd |> Maybe.andThen (Erd.currentLayout >> .memos >> List.find .selected) |> Maybe.map (\m -> SelectItem (MemoId.toHtmlId m.id) False))
        |> Maybe.orElse
            (model.dataExplorer.display
                |> Maybe.map
                    (\_ ->
                        (model.dataExplorer.details |> List.head |> Maybe.map (\d -> DataExplorer.CloseDetails d.id))
                            |> Maybe.orElse (model.dataExplorer.results |> List.find (DataExplorerQuery.stateSuccess >> Maybe.mapOrElse .fullScreen False) |> Maybe.map (\r -> DataExplorerQuery.ToggleFullScreen |> DataExplorer.QueryMsg r.id))
                            |> Maybe.withDefault DataExplorer.Close
                            |> DataExplorerMsg
                    )
            )
        |> Maybe.orElse (model.detailsSidebar |> Maybe.map (\_ -> DetailsSidebarMsg DetailsSidebar.Close))
        |> Maybe.orElse (model.amlSidebar |> Maybe.map (\_ -> AmlSidebarMsg AClose))
        |> Maybe.map T.send
        |> Maybe.withDefault ("Nothing to cancel" |> Toasts.info |> Toast |> T.send)


moveTables : Delta -> Model -> Maybe (Cmd Msg)
moveTables delta model =
    let
        selectedTables : List ErdTableLayout
        selectedTables =
            model.erd |> Maybe.mapOrElse (Erd.currentLayout >> .tables >> List.filter (.props >> .selected)) []
    in
    if List.nonEmpty selectedTables then
        Cmd.batch (selectedTables |> List.map (\t -> T.send (TableMove t.id delta))) |> Just

    else
        Nothing


nextDetails : Model -> Maybe (Cmd Msg)
nextDetails model =
    onDetails model
        (\view -> view.schema.next |> Maybe.map DetailsSidebar.ShowSchema)
        (\view -> view.table.next |> Maybe.map (.id >> DetailsSidebar.ShowTable))
        (\view -> view.column.next |> Maybe.map (\col -> { table = view.table.item.id, column = col.path } |> DetailsSidebar.ShowColumn))


prevDetails : Model -> Maybe (Cmd Msg)
prevDetails model =
    onDetails model
        (\view -> view.schema.prev |> Maybe.map DetailsSidebar.ShowSchema)
        (\view -> view.table.prev |> Maybe.map (.id >> DetailsSidebar.ShowTable))
        (\view -> view.column.prev |> Maybe.map (\col -> { table = view.table.item.id, column = col.path } |> DetailsSidebar.ShowColumn))


upDetails : Model -> Maybe (Cmd Msg)
upDetails model =
    onDetails model
        (\_ -> DetailsSidebar.ShowList |> Just)
        (\view -> view.table.item.schema |> DetailsSidebar.ShowSchema |> Just)
        (\view -> view.table.item.id |> DetailsSidebar.ShowTable |> Just)


onDetails : Model -> (DetailsSidebar.SchemaData -> Maybe DetailsSidebar.Msg) -> (DetailsSidebar.TableData -> Maybe DetailsSidebar.Msg) -> (DetailsSidebar.ColumnData -> Maybe DetailsSidebar.Msg) -> Maybe (Cmd Msg)
onDetails model onSchema onTable onColumn =
    model.detailsSidebar
        |> Maybe.andThen
            (\d ->
                case d.view of
                    DetailsSidebar.ListView ->
                        Nothing

                    DetailsSidebar.SchemaView view ->
                        onSchema view

                    DetailsSidebar.TableView view ->
                        onTable view

                    DetailsSidebar.ColumnView view ->
                        onColumn view
            )
        |> Maybe.map (DetailsSidebarMsg >> T.send)


moveTablesOrder : Int -> Model -> Cmd Msg
moveTablesOrder delta model =
    let
        tables : List ErdTableLayout
        tables =
            model.erd |> Maybe.mapOrElse (Erd.currentLayout >> .tables) []

        selectedTables : List ( Int, ErdTableLayout )
        selectedTables =
            tables |> List.indexedMap Tuple.new |> List.filter (\( _, t ) -> t.props.selected)
    in
    if List.nonEmpty selectedTables then
        Cmd.batch (selectedTables |> List.map (\( i, t ) -> T.send (TableOrder t.id (List.length tables - 1 - i + delta))))

    else
        (model.hoverTable
            |> Maybe.andThen (\id -> tables |> List.findIndexBy .id id |> Maybe.map (\i -> ( id, i )))
            |> Maybe.map (\( id, i ) -> T.send (TableOrder id (List.length tables - 1 - i + delta)))
        )
            |> Maybe.withDefault ("Can't find an element to move :(" |> Toasts.info |> Toast |> T.send)
