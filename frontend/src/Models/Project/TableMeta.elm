module Models.Project.TableMeta exposing (TableMeta, decode, encode, upsertTags)

import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Models.Tag as Tag exposing (Tag)
import Models.Project.ColumnMeta as ColumnMeta exposing (ColumnMeta)
import Models.Project.ColumnName exposing (ColumnName)


type alias TableMeta =
    { tags : List Tag

    -- FIXME: use ColumnPath instead of ColumnName
    , columns : Dict ColumnName ColumnMeta
    }


upsertTags : Maybe ColumnName -> List Tag -> Maybe TableMeta -> TableMeta
upsertTags column tags meta =
    meta |> Maybe.map (updateTags column tags) |> Maybe.withDefault (createTags column tags)


createTags : Maybe ColumnName -> List Tag -> TableMeta
createTags column tags =
    column
        |> Maybe.map (\c -> { tags = [], columns = Dict.fromList [ ( c, { tags = tags } ) ] })
        |> Maybe.withDefault { tags = tags, columns = Dict.empty }


updateTags : Maybe ColumnName -> List Tag -> TableMeta -> TableMeta
updateTags column tags meta =
    column
        |> Maybe.map (\name -> { meta | columns = meta.columns |> updateColumnMetadata name tags })
        |> Maybe.withDefault { meta | tags = tags }


updateColumnMetadata : ColumnName -> List Tag -> Dict ColumnName ColumnMeta -> Dict ColumnName ColumnMeta
updateColumnMetadata name tags metadata =
    metadata |> Dict.update name (\col -> col |> Maybe.map (\c -> c) |> Maybe.withDefault { tags = tags } |> Just)


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
