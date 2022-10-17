module TestHelpers.OrganizationFuzzers exposing (..)

import Fuzz exposing (Fuzzer)
import Libs.Fuzz as Fuzz
import Models.Organization exposing (Organization)
import Models.OrganizationId exposing (OrganizationId)
import Models.OrganizationName exposing (OrganizationName)
import Models.OrganizationSlug exposing (OrganizationSlug)
import Models.Plan exposing (Plan)
import TestHelpers.Fuzzers exposing (identifier, intPosSmall, stringSmall, uuid)


organization : Fuzzer Organization
organization =
    Fuzz.map7 Organization organizationId organizationSlug organizationName plan logo (Fuzz.maybe location) (Fuzz.maybe description)


organizationId : Fuzzer OrganizationId
organizationId =
    uuid


organizationSlug : Fuzzer OrganizationSlug
organizationSlug =
    identifier


organizationName : Fuzzer OrganizationName
organizationName =
    identifier


plan : Fuzzer Plan
plan =
    Fuzz.map6 Plan planId planName (Fuzz.maybe intPosSmall) Fuzz.bool Fuzz.bool Fuzz.bool


planId : Fuzzer String
planId =
    Fuzz.oneOf ([ "free", "team" ] |> List.map Fuzz.constant)


planName : Fuzzer String
planName =
    Fuzz.oneOf ([ "Free plan", "Team plan" ] |> List.map Fuzz.constant)


logo : Fuzzer String
logo =
    stringSmall


location : Fuzzer String
location =
    Fuzz.oneOf ([ "Paris", "Last Vegas" ] |> List.map Fuzz.constant)


description : Fuzzer String
description =
    stringSmall
