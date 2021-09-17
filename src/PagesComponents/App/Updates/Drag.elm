module PagesComponents.App.Updates.Drag exposing (Model, dragEnd, dragMove, dragStart)

import Conf exposing (conf)
import Dict exposing (Dict)
import Libs.Area exposing (Area, overlap)
import Libs.Delta as Delta
import Libs.DomInfo exposing (DomInfo)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models exposing (HtmlId)
import Libs.Position as Position exposing (Position)
import Libs.Size as Size exposing (Size)
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
        |> Maybe.map (\_ -> ( model, Cmd.none {- toastInfo ("Can't drag " ++ id ++ ", already dragging " ++ ds.id) -} ))
        |> Maybe.withDefault ( model |> dragAction { id = id, init = pos, last = pos, delta = pos |> Position.diff pos |> Delta.fromTuple }, Cmd.none )


dragMove : DragId -> Position -> Model x -> ( Model x, Cmd Msg )
dragMove id pos model =
    model.dragState
        |> M.filter (\ds -> ds.id == id)
        |> Maybe.map (\ds -> ( model |> dragAction { ds | last = pos, delta = pos |> Position.diff ds.last |> Delta.fromTuple }, Cmd.none ))
        |> Maybe.withDefault (badDrag "move" id model)


dragEnd : DragId -> Position -> Model x -> ( Model x, Cmd Msg )
dragEnd id _ model =
    model.dragState
        |> M.filter (\ds -> ds.id == id)
        |> Maybe.map (\_ -> ( { model | dragState = Nothing, selection = Nothing }, Cmd.none ))
        |> Maybe.withDefault (badDrag "end" id model)


dragAction : DragState -> Model x -> Model x
dragAction dragState model =
    case ( model.cursorMode, dragState.id, model.project |> Maybe.map (\p -> p.schema.layout.canvas) |> Maybe.withDefault (CanvasProps (Position 0 0) 1) ) of
        ( Select, "erd", canvas ) ->
            let
                area : Area
                area =
                    computeSelectedArea model.domInfos canvas dragState
            in
            { model | dragState = Just dragState, selection = Just area }
                |> setCurrentLayout (setTables (List.map (\t -> { t | selected = overlap area (tableArea t model.domInfos) })))

        ( Drag, "erd", canvas ) ->
            { model | dragState = Just dragState } |> setCurrentLayout (setCanvas (setPosition dragState.delta canvas.zoom))

        ( _, id, canvas ) ->
            let
                tableId : TableId
                tableId =
                    htmlIdAsTableId id

                selected : Bool
                selected =
                    model.project |> Maybe.andThen (\p -> p.schema.layout.tables |> L.findBy .id tableId |> Maybe.map .selected) |> Maybe.withDefault False
            in
            { model | dragState = Just dragState } |> setCurrentLayout (setTableList (\t -> t.id == tableId || (selected && t.selected)) (setPosition dragState.delta canvas.zoom))


computeSelectedArea : Dict HtmlId DomInfo -> CanvasProps -> DragState -> Area
computeSelectedArea domInfos canvas dragState =
    let
        erdPos : Position
        erdPos =
            domInfos |> Dict.get conf.ids.erd |> Maybe.map .position |> Maybe.withDefault (Position 0 0)

        position : Position
        position =
            dragState.init |> Position.sub erdPos |> Position.sub canvas.position |> Position.div canvas.zoom

        size : Size
        size =
            Size (dragState.last.left - dragState.init.left) (dragState.last.top - dragState.init.top) |> Size.div canvas.zoom

        ( top, height ) =
            if size.height > 0 then
                ( position.top, size.height )

            else
                ( position.top + size.height, -size.height )

        ( left, width ) =
            if size.width > 0 then
                ( position.left, size.width )

            else
                ( position.left + size.width, -size.width )
    in
    { left = left, top = top, right = left + width, bottom = top + height }


tableArea : TableProps -> Dict HtmlId DomInfo -> Area
tableArea table domInfos =
    domInfos
        |> Dict.get (tableIdAsHtmlId table.id)
        |> Maybe.map (\domInfo -> { left = table.position.left, top = table.position.top, right = table.position.left + domInfo.size.width, bottom = table.position.top + domInfo.size.height })
        |> Maybe.withDefault { left = 0, top = 0, right = 0, bottom = 0 }


badDrag : String -> DragId -> Model x -> ( Model x, Cmd Msg )
badDrag kind id model =
    ( model
    , model.dragState
        |> Maybe.map (\ds -> toastInfo ("Dragging an other id (" ++ ds.id ++ " != " ++ id ++ ", on " ++ kind ++ ")"))
        |> Maybe.withDefault (toastInfo ("Not in drag state (" ++ kind ++ ")"))
    )
