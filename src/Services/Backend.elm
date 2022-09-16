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
import Models.ProjectInfo2 exposing (ProjectInfo2)
import Models.User2 as User2 exposing (User2)
import Time
import Url exposing (Url)


type Error
    = Error String


errorToString : Error -> String
errorToString (Error err) =
    err


homeUrl : Env -> String
homeUrl env =
    "/" |> buildUrl env


loginUrl : Env -> Url -> String
loginUrl env currentUrl =
    let
        ( url, redirect ) =
            ( "/auth/github" |> buildUrl env, Url.asString currentUrl )
    in
    if redirect == "" then
        url

    else
        url ++ "?redirect=" ++ Url.percentEncode redirect


logoutUrl : Env -> String
logoutUrl env =
    "/users/log_out" |> buildUrl env


profileUrl : Env -> String
profileUrl env =
    "/home" |> buildUrl env


buildUrl : Env -> String -> String
buildUrl env path =
    if env == Env.Dev then
        "http://localhost:4000" ++ path

    else
        path


getCurrentUser : (Result Error (Maybe User2) -> msg) -> Cmd msg
getCurrentUser toMsg =
    Http.get
        { url = "/api/v1/users/current"
        , expect = Http.expectJson (recoverUnauthorized >> Result.mapError buildError >> toMsg) User2.decode
        }


getOrganizationsAndProjects : (Result Error ( List Organization, List ProjectInfo2 ) -> msg) -> Cmd msg
getOrganizationsAndProjects toMsg =
    Http.get
        { url = "/api/v1/organizations?expand=projects"
        , expect = Http.expectJson (Result.bimap buildError formatOrgasAndProjects >> toMsg) (Decode.list decodeOrga)
        }


getDatabaseSchema : DatabaseUrl -> (Result Error String -> msg) -> Cmd msg
getDatabaseSchema url toMsg =
    Http.post
        { url = "/api/v1/analyzer/schema"
        , body = url |> databaseSchemaBody |> Http.jsonBody
        , expect = Http.expectStringResponse toMsg handleResponse
        }


databaseSchemaBody : DatabaseUrl -> Encode.Value
databaseSchemaBody url =
    Encode.object
        [ ( "url", url |> DatabaseUrl.encode ) ]



-- HELPERS


formatOrgasAndProjects : List OrgaWithProjects -> ( List Organization, List ProjectInfo2 )
formatOrgasAndProjects orgas =
    ( orgas |> List.map buildOrganization
    , orgas
        |> List.concatMap
            (\o ->
                o.projects
                    |> List.map
                        (\p ->
                            { organization = buildOrganization o
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
