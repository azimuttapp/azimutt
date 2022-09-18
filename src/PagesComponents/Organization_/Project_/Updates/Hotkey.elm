module PagesComponents.Organization_.Project_.Updates.Hotkey exposing (handleHotkey)

import Conf
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.Delta exposing (Delta)
import Libs.Task as T
import Libs.Tuple as Tuple
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Organization_.Project_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Organization_.Project_.Components.ProjectSaveDialog as ProjectSaveDialog
import PagesComponents.Organization_.Project_.Components.SourceUpdateDialog as SourceUpdateDialog
import PagesComponents.Organization_.Project_.Models exposing (AmlSidebarMsg(..), FindPathMsg(..), HelpMsg(..), LayoutMsg(..), Model, Msg(..), NotesMsg(..), ProjectSettingsMsg(..), SchemaAnalysisMsg(..), SharingMsg(..), VirtualRelationMsg(..))
import PagesComponents.Organization_.Project_.Models.Erd as Erd
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.Notes as NoteRef
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
            ( model, T.send TriggerSaveProject )

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
            ( model, T.send SelectAllTables )

        "create-layout" ->
            ( model, LOpen Nothing |> LayoutMsg |> T.send )

        "create-virtual-relation" ->
            ( model, T.send (VirtualRelationMsg (model.virtualRelation |> Maybe.mapOrElse (\_ -> VRCancel) (VRCreate (model |> currentColumn)))) )

        "find-path" ->
            ( model, T.send (FindPathMsg (model.findPath |> Maybe.mapOrElse (\_ -> FPClose) (FPOpen model.hoverTable Nothing))) )

        "reset-zoom" ->
            ( model, T.send (Zoom (1 - (model.erd |> Maybe.mapOrElse (Erd.currentLayout >> .canvas >> .zoom) 0))) )

        "fit-to-screen" ->
            ( model, T.send FitContent )

        "undo" ->
            -- FIXME
            ( model, "Undo action not handled yet" |> Toasts.info |> Toast |> T.send )

        "redo" ->
            -- FIXME
            ( model, "Redo action not handled yet" |> Toasts.info |> Toast |> T.send )

        "cancel" ->
            ( model, cancelElement model )

        "help" ->
            ( model, T.send (HelpMsg (model.help |> Maybe.mapOrElse (\_ -> HClose) (HOpen ""))) )

        _ ->
            ( model, "Unhandled hotkey '" ++ hotkey ++ "'" |> Toasts.warning |> Toast |> T.send )


notesElement : Model -> Cmd Msg
notesElement model =
    (model |> currentColumn |> Maybe.map (NoteRef.fromColumn >> NOpen >> NotesMsg >> T.send))
        |> Maybe.orElse (model |> currentTable |> Maybe.map (NoteRef.fromTable >> NOpen >> NotesMsg >> T.send))
        |> Maybe.withDefault ("Can't find an element to collapse :(" |> Toasts.info |> Toast |> T.send)


collapseElement : Model -> Cmd Msg
collapseElement model =
    (model |> currentTable |> Maybe.map (ToggleColumns >> T.send))
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
    (model |> currentColumn |> Maybe.map (ShowColumn >> T.send))
        |> Maybe.orElse (model |> currentTable |> Maybe.map (\t -> ShowTable t Nothing |> T.send))
        |> Maybe.withDefault ("Can't find an element to show :(" |> Toasts.info |> Toast |> T.send)


hideElement : Model -> Cmd Msg
hideElement model =
    (model |> currentColumn |> Maybe.map (HideColumn >> T.send))
        |> Maybe.orElse (model |> currentTable |> Maybe.map (HideTable >> T.send))
        |> Maybe.withDefault ("Can't find an element to hide :(" |> Toasts.info |> Toast |> T.send)


currentTable : Model -> Maybe TableId
currentTable model =
    model.hoverTable |> Maybe.orElse (model.erd |> Maybe.andThen (Erd.currentLayout >> .tables >> List.find (.props >> .selected) >> Maybe.map .id))


currentColumn : Model -> Maybe ColumnRef
currentColumn model =
    model.hoverColumn


cancelElement : Model -> Cmd Msg
cancelElement model =
    (model.contextMenu |> Maybe.map (\_ -> ContextMenuClose))
        |> Maybe.orElse (model.confirm |> Maybe.map (\c -> ModalClose (ConfirmAnswer False c.content.onConfirm)))
        |> Maybe.orElse (model.prompt |> Maybe.map (\_ -> ModalClose (PromptAnswer Cmd.none)))
        |> Maybe.orElse (model.virtualRelation |> Maybe.map (\_ -> VirtualRelationMsg VRCancel))
        |> Maybe.orElse (model.dragging |> Maybe.map (\_ -> DragCancel))
        |> Maybe.orElse (model.newLayout |> Maybe.map (\_ -> ModalClose (LayoutMsg LCancel)))
        |> Maybe.orElse (model.editNotes |> Maybe.map (\_ -> ModalClose (NotesMsg NCancel)))
        |> Maybe.orElse (model.save |> Maybe.map (\_ -> ModalClose (ProjectSaveMsg ProjectSaveDialog.Close)))
        |> Maybe.orElse (model.schemaAnalysis |> Maybe.map (\_ -> ModalClose (SchemaAnalysisMsg SAClose)))
        |> Maybe.orElse (model.amlSidebar |> Maybe.map (\_ -> AmlSidebarMsg AClose))
        |> Maybe.orElse (model.findPath |> Maybe.map (\_ -> ModalClose (FindPathMsg FPClose)))
        |> Maybe.orElse (model.sourceUpdate |> Maybe.map (\_ -> ModalClose (SourceUpdateDialog.Close |> PSSourceUpdate |> ProjectSettingsMsg)))
        |> Maybe.orElse (model.sharing |> Maybe.map (\_ -> ModalClose (SharingMsg SClose)))
        |> Maybe.orElse (model.settings |> Maybe.map (\_ -> ModalClose (ProjectSettingsMsg PSClose)))
        |> Maybe.orElse (model.help |> Maybe.map (\_ -> ModalClose (HelpMsg HClose)))
        |> Maybe.orElse (model.erd |> Maybe.andThen (Erd.currentLayout >> .tables >> List.find (.props >> .selected)) |> Maybe.map (\p -> SelectTable p.id False))
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
        (\view -> view.column.next |> Maybe.map (\col -> { table = view.table.item.id, column = col.name } |> DetailsSidebar.ShowColumn))


prevDetails : Model -> Maybe (Cmd Msg)
prevDetails model =
    onDetails model
        (\view -> view.schema.prev |> Maybe.map DetailsSidebar.ShowSchema)
        (\view -> view.table.prev |> Maybe.map (.id >> DetailsSidebar.ShowTable))
        (\view -> view.column.prev |> Maybe.map (\col -> { table = view.table.item.id, column = col.name } |> DetailsSidebar.ShowColumn))


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
