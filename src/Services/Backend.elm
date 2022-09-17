module Services.Backend exposing (Error, errorToString, getCurrentUser, getDatabaseSchema, getOrganizationsAndProjects, homeUrl, loginUrl, logoutUrl, profileUrl)

import Http exposing (Error(..))
import Json.Decode as Decode
import Json.Encode as Encode
import Libs.Bool as Bool
import Libs.Http as Http
import Libs.Json.Decode as Decode
import Libs.Models.DatabaseUrl as DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.Env as Env exposing (Env)
import Libs.Result as Result
import Libs.Time as Time
import Libs.Url as Url
import Models.Organization exposing (Organization)
import Models.Project.ProjectStorage as ProjectStorage exposing (ProjectStorage)
import Models.ProjectInfo exposing (ProjectInfo)
import Models.User as User2 exposing (User)
import Time
import Url exposing (Url)


type Error
    = Error String


errorToString : Error -> String
errorToString (Error err) =
    err


homeUrl : Env -> String
homeUrl env =
    "/" |> withLinkHost env


loginUrl : Env -> Url -> String
loginUrl env currentUrl =
    let
        ( url, redirect ) =
            ( "/auth/github" |> withLinkHost env, Url.asString currentUrl )
    in
    if redirect == "" then
        url

    else
        url ++ "?redirect=" ++ Url.percentEncode redirect


logoutUrl : Env -> String
logoutUrl env =
    "/users/log_out" |> withLinkHost env


profileUrl : Env -> String
profileUrl env =
    "/home" |> withLinkHost env


withLinkHost : Env -> String -> String
withLinkHost env path =
    if env == Env.Dev then
        "http://localhost:4000" ++ path

    else if env == Env.Staging then
        "https://azimutt.dev" ++ path

    else
        "https://azimutt.app" ++ path


getCurrentUser : Env -> (Result Error (Maybe User) -> msg) -> Cmd msg
getCurrentUser env toMsg =
    riskyGet
        { url = "/api/v1/users/current" |> withXhrHost env
        , expect = Http.expectJson (recoverUnauthorized >> Result.mapError buildError >> toMsg) User2.decode
        }


getOrganizationsAndProjects : Env -> (Result Error ( List Organization, List ProjectInfo ) -> msg) -> Cmd msg
getOrganizationsAndProjects env toMsg =
    riskyGet
        { url = "/api/v1/organizations?expand=projects" |> withXhrHost env
        , expect = Http.expectJson (Result.bimap buildError formatOrgasAndProjects >> toMsg) (Decode.list decodeOrga)
        }


getDatabaseSchema : Env -> DatabaseUrl -> (Result Error String -> msg) -> Cmd msg
getDatabaseSchema env url toMsg =
    riskyPost
        { url = "/api/v1/analyzer/schema" |> withXhrHost env
        , body = url |> databaseSchemaBody |> Http.jsonBody
        , expect = Http.expectStringResponse toMsg handleResponse
        }


databaseSchemaBody : DatabaseUrl -> Encode.Value
databaseSchemaBody url =
    Encode.object
        [ ( "url", url |> DatabaseUrl.encode ) ]


withXhrHost : Env -> String -> String
withXhrHost env path =
    if env == Env.Dev then
        path

    else if env == Env.Staging then
        "https://azimutt.dev" ++ path

    else
        "https://azimutt.app" ++ path


riskyGet : { url : String, expect : Http.Expect msg } -> Cmd msg
riskyGet r =
    Http.riskyRequest { method = "GET", url = r.url, headers = [], body = Http.emptyBody, expect = r.expect, timeout = Nothing, tracker = Nothing }


riskyPost : { url : String, body : Http.Body, expect : Http.Expect msg } -> Cmd msg
riskyPost r =
    Http.riskyRequest { method = "POST", url = r.url, headers = [], body = r.body, expect = r.expect, timeout = Nothing, tracker = Nothing }



-- HELPERS


formatOrgasAndProjects : List OrgaWithProjects -> ( List Organization, List ProjectInfo )
formatOrgasAndProjects orgas =
    ( orgas |> List.map buildOrganization
    , orgas
        |> List.concatMap
            (\o ->
                o.projects
                    |> List.map
                        (\p ->
                            { organization = Just (buildOrganization o)
                            , id = p.id
                            , slug = p.slug
                            , name = p.name
                            , description = p.description
                            , encodingVersion = p.encodingVersion
                            , storage = p.storage
                            , nbSources = p.nbSources
                            , nbTables = p.nbTables
                            , nbColumns = p.nbColumns
                            , nbRelations = p.nbRelations
                            , nbTypes = p.nbTypes
                            , nbComments = p.nbComments
                            , nbNotes = p.nbNotes
                            , nbLayouts = p.nbLayouts
                            , createdAt = p.createdAt
                            , updatedAt = p.updatedAt
                            , archivedAt = p.archivedAt
                            }
                        )
            )
    )


buildOrganization : OrgaWithProjects -> Organization
buildOrganization o =
    { id = o.id
    , slug = o.slug
    , name = o.name
    , activePlan = o.activePlan
    , logo = o.logo
    , location = o.location
    , description = o.description
    }


type alias OrgaWithProjects =
    { id : String
    , slug : String
    , name : String
    , activePlan : String
    , logo : String
    , location : Maybe String
    , description : Maybe String
    , projects : List OrgaProject
    }


type alias OrgaProject =
    { id : String
    , slug : String
    , name : String
    , description : Maybe String
    , encodingVersion : Int
    , storage : ProjectStorage
    , nbSources : Int
    , nbTables : Int
    , nbColumns : Int
    , nbRelations : Int
    , nbTypes : Int
    , nbComments : Int
    , nbNotes : Int
    , nbLayouts : Int
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    , archivedAt : Maybe Time.Posix
    }


decodeOrga : Decode.Decoder OrgaWithProjects
decodeOrga =
    Decode.map8 OrgaWithProjects
        (Decode.field "id" Decode.string)
        (Decode.field "slug" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "active_plan" Decode.string)
        (Decode.defaultField "logo" Decode.string "")
        (Decode.maybeField "location" Decode.string)
        (Decode.maybeField "description" Decode.string)
        (Decode.field "projects" (Decode.list decodeProject))


decodeProject : Decode.Decoder OrgaProject
decodeProject =
    Decode.map17 OrgaProject
        (Decode.field "id" Decode.string)
        (Decode.field "slug" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.maybeField "description" Decode.string)
        (Decode.field "encoding_version" Decode.int)
        (Decode.field "storage_kind" ProjectStorage.decode)
        (Decode.field "nb_sources" Decode.int)
        (Decode.field "nb_tables" Decode.int)
        (Decode.field "nb_columns" Decode.int)
        (Decode.field "nb_relations" Decode.int)
        (Decode.field "nb_types" Decode.int)
        (Decode.field "nb_comments" Decode.int)
        (Decode.field "nb_notes" Decode.int)
        (Decode.field "nb_layouts" Decode.int)
        (Decode.field "created_at" Time.decode)
        (Decode.field "updated_at" Time.decode)
        (Decode.maybeField "archived_at" Time.decode)


handleResponse : Http.Response String -> Result Error String
handleResponse response =
    case response of
        Http.BadUrl_ badUrl ->
            Http.BadUrl badUrl |> buildError |> Err

        Http.Timeout_ ->
            Http.Timeout |> buildError |> Err

        Http.NetworkError_ ->
            Http.NetworkError |> buildError |> Err

        Http.BadStatus_ metadata body ->
            case body |> Decode.decodeString errorDecoder of
                Ok err ->
                    metadata.statusText ++ ": " ++ err |> Error |> Err

                Err _ ->
                    (Http.BadStatus metadata.statusCode |> Http.errorToString) ++ (Bool.cond (String.isEmpty body) "" ": " ++ body) |> Error |> Err

        Http.GoodStatus_ _ body ->
            Ok body


recoverUnauthorized : Result Http.Error a -> Result Http.Error (Maybe a)
recoverUnauthorized r =
    case r of
        Ok a ->
            Ok (Just a)

        Err (BadStatus 401) ->
            Ok Nothing

        Err e ->
            Err e


buildError : Http.Error -> Error
buildError error =
    error |> Http.errorToString |> Error


errorDecoder : Decode.Decoder String
errorDecoder =
    Decode.field "message" Decode.string
