module PagesComponents.Organization_.Project_.Updates.Groups exposing (Model, handleGroups)

import Browser.Dom as Dom
import Components.Slices.PlanDialog as PlanDialog
import Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Tailwind as Tw exposing (Color)
import Libs.Task as T
import Models.Feature as Feature
import Models.Organization as Organization exposing (Organization)
import Models.Project.Group as Group exposing (Group)
import Models.Project.TableId exposing (TableId)
import Models.ProjectRef exposing (ProjectRef)
import PagesComponents.Organization_.Project_.Models exposing (GroupEdit, GroupMsg(..), Msg(..), NotesDialog)
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirty, setDirtyM)
import Services.Lenses exposing (mapColorT, mapEditGroupM, mapErdM, mapErdMTM, mapGroups, mapGroupsT, mapTables, setContent, setEditGroup, setName)
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


handleGroups : Time.Posix -> ProjectRef -> GroupMsg -> Model x -> ( Model x, Extra Msg )
handleGroups now projectRef msg model =
    case msg of
        GCreate tables ->
            model |> createGroup now tables

        GEdit index name ->
            ( model |> setEditGroup (Just { index = index, content = name }), index |> Group.toInputId |> Dom.focus |> Task.attempt (\_ -> Noop "focus-group-input") |> Extra.cmd )

        GEditUpdate name ->
            ( model |> mapEditGroupM (setContent name), Extra.none )

        GEditSave content ->
            model |> saveGroup now content

        GSetColor index color ->
            model |> setGroupColor now projectRef index color

        GAddTables index tables ->
            ( model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapGroups (List.mapAt index (mapTables (List.append tables)))))
            , Extra.history ( GroupMsg (GRemoveTables index tables), GroupMsg msg )
            )
                |> setDirty

        GRemoveTables index tables ->
            ( model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapGroups (List.mapAt index (mapTables (List.removeAll tables)))))
            , Extra.history ( GroupMsg (GAddTables index tables), GroupMsg msg )
            )
                |> setDirty

        GDelete index ->
            model
                |> mapErdMTM
                    (Erd.mapCurrentLayoutTWithTime now
                        (mapGroupsT
                            (\groups ->
                                (groups |> List.get index)
                                    |> Maybe.map (\g -> ( groups |> List.removeAt index, Extra.history ( GroupMsg (GUnDelete index g), GroupMsg msg ) ))
                                    |> Maybe.withDefault ( groups, Extra.none )
                            )
                        )
                    )
                |> setDirtyM

        GUnDelete index group ->
            model |> mapErdMTM (Erd.mapCurrentLayoutTWithTime now (mapGroupsT (\groups -> ( groups |> List.insertAt index group, Extra.history ( GroupMsg (GDelete index), GroupMsg msg ) )))) |> Extra.defaultT


createGroup : Time.Posix -> List TableId -> Model x -> ( Model x, Extra Msg )
createGroup now tables model =
    if tables |> List.isEmpty then
        ( model, Extra.none )

    else
        model
            |> mapErdMTM
                (Erd.mapCurrentLayoutTWithTime now
                    (\l ->
                        l
                            |> mapGroupsT
                                (\groups ->
                                    ( groups |> List.insert (Group.init tables (groupColor l tables))
                                    , Extra.new (Track.groupCreated model.erd) ( GroupMsg (GDelete (List.length groups)), GroupMsg (GCreate tables) )
                                    )
                                )
                    )
                )
            |> Extra.defaultT


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


setGroupColor : Time.Posix -> ProjectRef -> Int -> Color -> Model x -> ( Model x, Extra Msg )
setGroupColor now projectRef index color model =
    if Organization.canChangeColor projectRef then
        model |> mapErdMTM (Erd.mapCurrentLayoutTMWithTime now (mapGroupsT (List.mapAtT index (mapColorT (\c -> ( color, Extra.history ( GroupMsg (GSetColor index c), GroupMsg (GSetColor index color) ) )))))) |> Extra.defaultT

    else
        ( model, Extra.cmdL [ PlanDialog.colorsModalBody projectRef PlanDialogColors PlanDialog.colorsInit |> CustomModalOpen |> T.send, Track.planLimit Feature.colors model.erd ] )


saveGroup : Time.Posix -> GroupEdit -> Model x -> ( Model x, Extra Msg )
saveGroup now edit model =
    let
        groupName : String
        groupName =
            model.erd |> Maybe.andThen (Erd.currentLayout >> .groups >> List.get edit.index) |> Maybe.mapOrElse .name ""
    in
    if edit.content == groupName then
        -- no change, don't save
        ( model |> setEditGroup Nothing, Extra.none )

    else
        ( model |> setEditGroup Nothing |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapGroups (List.mapAt edit.index (setName edit.content))))
        , Extra.new (Track.groupRenamed edit.content model.erd) ( GroupMsg (GEditSave { edit | content = groupName }), GroupMsg (GEditSave edit) )
        )
            |> setDirty
