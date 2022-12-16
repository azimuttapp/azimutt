module TestHelpers.HerokuFuzzers exposing (..)

import Fuzz exposing (Fuzzer)
import Models.HerokuId exposing (HerokuId)
import Models.HerokuResource exposing (HerokuResource)
import TestHelpers.Fuzzers exposing (uuid)


herokuId : Fuzzer HerokuId
herokuId =
    uuid


herokuResource : Fuzzer HerokuResource
herokuResource =
    Fuzz.map HerokuResource herokuId
