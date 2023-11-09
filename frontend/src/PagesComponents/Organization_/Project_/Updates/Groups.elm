module PagesComponents.Organization_.Project_.Updates.Groups exposing (Model, handleGroups)

import Browser.Dom as Dom
import Components.Slices.ProPlan as ProPlan
import Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Tailwind as Tw exposing (Color)
import Libs.Task as T
import Libs.Url exposing (UrlPath)
import Models.Project.Group as Group exposing (Group)
import Models.Project.TableId exposing (TableId)
import Models.ProjectRef exposing (ProjectRef)
import Models.UrlInfos exposing (UrlInfos)
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


handleGroups : Time.Posix -> UrlPath -> UrlInfos -> GroupMsg -> Model x -> ( Model x, Cmd Msg )
handleGroups now basePath urlInfos msg model =
    case msg of
        GCreate tables ->
            model |> createGroup now basePath urlInfos tables

        GEdit index name ->
            ( model |> setEditGroup (Just { index = index, content = name }), index |> Group.toInputId |> Dom.focus |> Task.attempt (\_ -> Noop "focus-group-input") )

        GEditUpdate name ->
            ( model |> mapEditGroupM (setContent name), Cmd.none )

        GEditSave ->
            model.editGroup |> Maybe.mapOrElse (\edit -> model |> saveGroup now edit) ( model, "No group to save" |> Toasts.create "warning" |> Toast |> T.send )

        GSetColor index color ->
            model |> setGroupColor now basePath urlInfos index color

        GAddTables index tables ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapGroups (List.mapAt index (mapTables (List.append tables))))) |> setDirty

        GRemoveTables index tables ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapGroups (List.mapAt index (mapTables (List.removeAll tables))))) |> setDirty

        GDelete index ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapGroups (List.removeAt index))) |> setDirty


createGroup : Time.Posix -> UrlPath -> UrlInfos -> List TableId -> Model x -> ( Model x, Cmd Msg )
createGroup now basePath urlInfos tables model =
    if tables |> List.isEmpty then
        ( model, Cmd.none )

    else if model.erd |> Erd.canCreateGroup then
        ( model |> mapErdM (Erd.mapCurrentLayoutWithTime now (\l -> l |> mapGroups (List.add (Group.init tables (groupColor l tables))))), Track.groupCreated model.erd ) |> setDirtyCmd

    else
        ( model, model.erd |> Maybe.mapOrElse (\erd -> Cmd.batch [ erd |> Erd.getProjectRef urlInfos |> ProPlan.groupsModalBody basePath |> CustomModalOpen |> T.send, Track.planLimit .groups (Just erd) ]) Cmd.none )


groupColor : ErdLayout -> List TableId -> Color
groupColor layout tableIds =
    layout.tables
        |> List.filter (\t -> tableIds |> List.member t.id)
        |> List.map (.props >> .color)
        |> List.groupBy Tw.toString
        |> Dict.toList
        |> List.filterMap (\( _, colors ) -> colors |> List.head |> Maybe.map (\color -> ( color, colors |> List.length )))
        |> List.sortBy (Tuple.second >> negate)
        |> List.head
        |> Maybe.mapOrElse Tuple.first Tw.indigo


setGroupColor : Time.Posix -> UrlPath -> UrlInfos -> Int -> Color -> Model x -> ( Model x, Cmd Msg )
setGroupColor now basePath urlInfos index color model =
    let
        project : ProjectRef
        project =
            model.erd |> Erd.getProjectRefM urlInfos
    in
    if model.erd |> Erd.canChangeColor then
        model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapGroups (List.mapAt index (setColor color)))) |> setDirty

    else
        ( model, Cmd.batch [ ProPlan.colorsModalBody basePath project ProPlanColors ProPlan.colorsInit |> CustomModalOpen |> T.send, Track.planLimit .tableColor model.erd ] )


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
