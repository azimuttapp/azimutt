module PagesComponents.Projects.Id_.Updates.Hotkey exposing (handleHotkey)

import Conf
import Libs.Task as T
import PagesComponents.App.Updates.Helpers exposing (setActive, setNavbar, setSearch)
import PagesComponents.Projects.Id_.Models exposing (Model, Msg, toastInfo, toastWarning)
import Ports exposing (blur, focus, mouseDown, scroll)


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
            ( model, T.send (toastInfo ("Hotkey " ++ hotkey)) )

        "save" ->
            ( model, T.send (toastInfo ("Hotkey " ++ hotkey)) )

        "move-forward" ->
            ( model, T.send (toastInfo ("Hotkey " ++ hotkey)) )

        "move-backward" ->
            ( model, T.send (toastInfo ("Hotkey " ++ hotkey)) )

        "move-to-top" ->
            ( model, T.send (toastInfo ("Hotkey " ++ hotkey)) )

        "move-to-back" ->
            ( model, T.send (toastInfo ("Hotkey " ++ hotkey)) )

        "select-all" ->
            ( model, T.send (toastInfo ("Hotkey " ++ hotkey)) )

        "save-layout" ->
            ( model, T.send (toastInfo ("Hotkey " ++ hotkey)) )

        "find-path" ->
            ( model, T.send (toastInfo ("Hotkey " ++ hotkey)) )

        "create-virtual-relation" ->
            ( model, T.send (toastInfo ("Hotkey " ++ hotkey)) )

        "undo" ->
            ( model, T.send (toastInfo ("Hotkey " ++ hotkey)) )

        "redo" ->
            ( model, T.send (toastInfo ("Hotkey " ++ hotkey)) )

        "cancel" ->
            ( model, T.send (toastInfo ("Hotkey " ++ hotkey)) )

        "help" ->
            ( model, T.send (toastInfo ("Hotkey " ++ hotkey)) )

        _ ->
            ( model, T.send (toastWarning ("Unhandled hotkey '" ++ hotkey ++ "'")) )
