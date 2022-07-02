module PagesComponents.Projects.Id_.Updates.Hotkey exposing (handleHotkey)

import Conf
import Libs.Delta exposing (Delta)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Task as T
import Libs.Tuple as Tuple
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Projects.Id_.Components.ProjectUploadDialog as ProjectUploadDialog
import PagesComponents.Projects.Id_.Models exposing (AmlSidebarMsg(..), FindPathMsg(..), HelpMsg(..), LayoutMsg(..), Model, Msg(..), NotesMsg(..), ProjectSettingsMsg(..), SchemaAnalysisMsg(..), SharingMsg(..), VirtualRelationMsg(..), resetCanvas)
import PagesComponents.Projects.Id_.Models.Erd as Erd
import PagesComponents.Projects.Id_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Projects.Id_.Models.Notes as NoteRef
import Ports
import Services.Lenses exposing (mapActive, mapErdM, mapNavbar, mapProps, mapSearch, mapTables, setSelected)
import Services.Toasts as Toasts
import Time


handleHotkey : Time.Posix -> Model -> String -> ( Model, Cmd Msg )
handleHotkey now model hotkey =
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

        "remove" ->
            ( model, removeElement model )

        "save" ->
            ( model, T.send SaveProject )

        "move-up" ->
            ( model, moveTables { dx = 0, dy = -1 } model )

        "move-right" ->
            ( model, moveTables { dx = 1, dy = 0 } model )

        "move-down" ->
            ( model, moveTables { dx = 0, dy = 1 } model )

        "move-left" ->
            ( model, moveTables { dx = -1, dy = 0 } model )

        "move-up-big" ->
            ( model, moveTables { dx = 0, dy = -10 } model )

        "move-right-big" ->
            ( model, moveTables { dx = 10, dy = 0 } model )

        "move-down-big" ->
            ( model, moveTables { dx = 0, dy = 10 } model )

        "move-left-big" ->
            ( model, moveTables { dx = -10, dy = 0 } model )

        "move-forward" ->
            ( model, moveTablesOrder 1 model )

        "move-backward" ->
            ( model, moveTablesOrder -1 model )

        "move-to-top" ->
            ( model, moveTablesOrder 1000 model )

        "move-to-back" ->
            ( model, moveTablesOrder -1000 model )

        "select-all" ->
            ( model |> mapErdM (Erd.mapCurrentLayout now (mapTables (List.map (mapProps (setSelected True))))), Cmd.none )

        "save-layout" ->
            ( model, T.send (LayoutMsg LOpen) )

        "create-virtual-relation" ->
            ( model, T.send (VirtualRelationMsg (model.virtualRelation |> Maybe.mapOrElse (\_ -> VRCancel) VRCreate)) )

        "find-path" ->
            ( model, T.send (FindPathMsg (model.findPath |> Maybe.mapOrElse (\_ -> FPClose) (FPOpen model.hoverTable Nothing))) )

        "reset-zoom" ->
            ( model, T.send (Zoom (1 - (model.erd |> Maybe.mapOrElse (Erd.currentLayout >> .canvas >> .zoom) 0))) )

        "fit-to-screen" ->
            ( model, T.send FitContent )

        "undo" ->
            -- FIXME
            ( model, Toasts.info Toast "Undo action not handled yet" )

        "redo" ->
            -- FIXME
            ( model, Toasts.info Toast "Redo action not handled yet" )

        "cancel" ->
            ( model, cancelElement model )

        "help" ->
            ( model, T.send (HelpMsg (model.help |> Maybe.mapOrElse (\_ -> HClose) (HOpen ""))) )

        _ ->
            ( model, Toasts.warning Toast ("Unhandled hotkey '" ++ hotkey ++ "'") )


notesElement : Model -> Cmd Msg
notesElement model =
    (model |> currentColumn |> Maybe.map (NoteRef.fromColumn >> NOpen >> NotesMsg >> T.send))
        |> Maybe.orElse (model |> currentTable |> Maybe.map (NoteRef.fromTable >> NOpen >> NotesMsg >> T.send))
        |> Maybe.withDefault (Toasts.info Toast "Can't find an element to collapse :(")


collapseElement : Model -> Cmd Msg
collapseElement model =
    (model |> currentTable |> Maybe.map (ToggleColumns >> T.send))
        |> Maybe.withDefault (Toasts.info Toast "Can't find an element to collapse :(")


expandElement : Model -> Cmd Msg
expandElement model =
    (model |> currentTable |> Maybe.map (ShowRelatedTables >> T.send))
        |> Maybe.withDefault (Toasts.info Toast "Can't find an element to expand :(")


shrinkElement : Model -> Cmd Msg
shrinkElement model =
    (model |> currentTable |> Maybe.map (HideRelatedTables >> T.send))
        |> Maybe.withDefault (Toasts.info Toast "Can't find an element to shrink :(")


removeElement : Model -> Cmd Msg
removeElement model =
    (model |> currentColumn |> Maybe.map (HideColumn >> T.send))
        |> Maybe.orElse (model |> currentTable |> Maybe.map (HideTable >> T.send))
        |> Maybe.orElse (model.erd |> Maybe.filter Erd.canResetCanvas |> Maybe.map (\_ -> resetCanvas |> T.send))
        |> Maybe.withDefault (Toasts.info Toast "Can't find an element to remove :(")


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
        |> Maybe.orElse (model.amlSidebar |> Maybe.map (\_ -> AmlSidebarMsg AClose))
        |> Maybe.orElse (model.findPath |> Maybe.map (\_ -> ModalClose (FindPathMsg FPClose)))
        |> Maybe.orElse (model.schemaAnalysis |> Maybe.map (\_ -> ModalClose (SchemaAnalysisMsg SAClose)))
        |> Maybe.orElse (model.sourceUpload |> Maybe.map (\_ -> ModalClose (ProjectSettingsMsg PSSourceUploadClose)))
        |> Maybe.orElse (model.sharing |> Maybe.map (\_ -> ModalClose (SharingMsg SClose)))
        |> Maybe.orElse (model.upload |> Maybe.map (\_ -> ModalClose (ProjectUploadDialogMsg ProjectUploadDialog.Close)))
        |> Maybe.orElse (model.settings |> Maybe.map (\_ -> ModalClose (ProjectSettingsMsg PSClose)))
        |> Maybe.orElse (model.help |> Maybe.map (\_ -> ModalClose (HelpMsg HClose)))
        |> Maybe.orElse (model.erd |> Maybe.andThen (Erd.currentLayout >> .tables >> List.find (.props >> .selected)) |> Maybe.map (\p -> SelectTable p.id False))
        |> Maybe.map T.send
        |> Maybe.withDefault (Toasts.info Toast "Nothing to cancel")


moveTables : Delta -> Model -> Cmd Msg
moveTables delta model =
    let
        selectedTables : List ErdTableLayout
        selectedTables =
            model.erd |> Maybe.mapOrElse (Erd.currentLayout >> .tables >> List.filter (.props >> .selected)) []
    in
    if List.nonEmpty selectedTables then
        Cmd.batch (selectedTables |> List.map (\t -> T.send (TableMove t.id delta)))

    else
        Cmd.none


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
            |> Maybe.withDefault (Toasts.info Toast "Can't find an element to move :(")
