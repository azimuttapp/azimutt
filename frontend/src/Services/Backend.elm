module Services.Backend exposing (Error, Sample, SampleSchema, blogArticleUrl, blogUrl, embedUrl, errorStatus, errorToString, getCurrentUser, getDatabaseSchema, getOrganizationsAndProjects, getSamples, homeUrl, internal, loginUrl, logoutUrl, organizationBillingUrl, organizationUrl, projectContentUrl, resourceUrl)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Either exposing (Either(..))
import Http exposing (Error(..))
import Json.Decode as Decode
import Json.Encode as Encode
import Libs.Bool as Bool
import Libs.Http as Http
import Libs.Json.Decode as Decode
import Libs.Maybe as Maybe
import Libs.Models.DatabaseUrl as DatabaseUrl exposing (DatabaseUrl)
import Libs.Result as Result
import Libs.Tailwind exposing (Color, decodeColor)
import Libs.Time as Time
import Libs.Url as Url
import Models.Organization exposing (Organization)
import Models.OrganizationId as OrganizationId exposing (OrganizationId)
import Models.Plan as Plan exposing (Plan)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)
import Models.Project.ProjectStorage as ProjectStorage exposing (ProjectStorage)
import Models.ProjectInfo exposing (ProjectInfo)
import Models.User as User exposing (User)
import PagesComponents.Organization_.Project_.Models.EmbedKind as EmbedKind exposing (EmbedKind)
import PagesComponents.Organization_.Project_.Models.EmbedMode as EmbedMode exposing (EmbedModeId)
import Time
import Url exposing (Url)


type Error
    = Error Int String


errorStatus : Error -> Int
errorStatus (Error status _) =
    status


errorToString : Error -> String
errorToString (Error _ err) =
    err


homeUrl : String
homeUrl =
    "/"


loginUrl : Url -> String
loginUrl currentUrl =
    let
        ( url, redirect ) =
            ( "/login", currentUrl |> Url.relative )
    in
    if redirect == "" then
        url

    else
        url ++ "/redirect?url=" ++ Url.percentEncode redirect


logoutUrl : String
logoutUrl =
    "/logout"


organizationUrl : Maybe OrganizationId -> String
organizationUrl organization =
    organization |> Maybe.filter (\id -> id /= OrganizationId.zero) |> Maybe.mapOrElse (\id -> "/organizations/" ++ id) "/home"


organizationBillingUrl : OrganizationId -> String
organizationBillingUrl organization =
    "/organizations/" ++ organization ++ "/billing"


projectContentUrl : OrganizationId -> ProjectId -> String
projectContentUrl organization project =
    "/api/v1/organizations/" ++ organization ++ "/projects/" ++ project ++ "/content"


blogUrl : String
blogUrl =
    "/blog"


blogArticleUrl : String -> String
blogArticleUrl slug =
    "/blog/" ++ slug


embedUrl : EmbedKind -> String -> LayoutName -> EmbedModeId -> String
embedUrl kind content layout mode =
    let
        queryString : String
        queryString =
            [ ( EmbedKind.value kind, content )
            , ( "layout", layout )
            , ( EmbedMode.key, mode )
            ]
                |> List.filter (\( _, value ) -> value /= "")
                |> Url.buildQueryString
    in
    "/embed?" ++ queryString


resourceUrl : String -> String
resourceUrl path =
    "/elm" ++ path


type alias SampleSchema =
    { url : String, color : Color, icon : Icon, key : String, name : String, description : String, tables : Int }


internal : Url -> Either String Url
internal url =
    if isExternal url then
        url |> Url.relative |> Left

    else
        url |> Right


isExternal : Url -> Bool
isExternal url =
    -- identify urls that are not inside Elm app and needs a page load (Elixir backend pages)
    (url.path == "/")
        || (url.path == "/home")
        || (url.path |> String.startsWith "/login")
        || (url.path == "/logout")
        || (url.path |> String.startsWith "/organizations/")


type alias Sample =
    { slug : String, color : Color, icon : Icon, name : String, description : String, project_id : ProjectId, nb_tables : Int }


getSamples : (Result Error (List Sample) -> msg) -> Cmd msg
getSamples toMsg =
    riskyGet
        { url = "/api/v1/gallery"
        , expect = Http.expectJson (Result.mapError buildError >> toMsg) (Decode.list decodeSample)
        }


getCurrentUser : (Result Error (Maybe User) -> msg) -> Cmd msg
getCurrentUser toMsg =
    riskyGet
        { url = "/api/v1/users/current"
        , expect = Http.expectJson (recoverUnauthorized >> Result.mapError buildError >> toMsg) User.decode
        }


getOrganizationsAndProjects : (Result Error ( List Organization, List ProjectInfo ) -> msg) -> Cmd msg
getOrganizationsAndProjects toMsg =
    riskyGet
        { url = "/api/v1/organizations?expand=plan,projects"
        , expect = Http.expectJson (Result.bimap buildError formatOrgasAndProjects >> toMsg) (Decode.list decodeOrga)
        }


getDatabaseSchema : DatabaseUrl -> (Result Error String -> msg) -> Cmd msg
getDatabaseSchema url toMsg =
    riskyPost
        { url = "/api/v1/analyzer/schema"
        , body = url |> databaseSchemaBody |> Http.jsonBody
        , expect = Http.expectStringResponse toMsg handleResponse
        }


databaseSchemaBody : DatabaseUrl -> Encode.Value
databaseSchemaBody url =
    Encode.object
        [ ( "url", url |> DatabaseUrl.encode ) ]


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
                            , storage = p.storage
                            , version = p.encodingVersion
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
                            }
                        )
            )
    )


buildOrganization : OrgaWithProjects -> Organization
buildOrganization o =
    { id = o.id
    , slug = o.slug
    , name = o.name
    , plan = o.plan
    , logo = o.logo
    , location = o.location
    , description = o.description
    }


type alias OrgaWithProjects =
    { id : String
    , slug : String
    , name : String
    , plan : Plan
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
        (Decode.field "plan" Plan.decode)
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


decodeSample : Decode.Decoder Sample
decodeSample =
    Decode.map7 Sample
        (Decode.field "slug" Decode.string)
        (Decode.field "color" decodeColor)
        (Decode.field "icon" Icon.decode)
        (Decode.field "name" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "project_id" ProjectId.decode)
        (Decode.field "nb_tables" Decode.int)


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
                    metadata.statusText ++ ": " ++ err |> Error metadata.statusCode |> Err

                Err _ ->
                    (Http.BadStatus metadata.statusCode |> Http.errorToString) ++ (Bool.cond (String.isEmpty body) "" ": " ++ body) |> Error metadata.statusCode |> Err

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
    case error of
        BadStatus status ->
            error |> Http.errorToString |> Error status

        _ ->
            error |> Http.errorToString |> Error 0


errorDecoder : Decode.Decoder String
errorDecoder =
    Decode.field "message" Decode.string
