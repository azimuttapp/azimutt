module Shared exposing (Confirm, Flags, Model, Msg, StoredProjects(..), init, subscriptions, update)

import Components.Atoms.Icon exposing (Icon)
import Html.Styled exposing (Html)
import Libs.Models.Color as Color exposing (Color)
import Libs.Models.Theme exposing (Theme)
import Models.Project exposing (Project)
import Request exposing (Request)
import Task
import Time


type alias Flags =
    { now : Int }


type alias Model =
    { zone : Time.Zone
    , now : Time.Posix
    , theme : Theme
    }


type Msg
    = ZoneChanged Time.Zone
    | TimeChanged Time.Posix


type StoredProjects
    = Loading
    | Loaded (List Project)


type alias Confirm msg =
    { color : Color
    , icon : Icon
    , title : String
    , message : Html msg
    , confirm : String
    , cancel : String
    , onConfirm : Cmd msg
    }



-- INIT


init : Request -> Flags -> ( Model, Cmd Msg )
init _ flags =
    ( { zone = Time.utc
      , now = Time.millisToPosix flags.now
      , theme = { color = Color.indigo }
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



-- SUBSCRIPTIONS


subscriptions : Request -> Model -> Sub Msg
subscriptions _ _ =
    Sub.batch [ Time.every (10 * 1000) TimeChanged ]
