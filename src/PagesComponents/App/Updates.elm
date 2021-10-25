module PagesComponents.App.Updates exposing (moveTable, removeElement, updateSizes)

import Conf exposing (conf)
import Dict
import Libs.Bool as B
import Libs.List as L
import Libs.Maybe as M
import Libs.Models exposing (SizeChange)
import Libs.Position exposing (Position)
import Libs.Size exposing (Size)
import Libs.Task exposing (send)
import Models.Project exposing (Layout, TableProps, viewportArea)
import Models.Project.TableId as TableId
import PagesComponents.App.Commands.InitializeTable exposing (initializeTable)
import PagesComponents.App.Models exposing (CursorMode(..), Hover, Model, Msg(..))
import Ports exposing (toastInfo)


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
                Maybe.map3 (\t props canvasInfos -> ( t, props, canvasInfos ))
                    (p.tables |> Dict.get (TableId.fromHtmlId change.id))
                    (p.layout.tables |> L.findBy .id (TableId.fromHtmlId change.id))
                    (model.domInfos |> Dict.get conf.ids.erd)
                    |> M.filter (\( _, props, _ ) -> props.position == Position 0 0 && not (model.domInfos |> Dict.member change.id))
                    |> Maybe.map (\( t, _, canvasInfos ) -> t.id |> initializeTable change.size (viewportArea canvasInfos.size p.layout.canvas))
            )


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
