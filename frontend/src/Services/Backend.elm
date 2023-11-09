module Services.Backend exposing (Error, Sample, SampleSchema, TableColorTweet, blogArticleUrl, blogUrl, createProjectToken, embedUrl, errorStatus, errorToString, getCurrentUser, getOrganizationsAndProjects, getProjectTokens, getSamples, getTableColorTweet, internal, loginUrl, logoutUrl, organizationBillingUrl, organizationUrl, resourceUrl, revokeProjectToken, rootUrl)

import Components.Atoms.Icon as Icon exposing (Icon)
import Either exposing (Either(..))
import Http exposing (Error(..), Expect)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Libs.Bool as Bool
import Libs.Http as Http
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Maybe as Maybe
import Libs.Models exposing (TweetUrl)
import Libs.Tailwind exposing (Color, decodeColor)
import Libs.Time as Time
import Libs.Url as Url exposing (UrlPath(..))
import Models.CleverCloudResource as CleverCloudResource exposing (CleverCloudResource)
import Models.HerokuResource as HerokuResource exposing (HerokuResource)
import Models.Organization exposing (Organization)
import Models.OrganizationId as OrganizationId exposing (OrganizationId)
import Models.Plan as Plan exposing (Plan)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)
import Models.Project.ProjectStorage as ProjectStorage exposing (ProjectStorage)
import Models.Project.ProjectVisibility as ProjectVisibility exposing (ProjectVisibility)
import Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import Models.ProjectToken as ProjectToken exposing (ProjectToken)
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


rootUrl : UrlPath -> String
rootUrl (UrlPath basePath) =
    if basePath == "" then
        "/"

    else
        basePath


loginUrl : UrlPath -> Url -> String
loginUrl (UrlPath basePath) currentUrl =
    let
        ( url, redirect ) =
            ( basePath ++ "/login", currentUrl |> Url.relative )
    in
    if redirect == "" then
        url

    else
        url ++ "/redirect?url=" ++ Url.percentEncode redirect


logoutUrl : UrlPath -> String
logoutUrl (UrlPath basePath) =
    basePath ++ "/logout"


homeUrl : UrlPath -> String
homeUrl (UrlPath basePath) =
    basePath ++ "/home"


organizationUrl : UrlPath -> Maybe OrganizationId -> String
organizationUrl (UrlPath basePath) organization =
    organization |> Maybe.filter (\id -> id /= OrganizationId.zero) |> Maybe.mapOrElse (\id -> basePath ++ "/organizations/" ++ id) (homeUrl (UrlPath basePath))


organizationBillingUrl : UrlPath -> OrganizationId -> String -> String
organizationBillingUrl (UrlPath basePath) organization source =
    basePath ++ "/organizations/" ++ organization ++ "/billing?source=" ++ source


blogUrl : UrlPath -> String
blogUrl (UrlPath basePath) =
    basePath ++ "/blog"


blogArticleUrl : UrlPath -> String -> String
blogArticleUrl (UrlPath basePath) slug =
    basePath ++ "/blog/" ++ slug


embedUrl : UrlPath -> EmbedKind -> String -> LayoutName -> EmbedModeId -> Maybe ProjectToken -> String
embedUrl (UrlPath basePath) kind content layout mode token =
    let
        queryString : String
        queryString =
            [ ( EmbedKind.value kind, content )
            , ( "layout", layout )
            , ( EmbedMode.key, mode )
            , ( "token", token |> Maybe.mapOrElse .id "" )
            ]
                |> List.filter (\( _, value ) -> value /= "")
                |> Url.buildQueryString
    in
    basePath ++ "/embed?" ++ queryString


resourceUrl : UrlPath -> String -> String
resourceUrl (UrlPath basePath) path =
    basePath ++ "/elm" ++ path


type alias SampleSchema =
    { url : String, color : Color, icon : Icon, key : String, name : String, description : String, tables : Int }


internal : UrlPath -> Url -> Either String Url
internal basePath url =
    if isExternal basePath url then
        url |> Url.relative |> Left

    else
        url |> Right


isExternal : UrlPath -> Url -> Bool
isExternal (UrlPath basePath) url =
    -- identify urls that are not inside Elm app and needs a page load (Elixir backend pages)
    (url.path == basePath ++ "/")
        || (url.path == basePath ++ "/home")
        || (url.path |> String.startsWith (basePath ++ "/login"))
        || (url.path == basePath ++ "/logout")
        || (url.path |> String.startsWith (basePath ++ "/organizations/"))


type alias Sample =
    { slug : String, color : Color, icon : Icon, name : String, description : String, project_id : ProjectId, nb_tables : Int }


getSamples : UrlPath -> (Result Error (List Sample) -> msg) -> Cmd msg
getSamples (UrlPath basePath) toMsg =
    riskyGet { url = basePath ++ "/api/v1/gallery", expect = expectJson toMsg (Decode.list decodeSample) }


getCurrentUser : UrlPath -> (Result Error (Maybe User) -> msg) -> Cmd msg
getCurrentUser (UrlPath basePath) toMsg =
    riskyGet { url = basePath ++ "/api/v1/users/current", expect = expectJson (recoverUnauthorized >> toMsg) User.decode }


getOrganizationsAndProjects : UrlPath -> (Result Error ( List Organization, List ProjectInfo ) -> msg) -> Cmd msg
getOrganizationsAndProjects (UrlPath basePath) toMsg =
    riskyGet { url = basePath ++ "/api/v1/organizations?expand=plan,projects", expect = expectJson (Result.map formatOrgasAndProjects >> toMsg) (Decode.list decodeOrga) }


getProjectTokens : UrlPath -> ProjectInfo -> (Result Error (List ProjectToken) -> msg) -> Cmd msg
getProjectTokens (UrlPath basePath) project toMsg =
    riskyGet
        { url = basePath ++ "/api/v1/organizations/" ++ (project |> ProjectInfo.organizationId) ++ "/projects/" ++ project.id ++ "/access-tokens"
        , expect = expectJson toMsg (Decode.list ProjectToken.decode)
        }


createProjectToken : UrlPath -> String -> Maybe Time.Posix -> ProjectInfo -> (Result Error () -> msg) -> Cmd msg
createProjectToken (UrlPath basePath) name expireAt project toMsg =
    riskyPost
        { url = basePath ++ "/api/v1/organizations/" ++ (project |> ProjectInfo.organizationId) ++ "/projects/" ++ project.id ++ "/access-tokens"
        , body = [ ( "name", name |> Encode.string ), ( "expire_at", expireAt |> Encode.maybe Time.encodeIso ) ] |> Encode.object |> Http.jsonBody
        , expect = expectEmpty toMsg
        }


revokeProjectToken : UrlPath -> ProjectToken -> ProjectInfo -> (Result Error () -> msg) -> Cmd msg
revokeProjectToken (UrlPath basePath) token project toMsg =
    riskyDelete
        { url = basePath ++ "/api/v1/organizations/" ++ (project |> ProjectInfo.organizationId) ++ "/projects/" ++ project.id ++ "/access-tokens/" ++ token.id
        , expect = expectEmpty toMsg
        }


type alias TableColorTweet =
    { tweet : String, errors : List String }


getTableColorTweet : UrlPath -> OrganizationId -> TweetUrl -> (Result Error TableColorTweet -> msg) -> Cmd msg
getTableColorTweet (UrlPath basePath) organizationId tweetUrl toMsg =
    riskyPost
        { url = basePath ++ "/api/v1/organizations/" ++ organizationId ++ "/tweet-for-table-colors"
        , body = [ ( "tweet_url", tweetUrl |> Encode.string ) ] |> Encode.object |> Http.jsonBody
        , expect =
            expectJson toMsg
                (Decode.map2 TableColorTweet
                    (Decode.field "tweet" Decode.string)
                    (Decode.field "errors" (Decode.list Decode.string))
                )
        }


riskyGet : { url : String, expect : Http.Expect msg } -> Cmd msg
riskyGet r =
    Http.riskyRequest { method = "GET", url = r.url, headers = [], body = Http.emptyBody, expect = r.expect, timeout = Nothing, tracker = Nothing }


riskyPost : { url : String, body : Http.Body, expect : Http.Expect msg } -> Cmd msg
riskyPost r =
    Http.riskyRequest { method = "POST", url = r.url, headers = [], body = r.body, expect = r.expect, timeout = Nothing, tracker = Nothing }


riskyDelete : { url : String, expect : Http.Expect msg } -> Cmd msg
riskyDelete r =
    Http.riskyRequest { method = "DELETE", url = r.url, headers = [], body = Http.emptyBody, expect = r.expect, timeout = Nothing, tracker = Nothing }


expectJson : (Result Error a -> msg) -> Decoder a -> Expect msg
expectJson toMsg decoder =
    Http.expectStringResponse toMsg (handleResponse >> Result.andThen (Decode.decodeString decoder >> Result.mapError (Decode.errorToStringNoValue >> Error 0)))


expectEmpty : (Result Error () -> msg) -> Expect msg
expectEmpty toMsg =
    Http.expectStringResponse toMsg (handleResponse >> Result.andThen (\v -> Bool.cond (v == "") (Ok ()) (Err (Error 0 ("Expected empty string but got: " ++ v)))))



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
                            , visibility = p.visibility
                            , version = p.encodingVersion
                            , nbSources = p.nbSources
                            , nbTables = p.nbTables
                            , nbColumns = p.nbColumns
                            , nbRelations = p.nbRelations
                            , nbTypes = p.nbTypes
                            , nbComments = p.nbComments
                            , nbLayouts = p.nbLayouts
                            , nbNotes = p.nbNotes
                            , nbMemos = p.nbMemos
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
    , description = o.description
    , cleverCloud = o.cleverCloud
    , heroku = o.heroku
    }


type alias OrgaWithProjects =
    { id : String
    , slug : String
    , name : String
    , plan : Plan
    , logo : String
    , description : Maybe String
    , cleverCloud : Maybe CleverCloudResource
    , heroku : Maybe HerokuResource
    , projects : List OrgaProject
    }


type alias OrgaProject =
    { id : String
    , slug : String
    , name : String
    , description : Maybe String
    , encodingVersion : Int
    , storage : ProjectStorage
    , visibility : ProjectVisibility
    , nbSources : Int
    , nbTables : Int
    , nbColumns : Int
    , nbRelations : Int
    , nbTypes : Int
    , nbComments : Int
    , nbLayouts : Int
    , nbNotes : Int
    , nbMemos : Int
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    , archivedAt : Maybe Time.Posix
    }


decodeOrga : Decode.Decoder OrgaWithProjects
decodeOrga =
    Decode.map9 OrgaWithProjects
        (Decode.field "id" Decode.string)
        (Decode.field "slug" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "plan" Plan.decode)
        (Decode.defaultField "logo" Decode.string "")
        (Decode.maybeField "description" Decode.string)
        (Decode.maybeField "clever_cloud" CleverCloudResource.decode)
        (Decode.maybeField "heroku" HerokuResource.decode)
        (Decode.field "projects" (Decode.list decodeProject))


decodeProject : Decode.Decoder OrgaProject
decodeProject =
    Decode.map19 OrgaProject
        (Decode.field "id" Decode.string)
        (Decode.field "slug" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.maybeField "description" Decode.string)
        (Decode.field "encoding_version" Decode.int)
        (Decode.field "storage_kind" ProjectStorage.decode)
        (Decode.field "visibility" ProjectVisibility.decode)
        (Decode.field "nb_sources" Decode.int)
        (Decode.field "nb_tables" Decode.int)
        (Decode.field "nb_columns" Decode.int)
        (Decode.field "nb_relations" Decode.int)
        (Decode.field "nb_types" Decode.int)
        (Decode.field "nb_comments" Decode.int)
        (Decode.field "nb_layouts" Decode.int)
        (Decode.field "nb_notes" Decode.int)
        (Decode.field "nb_memos" Decode.int)
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
                    err |> Error metadata.statusCode |> Err

                Err _ ->
                    (Http.BadStatus metadata.statusCode |> Http.errorToString) ++ Bool.cond (String.isEmpty body) "" (": " ++ body) |> Error metadata.statusCode |> Err

        Http.GoodStatus_ _ body ->
            Ok body


recoverUnauthorized : Result Error a -> Result Error (Maybe a)
recoverUnauthorized r =
    case r of
        Ok a ->
            Ok (Just a)

        Err (Error 401 _) ->
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
