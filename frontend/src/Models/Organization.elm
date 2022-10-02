module Models.Organization exposing (Organization, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Models.OrganizationId as OrganizationId exposing (OrganizationId)
import Models.OrganizationName as OrganizationName exposing (OrganizationName)
import Models.OrganizationSlug as OrganizationSlug exposing (OrganizationSlug)


type alias Organization =
    { id : OrganizationId
    , slug : OrganizationSlug
    , name : OrganizationName
    , activePlan : String
    , logo : String
    , location : Maybe String
    , description : Maybe String
    }


encode : Organization -> Value
encode value =
    Encode.notNullObject
        [ ( "id", value.id |> OrganizationId.encode )
        , ( "slug", value.slug |> OrganizationSlug.encode )
        , ( "name", value.name |> OrganizationName.encode )
        , ( "activePlan", value.activePlan |> Encode.string )
        , ( "logo", value.logo |> Encode.string )
        , ( "location", value.location |> Encode.maybe Encode.string )
        , ( "description", value.description |> Encode.maybe Encode.string )
        ]


decode : Decode.Decoder Organization
decode =
    Decode.map7 Organization
        (Decode.field "id" OrganizationId.decode)
        (Decode.field "slug" OrganizationSlug.decode)
        (Decode.field "name" OrganizationName.decode)
        (Decode.field "activePlan" Decode.string)
        (Decode.field "logo" Decode.string)
        (Decode.maybeField "location" Decode.string)
        (Decode.maybeField "description" Decode.string)