module Pages.Organizations.OrganizationId_.Projects.ProjectId_ exposing (Model, Msg, page)

import Gen.Params.Organizations.OrganizationId_.Projects.ProjectId_ exposing (Params)
import Libs.Maybe as Maybe
import Libs.Result as Result
import Models.ProjectInfo2 exposing (ProjectInfo2)
import Models.User2 exposing (User2)
import Page
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import Ports exposing (JsMsg)
import Request
import Services.Backend as Backend
import Shared
import View exposing (View)



-- elm-spa add /organizations/:organization-id/projects/:project-id element


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page _ req =
    Page.element
        { init = init req.params
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    { params : Params
    , currentUser : Maybe User2
    , projects : List ProjectInfo2
    , erd : Maybe Erd
    }


type Msg
    = GotUser (Result Backend.Error (Maybe User2))
    | GotProjects (Result Backend.Error (List ProjectInfo2))
    | JsMessage JsMsg



-- INIT


init : Params -> ( Model, Cmd Msg )
init params =
    ( { params = params
      , currentUser = Nothing
      , projects = []
      , erd = Nothing
      }
    , Cmd.batch
        [ Backend.getCurrentUser GotUser
        , Backend.getProjects GotProjects
        , Ports.getProject params.organizationId params.projectId
        ]
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotUser user ->
            ( user |> Result.fold (\_ -> model) (\u -> { model | currentUser = u }), Cmd.none )

        GotProjects projects ->
            ( projects |> Result.fold (\_ -> model) (\p -> { model | projects = p }), Cmd.none )

        JsMessage m ->
            model |> handleJsMessage m


handleJsMessage : JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage msg model =
    case msg of
        Ports.GotProject project ->
            ( project |> Maybe.mapOrElse (Result.fold (\_ -> model) (\p -> { model | erd = p |> Erd.create |> Just })) model, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.onJsMessage JsMessage



-- VIEW


view : Model -> View Msg
view _ =
    View.placeholder "Organizations.OrganizationId_.Projects.ProjectId_"
