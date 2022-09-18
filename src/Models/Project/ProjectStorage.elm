module Models.Project.ProjectStorage exposing (ProjectStorage(..), decode, encode, icon)

import Components.Atoms.Icon as Icon
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type ProjectStorage
    = Local
    | Remote


icon : ProjectStorage -> Icon.Icon
icon storage =
    if storage == Local then
        Icon.Folder

    else
        Icon.Cloud


encode : ProjectStorage -> Value
encode value =
    case value of
        Local ->
            "local" |> Encode.string

        Remote ->
            "remote" |> Encode.string


decode : Decode.Decoder ProjectStorage
decode =
    Decode.string
        |> Decode.andThen
            (\value ->
                case value of
                    "local" ->
                        Local |> Decode.succeed

                    "remote" ->
                        Remote |> Decode.succeed

                    -- legacy values:
                    "browser" ->
                        Local |> Decode.succeed

                    "cloud" ->
                        Remote |> Decode.succeed

                    _ ->
                        Decode.fail ("invalid ProjectStorage '" ++ value ++ "'")
            )
