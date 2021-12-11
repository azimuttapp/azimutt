module Pages.Projects.Id_ exposing (Model, Msg, page)

import Components.Atoms.Icon exposing (Icon(..))
import Gen.Params.Projects.Id_ exposing (Params)
import Html.Styled as Styled exposing (text)
import Libs.Bool as B
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.TwColor exposing (TwColor(..))
import Libs.Task as T
import Page
import PagesComponents.Projects.Id_.Models as Models exposing (Msg(..))
import PagesComponents.Projects.Id_.View exposing (viewProject)
import Ports
import Request
import Shared
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init shared req
        , update = update
        , view = view shared
        , subscriptions = subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : Shared.Model -> Request.With Params -> ( Model, Cmd Msg )
init _ req =
    ( { projectId = req.params.id
      , navbar = { mobileMenuOpen = False }
      , openedDropdown = ""
      , confirm = { color = Red, icon = X, title = "", message = text "", confirm = "", cancel = "", onConfirm = T.send Noop, isOpen = False }
      , toastCpt = 0
      , toasts = []
      }
    , Cmd.batch [ Ports.loadProjects ]
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleMobileMenu ->
            ( { model | navbar = model.navbar |> (\n -> { n | mobileMenuOpen = not n.mobileMenuOpen }) }, Cmd.none )

        ToggleDropdown id ->
            ( { model | openedDropdown = B.cond (model.openedDropdown == id) "" id }, Cmd.none )

        ShowAllTables ->
            ( model, Cmd.none )

        HideAllTables ->
            ( model, Cmd.none )

        ResetCanvas ->
            ( model, Cmd.none )

        LayoutMsg ->
            ( model, Cmd.none )

        VirtualRelationMsg ->
            ( model, Cmd.none )

        FindPathMsg ->
            ( model, Cmd.none )

        Noop ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = shared |> Shared.projects |> L.find (\p -> p.id == model.projectId) |> M.mapOrElse (\p -> p.name ++ " - Azimutt") "Azimutt - Explore your database schema"
    , body = model |> viewProject shared |> List.map Styled.toUnstyled
    }
