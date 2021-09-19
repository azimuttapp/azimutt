module PagesComponents.App.Updates.Graph exposing (advanceSimulation, initGraph)

import Conf exposing (conf)
import Dict exposing (Dict)
import Force
import Graph exposing (Graph, NodeContext, NodeId)
import Libs.DomInfo exposing (DomInfo)
import Libs.Models exposing (HtmlId)
import Libs.Size exposing (Size)
import Models.Project exposing (Project, Relation, Schema, TableId, TableProps, showTableId)
import PagesComponents.App.Models exposing (Entity, GraphMode, Model, NodeLabel)


initGraph : Dict HtmlId DomInfo -> Maybe Project -> GraphMode
initGraph domInfos project =
    let
        size : Size
        size =
            domInfos |> Dict.get conf.ids.erd |> Maybe.map .size |> Maybe.withDefault (Size 0 0)

        graph : Graph NodeLabel ()
        graph =
            buildGraph (project |> Maybe.map .schema)
    in
    { canvas = size
    , graph = Graph.mapContexts initNode graph
    , simulation =
        Force.simulation
            [ graph |> Graph.edges |> List.map (\{ from, to } -> ( from, to )) |> Force.links
            , graph |> Graph.nodes |> List.map .id |> Force.manyBodyStrength -800
            , graph |> Graph.nodes |> List.map .id |> Force.collision 70
            , Force.center (size.width / 2) (size.height / 2)
            ]
    }


advanceSimulation : Model -> Model
advanceSimulation model =
    model.graph
        |> Maybe.map
            (\g ->
                let
                    ( newState, list ) =
                        g.graph |> Graph.nodes |> List.map .label |> Force.tick g.simulation
                in
                { model | graph = Just { g | graph = updateGraphWithList g.graph list, simulation = newState } }
            )
        |> Maybe.withDefault model


buildGraph : Maybe Schema -> Graph NodeLabel ()
buildGraph schema =
    case schema of
        Nothing ->
            Graph.fromNodeLabelsAndEdgePairs [] []

        Just s ->
            let
                visibleTables : Dict TableId NodeId
                visibleTables =
                    s.layout.tables |> List.indexedMap (\i t -> ( t.id, i )) |> Dict.fromList

                nodeLabels : List NodeLabel
                nodeLabels =
                    s.layout.tables |> List.map buildNodeLabel

                edges : List ( NodeId, NodeId )
                edges =
                    s.relations |> List.filter (\r -> r.src.column /= "created_by" && r.src.column /= "updated_by") |> List.filterMap (buildEdge visibleTables)
            in
            Graph.fromNodeLabelsAndEdgePairs nodeLabels edges


buildNodeLabel : TableProps -> NodeLabel
buildNodeLabel table =
    { name = showTableId table.id, color = table.color, columns = table.columns |> List.length }


buildEdge : Dict TableId NodeId -> Relation -> Maybe ( NodeId, NodeId )
buildEdge visibleTables relation =
    Maybe.map2 (\src ref -> ( src, ref ))
        (visibleTables |> Dict.get relation.src.table)
        (visibleTables |> Dict.get relation.ref.table)


initNode : NodeContext NodeLabel () -> NodeContext Entity ()
initNode ctx =
    { node = { label = Force.entity ctx.node.id ctx.node.label, id = ctx.node.id }
    , incoming = ctx.incoming
    , outgoing = ctx.outgoing
    }


updateGraphWithList : Graph Entity () -> List Entity -> Graph Entity ()
updateGraphWithList =
    let
        graphUpdater : Entity -> Maybe (NodeContext Entity ()) -> Maybe (NodeContext Entity ())
        graphUpdater value =
            Maybe.map (\ctx -> updateContextWithValue ctx value)
    in
    List.foldr (\node graph -> Graph.update node.id (graphUpdater node) graph)


updateContextWithValue : NodeContext Entity () -> Entity -> NodeContext Entity ()
updateContextWithValue nodeCtx value =
    let
        node : Graph.Node Entity
        node =
            nodeCtx.node
    in
    { nodeCtx | node = { node | label = value } }
