module Models.Project.Layout exposing (Layout, decode, empty, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Time as Time
import Models.Project.Group as Group exposing (Group)
import Models.Project.TableProps as TableProps exposing (TableProps)
import Models.Project.TableRow as TableRow exposing (TableRow)
import PagesComponents.Organization_.Project_.Models.Memo as Memo exposing (Memo)
import Time


type alias Layout =
    { tables : List TableProps
    , groups : List Group
    , memos : List Memo
    , tableRows : List TableRow
    , tableRowsSeq : Int
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


empty : Time.Posix -> Layout
empty now =
    { tables = [], groups = [], memos = [], tableRows = [], tableRowsSeq = 1, createdAt = now, updatedAt = now }


encode : Layout -> Value
encode value =
    Encode.notNullObject
        [ ( "tables", value.tables |> Encode.list TableProps.encode )
        , ( "groups", value.groups |> Encode.withDefault (Encode.list Group.encode) [] )
        , ( "memos", value.memos |> Encode.withDefault (Encode.list Memo.encode) [] )
        , ( "tableRows", value.tableRows |> Encode.withDefault (Encode.list TableRow.encode) [] )
        , ( "tableRowsSeq", value.tableRowsSeq |> Encode.withDefault Encode.int 1 )
        , ( "createdAt", value.createdAt |> Time.encode )
        , ( "updatedAt", value.updatedAt |> Time.encode )
        ]


decode : Decode.Decoder Layout
decode =
    Decode.map7 Layout
        (Decode.field "tables" (Decode.list TableProps.decode))
        (Decode.defaultField "groups" (Decode.list Group.decode) [])
        (Decode.defaultField "memos" (Decode.list Memo.decode) [])
        (Decode.defaultField "tableRows" (Decode.list TableRow.decode) [])
        (Decode.defaultField "tableRowsSeq" Decode.int 1)
        (Decode.field "createdAt" Time.decode)
        (Decode.field "updatedAt" Time.decode)
