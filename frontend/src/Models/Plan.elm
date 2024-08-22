module Models.Plan exposing (Plan, decode, docSample, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Models.Feature as Feature


type alias Plan =
    -- MUST stay in sync with libs/models/src/legacy/legacyProject.ts & backend/lib/azimutt/organizations/organization_plan.ex
    { id : String
    , name : String
    , dataExploration : Bool -- TODO: add limitation (not done because available on all plans for now)
    , colors : Bool
    , aml : Bool
    , schemaExport : Bool
    , ai : Bool
    , analysis : String
    , projectExport : Bool
    , projects : Maybe Int
    , projectDbs : Maybe Int -- TODO
    , projectLayouts : Maybe Int
    , layoutTables : Maybe Int
    , projectDoc : Maybe Int -- TODO
    , projectShare : Bool
    , streak : Int
    }


encode : Plan -> Value
encode value =
    Encode.object
        [ ( "id", value.id |> Encode.string )
        , ( "name", value.name |> Encode.string )
        , ( Feature.dataExploration.name, value.dataExploration |> Encode.bool )
        , ( Feature.colors.name, value.colors |> Encode.bool )
        , ( Feature.aml.name, value.aml |> Encode.bool )
        , ( Feature.schemaExport.name, value.schemaExport |> Encode.bool )
        , ( Feature.ai.name, value.ai |> Encode.bool )
        , ( Feature.analysis.name, value.analysis |> Encode.string )
        , ( Feature.projectExport.name, value.projectExport |> Encode.bool )
        , ( Feature.projects.name, value.projects |> Encode.maybe Encode.int )
        , ( Feature.projectDbs.name, value.projectDbs |> Encode.maybe Encode.int )
        , ( Feature.projectLayouts.name, value.projectLayouts |> Encode.maybe Encode.int )
        , ( Feature.layoutTables.name, value.layoutTables |> Encode.maybe Encode.int )
        , ( Feature.projectDoc.name, value.projectDoc |> Encode.maybe Encode.int )
        , ( Feature.projectShare.name, value.projectShare |> Encode.bool )
        , ( "streak", value.streak |> Encode.int )
        ]


decode : Decode.Decoder Plan
decode =
    Decode.map16 Plan
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field Feature.dataExploration.name Decode.bool)
        (Decode.field Feature.colors.name Decode.bool)
        (Decode.field Feature.aml.name Decode.bool)
        (Decode.field Feature.schemaExport.name Decode.bool)
        (Decode.field Feature.ai.name Decode.bool)
        (Decode.field Feature.analysis.name Decode.string)
        (Decode.field Feature.projectExport.name Decode.bool)
        (Decode.maybeField Feature.projects.name Decode.int)
        (Decode.maybeField Feature.projectDbs.name Decode.int)
        (Decode.maybeField Feature.projectLayouts.name Decode.int)
        (Decode.maybeField Feature.layoutTables.name Decode.int)
        (Decode.maybeField Feature.projectDoc.name Decode.int)
        (Decode.field Feature.projectShare.name Decode.bool)
        (Decode.field "streak" Decode.int)


docSample : Plan
docSample =
    { id = "sample"
    , name = "Sample plan"
    , dataExploration = True
    , colors = True
    , aml = True
    , schemaExport = True
    , ai = True
    , analysis = "trends"
    , projectExport = True
    , projects = Nothing
    , projectDbs = Nothing
    , projectLayouts = Nothing
    , layoutTables = Nothing
    , projectDoc = Nothing
    , projectShare = True
    , streak = 0
    }
