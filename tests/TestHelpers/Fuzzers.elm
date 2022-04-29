module TestHelpers.Fuzzers exposing (..)

import Conf
import Dict exposing (Dict)
import Fuzz exposing (Fuzzer)
import Libs.Fuzz as Fuzz
import Libs.Models.FileLineIndex exposing (FileLineIndex)
import Libs.Models.FileName exposing (FileName)
import Libs.Models.FileSize exposing (FileSize)
import Libs.Models.FileUpdatedAt exposing (FileUpdatedAt)
import Libs.Models.FileUrl exposing (FileUrl)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size exposing (Size)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel exposing (Nel)
import Libs.Tailwind as Tw exposing (Color)
import Time


position : Fuzzer Position
position =
    Fuzz.map (Position.stepBy Conf.canvas.grid)
        (Fuzz.map2 Position
            (Fuzz.floatRange -10000 10000)
            (Fuzz.floatRange -10000 10000)
        )


size : Fuzzer Size
size =
    Fuzz.map2 Size
        (Fuzz.floatRange 0 10000)
        (Fuzz.floatRange 0 10000)


fileName : Fuzzer FileName
fileName =
    stringSmall


fileUrl : Fuzzer FileUrl
fileUrl =
    stringSmall


fileSize : Fuzzer FileSize
fileSize =
    intPos


fileLineIndex : Fuzzer FileLineIndex
fileLineIndex =
    intPos


fileModified : Fuzzer FileUpdatedAt
fileModified =
    posix


zoomLevel : Fuzzer ZoomLevel
zoomLevel =
    Fuzz.floatRange Conf.canvas.zoom.min Conf.canvas.zoom.max


color : Fuzzer Color
color =
    Fuzz.oneOf (Tw.list |> List.map Fuzz.constant)



-- Generic fuzzers


listSmall : Fuzzer a -> Fuzzer (List a)
listSmall fuzz =
    -- TODO: should find a way to randomize list size but keep it small efficiently
    -- Fuzz.list can generate long lists & F.listN generate only size of n list, generating a random int then chaining with listN will be best
    Fuzz.listN 3 fuzz


nelSmall : Fuzzer a -> Fuzzer (Nel a)
nelSmall fuzz =
    Fuzz.nelN 3 fuzz


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
    Fuzz.letter |> Fuzz.list |> Fuzz.map String.fromList


path : Fuzzer String
path =
    -- TODO: this should generate a file path
    Fuzz.letter |> Fuzz.list |> Fuzz.map String.fromList


text : Fuzzer String
text =
    -- TODO: this should generate a text "normal" text, for example for comments
    Fuzz.letter |> Fuzz.list |> Fuzz.map String.fromList


word : Fuzzer String
word =
    Fuzz.letter |> Fuzz.list |> Fuzz.map String.fromList


intPos : Fuzzer Int
intPos =
    Fuzz.intRange 0 100000


intPosSmall : Fuzzer Int
intPosSmall =
    Fuzz.intRange 0 100


posix : Fuzzer Time.Posix
posix =
    Fuzz.intRange -10000000000 10000000000 |> Fuzz.map (\offset -> Time.millisToPosix (1626342639000 + offset))
