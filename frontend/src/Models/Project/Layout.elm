module Models.Project.Layout exposing (Layout, decode, empty, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Time as Time
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.Group as Group exposing (Group)
import Models.Project.TableProps as TableProps exposing (TableProps)
import PagesComponents.Organization_.Project_.Models.Memo as Memo exposing (Memo)
import Time


type alias Layout =
    { canvas : CanvasProps
    , tables : List TableProps
    , groups : List Group
    , memos : List Memo
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


empty : Time.Posix -> Layout
empty now =
    { canvas = CanvasProps.empty, tables = [], groups = [], memos = [], createdAt = now, updatedAt = now }


encode : Layout -> Value
encode value =
    Encode.notNullObject
        [ ( "canvas", value.canvas |> CanvasProps.encode )
        , ( "tables", value.tables |> Encode.list TableProps.encode )
        , ( "groups", value.groups |> Encode.withDefault (Encode.list Group.encode) [] )
        , ( "memos", value.memos |> Encode.withDefault (Encode.list Memo.encode) [] )
        , ( "createdAt", value.createdAt |> Time.encode )
        , ( "updatedAt", value.updatedAt |> Time.encode )
        ]


decode : Decode.Decoder Layout
decode =
    Decode.map6 Layout
        (Decode.field "canvas" CanvasProps.decode)
        (Decode.field "tables" (Decode.list TableProps.decode))
        (Decode.defaultField "groups" (Decode.list Group.decode) [])
        (Decode.defaultField "memos" (Decode.list Memo.decode) [])
        (Decode.field "createdAt" Time.decode)
        (Decode.field "updatedAt" Time.decode)
