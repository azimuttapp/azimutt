module Models.Plan exposing (Plan, decode, encode, free, pro)

import Conf
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode


type alias Plan =
    -- MUST stay in sync with libs/models/src/legacy/legacyProject.ts & backend/lib/azimutt/organizations/organization_plan.ex
    { id : String
    , name : String
    , projects : Maybe Int
    , layouts : Maybe Int
    , layoutTables : Maybe Int
    , memos : Maybe Int
    , groups : Maybe Int
    , colors : Bool
    , localSave : Bool
    , privateLinks : Bool
    , sqlExport : Bool
    , dbAnalysis : Bool
    , dbAccess : Bool
    , streak : Int
    }


free : Plan
free =
    -- MUST stay in sync with backend/lib/azimutt/organizations/organization_plan.ex#free
    { id = "free"
    , name = "Free plan"
    , projects = Just Conf.features.projects.free
    , layouts = Just Conf.features.layouts.free
    , layoutTables = Just Conf.features.layoutTables.free
    , memos = Just Conf.features.memos.free
    , groups = Just Conf.features.groups.free
    , colors = Conf.features.tableColor.free
    , localSave = Conf.features.localSave.free
    , privateLinks = Conf.features.privateLinks.free
    , sqlExport = Conf.features.sqlExport.free
    , dbAnalysis = Conf.features.dbAnalysis.free
    , dbAccess = Conf.features.dbAnalysis.free
    , streak = 0
    }


pro : Plan
pro =
    -- used in tests
    { id = "pro"
    , name = "Pro"
    , projects = Nothing
    , layouts = Nothing
    , layoutTables = Nothing
    , memos = Nothing
    , groups = Nothing
    , colors = True
    , localSave = True
    , privateLinks = True
    , sqlExport = True
    , dbAnalysis = True
    , dbAccess = True
    , streak = 0
    }


encode : Plan -> Value
encode value =
    Encode.object
        [ ( "id", value.id |> Encode.string )
        , ( "name", value.name |> Encode.string )
        , ( "projects", value.projects |> Encode.maybe Encode.int )
        , ( "layouts", value.layouts |> Encode.maybe Encode.int )
        , ( "layout_tables", value.layoutTables |> Encode.maybe Encode.int )
        , ( "memos", value.memos |> Encode.maybe Encode.int )
        , ( "groups", value.groups |> Encode.maybe Encode.int )
        , ( "colors", value.colors |> Encode.bool )
        , ( "local_save", value.localSave |> Encode.bool )
        , ( "private_links", value.privateLinks |> Encode.bool )
        , ( "sql_export", value.sqlExport |> Encode.bool )
        , ( "db_analysis", value.dbAnalysis |> Encode.bool )
        , ( "db_access", value.dbAccess |> Encode.bool )
        , ( "streak", value.streak |> Encode.int )
        ]


decode : Decode.Decoder Plan
decode =
    Decode.map14 Plan
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.maybeField "projects" Decode.int)
        (Decode.maybeField "layouts" Decode.int)
        (Decode.maybeField "layout_tables" Decode.int)
        (Decode.maybeField "memos" Decode.int)
        (Decode.maybeField "groups" Decode.int)
        (Decode.field "colors" Decode.bool)
        (Decode.field "local_save" Decode.bool)
        (Decode.field "private_links" Decode.bool)
        (Decode.field "sql_export" Decode.bool)
        (Decode.field "db_analysis" Decode.bool)
        (Decode.field "db_access" Decode.bool)
        (Decode.field "streak" Decode.int)
