module PagesComponents.App.Updates exposing (dragConfig, dragItem, isInside, moveTable, removeElement, toArea, updateSizes)

import Conf exposing (conf)
import Dict exposing (Dict)
import Draggable
import Draggable.Events exposing (onDragBy, onDragEnd, onDragStart)
import Libs.Area as Area exposing (Area)
import Libs.Bool as B
import Libs.DomInfo exposing (DomInfo)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models exposing (HtmlId, SizeChange)
import Libs.Position exposing (Position)
import Libs.Size exposing (Size)
import Libs.Task exposing (send)
import Models.Project exposing (CanvasProps, Layout, TableId, TableProps, htmlIdAsTableId, tableIdAsHtmlId)
import PagesComponents.App.Commands.InitializeTable exposing (initializeTable)
import PagesComponents.App.Models exposing (CursorMode(..), DragId, Hover, Model, Msg(..), SelectSquare)
import PagesComponents.App.Updates.Helpers exposing (setCanvas, setLayout, setPosition, setProject, setSchema, setTableList)
import Ports exposing (toastError, toastInfo)


updateSizes : List SizeChange -> Model -> ( Model, Cmd Msg )
updateSizes sizeChanges model =
    ( sizeChanges |> List.foldl updateSize model, Cmd.batch (sizeChanges |> List.filterMap (initializeTableOnFirstSize model)) )


updateSize : SizeChange -> Model -> Model
updateSize change model =
    { model | domInfos = model.domInfos |> Dict.update change.id (\_ -> B.cond (change.size == Size 0 0) Nothing (Just { position = change.position, size = change.size })) }


initializeTableOnFirstSize : Model -> SizeChange -> Maybe (Cmd Msg)
initializeTableOnFirstSize model change =
    model.project
        |> Maybe.andThen
            (\p ->
                Maybe.map3 (\t props canvasSize -> ( t, props, canvasSize ))
                    (p.schema.tables |> Dict.get (htmlIdAsTableId change.id))
                    (p.schema.layout.tables |> L.findBy .id (htmlIdAsTableId change.id))
                    (model.domInfos |> Dict.get conf.ids.erd)
                    |> M.filter (\( _, props, _ ) -> props.position == Position 0 0 && not (model.domInfos |> Dict.member change.id))
                    |> Maybe.map (\( t, _, canvasInfos ) -> t.id |> initializeTable change.size (getArea canvasInfos.size p.schema.layout.canvas))
            )


getArea : Size -> CanvasProps -> Area
getArea canvasSize canvas =
    { left = (0 - canvas.position.left) / canvas.zoom
    , right = (canvasSize.width - canvas.position.left) / canvas.zoom
    , top = (0 - canvas.position.top) / canvas.zoom
    , bottom = (canvasSize.height - canvas.position.top) / canvas.zoom
    }


dragConfig : Draggable.Config DragId Msg
dragConfig =
    Draggable.customConfig
        [ onDragStart StartDragging
        , onDragEnd StopDragging
        , onDragBy OnDragBy
        ]


dragItem : Draggable.Delta -> Model -> ( Model, Cmd Msg )
dragItem delta model =
    case model.dragId of
        Just id ->
            if id == conf.ids.erd then
                ( model |> setProject (setSchema (setLayout (setCanvas (setPosition delta 1)))), Cmd.none )

            else
                let
                    tableId : TableId
                    tableId =
                        htmlIdAsTableId id

                    selected : Bool
                    selected =
                        model.project |> Maybe.andThen (\p -> p.schema.layout.tables |> L.findBy .id tableId |> Maybe.map .selected) |> Maybe.withDefault False
                in
                ( model |> setProject (setSchema (setLayout (\l -> l |> setTableList (\t -> t.id == tableId || (selected && t.selected)) (setPosition delta l.canvas.zoom)))), Cmd.none )

        Nothing ->
            ( model, toastError "Can't dragItem when no drag id" )


isInside : Dict HtmlId DomInfo -> Area -> TableProps -> Bool
isInside domInfos selection table =
    domInfos |> Dict.get (tableIdAsHtmlId table.id) |> Maybe.map (\domInfo -> Area.doOverlap selection (tableToArea table domInfo)) |> Maybe.withDefault False


tableToArea : TableProps -> DomInfo -> Area
tableToArea table domInfo =
    { left = table.position.left, top = table.position.top, right = table.position.left + domInfo.size.width, bottom = table.position.top + domInfo.size.height }


toArea : SelectSquare -> Area
toArea square =
    let
        ( top, height ) =
            if square.size.height > 0 then
                ( square.position.top, square.size.height )

            else
                ( square.position.top + square.size.height, -square.size.height )

        ( left, width ) =
            if square.size.width > 0 then
                ( square.position.left, square.size.width )

            else
                ( square.position.left + square.size.width, -square.size.width )
    in
    { left = left, top = top, right = left + width, bottom = top + height }


removeElement : Hover -> Cmd Msg
removeElement hover =
    (hover.column |> Maybe.map (\c -> send (HideColumn c)))
        |> M.orElse (hover.table |> Maybe.map (\t -> send (HideTable t)))
        |> Maybe.withDefault (toastInfo "Can't find an element to remove :(")


moveTable : Int -> Hover -> Layout -> Cmd Msg
moveTable delta hover layout =
    let
        selectedTables : List ( Int, TableProps )
        selectedTables =
            layout.tables |> List.indexedMap (\i t -> ( i, t )) |> List.filter (\( _, t ) -> t.selected)
    in
    if L.nonEmpty selectedTables then
        Cmd.batch (selectedTables |> List.map (\( i, t ) -> send (TableOrder t.id (List.length layout.tables - 1 - i + delta))))

    else
        (hover.table
            |> Maybe.andThen (\id -> layout.tables |> L.findIndexBy .id id |> Maybe.map (\i -> ( id, i )))
            |> Maybe.map (\( id, i ) -> send (TableOrder id (List.length layout.tables - 1 - i + delta)))
        )
            |> Maybe.withDefault (toastInfo "Can't find an element to move :(")
