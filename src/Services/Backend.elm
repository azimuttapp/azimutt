module Services.Backend exposing (Error, Url, errorToString, getDatabaseSchema, urlFromString)

import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Libs.Bool as Bool
import Libs.Http as Http
import Libs.Models.DatabaseUrl as DatabaseUrl exposing (DatabaseUrl)


type Url
    = BackendUrl String


type Error
    = Error String


urlFromString : String -> Url
urlFromString url =
    BackendUrl url


errorToString : Error -> String
errorToString (Error err) =
    err


getDatabaseSchema : Url -> DatabaseUrl -> (Result Error String -> msg) -> Cmd msg
getDatabaseSchema (BackendUrl backendUrl) url toMsg =
    Http.post
        { url = backendUrl ++ "/database/schema"
        , body = url |> databaseSchemaBody |> Http.jsonBody
        , expect = Http.expectStringResponse toMsg handleResponse
        }


databaseSchemaBody : DatabaseUrl -> Encode.Value
databaseSchemaBody url =
    Encode.object
        [ ( "url", url |> DatabaseUrl.encode ) ]



-- HELPERS


handleResponse : Http.Response String -> Result Error String
handleResponse response =
    case response of
        Http.BadUrl_ badUrl ->
            Http.BadUrl badUrl |> Http.errorToString |> Error |> Err

        Http.Timeout_ ->
            Http.Timeout |> Http.errorToString |> Error |> Err

        Http.NetworkError_ ->
            Http.NetworkError |> Http.errorToString |> Error |> Err

        Http.BadStatus_ metadata body ->
            case body |> Decode.decodeString errorDecoder of
                Ok err ->
                    metadata.statusText ++ ": " ++ err |> Error |> Err

                Err _ ->
                    (Http.BadStatus metadata.statusCode |> Http.errorToString) ++ (Bool.cond (String.isEmpty body) "" ": " ++ body) |> Error |> Err

        Http.GoodStatus_ _ body ->
            Ok body


errorDecoder : Decode.Decoder String
errorDecoder =
    Decode.field "message" Decode.string
