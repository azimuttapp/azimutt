module Models.Project.ProjectStorage exposing (ProjectStorage(..), decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type ProjectStorage
    = Browser
    | Cloud


encode : ProjectStorage -> Value
encode value =
    case value of
        Browser ->
            "browser" |> Encode.string

        Cloud ->
            "cloud" |> Encode.string


decode : Decode.Decoder ProjectStorage
decode =
    Decode.string
        |> Decode.andThen
            (\value ->
                case value of
                    "browser" ->
                        Browser |> Decode.succeed

                    "cloud" ->
                        Cloud |> Decode.succeed

                    _ ->
                        Decode.fail ("invalid ProjectStorage '" ++ value ++ "'")
            )
