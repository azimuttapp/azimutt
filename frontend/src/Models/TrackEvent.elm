module Models.TrackEvent exposing (TrackClick, TrackEvent, encode)

import Json.Encode as Encode
import Libs.Json.Encode as Encode
import Libs.Nel as Nel
import Models.OrganizationId as OrganizationId exposing (OrganizationId)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)


type alias TrackEvent =
    { name : String
    , details : List ( String, Encode.Value )
    , organization : Maybe OrganizationId
    , project : Maybe ProjectId
    }


encode : TrackEvent -> Encode.Value
encode key =
    Encode.notNullObject
        [ ( "name", key.name |> Encode.string )
        , ( "details", key.details |> Nel.fromList |> Maybe.map Nel.toList |> Encode.maybe Encode.object )
        , ( "organization", key.organization |> Encode.maybe OrganizationId.encode )
        , ( "project", key.project |> Encode.maybe ProjectId.encode )
        ]


type alias TrackClick =
    { name : String
    , details : List ( String, String )
    , organization : Maybe OrganizationId
    , project : Maybe ProjectId
    }
