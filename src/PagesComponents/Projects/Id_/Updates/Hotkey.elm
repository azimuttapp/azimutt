module PagesComponents.Projects.Id_.Updates.Hotkey exposing (handleHotkey)

import Conf
import Libs.List as L
import Libs.Maybe as M
import Libs.Task as T
import Models.Project.TableProps exposing (TableProps)
import PagesComponents.App.Updates.Helpers exposing (setActive, setCurrentLayout, setNavbar, setSearch, setTables)
import PagesComponents.Projects.Id_.Models exposing (LayoutMsg(..), Model, Msg(..), VirtualRelationMsg(..), toastInfo, toastWarning)
import Ports exposing (blur, focus, mouseDown, saveProject, scroll, track)
import Tracking


handleHotkey : Model -> String -> ( Model, Cmd Msg )
handleHotkey model hotkey =
    case hotkey of
        "search-open" ->
            ( model, focus Conf.ids.searchInput )

        "search-close" ->
            ( model, blur Conf.ids.searchInput )

        "search-up" ->
            ( model |> setNavbar (setSearch (setActive (\a -> a - 1))), scroll (Conf.ids.searchInput ++ "-active") "end" )

        "search-down" ->
            ( model |> setNavbar (setSearch (setActive (\a -> a + 1))), scroll (Conf.ids.searchInput ++ "-active") "end" )

        "search-confirm" ->
            ( model, Cmd.batch [ mouseDown (Conf.ids.searchInput ++ "-active"), blur Conf.ids.searchInput ] )

        "remove" ->
            ( model, removeElement model )

        "save" ->
            ( model, Cmd.batch (model.project |> M.mapOrElse (\p -> [ saveProject p, T.send (toastInfo "Project saved"), track (Tracking.events.updateProject p) ]) [ T.send (toastWarning "No project to save") ]) )

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
            -- FIXME
            ( model, T.send (toastInfo ("Hotkey " ++ hotkey)) )

        "undo" ->
            -- FIXME
            ( model, T.send (toastInfo ("Hotkey " ++ hotkey)) )

        "redo" ->
            -- FIXME
            ( model, T.send (toastInfo ("Hotkey " ++ hotkey)) )

        "cancel" ->
            ( model, cancelElement model )

        "help" ->
            ( model, T.send (toastInfo ("Hotkey " ++ hotkey)) )

        _ ->
            ( model, T.send (toastWarning ("Unhandled hotkey '" ++ hotkey ++ "'")) )


removeElement : Model -> Cmd Msg
removeElement model =
    (model.hoverColumn |> Maybe.map (HideColumn >> T.send))
        |> M.orElse (model.hoverTable |> Maybe.map (HideTable >> T.send))
        |> Maybe.withDefault (T.send (toastInfo "Can't find an element to remove :("))


cancelElement : Model -> Cmd Msg
cancelElement model =
    T.send
        ((model.confirm |> Maybe.map (\c -> ModalClose (ConfirmAnswer False c.onConfirm)))
            |> M.orElse (model.newLayout |> Maybe.map (\_ -> ModalClose (LayoutMsg LCancel)))
            |> M.orElse (model.dragging |> Maybe.map (\_ -> DragCancel))
            |> M.orElse (model.virtualRelation |> Maybe.map (\_ -> VirtualRelationMsg VRCancel))
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
