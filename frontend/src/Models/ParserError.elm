module Models.ParserError exposing (EditorPosition, ParserError, ParserErrorLevel(..), TokenOffset, TokenPosition, decode)

import Json.Decode as Decode
import Libs.Json.Decode as Decode


type alias ParserError =
    { message : String
    , kind : String
    , level : ParserErrorLevel
    , offset : TokenOffset
    , position : TokenPosition
    }


type ParserErrorLevel
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
        (Decode.field "message" Decode.string)
        (Decode.field "kind" Decode.string)
        (Decode.field "level" decodeParserErrorLevel)
        (Decode.field "offset" decodeTokenOffset)
        (Decode.field "position" decodeTokenPosition)


decodeParserErrorLevel : Decode.Decoder ParserErrorLevel
decodeParserErrorLevel =
    Decode.string |> Decode.andThen (\v -> v |> parserErrorLevelFromString |> Decode.fromMaybe ("'" ++ v ++ "' is not a valid ParserErrorLevel"))


parserErrorLevelFromString : String -> Maybe ParserErrorLevel
parserErrorLevelFromString value =
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
