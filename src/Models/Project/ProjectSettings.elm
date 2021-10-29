module Models.Project.ProjectSettings exposing (ProjectSettings, decode, encode, init)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Models.Project.FindPathSettings as FindPathSettings exposing (FindPathSettings)
import Models.Project.SchemaName as SchemaName exposing (SchemaName)


type alias ProjectSettings =
    { findPath : FindPathSettings
    , hiddenSchemas : List SchemaName
    , shouldDisplayViews : Bool
    }


init : ProjectSettings
init =
    { findPath = FindPathSettings 3 [] []
    , hiddenSchemas = []
    , shouldDisplayViews = True
    }


encode : ProjectSettings -> ProjectSettings -> Value
encode default value =
    E.object
        [ ( "findPath", value.findPath |> E.withDefaultDeep FindPathSettings.encode default.findPath )
        , ( "hiddenSchemas", value.hiddenSchemas |> E.withDefault (Encode.list SchemaName.encode) default.hiddenSchemas )
        , ( "shouldDisplayViews", value.shouldDisplayViews |> E.withDefault Encode.bool default.shouldDisplayViews )
        ]


decode : ProjectSettings -> Decode.Decoder ProjectSettings
decode default =
    Decode.map3 ProjectSettings
        (D.defaultFieldDeep "findPath" FindPathSettings.decode default.findPath)
        (D.defaultField "hiddenSchemas" (Decode.list SchemaName.decode) default.hiddenSchemas)
        (D.defaultField "shouldDisplayViews" Decode.bool default.shouldDisplayViews)
