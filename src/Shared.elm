module Shared exposing (Confirm, Flags, Model, Msg, StoredProjects(..), init, loadedProjects, subscriptions, update)

import Components.Atoms.Icon exposing (Icon)
import Html.Styled exposing (Html)
import Libs.Json.Decode as D
import Libs.Models.Theme exposing (Theme)
import Libs.Models.TwColor exposing (TwColor(..))
import Models.Project exposing (Project)
import Ports exposing (JsMsg(..))
import Request exposing (Request)
import Task
import Time


type alias Flags =
    { now : Int }


type alias Model =
    { zone : Time.Zone
    , now : Time.Posix
    , theme : Theme
    , projects : StoredProjects
    }


type alias Confirm msg =
    { color : TwColor
    , icon : Icon
    , title : String
    , message : Html msg
    , confirm : String
    , cancel : String
    , onConfirm : Cmd msg
    , isOpen : Bool
    }


type StoredProjects
    = Loading
    | Loaded (List Project)


type Msg
    = ZoneChanged Time.Zone
    | TimeChanged Time.Posix
    | JsMessage JsMsg


init : Request -> Flags -> ( Model, Cmd Msg )
init _ flags =
    ( { zone = Time.utc
      , now = Time.millisToPosix flags.now
      , theme = { color = Indigo }
      , projects = Loading
      }
    , Cmd.batch
        [ Time.here |> Task.perform ZoneChanged
        , Ports.loadProjects
        ]
    )


update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        ZoneChanged zone ->
            ( { model | zone = zone }, Cmd.none )

        TimeChanged time ->
            ( { model | now = time }, Cmd.none )

        JsMessage (GotProjects ( errors, projects )) ->
            ( { model | projects = Loaded (projects |> List.sortBy (\p -> negate (Time.posixToMillis p.updatedAt))) }
            , Cmd.batch
                (errors
                    |> List.concatMap
                        (\( name, err ) ->
                            [ Ports.toastError ("Unable to read project <b>" ++ name ++ "</b>:<br>" ++ D.errorToHtml err)
                            , Ports.trackJsonError "decode-project" err
                            ]
                        )
                )
            )

        JsMessage _ ->
            ( model, Cmd.none )


subscriptions : Request -> Model -> Sub Msg
subscriptions _ _ =
    Sub.batch
        [ Time.every (10 * 1000) TimeChanged
        , Ports.onJsMessage JsMessage
        ]


loadedProjects : Model -> List Project
loadedProjects model =
    case model.projects of
        Loading ->
            []

        Loaded projects ->
            projects
