module Models.Project.Layout exposing (Layout, decode, empty, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Time as Time
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.TableProps as TableProps exposing (TableProps)
import PagesComponents.Organization_.Project_.Models.Memo as Memo exposing (Memo)
import Time


type alias Layout =
    { canvas : CanvasProps
    , tables : List TableProps
    , memos : List Memo
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


empty : Time.Posix -> Layout
empty now =
    { canvas = CanvasProps.empty, tables = [], memos = [], createdAt = now, updatedAt = now }


encode : Layout -> Value
encode value =
    Encode.notNullObject
        [ ( "canvas", value.canvas |> CanvasProps.encode )
        , ( "tables", value.tables |> Encode.list TableProps.encode )
        , ( "memos", value.memos |> Encode.withDefault (Encode.list Memo.encode) [] )
        , ( "createdAt", value.createdAt |> Time.encode )
        , ( "updatedAt", value.updatedAt |> Time.encode )
        ]


decode : Decode.Decoder Layout
decode =
    Decode.map5 Layout
        (Decode.field "canvas" CanvasProps.decode)
        (Decode.field "tables" (Decode.list TableProps.decode))
        (Decode.defaultField "memos" (Decode.list Memo.decode) [])
        (Decode.field "createdAt" Time.decode)
        (Decode.field "updatedAt" Time.decode)
