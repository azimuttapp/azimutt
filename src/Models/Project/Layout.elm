module Models.Project.Layout exposing (Layout, decode, encode, init)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Time as Time
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.TableProps as TableProps exposing (TableProps)
import Time


type alias Layout =
    { canvas : CanvasProps
    , tables : List TableProps
    , hiddenTables : List TableProps
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


init : Time.Posix -> Layout
init now =
    { canvas = CanvasProps.zero, tables = [], hiddenTables = [], createdAt = now, updatedAt = now }


encode : Layout -> Value
encode value =
    Encode.notNullObject
        [ ( "canvas", value.canvas |> CanvasProps.encode )
        , ( "tables", value.tables |> Encode.list TableProps.encode )
        , ( "hiddenTables", value.hiddenTables |> Encode.withDefault (Encode.list TableProps.encode) [] )
        , ( "createdAt", value.createdAt |> Time.encode )
        , ( "updatedAt", value.updatedAt |> Time.encode )
        ]


decode : Decode.Decoder Layout
decode =
    Decode.map5 Layout
        (Decode.field "canvas" CanvasProps.decode)
        (Decode.field "tables" (Decode.list TableProps.decode))
        (Decode.defaultField "hiddenTables" (Decode.list TableProps.decode) [])
        (Decode.field "createdAt" Time.decode)
        (Decode.field "updatedAt" Time.decode)
