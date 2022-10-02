module Libs.Http exposing (decodeJson, errorToString)

import Http
import Json.Decode as Decode


decodeJson : (Result Http.Error (Result Decode.Error a) -> msg) -> Decode.Decoder a -> Http.Expect msg
decodeJson toMsg decoder =
    Http.expectString (Result.map (Decode.decodeString decoder) >> toMsg)


errorToString : Http.Error -> String
errorToString error =
    case error of
        Http.BadUrl url ->
            "The URL " ++ url ++ " was invalid"

        Http.Timeout ->
            "Unable to reach the server, try again"

        Http.NetworkError ->
            "Unable to reach the server, check your network connection"

        Http.BadStatus 500 ->
            "The server had a problem, try again later"

        Http.BadStatus 400 ->
            "Verify your information and try again"

        Http.BadStatus 404 ->
            "Not found"

        Http.BadStatus code ->
            "Unknown error (code: " ++ String.fromInt code ++ ")"

        Http.BadBody errorMessage ->
            errorMessage
