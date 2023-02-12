module Models.Project.Origin exposing (Origin, decode, encode, encodeList)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Encode as Encode
import Libs.Models.FileLineIndex as FileLineIndex exposing (FileLineIndex)
import Libs.Nel as Nel
import Models.Project.SourceId as SourceId exposing (SourceId)


type alias Origin =
    { id : SourceId, lines : List FileLineIndex }


encodeList : List Origin -> Value
encodeList origins =
    origins |> Nel.fromList |> Encode.maybe (Encode.nel encode)


encode : Origin -> Value
encode value =
    Encode.notNullObject
        [ ( "id", value.id |> SourceId.encode )
        , ( "lines", value.lines |> Encode.list FileLineIndex.encode )
        ]


decode : Decode.Decoder Origin
decode =
    Decode.map2 Origin
        (Decode.field "id" SourceId.decode)
        (Decode.field "lines" (Decode.list FileLineIndex.decode))
