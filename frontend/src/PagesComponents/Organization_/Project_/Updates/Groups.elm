module PagesComponents.Organization_.Project_.Updates.Groups exposing (Model, handleGroups)

import Browser.Dom as Dom
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Task as T
import Models.Project.Group as Group exposing (Group)
import PagesComponents.Organization_.Project_.Models exposing (GroupEdit, GroupMsg(..), Msg(..), NotesDialog)
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirty, setDirtyCmd)
import Services.Lenses exposing (mapEditGroupM, mapErdM, mapGroups, mapTables, setColor, setContent, setEditGroup, setName)
import Services.Toasts as Toasts
import Task
import Time
import Track


type alias Model x =
    { x
        | conf : ErdConf
        , dirty : Bool
        , erd : Maybe Erd
        , editGroup : Maybe GroupEdit
    }


handleGroups : Time.Posix -> GroupMsg -> Model x -> ( Model x, Cmd Msg )
handleGroups now msg model =
    case msg of
        GCreate tables ->
            ( model |> mapErdM (Erd.mapCurrentLayoutWithTime now (\l -> l |> mapGroups (List.add (Group.init tables)))), Track.groupCreated model.erd ) |> setDirtyCmd

        GEdit index name ->
            ( model |> setEditGroup (Just { index = index, content = name }), index |> Group.toInputId |> Dom.focus |> Task.attempt (\_ -> Noop "focus-group-input") )

        GEditUpdate name ->
            ( model |> mapEditGroupM (setContent name), Cmd.none )

        GEditSave ->
            model.editGroup |> Maybe.mapOrElse (\edit -> model |> saveGroup now edit) ( model, "No group to save" |> Toasts.create "warning" |> Toast |> T.send )

        GSetColor index color ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapGroups (List.mapAt index (setColor color)))) |> setDirty

        GAddTables index tables ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapGroups (List.mapAt index (mapTables (List.append tables))))) |> setDirty

        GRemoveTables index tables ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapGroups (List.mapAt index (mapTables (List.removeAll tables))))) |> setDirty

        GDelete index ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapGroups (List.removeAt index))) |> setDirty


saveGroup : Time.Posix -> GroupEdit -> Model x -> ( Model x, Cmd Msg )
saveGroup now edit model =
    let
        groupName : String
        groupName =
            model.erd |> Maybe.andThen (\erd -> erd |> Erd.currentLayout |> .groups |> List.get edit.index) |> Maybe.mapOrElse .name ""
    in
    if edit.content == groupName then
        -- no change, don't save
        ( model |> setEditGroup Nothing, Cmd.none )

    else
        ( model |> setEditGroup Nothing |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapGroups (List.mapAt edit.index (setName edit.content)))), Track.groupRenamed edit.content model.erd ) |> setDirtyCmd
