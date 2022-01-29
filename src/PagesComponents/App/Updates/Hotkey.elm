module PagesComponents.App.Updates.Hotkey exposing (handleHotkey)

import Conf
import Libs.Maybe as M
import Libs.Task exposing (send)
import PagesComponents.App.Models exposing (FindPathMsg(..), Model, Msg(..), VirtualRelationMsg(..))
import PagesComponents.App.Updates exposing (moveTable, removeElement)
import Ports
import Track


handleHotkey : Model -> String -> List (Cmd Msg)
handleHotkey model hotkey =
    case hotkey of
        "search-open" ->
            [ Ports.click Conf.ids.searchInput ]

        "remove" ->
            [ removeElement model.hover ]

        "move-forward" ->
            model.project |> Maybe.map .layout |> M.mapOrElse (\l -> [ moveTable 1 model.hover l ]) []

        "move-backward" ->
            model.project |> Maybe.map .layout |> M.mapOrElse (\l -> [ moveTable -1 model.hover l ]) []

        "move-to-top" ->
            model.project |> Maybe.map .layout |> M.mapOrElse (\l -> [ moveTable 1000 model.hover l ]) []

        "move-to-back" ->
            model.project |> Maybe.map .layout |> M.mapOrElse (\l -> [ moveTable -1000 model.hover l ]) []

        "select-all" ->
            [ send SelectAllTables ]

        "find-path" ->
            [ send (FindPathMsg (FPInit Nothing Nothing)) ]

        "create-virtual-relation" ->
            [ send (VirtualRelationMsg VRCreate) ]

        "save" ->
            model.project
                |> M.mapOrElse (\p -> [ Ports.saveProject p, Ports.toastInfo "Project saved", Ports.track (Track.updateProject p) ])
                    [ Ports.toastWarning "No project to save" ]

        "cancel" ->
            model.virtualRelation |> M.mapOrElse (\_ -> [ send (VirtualRelationMsg VRCancel) ]) []

        "help" ->
            [ Ports.showModal Conf.ids.helpDialog ]

        other ->
            [ Ports.toastInfo ("Shortcut <b>" ++ other ++ "</b> is not implemented yet :(") ]
