module Models.Project.TableMeta exposing (TableMeta, decode, empty, encode)

import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Models.Notes as Notes exposing (Notes)
import Libs.Models.Tag as Tag exposing (Tag)
import Libs.Tailwind as Tw
import Models.Project.ColumnMeta as ColumnMeta exposing (ColumnMeta)
import Models.Project.ColumnPath exposing (ColumnPath, ColumnPathStr)


type alias TableMeta =
    { notes : Maybe Notes
    , tags : List Tag
    , color : Maybe Tw.Color
    , columns : Dict ColumnPathStr ColumnMeta
    }


empty : TableMeta
empty =
    { notes = Nothing, tags = [], color = Nothing, columns = Dict.empty }


encode : TableMeta -> Value
encode value =
    Encode.notNullObject
        [ ( "notes", value.notes |> Encode.maybe Notes.encode )
        , ( "tags", value.tags |> Encode.withDefault (Encode.list Tag.encode) [] )
        , ( "color", value.color |> Encode.maybe Tw.encodeColor )
        , ( "columns", value.columns |> Encode.dict identity ColumnMeta.encode )
        ]


decode : Decode.Decoder TableMeta
decode =
    Decode.map4 TableMeta
        (Decode.maybeField "notes" Notes.decode)
        (Decode.defaultField "tags" (Decode.list Tag.decode) [])
        (Decode.maybeField "color" Tw.decodeColor)
        (Decode.defaultField "columns" (Decode.dict ColumnMeta.decode) Dict.empty)
