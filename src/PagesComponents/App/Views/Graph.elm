module PagesComponents.App.Views.Graph exposing (viewGraph)

import Color
import Force
import Graph exposing (Edge, Graph, NodeId)
import Html exposing (Html)
import PagesComponents.App.Models exposing (Entity, GraphMode, Msg)
import TypedSvg exposing (circle, g, line, svg, title)
import TypedSvg.Attributes exposing (class, fill, stroke, viewBox)
import TypedSvg.Attributes.InPx exposing (cx, cy, r, strokeWidth, x1, x2, y1, y2)
import TypedSvg.Core exposing (Svg, text)
import TypedSvg.Types exposing (Paint(..))


viewGraph : GraphMode -> Html Msg
viewGraph graphMode =
    svg [ viewBox 0 0 graphMode.canvas.width graphMode.canvas.height ]
        [ Graph.nodes graphMode.graph
            |> List.map nodeElement
            |> g [ class [ "nodes" ] ]
        , Graph.edges graphMode.graph
            |> List.map (linkElement graphMode.graph)
            |> g [ class [ "links" ] ]
        ]


nodeElement : { a | id : NodeId, label : { b | x : Float, y : Float, value : String } } -> Svg Msg
nodeElement node =
    circle
        [ r 2.5
        , fill <| Paint Color.black
        , stroke <| Paint <| Color.rgba 0 0 0 0
        , strokeWidth 7

        -- , onMouseDown node.id
        , cx node.label.x
        , cy node.label.y
        ]
        [ title [] [ text node.label.value ] ]


linkElement : Graph Entity () -> Edge () -> Svg msg
linkElement graph edge =
    let
        source : Force.Entity Int { value : String }
        source =
            Maybe.withDefault (Force.entity 0 "") <| Maybe.map (.node >> .label) <| Graph.get edge.from graph

        target : Force.Entity Int { value : String }
        target =
            Maybe.withDefault (Force.entity 0 "") <| Maybe.map (.node >> .label) <| Graph.get edge.to graph
    in
    line
        [ strokeWidth 1
        , stroke <| Paint <| Color.rgb255 170 170 170
        , x1 source.x
        , y1 source.y
        , x2 target.x
        , y2 target.y
        ]
        []
