module PagesComponents.Projects.Id_.Updates.Hotkey exposing (handleHotkey)

import Conf
import Dict
import Libs.Delta exposing (Delta)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Task as T
import PagesComponents.Projects.Id_.Models exposing (FindPathMsg(..), HelpMsg(..), LayoutMsg(..), Model, Msg(..), NotesMsg(..), ProjectSettingsMsg(..), SchemaAnalysisMsg(..), SharingMsg(..), VirtualRelationMsg(..), resetCanvas, toastInfo, toastWarning)
import PagesComponents.Projects.Id_.Models.ErdTableProps as ErdTableProps exposing (ErdTableProps)
import Ports
import Services.Lenses exposing (mapActive, mapErdM, mapNavbar, mapSearch, mapTableProps)


handleHotkey : Model -> String -> ( Model, Cmd Msg )
handleHotkey model hotkey =
    case hotkey of
        "search-open" ->
            ( model, Ports.focus Conf.ids.searchInput )

        "search-up" ->
            ( model |> mapNavbar (mapSearch (mapActive (\a -> a - 1))), Ports.scrollTo (Conf.ids.searchInput ++ "-active-item") "end" )

        "search-down" ->
            ( model |> mapNavbar (mapSearch (mapActive (\a -> a + 1))), Ports.scrollTo (Conf.ids.searchInput ++ "-active-item") "end" )

        "search-confirm" ->
            ( model, Cmd.batch [ Ports.mouseDown (Conf.ids.searchInput ++ "-active-item"), Ports.blur Conf.ids.searchInput ] )

        "collapse" ->
            ( model, collapseElement model )

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
            ( model |> mapErdM (mapTableProps (Dict.map (\_ -> ErdTableProps.setSelected True))), Cmd.none )

        "save-layout" ->
            ( model, T.send (LayoutMsg LOpen) )

        "create-virtual-relation" ->
            ( model, T.send (VirtualRelationMsg (model.virtualRelation |> Maybe.mapOrElse (\_ -> VRCancel) VRCreate)) )

        "find-path" ->
            ( model, T.send (FindPathMsg (model.findPath |> Maybe.mapOrElse (\_ -> FPClose) (FPOpen model.hoverTable Nothing))) )

        "reset-zoom" ->
            ( model, T.send (Zoom (1 - (model.erd |> Maybe.mapOrElse (\erd -> erd.canvas.zoom) 0))) )

        "fit-to-screen" ->
            ( model, T.send FitContent )

        "undo" ->
            -- FIXME
            ( model, T.send (toastInfo "Undo action not handled yet") )

        "redo" ->
            -- FIXME
            ( model, T.send (toastInfo "Redo action not handled yet") )

        "cancel" ->
            ( model, cancelElement model )

        "help" ->
            ( model, T.send (HelpMsg (model.help |> Maybe.mapOrElse (\_ -> HClose) (HOpen ""))) )

        _ ->
            ( model, T.send (toastWarning ("Unhandled hotkey '" ++ hotkey ++ "'")) )


collapseElement : Model -> Cmd Msg
collapseElement model =
    (model.hoverTable |> Maybe.map (ToggleColumns >> T.send))
        |> Maybe.withDefault (T.send (toastInfo "Can't find an element to collapse :("))


removeElement : Model -> Cmd Msg
removeElement model =
    (model.hoverColumn |> Maybe.map (HideColumn >> T.send))
        |> Maybe.orElse (model.hoverTable |> Maybe.map (HideTable >> T.send))
        |> Maybe.orElse (model.erd |> Maybe.filter (\e -> e.shownTables |> List.nonEmpty) |> Maybe.map (\_ -> resetCanvas |> T.send))
        |> Maybe.withDefault (T.send (toastInfo "Can't find an element to remove :("))


cancelElement : Model -> Cmd Msg
cancelElement model =
    T.send
        ((model.contextMenu |> Maybe.map (\_ -> ContextMenuClose))
            |> Maybe.orElse (model.confirm |> Maybe.map (\c -> ModalClose (ConfirmAnswer False c.content.onConfirm)))
            |> Maybe.orElse (model.newLayout |> Maybe.map (\_ -> ModalClose (LayoutMsg LCancel)))
            |> Maybe.orElse (model.editNotes |> Maybe.map (\_ -> ModalClose (NotesMsg NCancel)))
            |> Maybe.orElse (model.dragging |> Maybe.map (\_ -> DragCancel))
            |> Maybe.orElse (model.virtualRelation |> Maybe.map (\_ -> VirtualRelationMsg VRCancel))
            |> Maybe.orElse (model.findPath |> Maybe.map (\_ -> ModalClose (FindPathMsg FPClose)))
            |> Maybe.orElse (model.schemaAnalysis |> Maybe.map (\_ -> ModalClose (SchemaAnalysisMsg SAClose)))
            |> Maybe.orElse (model.sourceUpload |> Maybe.map (\_ -> ModalClose (ProjectSettingsMsg PSSourceUploadClose)))
            |> Maybe.orElse (model.sharing |> Maybe.map (\_ -> ModalClose (SharingMsg SClose)))
            |> Maybe.orElse (model.settings |> Maybe.map (\_ -> ModalClose (ProjectSettingsMsg PSClose)))
            |> Maybe.orElse (model.help |> Maybe.map (\_ -> ModalClose (HelpMsg HClose)))
            |> Maybe.orElse (model.erd |> Maybe.andThen (\e -> e.tableProps |> Dict.values |> List.find (\p -> p.selected)) |> Maybe.map (\p -> SelectTable p.id False))
            |> Maybe.withDefault (toastInfo "Nothing to cancel")
        )


moveTables : Delta -> Model -> Cmd Msg
moveTables delta model =
    let
        selectedTables : List ErdTableProps
        selectedTables =
            model.erd |> Maybe.mapOrElse (\e -> e.shownTables |> List.filterMap (\id -> e.tableProps |> Dict.get id) |> List.filter .selected) []
    in
    if List.nonEmpty selectedTables then
        Cmd.batch (selectedTables |> List.map (\t -> T.send (TableMove t.id delta)))

    else
        Cmd.none


moveTablesOrder : Int -> Model -> Cmd Msg
moveTablesOrder delta model =
    let
        tables : List ErdTableProps
        tables =
            model.erd |> Maybe.mapOrElse (\e -> e.shownTables |> List.filterMap (\id -> e.tableProps |> Dict.get id)) []

        selectedTables : List ( Int, ErdTableProps )
        selectedTables =
            tables |> List.indexedMap (\i t -> ( i, t )) |> List.filter (\( _, t ) -> t.selected)
    in
    if List.nonEmpty selectedTables then
        Cmd.batch (selectedTables |> List.map (\( i, t ) -> T.send (TableOrder t.id (List.length tables - 1 - i + delta))))

    else
        (model.hoverTable
            |> Maybe.andThen (\id -> tables |> List.findIndexBy .id id |> Maybe.map (\i -> ( id, i )))
            |> Maybe.map (\( id, i ) -> T.send (TableOrder id (List.length tables - 1 - i + delta)))
        )
            |> Maybe.withDefault (T.send (toastInfo "Can't find an element to move :("))
