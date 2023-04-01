module Models.Organization exposing (Organization, decode, encode, one, zero)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Models.HerokuResource as HerokuResource exposing (HerokuResource)
import Models.OrganizationId as OrganizationId exposing (OrganizationId)
import Models.OrganizationName as OrganizationName exposing (OrganizationName)
import Models.OrganizationSlug as OrganizationSlug exposing (OrganizationSlug)
import Models.Plan as Plan exposing (Plan)


type alias Organization =
    { id : OrganizationId
    , slug : OrganizationSlug
    , name : OrganizationName
    , plan : Plan
    , logo : String
    , location : Maybe String
    , description : Maybe String
    , heroku : Maybe HerokuResource
    }


zero : Organization
zero =
    { id = OrganizationId.zero
    , slug = OrganizationId.zero
    , name = "zero"
    , plan = Plan.free
    , logo = "https://azimutt.app/images/logo_dark.svg"
    , location = Nothing
    , description = Nothing
    , heroku = Nothing
    }


one : Organization
one =
    { id = OrganizationId.one
    , slug = OrganizationId.one
    , name = "one"
    , plan = Plan.free
    , logo = "https://azimutt.app/images/logo_dark.svg"
    , location = Nothing
    , description = Nothing
    , heroku = Nothing
    }


encode : Organization -> Value
encode value =
    Encode.notNullObject
        [ ( "id", value.id |> OrganizationId.encode )
        , ( "slug", value.slug |> OrganizationSlug.encode )
        , ( "name", value.name |> OrganizationName.encode )
        , ( "plan", value.plan |> Plan.encode )
        , ( "logo", value.logo |> Encode.string )
        , ( "location", value.location |> Encode.maybe Encode.string )
        , ( "description", value.description |> Encode.maybe Encode.string )
        , ( "heroku", value.heroku |> Encode.maybe HerokuResource.encode )
        ]


decode : Decode.Decoder Organization
decode =
    Decode.map8 Organization
        (Decode.field "id" OrganizationId.decode)
        (Decode.field "slug" OrganizationSlug.decode)
        (Decode.field "name" OrganizationName.decode)
        (Decode.field "plan" Plan.decode)
        (Decode.field "logo" Decode.string)
        (Decode.maybeField "location" Decode.string)
        (Decode.maybeField "description" Decode.string)
        (Decode.maybeField "heroku" HerokuResource.decode)
