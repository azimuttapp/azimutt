module Models.OpenAIModel exposing (OpenAIModel, all, decode, default, encode, fromString, toLabel, toString)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Libs.Json.Decode as Decode


type OpenAIModel
    = GPT4o
    | GPT4
    | GPT3_5


default : OpenAIModel
default =
    GPT4o


all : List OpenAIModel
all =
    [ GPT4o, GPT4, GPT3_5 ]


fromString : String -> Maybe OpenAIModel
fromString model =
    case model of
        "gpt-4o" ->
            Just GPT4o

        "gpt-4-turbo" ->
            Just GPT4

        "gpt-3.5-turbo" ->
            Just GPT3_5

        _ ->
            Nothing


toString : OpenAIModel -> String
toString model =
    case model of
        GPT4o ->
            "gpt-4o"

        GPT4 ->
            "gpt-4-turbo"

        GPT3_5 ->
            "gpt-3.5-turbo"


toLabel : OpenAIModel -> String
toLabel model =
    case model of
        GPT4o ->
            "GPT-4o (newest)"

        GPT4 ->
            "GPT-4"

        GPT3_5 ->
            "GPT-3.5 (cheapest)"


encode : OpenAIModel -> Encode.Value
encode model =
    model |> toString |> Encode.string


decode : Decoder OpenAIModel
decode =
    Decode.string |> Decode.andThen (\v -> v |> fromString |> Decode.fromMaybe ("'" ++ v ++ "' is not a valid OpenAIModel"))
