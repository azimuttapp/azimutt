module Shared exposing (Confirm, Flags, Model, Msg, Prompt, StoredProjects(..), init, subscriptions, update)

import Components.Atoms.Icon exposing (Icon)
import Html exposing (Html)
import Libs.Tailwind exposing (Color)
import Models.User exposing (User)
import PagesComponents.Projects.Id_.Models.ProjectInfo exposing (ProjectInfo)
import Ports exposing (JsMsg(..))
import Request exposing (Request)
import Task
import Time


type alias Flags =
    { now : Int }


type alias Model =
    { zone : Time.Zone
    , now : Time.Posix
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
      , user = Nothing
      , projects = Loading
      }
    , Cmd.batch [ Time.here |> Task.perform ZoneChanged ]
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
    Sub.batch [ Time.every (10 * 1000) TimeChanged, Ports.onJsMessage JsMessage ]
