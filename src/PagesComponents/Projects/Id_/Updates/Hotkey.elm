module PagesComponents.Projects.Id_.Updates.Hotkey exposing (handleHotkey)

import Conf
import Libs.List as L
import Libs.Maybe as M
import Libs.Task as T
import Models.Project.TableProps exposing (TableProps)
import PagesComponents.Projects.Id_.Models exposing (FindPathMsg(..), HelpMsg(..), LayoutMsg(..), Model, Msg(..), ProjectSettingsMsg(..), VirtualRelationMsg(..), resetCanvas, toastInfo, toastWarning)
import Ports
import Services.Lenses exposing (setActive, setCurrentLayout, setNavbar, setSearch, setTables)


handleHotkey : Model -> String -> ( Model, Cmd Msg )
handleHotkey model hotkey =
    case hotkey of
        "search-open" ->
            ( model, Ports.focus Conf.ids.searchInput )

        "search-up" ->
            ( model |> setNavbar (setSearch (setActive (\a -> a - 1))), Ports.scrollTo (Conf.ids.searchInput ++ "-active") "end" )

        "search-down" ->
            ( model |> setNavbar (setSearch (setActive (\a -> a + 1))), Ports.scrollTo (Conf.ids.searchInput ++ "-active") "end" )

        "search-confirm" ->
            ( model, Cmd.batch [ Ports.mouseDown (Conf.ids.searchInput ++ "-active"), Ports.blur Conf.ids.searchInput ] )

        "remove" ->
            ( model, removeElement model )

        "save" ->
            ( model, T.send SaveProject )

        "move-forward" ->
            ( model, moveTables 1 model )

        "move-backward" ->
            ( model, moveTables -1 model )

        "move-to-top" ->
            ( model, moveTables 1000 model )

        "move-to-back" ->
            ( model, moveTables -1000 model )

        "select-all" ->
            ( model |> setCurrentLayout (setTables (List.map (\t -> { t | selected = True }))), Cmd.none )

        "save-layout" ->
            ( model, T.send (LayoutMsg LOpen) )

        "create-virtual-relation" ->
            ( model, T.send (VirtualRelationMsg (model.virtualRelation |> M.mapOrElse (\_ -> VRCancel) VRCreate)) )

        "find-path" ->
            ( model, T.send (FindPathMsg (model.findPath |> M.mapOrElse (\_ -> FPClose) (FPOpen model.hoverTable Nothing))) )

        "undo" ->
            -- FIXME
            ( model, T.send (toastInfo "Undo action not handled yet") )

        "redo" ->
            -- FIXME
            ( model, T.send (toastInfo "Redo action not handled yet") )

        "cancel" ->
            ( model, cancelElement model )

        "help" ->
            ( model, T.send (HelpMsg (model.help |> M.mapOrElse (\_ -> HClose) (HOpen ""))) )

        _ ->
            ( model, T.send (toastWarning ("Unhandled hotkey '" ++ hotkey ++ "'")) )


removeElement : Model -> Cmd Msg
removeElement model =
    (model.hoverColumn |> Maybe.map (HideColumn >> T.send))
        |> M.orElse (model.hoverTable |> Maybe.map (HideTable >> T.send))
        |> M.orElse (model.project |> M.filter (\p -> p.layout.tables /= []) |> Maybe.map (\_ -> resetCanvas |> T.send))
        |> Maybe.withDefault (T.send (toastInfo "Can't find an element to remove :("))


cancelElement : Model -> Cmd Msg
cancelElement model =
    T.send
        ((model.confirm |> Maybe.map (\c -> ModalClose (ConfirmAnswer False c.content.onConfirm)))
            |> M.orElse (model.newLayout |> Maybe.map (\_ -> ModalClose (LayoutMsg LCancel)))
            |> M.orElse (model.dragging |> Maybe.map (\_ -> DragCancel))
            |> M.orElse (model.virtualRelation |> Maybe.map (\_ -> VirtualRelationMsg VRCancel))
            |> M.orElse (model.findPath |> Maybe.map (\_ -> ModalClose (FindPathMsg FPClose)))
            |> M.orElse (model.sourceUpload |> Maybe.map (\_ -> ModalClose (ProjectSettingsMsg PSSourceUploadClose)))
            |> M.orElse (model.settings |> Maybe.map (\_ -> ModalClose (ProjectSettingsMsg PSClose)))
            |> M.orElse (model.help |> Maybe.map (\_ -> ModalClose (HelpMsg HClose)))
            |> Maybe.withDefault (toastInfo "Nothing to cancel")
        )


moveTables : Int -> Model -> Cmd Msg
moveTables delta model =
    let
        tables : List TableProps
        tables =
            model.project |> M.mapOrElse (\p -> p.layout.tables) []

        selectedTables : List ( Int, TableProps )
        selectedTables =
            tables |> List.indexedMap (\i t -> ( i, t )) |> List.filter (\( _, t ) -> t.selected)
    in
    if L.nonEmpty selectedTables then
        Cmd.batch (selectedTables |> List.map (\( i, t ) -> T.send (TableOrder t.id (List.length tables - 1 - i + delta))))

    else
        (model.hoverTable
            |> Maybe.andThen (\id -> tables |> L.findIndexBy .id id |> Maybe.map (\i -> ( id, i )))
            |> Maybe.map (\( id, i ) -> T.send (TableOrder id (List.length tables - 1 - i + delta)))
        )
            |> Maybe.withDefault (T.send (toastInfo "Can't find an element to move :("))
