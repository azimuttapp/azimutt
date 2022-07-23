module Services.Backend exposing (Error, Url, errorToString, getDatabaseSchema, urlFromString)

import Http
import Json.Decode as Decode
import Json.Encode as Encode
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
            Err (Error ("Bad url: " ++ badUrl))

        Http.Timeout_ ->
            Err (Error "Timeout")

        Http.NetworkError_ ->
            Err (Error "Network error")

        Http.BadStatus_ metadata body ->
            case body |> Decode.decodeString errorDecoder of
                Ok err ->
                    Err (Error (metadata.statusText ++ ": " ++ err))

                Err _ ->
                    Err
                        (Error
                            ("Unknown "
                                ++ metadata.statusText
                                ++ " error"
                                ++ (if String.isEmpty body then
                                        ""

                                    else
                                        ": " ++ body
                                   )
                            )
                        )

        Http.GoodStatus_ _ body ->
            Ok body


errorDecoder : Decode.Decoder String
errorDecoder =
    Decode.field "message" Decode.string
