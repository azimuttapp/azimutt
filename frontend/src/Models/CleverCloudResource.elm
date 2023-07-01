module Models.CleverCloudResource exposing (CleverCloudResource, decode, encode)

import Json.Decode as Decode
import Json.Encode exposing (Value)
import Libs.Json.Encode as Encode
import Models.CleverCloudId as CleverCloudId exposing (CleverCloudId)


type alias CleverCloudResource =
    { id : CleverCloudId }


encode : CleverCloudResource -> Value
encode value =
    Encode.notNullObject
        [ ( "id", value.id |> CleverCloudId.encode ) ]


decode : Decode.Decoder CleverCloudResource
decode =
    Decode.map CleverCloudResource
        (Decode.field "id" CleverCloudId.decode)
