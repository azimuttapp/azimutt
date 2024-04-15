module Models.Project.TableDbStats exposing (TableDbStats, decode, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode


type alias TableDbStats =
    -- stats loaded from db computed stats
    { rows : Maybe Int
    , size : Maybe Int
    , sizeIdx : Maybe Int
    , scanSeq : Maybe Int
    , scanIdx : Maybe Int
    }


decode : Decoder TableDbStats
decode =
    Decode.map5 TableDbStats
        (Decode.maybeField "rows" Decode.int)
        (Decode.maybeField "size" Decode.int)
        (Decode.maybeField "sizeIdx" Decode.int)
        (Decode.maybeField "scanSeq" Decode.int)
        (Decode.maybeField "scanIdx" Decode.int)


encode : TableDbStats -> Value
encode value =
    Encode.notNullObject
        [ ( "rows", value.rows |> Encode.maybe Encode.int )
        , ( "size", value.size |> Encode.maybe Encode.int )
        , ( "sizeIdx", value.sizeIdx |> Encode.maybe Encode.int )
        , ( "scanSeq", value.scanSeq |> Encode.maybe Encode.int )
        , ( "scanIdx", value.scanIdx |> Encode.maybe Encode.int )
        ]
