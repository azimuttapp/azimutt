module Models.Project.TableMeta exposing (TableMeta, decode, empty, encode, upsertTags)

import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Models.Tag as Tag exposing (Tag)
import Models.Project.ColumnMeta as ColumnMeta exposing (ColumnMeta)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath, ColumnPathStr)


type alias TableMeta =
    { tags : List Tag
    , columns : Dict ColumnPathStr ColumnMeta
    }


empty : TableMeta
empty =
    { tags = [], columns = Dict.empty }


upsertTags : Maybe ColumnPath -> List Tag -> Maybe TableMeta -> Maybe TableMeta
upsertTags column tags meta =
    meta |> Maybe.map (updateTags column tags) |> Maybe.withDefault (createTags column tags) |> Just


createTags : Maybe ColumnPath -> List Tag -> TableMeta
createTags column tags =
    column
        |> Maybe.map (\c -> { tags = [], columns = Dict.fromList [ ( c |> ColumnPath.toString, { tags = tags } ) ] })
        |> Maybe.withDefault { tags = tags, columns = Dict.empty }


updateTags : Maybe ColumnPath -> List Tag -> TableMeta -> TableMeta
updateTags column tags meta =
    column
        |> Maybe.map (\name -> { meta | columns = meta.columns |> updateColumnMeta name tags })
        |> Maybe.withDefault { meta | tags = tags }


updateColumnMeta : ColumnPath -> List Tag -> Dict ColumnPathStr ColumnMeta -> Dict ColumnPathStr ColumnMeta
updateColumnMeta column tags metadata =
    metadata |> Dict.update (column |> ColumnPath.toString) (\col -> col |> Maybe.map (\c -> { c | tags = tags }) |> Maybe.withDefault { tags = tags } |> Just)


encode : TableMeta -> Value
encode value =
    Encode.notNullObject
        [ ( "tags", value.tags |> Encode.withDefault (Encode.list Tag.encode) [] )
        , ( "columns", value.columns |> Encode.dict identity ColumnMeta.encode )
        ]


decode : Decode.Decoder TableMeta
decode =
    Decode.map2 TableMeta
        (Decode.defaultField "tags" (Decode.list Decode.string) [])
        (Decode.defaultField "columns" (Decode.dict ColumnMeta.decode) Dict.empty)
