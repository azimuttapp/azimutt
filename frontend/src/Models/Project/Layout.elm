module Models.Project.Layout exposing (Layout, decode, doc, docLayout, empty, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Time as Time
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Group as Group exposing (Group)
import Models.Project.TableName exposing (TableName)
import Models.Project.TableProps as TableProps exposing (TableProps)
import Models.Project.TableRow as TableRow exposing (TableRow)
import PagesComponents.Organization_.Project_.Models.LinkLayout as LinkLayout exposing (LinkLayout)
import PagesComponents.Organization_.Project_.Models.Memo as Memo exposing (Memo)
import Time


type alias Layout =
    { tables : List TableProps
    , tableRows : List TableRow
    , groups : List Group
    , memos : List Memo
    , links : List LinkLayout
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


empty : Time.Posix -> Layout
empty now =
    { tables = [], tableRows = [], groups = [], memos = [], links = [], createdAt = now, updatedAt = now }


encode : Layout -> Value
encode value =
    Encode.notNullObject
        [ ( "tables", value.tables |> Encode.list TableProps.encode )
        , ( "tableRows", value.tableRows |> Encode.withDefault (Encode.list TableRow.encode) [] )
        , ( "groups", value.groups |> Encode.withDefault (Encode.list Group.encode) [] )
        , ( "memos", value.memos |> Encode.withDefault (Encode.list Memo.encode) [] )
        , ( "links", value.links |> Encode.withDefault (Encode.list LinkLayout.encode) [] )
        , ( "createdAt", value.createdAt |> Time.encode )
        , ( "updatedAt", value.updatedAt |> Time.encode )
        ]


decode : Decode.Decoder Layout
decode =
    Decode.map7 Layout
        (Decode.field "tables" (Decode.list TableProps.decode))
        (Decode.defaultField "tableRows" (Decode.list TableRow.decode) [])
        (Decode.defaultField "groups" (Decode.list Group.decode) [])
        (Decode.defaultField "memos" (Decode.list Memo.decode) [])
        (Decode.defaultField "links" (Decode.list LinkLayout.decode) [])
        (Decode.field "createdAt" Time.decode)
        (Decode.field "updatedAt" Time.decode)


docLayout : Layout
docLayout =
    { tables = [], tableRows = [], groups = [], memos = [], links = [], createdAt = Time.zero, updatedAt = Time.zero }


doc : List ( TableName, List ColumnName ) -> Layout
doc tables =
    { docLayout | tables = tables |> List.map (\( t, c ) -> TableProps.doc t c) }
