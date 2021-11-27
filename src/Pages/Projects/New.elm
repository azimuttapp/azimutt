module Pages.Projects.New exposing (Model, Msg, page)

import DataSources.SqlParser.ProjectAdapter exposing (buildSourceFromSql)
import Gen.Params.Projects.New exposing (Params)
import Gen.Route as Route
import Html.Styled as Styled
import Libs.String as S
import Libs.Task as T
import Models.Project as Project
import Page
import PagesComponents.Projects.New.Models as Models exposing (Msg(..), Tab(..))
import PagesComponents.Projects.New.Updates.PortMsg exposing (handleJsMsg)
import PagesComponents.Projects.New.Updates.ProjectParser as ProjectParser
import PagesComponents.Projects.New.View exposing (viewNewProject)
import Ports exposing (JsMsg(..), onJsMessage, readLocalFile, saveProject)
import Request
import Shared exposing (loadedProjects)
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init
        , update = update req shared
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
    ( { navigationActive = "New project"
      , mobileMenuOpen = False
      , tabActive = Schema
      , schemaFile = Nothing
      , schemaFileContent = Nothing
      , schemaParser = Nothing
      , project = Nothing
      }
    , Cmd.none
    )



-- UPDATE


update : Request.With Params -> Shared.Model -> Msg -> Model -> ( Model, Cmd Msg )
update req shared msg model =
    case msg of
        SelectMenu menu ->
            ( { model | navigationActive = menu }, Cmd.none )

        ToggleMobileMenu ->
            ( { model | mobileMenuOpen = not model.mobileMenuOpen }, Cmd.none )

        SelectTab tab ->
            ( { model | tabActive = tab }, Cmd.none )

        FileDragOver ->
            ( model, Cmd.none )

        FileDragLeave ->
            ( model, Cmd.none )

        LoadLocalFile file ->
            ( { model | schemaFile = Just file, schemaFileContent = Nothing, schemaParser = Nothing, project = Nothing }, readLocalFile Nothing Nothing file )

        FileLoaded projectId sourceInfo fileContent ->
            ( { model | schemaFileContent = Just ( projectId, sourceInfo, fileContent ), schemaParser = Just (ProjectParser.init fileContent ParseMsg BuildProject) }
            , T.send (ParseMsg ProjectParser.BuildLines)
            )

        ParseMsg parseMsg ->
            model.schemaParser
                |> Maybe.map (\p -> p |> ProjectParser.update parseMsg |> (\( m, messages ) -> ( { model | schemaParser = Just m }, Cmd.batch (messages |> List.map T.send) )))
                |> Maybe.withDefault ( model, Cmd.none )

        BuildProject ->
            model.schemaParser
                |> Maybe.andThen (\p -> Maybe.map3 (\( projectId, sourceInfo, _ ) lines schema -> ( projectId, buildSourceFromSql sourceInfo lines schema )) model.schemaFileContent p.lines p.schema)
                |> Maybe.map (\( projectId, source ) -> Project.create projectId (S.unique (shared |> loadedProjects |> List.map .name) source.name) source)
                |> Maybe.map (\project -> ( { model | project = Just project }, Cmd.none ))
                |> Maybe.withDefault ( model, Cmd.none )

        DropSchema ->
            ( { model | schemaFile = Nothing, schemaFileContent = Nothing, schemaParser = Nothing, project = Nothing }, Cmd.none )

        CreateProject project ->
            ( model, Cmd.batch [ saveProject project, Request.pushRoute (Route.Projects__Id_ { id = project.id }) req ] )

        JsMessage jsMsg ->
            ( model, handleJsMsg jsMsg )

        Noop ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    onJsMessage JsMessage



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "Azimutt - Explore your database schema"
    , body = model |> viewNewProject shared |> List.map Styled.toUnstyled
    }
