module Models.Project.TableDbStats exposing (TableDbStats, decode, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Time as Time
import Time


type alias TableDbStats =
    -- stats loaded from db computed stats
    { rows : Maybe Int
    , size : Maybe Int
    , sizeIdx : Maybe Int
    , scanSeq : Maybe Int
    , scanSeqLast : Maybe Time.Posix
    , scanIdx : Maybe Int
    , scanIdxLast : Maybe Time.Posix
    , analyzeLast : Maybe Time.Posix
    , vacuumLast : Maybe Time.Posix
    }


decode : Decoder TableDbStats
decode =
    Decode.map9 TableDbStats
        (Decode.maybeField "rows" Decode.int)
        (Decode.maybeField "size" Decode.int)
        (Decode.maybeField "sizeIdx" Decode.int)
        (Decode.maybeField "scanSeq" Decode.int)
        (Decode.maybeField "scanSeqLast" Time.decode)
        (Decode.maybeField "scanIdx" Decode.int)
        (Decode.maybeField "scanIdxLast" Time.decode)
        (Decode.maybeField "analyzeLast" Time.decode)
        (Decode.maybeField "vacuumLast" Time.decode)


encode : TableDbStats -> Value
encode value =
    Encode.notNullObject
        [ ( "rows", value.rows |> Encode.maybe Encode.int )
        , ( "size", value.size |> Encode.maybe Encode.int )
        , ( "sizeIdx", value.sizeIdx |> Encode.maybe Encode.int )
        , ( "scanSeq", value.scanSeq |> Encode.maybe Encode.int )
        , ( "scanSeqLast", value.scanSeqLast |> Encode.maybe Time.encodeIso )
        , ( "scanIdx", value.scanIdx |> Encode.maybe Encode.int )
        , ( "scanIdxLast", value.scanIdxLast |> Encode.maybe Time.encodeIso )
        , ( "analyzeLast", value.analyzeLast |> Encode.maybe Time.encodeIso )
        , ( "vacuumLast", value.vacuumLast |> Encode.maybe Time.encodeIso )
        ]
