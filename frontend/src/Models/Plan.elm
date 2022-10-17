module Models.Plan exposing (Plan, decode, encode, free)

import Conf
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode


type alias Plan =
    { id : String
    , name : String
    , layouts : Maybe Int
    , colors : Bool
    , dbAnalysis : Bool
    , dbAccess : Bool
    }


free : Plan
free =
    -- MUST stay in sync with backend/lib/azimutt/organizations/organization_plan.ex#free
    { id = "free"
    , name = "Free plan"
    , layouts = Just Conf.constants.freePlanLayouts
    , colors = False
    , dbAnalysis = False
    , dbAccess = False
    }


encode : Plan -> Value
encode value =
    Encode.object
        [ ( "id", value.id |> Encode.string )
        , ( "name", value.name |> Encode.string )
        , ( "layouts", value.layouts |> Encode.maybe Encode.int )
        , ( "colors", value.colors |> Encode.bool )
        , ( "db_analysis", value.dbAnalysis |> Encode.bool )
        , ( "db_access", value.dbAccess |> Encode.bool )
        ]


decode : Decode.Decoder Plan
decode =
    Decode.map6 Plan
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.maybeField "layouts" Decode.int)
        (Decode.field "colors" Decode.bool)
        (Decode.field "db_analysis" Decode.bool)
        (Decode.field "db_access" Decode.bool)
