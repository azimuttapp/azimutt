module Models.AutoLayout exposing (AutoLayoutMethod(..), DiagramEdge, DiagramNode, decodeDiagramNode, default, encodeAutoLayoutMethod, encodeDiagramEdge, encodeDiagramNode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size exposing (Size)


type AutoLayoutMethod
    = Random
    | Grid
    | Circle
    | Avsdf
    | BreadthFirst
    | Dagre
    | Cose
    | FCose


default : AutoLayoutMethod
default =
    Cose


type alias DiagramNode =
    { id : String, size : Size, position : Position }


type alias DiagramEdge =
    { src : String, ref : String }


encodeAutoLayoutMethod : AutoLayoutMethod -> Value
encodeAutoLayoutMethod value =
    case value of
        Random ->
            "random" |> Encode.string

        Grid ->
            "grid" |> Encode.string

        Circle ->
            "circle" |> Encode.string

        Avsdf ->
            "avsdf" |> Encode.string

        BreadthFirst ->
            "breadthfirst" |> Encode.string

        Dagre ->
            "dagre" |> Encode.string

        Cose ->
            "cose" |> Encode.string

        FCose ->
            "fcose" |> Encode.string


encodeDiagramNode : DiagramNode -> Value
encodeDiagramNode value =
    Encode.object
        [ ( "id", value.id |> Encode.string )
        , ( "size", value.size |> Size.encode )
        , ( "position", value.position |> Position.encode )
        ]


decodeDiagramNode : Decoder DiagramNode
decodeDiagramNode =
    Decode.map3 DiagramNode
        (Decode.field "id" Decode.string)
        (Decode.field "size" Size.decode)
        (Decode.field "position" Position.decode)


encodeDiagramEdge : DiagramEdge -> Value
encodeDiagramEdge value =
    Encode.object
        [ ( "src", value.src |> Encode.string )
        , ( "ref", value.ref |> Encode.string )
        ]
