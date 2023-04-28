module Models.Project.ColumnMeta exposing (ColumnMeta, decode, empty, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Models.Notes as Notes exposing (Notes)
import Libs.Models.Tag as Tag exposing (Tag)


type alias ColumnMeta =
    { notes : Maybe Notes
    , tags : List Tag
    }


empty : ColumnMeta
empty =
    { notes = Nothing, tags = [] }


encode : ColumnMeta -> Value
encode value =
    Encode.notNullObject
        [ ( "notes", value.notes |> Encode.maybe Notes.encode )
        , ( "tags", value.tags |> Encode.withDefault (Encode.list Tag.encode) [] )
        ]


decode : Decode.Decoder ColumnMeta
decode =
    Decode.map2 ColumnMeta
        (Decode.maybeField "notes" Notes.decode)
        (Decode.defaultField "tags" (Decode.list Decode.string) [])
