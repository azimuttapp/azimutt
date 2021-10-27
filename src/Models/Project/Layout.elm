module Models.Project.Layout exposing (Layout, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Libs.Json.Formats exposing (decodePosix, encodePosix)
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


encode : Layout -> Value
encode value =
    E.object
        [ ( "canvas", value.canvas |> CanvasProps.encode )
        , ( "tables", value.tables |> Encode.list TableProps.encode )
        , ( "hiddenTables", value.hiddenTables |> E.withDefault (Encode.list TableProps.encode) [] )
        , ( "createdAt", value.createdAt |> encodePosix )
        , ( "updatedAt", value.updatedAt |> encodePosix )
        ]


decode : Decode.Decoder Layout
decode =
    Decode.map5 Layout
        (Decode.field "canvas" CanvasProps.decode)
        (Decode.field "tables" (Decode.list TableProps.decode))
        (D.defaultField "hiddenTables" (Decode.list TableProps.decode) [])
        (Decode.field "createdAt" decodePosix)
        (Decode.field "updatedAt" decodePosix)
