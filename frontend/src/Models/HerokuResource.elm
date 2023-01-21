module Models.HerokuResource exposing (HerokuResource, decode, encode)

import Json.Decode as Decode
import Json.Encode exposing (Value)
import Libs.Json.Encode as Encode
import Models.HerokuId as HerokuId exposing (HerokuId)


type alias HerokuResource =
    { id : HerokuId }


encode : HerokuResource -> Value
encode value =
    Encode.notNullObject
        [ ( "id", value.id |> HerokuId.encode ) ]


decode : Decode.Decoder HerokuResource
decode =
    Decode.map HerokuResource
        (Decode.field "id" HerokuId.decode)
