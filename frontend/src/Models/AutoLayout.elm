module Models.AutoLayout exposing (AutoLayoutMethod(..), DiagramEdge, DiagramNode, decodeDiagramNode, default, encodeAutoLayoutMethod, encodeDiagramEdge, encodeDiagramNode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size exposing (Size)


type AutoLayoutMethod
    = Dagre
    | CytoRand
    | CytoGrid
    | CytoCircle
    | CytoAvsdf
    | CytoBreadth
    | CytoCose
    | CytoDagre
    | CytoFcose


default : AutoLayoutMethod
default =
    Dagre


type alias DiagramNode =
    { id : String, size : Size, pos : Position }


type alias DiagramEdge =
    { src : String, ref : String }


encodeAutoLayoutMethod : AutoLayoutMethod -> Value
encodeAutoLayoutMethod value =
    case value of
        Dagre ->
            "dagre" |> Encode.string

        CytoRand ->
            "cytoscape/random" |> Encode.string

        CytoGrid ->
            "cytoscape/grid" |> Encode.string

        CytoCircle ->
            "cytoscape/circle" |> Encode.string

        CytoAvsdf ->
            "cytoscape/avsdf" |> Encode.string

        CytoBreadth ->
            "cytoscape/breadthfirst" |> Encode.string

        CytoCose ->
            "cytoscape/cose" |> Encode.string

        CytoDagre ->
            "cytoscape/dagre" |> Encode.string

        CytoFcose ->
            "cytoscape/fcose" |> Encode.string


encodeDiagramNode : DiagramNode -> Value
encodeDiagramNode value =
    Encode.object
        [ ( "id", value.id |> Encode.string )
        , ( "size", value.size |> Size.encode )
        , ( "pos", value.pos |> Position.encode )
        ]


decodeDiagramNode : Decoder DiagramNode
decodeDiagramNode =
    Decode.map3 DiagramNode
        (Decode.field "id" Decode.string)
        (Decode.field "size" Size.decode)
        (Decode.field "pos" Position.decode)


encodeDiagramEdge : DiagramEdge -> Value
encodeDiagramEdge value =
    Encode.object
        [ ( "src", value.src |> Encode.string )
        , ( "ref", value.ref |> Encode.string )
        ]
