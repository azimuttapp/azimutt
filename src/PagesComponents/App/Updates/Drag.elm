module PagesComponents.App.Updates.Drag exposing (Model, dragEnd, dragMove, dragStart)

import Conf
import Dict exposing (Dict)
import Libs.Area as Area exposing (Area, overlap)
import Libs.Delta as Delta
import Libs.DomInfo exposing (DomInfo)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.DragId exposing (DragId)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position as Position exposing (Position)
import Models.Project exposing (Project)
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableProps exposing (TableProps)
import PagesComponents.App.Models exposing (CursorMode(..), DragState, Msg)
import Ports
import Services.Lenses exposing (mapCanvas, mapEachTable, mapProjectMLayout, mapTables, setDragState, setSelected, setSelection, updatePosition)


type alias Model x =
    { x
        | dragState : Maybe DragState
        , project : Maybe Project
        , domInfos : Dict HtmlId DomInfo
        , cursorMode : CursorMode
        , selection : Maybe Area
    }


dragStart : DragId -> Position -> Model x -> ( Model x, Cmd Msg )
dragStart id pos model =
    model.dragState
        |> M.mapOrElse (\_ -> ( model, Cmd.none {- toastInfo ("Can't drag " ++ id ++ ", already dragging " ++ ds.id) -} ))
            ( model |> dragAction { id = id, init = pos, last = pos, delta = pos |> Position.diff pos |> Delta.fromTuple }, Cmd.none )


dragMove : Position -> Model x -> ( Model x, Cmd Msg )
dragMove pos model =
    model.dragState
        |> M.mapOrElse (\ds -> ( model |> dragAction { ds | last = pos, delta = pos |> Position.diff ds.last |> Delta.fromTuple }, Cmd.none ))
            (badDrag "dragMove" model)


dragEnd : Position -> Model x -> ( Model x, Cmd Msg )
dragEnd _ model =
    model.dragState
        |> M.mapOrElse (\_ -> ( { model | dragState = Nothing, selection = Nothing }, Cmd.none ))
            (badDrag "dragEnd" model)


dragAction : DragState -> Model x -> Model x
dragAction dragState model =
    case ( model.cursorMode, dragState.id, model.project |> M.mapOrElse (.layout >> .canvas) CanvasProps.zero ) of
        ( Select, "erd", canvas ) ->
            let
                area : Area
                area =
                    computeSelectedArea model.domInfos canvas dragState
            in
            model
                |> setDragState (Just dragState)
                |> setSelection (Just area)
                |> mapProjectMLayout (mapTables (List.map (\t -> t |> setSelected (overlap area (tableArea t model.domInfos)))))

        ( Select, id, canvas ) ->
            let
                tableId : TableId
                tableId =
                    TableId.fromHtmlId id

                selected : Bool
                selected =
                    model.project |> Maybe.andThen (\p -> p.layout.tables |> L.findBy .id tableId |> Maybe.map .selected) |> Maybe.withDefault False
            in
            model |> setDragState (Just dragState) |> mapProjectMLayout (mapEachTable (\t -> t.id == tableId || (selected && t.selected)) (updatePosition dragState.delta canvas.zoom))

        ( Drag, "erd", _ ) ->
            model |> setDragState (Just dragState) |> mapProjectMLayout (mapCanvas (updatePosition dragState.delta 1))

        ( Drag, _, _ ) ->
            model


computeSelectedArea : Dict HtmlId DomInfo -> CanvasProps -> DragState -> Area
computeSelectedArea domInfos canvas dragState =
    let
        erdPos : Position
        erdPos =
            domInfos |> Dict.get Conf.ids.erd |> M.mapOrElse .position Position.zero
    in
    Area.from dragState.init dragState.last
        |> Area.move (erdPos |> Position.add canvas.position |> Position.negate)
        |> Area.div canvas.zoom


tableArea : TableProps -> Dict HtmlId DomInfo -> Area
tableArea table domInfos =
    domInfos
        |> Dict.get (TableId.toHtmlId table.id)
        |> M.mapOrElse (\domInfo -> Area table.position domInfo.size) Area.zero


badDrag : String -> Model x -> ( Model x, Cmd Msg )
badDrag kind model =
    ( model, Ports.toastInfo ("Can't " ++ kind ++ ", not in drag state") )
