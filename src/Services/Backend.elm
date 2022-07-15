module Services.Backend exposing (BackendUrl, getDatabaseSchema, urlFromString)

import DataSources.DatabaseSchemaParser.DatabaseSchema as DatabaseSchema exposing (DatabaseSchema)
import Http
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)


type BackendUrl
    = BackendUrl String


urlFromString : String -> BackendUrl
urlFromString url =
    BackendUrl url


getDatabaseSchema : BackendUrl -> DatabaseUrl -> (Result Http.Error DatabaseSchema -> msg) -> Cmd msg
getDatabaseSchema (BackendUrl backendUrl) url toMsg =
    Http.get
        { url = backendUrl ++ "/database/schema?url=" ++ url
        , expect = Http.expectJson toMsg DatabaseSchema.decode
        }
