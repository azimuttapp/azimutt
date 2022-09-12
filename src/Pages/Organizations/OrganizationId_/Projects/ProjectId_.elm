module Pages.Organizations.OrganizationId_.Projects.ProjectId_ exposing (Model, Msg, page)

import Gen.Params.Organizations.OrganizationId_.Projects.ProjectId_ exposing (Params)
import Libs.Result as Result
import Models.ProjectInfo2 exposing (ProjectInfo2)
import Models.User2 exposing (User2)
import Page
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
    }


type Msg
    = GotUser (Result Backend.Error (Maybe User2))
    | GotProjects (Result Backend.Error (List ProjectInfo2))



-- INIT


init : Params -> ( Model, Cmd Msg )
init params =
    ( { params = params
      , currentUser = Nothing
      , projects = []
      }
    , Cmd.batch
        [ Backend.getCurrentUser GotUser
        , Backend.getProjects GotProjects
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view _ =
    View.placeholder "Organizations.OrganizationId_.Projects.ProjectId_"
