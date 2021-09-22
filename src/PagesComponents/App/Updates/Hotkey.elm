module PagesComponents.App.Updates.Hotkey exposing (handleHotkey)

import Conf exposing (conf)
import Libs.Task exposing (send)
import PagesComponents.App.Models exposing (Model, Msg(..), VirtualRelationMsg(..))
import PagesComponents.App.Updates exposing (moveTable, removeElement)
import Ports exposing (click, saveProject, showModal, toastInfo, toastWarning, track)
import Tracking exposing (events)


handleHotkey : Model -> String -> List (Cmd Msg)
handleHotkey model hotkey =
    case hotkey of
        "focus-search" ->
            [ click conf.ids.searchInput ]

        "remove" ->
            [ removeElement model.hover ]

        "move-forward" ->
            model.project |> Maybe.map (\p -> p.schema.layout) |> Maybe.map (\l -> [ moveTable 1 model.hover l ]) |> Maybe.withDefault []

        "move-backward" ->
            model.project |> Maybe.map (\p -> p.schema.layout) |> Maybe.map (\l -> [ moveTable -1 model.hover l ]) |> Maybe.withDefault []

        "move-to-top" ->
            model.project |> Maybe.map (\p -> p.schema.layout) |> Maybe.map (\l -> [ moveTable 1000 model.hover l ]) |> Maybe.withDefault []

        "move-to-back" ->
            model.project |> Maybe.map (\p -> p.schema.layout) |> Maybe.map (\l -> [ moveTable -1000 model.hover l ]) |> Maybe.withDefault []

        "select-all" ->
            [ send SelectAllTables ]

        "find-path" ->
            [ send (FindPath Nothing Nothing) ]

        "create-virtual-relation" ->
            [ send (VirtualRelationMsg Create) ]

        "save" ->
            model.project
                |> Maybe.map (\p -> [ saveProject p, toastInfo "Project saved", track (events.updateProject p) ])
                |> Maybe.withDefault [ toastWarning "No project to save" ]

        "cancel" ->
            model.virtualRelation |> Maybe.map (\_ -> [ send (VirtualRelationMsg Cancel) ]) |> Maybe.withDefault []

        "help" ->
            [ showModal conf.ids.helpModal ]

        other ->
            [ toastInfo ("Shortcut <b>" ++ other ++ "</b> is not implemented yet :(") ]
