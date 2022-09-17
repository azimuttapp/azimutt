module TestHelpers.OrganizationFuzzers exposing (..)

import Fuzz exposing (Fuzzer)
import Libs.Fuzz as Fuzz
import Models.Organization exposing (Organization)
import Models.OrganizationId exposing (OrganizationId)
import Models.OrganizationName exposing (OrganizationName)
import Models.OrganizationSlug exposing (OrganizationSlug)
import TestHelpers.Fuzzers exposing (identifier, stringSmall, uuid)


organization : Fuzzer Organization
organization =
    Fuzz.map7 Organization organizationId organizationSlug organizationName activePlan logo (Fuzz.maybe location) (Fuzz.maybe description)


organizationId : Fuzzer OrganizationId
organizationId =
    uuid


organizationSlug : Fuzzer OrganizationSlug
organizationSlug =
    identifier


organizationName : Fuzzer OrganizationName
organizationName =
    identifier


activePlan : Fuzzer String
activePlan =
    Fuzz.oneOf ([ "free", "pro" ] |> List.map Fuzz.constant)


logo : Fuzzer String
logo =
    stringSmall


location : Fuzzer String
location =
    Fuzz.oneOf ([ "Paris", "Last Vegas" ] |> List.map Fuzz.constant)


description : Fuzzer String
description =
    stringSmall
