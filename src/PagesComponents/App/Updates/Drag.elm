module PagesComponents.App.Updates.Drag exposing (Model, dragEnd, dragMove, dragStart)

import Conf exposing (conf)
import Dict exposing (Dict)
import Libs.Area as Area exposing (Area, overlap)
import Libs.Delta as Delta
import Libs.DomInfo exposing (DomInfo)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models exposing (HtmlId)
import Libs.Position as Position exposing (Position)
import Libs.Size exposing (Size)
import Models.Project exposing (CanvasProps, Project, TableId, TableProps, htmlIdAsTableId, tableIdAsHtmlId)
import PagesComponents.App.Models exposing (CursorMode(..), DragId, DragState, Msg)
import PagesComponents.App.Updates.Helpers exposing (setCanvas, setCurrentLayout, setPosition, setTableList, setTables)
import Ports exposing (toastInfo)


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
    case ( model.cursorMode, dragState.id, model.project |> M.mapOrElse (.layout >> .canvas) (CanvasProps (Position 0 0) 1) ) of
        ( Select, "erd", canvas ) ->
            let
                area : Area
                area =
                    computeSelectedArea model.domInfos canvas dragState
            in
            { model | dragState = Just dragState, selection = Just area }
                |> setCurrentLayout (setTables (List.map (\t -> { t | selected = overlap area (tableArea t model.domInfos) })))

        ( Select, id, canvas ) ->
            let
                tableId : TableId
                tableId =
                    htmlIdAsTableId id

                selected : Bool
                selected =
                    model.project |> Maybe.andThen (\p -> p.layout.tables |> L.findBy .id tableId |> Maybe.map .selected) |> Maybe.withDefault False
            in
            { model | dragState = Just dragState } |> setCurrentLayout (setTableList (\t -> t.id == tableId || (selected && t.selected)) (setPosition dragState.delta canvas.zoom))

        ( Drag, "erd", _ ) ->
            { model | dragState = Just dragState } |> setCurrentLayout (setCanvas (setPosition dragState.delta 1))

        ( Drag, _, _ ) ->
            model


computeSelectedArea : Dict HtmlId DomInfo -> CanvasProps -> DragState -> Area
computeSelectedArea domInfos canvas dragState =
    let
        erdPos : Position
        erdPos =
            domInfos |> Dict.get conf.ids.erd |> M.mapOrElse .position (Position 0 0)

        position : Position
        position =
            dragState.init |> Position.sub erdPos |> Position.sub canvas.position

        size : Size
        size =
            Size (dragState.last.left - dragState.init.left) (dragState.last.top - dragState.init.top)
    in
    Area position size |> Area.div canvas.zoom |> Area.normalize


tableArea : TableProps -> Dict HtmlId DomInfo -> Area
tableArea table domInfos =
    domInfos
        |> Dict.get (tableIdAsHtmlId table.id)
        |> M.mapOrElse (\domInfo -> { position = table.position, size = domInfo.size })
            { position = Position 0 0, size = Size 0 0 }


badDrag : String -> Model x -> ( Model x, Cmd Msg )
badDrag kind model =
    ( model, toastInfo ("Can't " ++ kind ++ ", not in drag state") )
