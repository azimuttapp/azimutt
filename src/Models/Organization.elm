module Models.Organization exposing (Organization)

import Libs.Models.Slug exposing (Slug)
import Models.OrganizationId exposing (OrganizationId)


type alias Organization =
    { id : OrganizationId
    , slug : Slug
    , name : String
    , activePlan : String
    , logo : String
    , location : Maybe String
    , description : Maybe String
    }
