module Pages.Projects exposing (Model, Msg, page)

import Browser.Navigation as Navigation
import Conf
import Gen.Params.Projects exposing (Params)
import Html.Styled as Styled
import Libs.Bool as B
import Libs.Task as T
import Page
import PagesComponents.Projects.Models as Models exposing (Msg(..))
import PagesComponents.Projects.View exposing (viewProjects)
import Ports exposing (JsMsg(..))
import Request
import Shared exposing (StoredProjects(..))
import Time
import Track
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init
        , update = update req
        , view = view shared
        , subscriptions = subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : ( Model, Cmd Msg )
init =
    ( { selectedMenu = "Dashboard"
      , mobileMenuOpen = False
      , projects = Loading
      , confirm = Nothing
      , modalOpened = False
      , toastCpt = 0
      , toasts = []
      }
    , Cmd.batch
        [ Ports.loadProjects
        , Ports.trackPage "dashboard"
        ]
    )



-- UPDATE


update : Request.With Params -> Msg -> Model -> ( Model, Cmd Msg )
update req msg model =
    case msg of
        SelectMenu menu ->
            ( { model | selectedMenu = menu }, Cmd.none )

        ToggleMobileMenu ->
            ( { model | mobileMenuOpen = not model.mobileMenuOpen }, Cmd.none )

        DeleteProject project ->
            ( model, Cmd.batch [ Ports.dropProject project, Ports.track (Track.deleteProject project) ] )

        ConfirmOpen confirm ->
            ( { model | confirm = Just confirm }, T.sendAfter 1 ModalOpen )

        ConfirmAnswer answer cmd ->
            ( { model | confirm = Nothing }, B.cond answer cmd Cmd.none )

        ModalOpen ->
            ( { model | modalOpened = True }, Ports.autofocusWithin Conf.ids.modal )

        ModalClose message ->
            ( { model | modalOpened = False }, T.sendAfter Conf.ui.closeDuration message )

        NavigateTo url ->
            ( model, Navigation.pushUrl req.key url )

        JsMessage message ->
            model |> handleJsMessage message


handleJsMessage : JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage msg model =
    case msg of
        GotProjects ( _, projects ) ->
            ( { model | projects = Loaded (projects |> List.sortBy (\p -> negate (Time.posixToMillis p.updatedAt))) }, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.onJsMessage JsMessage



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "Azimutt - Explore your database schema"
    , body = model |> viewProjects shared |> List.map Styled.toUnstyled
    }
