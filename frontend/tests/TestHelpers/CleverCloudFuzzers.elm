module TestHelpers.CleverCloudFuzzers exposing (..)

import Fuzz exposing (Fuzzer)
import Models.CleverCloudId exposing (CleverCloudId)
import Models.CleverCloudResource exposing (CleverCloudResource)
import TestHelpers.Fuzzers exposing (uuid)


cleverCloudId : Fuzzer CleverCloudId
cleverCloudId =
    uuid


cleverCloudResource : Fuzzer CleverCloudResource
cleverCloudResource =
    Fuzz.map CleverCloudResource cleverCloudId
