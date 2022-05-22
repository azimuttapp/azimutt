module Models.Project.ProjectStorage exposing (ProjectStorage(..), decode, encode, icon)

import Components.Atoms.Icon as Icon
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type ProjectStorage
    = Browser
    | Cloud


icon : ProjectStorage -> Icon.Icon
icon storage =
    if storage == Browser then
        Icon.Folder

    else
        Icon.Cloud


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
