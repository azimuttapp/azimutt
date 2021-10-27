module Models.Project.Origin exposing (Origin, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Encode as E
import Libs.Json.Formats exposing (decodeFileLineIndex, encodeFileLineIndex)
import Libs.Models exposing (FileLineIndex)
import Models.Project.SourceId as SourceId exposing (SourceId)


type alias Origin =
    { id : SourceId, lines : List FileLineIndex }


encode : Origin -> Value
encode value =
    E.object
        [ ( "id", value.id |> SourceId.encode )
        , ( "lines", value.lines |> Encode.list encodeFileLineIndex )
        ]


decode : Decode.Decoder Origin
decode =
    Decode.map2 Origin
        (Decode.field "id" SourceId.decode)
        (Decode.field "lines" (Decode.list decodeFileLineIndex))
