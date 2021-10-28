module Models.Project.ProjectSettings exposing (ProjectSettings, decode, encode, init)

import Json.Decode as Decode
import Json.Encode exposing (Value)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Models.Project.FindPathSettings as FindPathSettings exposing (FindPathSettings)


type alias ProjectSettings =
    { findPath : FindPathSettings }


init : ProjectSettings
init =
    { findPath = FindPathSettings 3 [] [] }


encode : ProjectSettings -> ProjectSettings -> Value
encode default value =
    E.object [ ( "findPath", value.findPath |> E.withDefaultDeep FindPathSettings.encode default.findPath ) ]


decode : ProjectSettings -> Decode.Decoder ProjectSettings
decode default =
    Decode.map ProjectSettings
        (D.defaultFieldDeep "findPath" FindPathSettings.decode default.findPath)
