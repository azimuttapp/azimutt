module Shared exposing (Confirm, Flags, GlobalConf, Model, Msg, Prompt, StoredProjects(..), init, subscriptions, update)

import Components.Atoms.Icon exposing (Icon)
import Html exposing (Html)
import Libs.Models.Env as Env exposing (Env)
import Libs.Models.Platform as Platform exposing (Platform)
import Libs.Result as Result
import Libs.Tailwind exposing (Color)
import Models.Organization exposing (Organization)
import Models.ProjectInfo exposing (ProjectInfo)
import Models.User exposing (User)
import Ports exposing (JsMsg)
import Request exposing (Request)
import Services.Backend as Backend
import Services.Sort as Sort
import Task
import Time


type alias Flags =
    { now : Int
    , conf : { env : String, platform : String }
    }


type alias GlobalConf =
    { env : Env, platform : Platform }


type alias Model =
    { zone : Time.Zone
    , now : Time.Posix
    , conf : GlobalConf
    , user : Maybe User
    , userLoaded : Bool
    , organizations : List Organization
    , projects : List ProjectInfo
    , projectsLoaded : Bool
    , legacyProjects : StoredProjects
    }


type Msg
    = ZoneChanged Time.Zone
    | TimeChanged Time.Posix
    | GotUser (Result Backend.Error (Maybe User))
    | GotBackendProjects (Result Backend.Error ( List Organization, List ProjectInfo ))
    | JsMessage JsMsg


type StoredProjects
    = Loading
    | Loaded (List ProjectInfo)


type alias Confirm msg =
    { color : Color
    , icon : Icon
    , title : String
    , message : Html msg
    , confirm : String
    , cancel : String
    , onConfirm : Cmd msg
    }


type alias Prompt msg =
    { color : Color
    , icon : Icon
    , title : String
    , message : Html msg
    , confirm : String
    , cancel : String
    , onConfirm : String -> Cmd msg
    }



-- INIT


init : Request -> Flags -> ( Model, Cmd Msg )
init _ flags =
    let
        env : Env
        env =
            Env.fromString flags.conf.env
    in
    ( { zone = Time.utc
      , now = Time.millisToPosix flags.now
      , conf =
            { env = env
            , platform = Platform.fromString flags.conf.platform
            }
      , user = Nothing
      , userLoaded = False
      , projects = []
      , organizations = []
      , projectsLoaded = False
      , legacyProjects = Loading
      }
    , Cmd.batch
        [ Task.perform ZoneChanged Time.here
        , Backend.getCurrentUser env GotUser
        , Backend.getOrganizationsAndProjects env GotBackendProjects
        , Ports.getLegacyProjects
        ]
    )



-- UPDATE


update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        ZoneChanged zone ->
            ( { model | zone = zone }, Cmd.none )

        TimeChanged time ->
            ( { model | now = time }, Cmd.none )

        GotUser result ->
            ( result |> Result.fold (\_ -> { model | userLoaded = True }) (\user -> { model | user = user, userLoaded = True }), Cmd.none )

        GotBackendProjects result ->
            ( result |> Result.fold (\_ -> { model | projectsLoaded = True }) (\( orgas, projects ) -> { model | organizations = orgas, projects = Sort.lastUpdatedFirst projects, projectsLoaded = True }), Cmd.none )

        JsMessage (Ports.GotLegacyProjects ( _, projects )) ->
            ( { model | legacyProjects = Loaded (Sort.lastUpdatedFirst projects) }, Cmd.none )

        JsMessage (Ports.ProjectDeleted _) ->
            ( model, Cmd.batch [ Backend.getOrganizationsAndProjects model.conf.env GotBackendProjects, Ports.getLegacyProjects ] )

        JsMessage _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Request -> Model -> Sub Msg
subscriptions _ _ =
    Sub.batch [ Time.every (10 * 1000) TimeChanged, Ports.onJsMessage JsMessage ]
