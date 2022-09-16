module Shared exposing (Confirm, Flags, GlobalConf, Model, Msg, Prompt, StoredProjects(..), init, subscriptions, update)

import Components.Atoms.Icon exposing (Icon)
import Html exposing (Html)
import Libs.Models.Env as Env exposing (Env)
import Libs.Models.Platform as Platform exposing (Platform)
import Libs.Result as Result
import Libs.Tailwind exposing (Color)
import Models.Organization exposing (Organization)
import Models.ProjectInfo2 exposing (ProjectInfo2)
import Models.User2 exposing (User2)
import PagesComponents.Organization_.Project_.Models.ProjectInfo exposing (ProjectInfo)
import Ports exposing (JsMsg(..))
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
    , projects : StoredProjects
    , user2 : Maybe User2
    , userLoaded : Bool
    , organizations : List Organization
    , projects2 : List ProjectInfo2
    , projectsLoaded : Bool
    }


type Msg
    = ZoneChanged Time.Zone
    | TimeChanged Time.Posix
    | GotUser (Result Backend.Error (Maybe User2))
    | GotProjects (Result Backend.Error ( List Organization, List ProjectInfo2 ))
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
    ( { zone = Time.utc
      , now = Time.millisToPosix flags.now
      , conf =
            { env = Env.fromString flags.conf.env
            , platform = Platform.fromString flags.conf.platform
            }
      , projects = Loading
      , user2 = Nothing
      , userLoaded = False
      , projects2 = []
      , organizations = []
      , projectsLoaded = False
      }
    , Cmd.batch
        [ Task.perform ZoneChanged Time.here
        , Backend.getCurrentUser GotUser
        , Backend.getOrganizationsAndProjects GotProjects
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

        GotUser userR ->
            ( userR |> Result.fold (\_ -> model) (\user -> { model | user2 = user, userLoaded = True }), Cmd.none )

        GotProjects result ->
            ( result |> Result.fold (\_ -> model) (\( orgas, projects ) -> { model | organizations = orgas, projects2 = Sort.lastUpdatedFirst projects, projectsLoaded = True }), Cmd.none )

        JsMessage (Ports.GotProjects ( _, projects )) ->
            ( { model | projects = Loaded (Sort.lastUpdatedFirst projects) }, Cmd.none )

        JsMessage (Ports.ProjectDeleted _) ->
            ( model, Backend.getOrganizationsAndProjects GotProjects )

        JsMessage _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Request -> Model -> Sub Msg
subscriptions _ _ =
    Sub.batch [ Time.every (10 * 1000) TimeChanged, Ports.onJsMessage JsMessage ]
