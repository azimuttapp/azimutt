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
import Libs.Models.Position exposing (Position)
import Libs.Models.Size exposing (Size)
import Libs.Models.Uuid as Uuid exposing (Uuid)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel exposing (Nel)
import Libs.Tailwind as Tw exposing (Color)
import Models.Position as Position
import Random
import Time


positionViewport : Fuzzer Position.Viewport
positionViewport =
    position |> Fuzz.map Position.buildViewport


positionCanvas : Fuzzer Position.Diagram
positionCanvas =
    position |> Fuzz.map Position.buildDiagram


positionInCanvas : Fuzzer Position.Canvas
positionInCanvas =
    position |> Fuzz.map Position.buildCanvas


positionGrid : Fuzzer Position.CanvasGrid
positionGrid =
    position |> Fuzz.map Position.buildCanvasGrid


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


uuid : Fuzzer Uuid
uuid =
    Fuzz.int |> Fuzz.map (Random.initialSeed >> Random.step Uuid.generator >> Tuple.first)


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
