module Models.Project.Layout exposing (Layout, decode, empty, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Encode as Encode
import Libs.Time as Time
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.TableProps as TableProps exposing (TableProps)
import Time


type alias Layout =
    { canvas : CanvasProps
    , tables : List TableProps
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


empty : Time.Posix -> Layout
empty now =
    { canvas = CanvasProps.empty, tables = [], createdAt = now, updatedAt = now }


encode : Layout -> Value
encode value =
    Encode.notNullObject
        [ ( "canvas", value.canvas |> CanvasProps.encode )
        , ( "tables", value.tables |> Encode.list TableProps.encode )
        , ( "createdAt", value.createdAt |> Time.encode )
        , ( "updatedAt", value.updatedAt |> Time.encode )
        ]


decode : Decode.Decoder Layout
decode =
    Decode.map4 Layout
        (Decode.field "canvas" CanvasProps.decode)
        (Decode.field "tables" (Decode.list TableProps.decode))
        (Decode.field "createdAt" Time.decode)
        (Decode.field "updatedAt" Time.decode)
