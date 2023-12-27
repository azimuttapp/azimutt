module PagesComponents.Organization_.Project_.Updates.Groups exposing (Model, handleGroups)

import Browser.Dom as Dom
import Components.Slices.ProPlan as ProPlan
import Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Tailwind as Tw exposing (Color)
import Libs.Task as T
import Models.Project.Group as Group exposing (Group)
import Models.Project.TableId exposing (TableId)
import Models.ProjectRef exposing (ProjectRef)
import Models.UrlInfos exposing (UrlInfos)
import PagesComponents.Organization_.Project_.Models exposing (GroupEdit, GroupMsg(..), Msg(..), NotesDialog)
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setHDirty, setHDirtyCmd, setHL, setHLCmd, setHLDirty)
import Services.Lenses exposing (mapColorT, mapEditGroupM, mapErdM, mapErdMT, mapErdMTM, mapGroups, mapGroupsT, mapTables, setContent, setEditGroup, setName)
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


handleGroups : Time.Posix -> UrlInfos -> GroupMsg -> Model x -> ( Model x, Cmd Msg, List ( Msg, Msg ) )
handleGroups now urlInfos msg model =
    case msg of
        GCreate tables ->
            model |> createGroup now urlInfos tables

        GEdit index name ->
            ( model |> setEditGroup (Just { index = index, content = name }), index |> Group.toInputId |> Dom.focus |> Task.attempt (\_ -> Noop "focus-group-input"), [] )

        GEditUpdate name ->
            ( model |> mapEditGroupM (setContent name), Cmd.none, [] )

        GEditSave content ->
            model |> saveGroup now content

        GSetColor index color ->
            model |> setGroupColor now urlInfos index color

        GAddTables index tables ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapGroups (List.mapAt index (mapTables (List.append tables))))) |> setHDirty [ ( GroupMsg (GRemoveTables index tables), GroupMsg msg ) ]

        GRemoveTables index tables ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapGroups (List.mapAt index (mapTables (List.removeAll tables))))) |> setHDirty [ ( GroupMsg (GAddTables index tables), GroupMsg msg ) ]

        GDelete index ->
            model
                |> mapErdMT
                    (Erd.mapCurrentLayoutTLWithTime now
                        (mapGroupsT
                            (\groups ->
                                (groups |> List.get index)
                                    |> Maybe.map (\g -> ( groups |> List.removeAt index, [ ( GroupMsg (GUnDelete index g), GroupMsg msg ) ] ))
                                    |> Maybe.withDefault ( groups, [] )
                            )
                        )
                    )
                |> setHLDirty

        GUnDelete index group ->
            model |> mapErdMTM (Erd.mapCurrentLayoutTWithTime now (mapGroupsT (\groups -> ( groups |> List.insertAt index group, [ ( GroupMsg (GDelete index), GroupMsg msg ) ] )))) |> setHL


createGroup : Time.Posix -> UrlInfos -> List TableId -> Model x -> ( Model x, Cmd Msg, List ( Msg, Msg ) )
createGroup now urlInfos tables model =
    if tables |> List.isEmpty then
        ( model, Cmd.none, [] )

    else if model.erd |> Erd.canCreateGroup then
        model
            |> mapErdMTM
                (Erd.mapCurrentLayoutTWithTime now
                    (\l ->
                        l
                            |> mapGroupsT
                                (\groups ->
                                    ( groups |> List.insert (Group.init tables (groupColor l tables))
                                    , ( Track.groupCreated model.erd, [ ( GroupMsg (GDelete (List.length groups)), GroupMsg (GCreate tables) ) ] )
                                    )
                                )
                    )
                )
            |> setHLCmd

    else
        ( model, model.erd |> Maybe.mapOrElse (\erd -> Cmd.batch [ erd |> Erd.getProjectRef urlInfos |> ProPlan.groupsModalBody |> CustomModalOpen |> T.send, Track.planLimit .groups (Just erd) ]) Cmd.none, [] )


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


setGroupColor : Time.Posix -> UrlInfos -> Int -> Color -> Model x -> ( Model x, Cmd Msg, List ( Msg, Msg ) )
setGroupColor now urlInfos index color model =
    let
        project : ProjectRef
        project =
            model.erd |> Erd.getProjectRefM urlInfos
    in
    if model.erd |> Erd.canChangeColor then
        model |> mapErdMT (Erd.mapCurrentLayoutTLWithTime now (mapGroupsT (List.mapAtTL index (mapColorT (\c -> ( color, [ ( GroupMsg (GSetColor index c), GroupMsg (GSetColor index color) ) ] )))))) |> setHLDirty

    else
        ( model, Cmd.batch [ ProPlan.colorsModalBody project ProPlanColors ProPlan.colorsInit |> CustomModalOpen |> T.send, Track.planLimit .tableColor model.erd ], [] )


saveGroup : Time.Posix -> GroupEdit -> Model x -> ( Model x, Cmd Msg, List ( Msg, Msg ) )
saveGroup now edit model =
    let
        groupName : String
        groupName =
            model.erd |> Maybe.andThen (Erd.currentLayout >> .groups >> List.get edit.index) |> Maybe.mapOrElse .name ""
    in
    if edit.content == groupName then
        -- no change, don't save
        ( model |> setEditGroup Nothing, Cmd.none, [] )

    else
        ( model |> setEditGroup Nothing |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapGroups (List.mapAt edit.index (setName edit.content))))
        , Track.groupRenamed edit.content model.erd
        )
            |> setHDirtyCmd [ ( GroupMsg (GEditSave { edit | content = groupName }), GroupMsg (GEditSave edit) ) ]
