module PagesComponents.App.Views.Graph exposing (viewGraph)

import Color exposing (Color)
import Dict exposing (Dict)
import Force
import Graph exposing (Edge, Graph, NodeId)
import Html exposing (Html)
import Libs.Color exposing (fromHex)
import PagesComponents.App.Models exposing (Entity, GraphMode, Msg, NodeLabel)
import TypedSvg exposing (circle, g, line, svg, title)
import TypedSvg.Attributes exposing (class, fill, stroke, viewBox)
import TypedSvg.Attributes.InPx exposing (cx, cy, r, strokeWidth, x1, x2, y1, y2)
import TypedSvg.Core exposing (Svg, text)
import TypedSvg.Types exposing (Paint(..))



{- inspirations ("graph drawing library javascript"):
   - https://visjs.github.io/vis-network/examples
   - https://js.cytoscape.org
-}


viewGraph : GraphMode -> Html Msg
viewGraph graphMode =
    svg [ viewBox 0 0 graphMode.canvas.width graphMode.canvas.height ]
        [ g [ class [ "links" ] ] (graphMode.graph |> Graph.edges |> List.map (linkElement graphMode.graph))
        , g [ class [ "nodes" ] ] (graphMode.graph |> Graph.nodes |> List.map nodeElement)
        ]


nodeElement : { a | id : NodeId, label : { b | x : Float, y : Float, value : NodeLabel } } -> Svg Msg
nodeElement { label } =
    circle [ r (toFloat (5 + label.value.columns)), fill (label.value.color |> asColor |> Paint), cx label.x, cy label.y ]
        [ title [] [ text label.value.name ]
        ]


linkElement : Graph Entity () -> Edge () -> Svg msg
linkElement graph edge =
    let
        source : Maybe (Force.Entity Int { value : NodeLabel })
        source =
            graph |> Graph.get edge.from |> Maybe.map (.node >> .label)

        target : Maybe (Force.Entity Int { value : NodeLabel })
        target =
            graph |> Graph.get edge.to |> Maybe.map (.node >> .label)
    in
    line
        [ strokeWidth 1
        , stroke <| Paint <| Color.rgb255 170 170 170
        , x1 (source |> Maybe.map .x |> Maybe.withDefault 0)
        , y1 (source |> Maybe.map .y |> Maybe.withDefault 0)
        , x2 (target |> Maybe.map .x |> Maybe.withDefault 0)
        , y2 (target |> Maybe.map .y |> Maybe.withDefault 0)
        ]
        []


asColor : String -> Color
asColor color =
    colorCodes |> Dict.get color |> Maybe.withDefault Color.black


colorCodes : Dict String Color
colorCodes =
    Dict.fromList
        [ ( "red", fromHex "#EF4444" |> Maybe.withDefault Color.red )
        , ( "orange", fromHex "#F97316" |> Maybe.withDefault Color.darkOrange )
        , ( "amber", fromHex "#F59E0B" |> Maybe.withDefault Color.orange )
        , ( "yellow", fromHex "#EAB308" |> Maybe.withDefault Color.yellow )
        , ( "lime", fromHex "#84CC16" |> Maybe.withDefault Color.lightGreen )
        , ( "green", fromHex "#22C55E" |> Maybe.withDefault Color.green )
        , ( "emerald", fromHex "#10B981" |> Maybe.withDefault Color.darkGreen )
        , ( "teal", fromHex "#14B8A6" |> Maybe.withDefault Color.lightBlue )
        , ( "cyan", fromHex "#06B6D4" |> Maybe.withDefault Color.lightBlue )
        , ( "sky", fromHex "#0EA5E9" |> Maybe.withDefault Color.blue )
        , ( "blue", fromHex "#3B82F6" |> Maybe.withDefault Color.darkBlue )
        , ( "indigo", fromHex "#6366F1" |> Maybe.withDefault Color.lightPurple )
        , ( "violet", fromHex "#8B5CF6" |> Maybe.withDefault Color.purple )
        , ( "purple", fromHex "#A855F7" |> Maybe.withDefault Color.darkPurple )
        , ( "fuchsia", fromHex "#D946EF" |> Maybe.withDefault Color.lightBrown )
        , ( "pink", fromHex "#EC4899" |> Maybe.withDefault Color.brown )
        , ( "rose", fromHex "#F43F5E" |> Maybe.withDefault Color.darkBrown )
        ]
