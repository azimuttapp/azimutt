module DataSources.DatabaseMiner.Models.DatabaseType exposing (DatabaseType, decode)

import Json.Decode as Decode
import Libs.Json.Decode as Decode


type alias DatabaseType =
    { schema : String
    , name : String
    , values : Maybe (List String)
    }


decode : Decode.Decoder DatabaseType
decode =
    Decode.map3 DatabaseType
        (Decode.field "schema" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.maybeField "values" (Decode.list Decode.string))
