module Models.Project.ProjectVisibility exposing (ProjectVisibility(..), decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type ProjectVisibility
    = None
    | Read
    | Write


encode : ProjectVisibility -> Value
encode value =
    case value of
        None ->
            "none" |> Encode.string

        Read ->
            "read" |> Encode.string

        Write ->
            "write" |> Encode.string


decode : Decode.Decoder ProjectVisibility
decode =
    Decode.string
        |> Decode.andThen
            (\value ->
                case value of
                    "none" ->
                        None |> Decode.succeed

                    "read" ->
                        Read |> Decode.succeed

                    "write" ->
                        Write |> Decode.succeed

                    _ ->
                        Decode.fail ("invalid ProjectVisibility '" ++ value ++ "'")
            )
