module Models.ParserError exposing (EditorPosition, ParserError, ParserErrorKind(..), TokenOffset, TokenPosition, decode)

import Json.Decode as Decode
import Libs.Json.Decode as Decode


type alias ParserError =
    { name : String
    , kind : ParserErrorKind
    , message : String
    , offset : TokenOffset
    , position : TokenPosition
    }


type ParserErrorKind
    = Error
    | Warning
    | Info
    | Hint


type alias TokenOffset =
    { start : Int, end : Int }


type alias TokenPosition =
    { start : EditorPosition, end : EditorPosition }


type alias EditorPosition =
    { line : Int, column : Int }


decode : Decode.Decoder ParserError
decode =
    Decode.map5 ParserError
        (Decode.field "name" Decode.string)
        (Decode.field "kind" decodeParserErrorKind)
        (Decode.field "message" Decode.string)
        (Decode.field "offset" decodeTokenOffset)
        (Decode.field "position" decodeTokenPosition)


decodeParserErrorKind : Decode.Decoder ParserErrorKind
decodeParserErrorKind =
    Decode.string |> Decode.andThen (\v -> v |> parserErrorKindFromString |> Decode.fromMaybe ("'" ++ v ++ "' is not a valid ParserErrorKind"))


parserErrorKindFromString : String -> Maybe ParserErrorKind
parserErrorKindFromString value =
    case value of
        "error" ->
            Just Error

        "warning" ->
            Just Warning

        "info" ->
            Just Info

        "hint" ->
            Just Hint

        _ ->
            Nothing


decodeTokenOffset : Decode.Decoder TokenOffset
decodeTokenOffset =
    Decode.map2 TokenOffset
        (Decode.field "start" Decode.int)
        (Decode.field "end" Decode.int)


decodeTokenPosition : Decode.Decoder TokenPosition
decodeTokenPosition =
    Decode.map2 TokenPosition
        (Decode.field "start" decodeEditorPosition)
        (Decode.field "end" decodeEditorPosition)


decodeEditorPosition : Decode.Decoder EditorPosition
decodeEditorPosition =
    Decode.map2 EditorPosition
        (Decode.field "line" Decode.int)
        (Decode.field "column" Decode.int)
