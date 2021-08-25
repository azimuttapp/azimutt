module TestHelpers.Fuzzers exposing (..)

import Conf exposing (conf)
import Dict exposing (Dict)
import Fuzz exposing (Fuzzer)
import Libs.Fuzz as F
import Libs.Models exposing (Color, ZoomLevel)
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel exposing (Nel)
import Libs.Position exposing (Position)
import Libs.Size exposing (Size)
import Time


position : Fuzzer Position
position =
    Fuzz.map2 Position
        (Fuzz.floatRange -10000 10000)
        (Fuzz.floatRange -10000 10000)


size : Fuzzer Size
size =
    Fuzz.map2 Size
        (Fuzz.floatRange 0 10000)
        (Fuzz.floatRange 0 10000)


zoomLevel : Fuzzer ZoomLevel
zoomLevel =
    Fuzz.floatRange conf.zoom.min conf.zoom.max


color : Fuzzer Color
color =
    Fuzz.oneOf (conf.colors |> List.map Fuzz.constant)



-- Generic fuzzers


listSmall : Fuzzer a -> Fuzzer (List a)
listSmall fuzz =
    -- TODO: should find a way to randomize list size but keep it small efficiently
    -- Fuzz.list can generate long lists & F.listN generate only size of n list, generating a random int then chaining with listN will be best
    F.listN 3 fuzz


nelSmall : Fuzzer a -> Fuzzer (Nel a)
nelSmall fuzz =
    F.nelN 3 fuzz


dictSmall : Fuzzer comparable -> Fuzzer a -> Fuzzer (Dict comparable a)
dictSmall fuzzK fuzzA =
    Fuzz.tuple ( fuzzK, fuzzA ) |> listSmall |> Fuzz.map Dict.fromList


nedSmall : Fuzzer comparable -> Fuzzer a -> Fuzzer (Ned comparable a)
nedSmall fuzzK fuzzA =
    Fuzz.tuple ( fuzzK, fuzzA ) |> nelSmall |> Fuzz.map Ned.fromNel


stringSmall : Fuzzer String
stringSmall =
    Fuzz.string |> Fuzz.map (String.slice 0 10)


identifier : Fuzzer String
identifier =
    -- TODO: this should generate valid sql identifiers (letters, digits, _)
    F.letter |> Fuzz.list |> Fuzz.map String.fromList


path : Fuzzer String
path =
    -- TODO: this should generate a file path
    F.letter |> Fuzz.list |> Fuzz.map String.fromList


text : Fuzzer String
text =
    -- TODO: this should generate a text "normal" text, for example for comments
    F.letter |> Fuzz.list |> Fuzz.map String.fromList


word : Fuzzer String
word =
    F.letter |> Fuzz.list |> Fuzz.map String.fromList


intPos : Fuzzer Int
intPos =
    Fuzz.intRange 0 100000


intPosSmall : Fuzzer Int
intPosSmall =
    Fuzz.intRange 0 100


posix : Fuzzer Time.Posix
posix =
    Fuzz.intRange -10000000000 10000000000 |> Fuzz.map (\offset -> Time.millisToPosix (1626342639000 + offset))
