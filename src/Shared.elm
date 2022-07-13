module Shared exposing (Confirm, Flags, GlobalConf, Model, Msg, Prompt, StoredProjects(..), init, subscriptions, update)

import Components.Atoms.Icon exposing (Icon)
import Html exposing (Html)
import Libs.Models.Env as Env exposing (Env)
import Libs.Models.Platform as Platform exposing (Platform)
import Libs.Tailwind exposing (Color)
import Models.User exposing (User)
import PagesComponents.Id_.Models.ProjectInfo exposing (ProjectInfo)
import Ports exposing (JsMsg(..))
import Request exposing (Request)
import Task
import Time


type alias Flags =
    { now : Int
    , conf : { env : String, platform : String, enableCloud : Bool }
    }


type alias GlobalConf =
    { env : Env, platform : Platform, enableCloud : Bool }


type alias Model =
    { zone : Time.Zone
    , now : Time.Posix
    , conf : GlobalConf
    , user : Maybe User
    , projects : StoredProjects
    }


type Msg
    = ZoneChanged Time.Zone
    | TimeChanged Time.Posix
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
            , enableCloud = flags.conf.enableCloud
            }
      , user = Nothing
      , projects = Loading
      }
    , Task.perform ZoneChanged Time.here
    )



-- UPDATE


update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        ZoneChanged zone ->
            ( { model | zone = zone }, Cmd.none )

        TimeChanged time ->
            ( { model | now = time }, Cmd.none )

        JsMessage (GotLogin user) ->
            ( { model | user = Just user }, Cmd.none )

        JsMessage GotLogout ->
            ( { model | user = Nothing }, Cmd.none )

        JsMessage (GotProjects ( _, projects )) ->
            ( { model | projects = Loaded (projects |> List.sortBy (\p -> negate (Time.posixToMillis p.updatedAt))) }, Cmd.none )

        JsMessage _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Request -> Model -> Sub Msg
subscriptions _ _ =
    Sub.batch [ Time.every (10 * 1000) TimeChanged, Ports.onJsMessage Nothing JsMessage ]
