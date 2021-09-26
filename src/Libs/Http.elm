module Libs.Http exposing (errorToString)

import Http exposing (Error(..))


errorToString : Http.Error -> String
errorToString error =
    case error of
        BadUrl url ->
            "The URL " ++ url ++ " was invalid"

        Timeout ->
            "Unable to reach the server, try again"

        NetworkError ->
            "Unable to reach the server, check your network connection"

        BadStatus 500 ->
            "The server had a problem, try again later"

        BadStatus 400 ->
            "Verify your information and try again"

        BadStatus 404 ->
            "Not found"

        BadStatus code ->
            "Unknown error (code: " ++ String.fromInt code ++ ")"

        BadBody errorMessage ->
            errorMessage
