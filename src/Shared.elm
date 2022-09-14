module Shared exposing (Confirm, Flags, GlobalConf, Model, Msg, Prompt, StoredProjects(..), init, subscriptions, update)

import Components.Atoms.Icon exposing (Icon)
import Html exposing (Html)
import Libs.Models.Env as Env exposing (Env)
import Libs.Models.Platform as Platform exposing (Platform)
import Libs.Result as Result
import Libs.Tailwind exposing (Color)
import Models.ProjectInfo2 exposing (ProjectInfo2)
import Models.User exposing (User)
import Models.User2 exposing (User2)
import PagesComponents.Projects.Id_.Models.ProjectInfo exposing (ProjectInfo)
import Ports exposing (JsMsg(..))
import Request exposing (Request)
import Services.Backend as Backend
import Task
import Time


type alias Flags =
    { now : Int
    , conf : { env : String, platform : String, backendUrl : String }
    }


type alias GlobalConf =
    { env : Env, platform : Platform, backendUrl : Backend.Url }


type alias Model =
    { zone : Time.Zone
    , now : Time.Posix
    , conf : GlobalConf
    , user : Maybe User
    , projects : StoredProjects
    , user2 : Maybe User2
    , projects2 : List ProjectInfo2
    , userLoaded : Bool
    , projectsLoaded : Bool
    }


type Msg
    = ZoneChanged Time.Zone
    | TimeChanged Time.Posix
    | GotUser (Result Backend.Error (Maybe User2))
    | GotProjects (Result Backend.Error (List ProjectInfo2))
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
            , backendUrl = Backend.urlFromString flags.conf.backendUrl
            }
      , user = Nothing
      , projects = Loading
      , user2 = Nothing
      , projects2 = []
      , userLoaded = False
      , projectsLoaded = False
      }
    , Cmd.batch
        [ Task.perform ZoneChanged Time.here
        , Backend.getCurrentUser GotUser
        , Backend.getProjects GotProjects
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

        GotProjects projectsR ->
            ( projectsR |> Result.fold (\_ -> model) (\projects -> { model | projects2 = projects |> List.sortBy (\p -> -(Time.posixToMillis p.updatedAt)), projectsLoaded = True }), Cmd.none )

        JsMessage (Ports.GotLogin user) ->
            ( { model | user = Just user }, Cmd.none )

        JsMessage Ports.GotLogout ->
            ( { model | user = Nothing }, Cmd.none )

        JsMessage (Ports.GotProjects ( _, projects )) ->
            ( { model | projects = Loaded (projects |> List.sortBy (\p -> -(Time.posixToMillis p.updatedAt))) }, Cmd.none )

        JsMessage _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Request -> Model -> Sub Msg
subscriptions _ _ =
    Sub.batch [ Time.every (10 * 1000) TimeChanged, Ports.onJsMessage JsMessage ]
