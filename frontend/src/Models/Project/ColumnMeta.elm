module Models.Project.ColumnMeta exposing (ColumnMeta, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Models.Tag as Tag exposing (Tag)


type alias ColumnMeta =
    { tags : List Tag }


encode : ColumnMeta -> Value
encode value =
    Encode.notNullObject
        [ ( "tags", value.tags |> Encode.withDefault (Encode.list Tag.encode) [] )
        ]


decode : Decode.Decoder ColumnMeta
decode =
    Decode.map ColumnMeta
        (Decode.defaultField "tags" (Decode.list Decode.string) [])
