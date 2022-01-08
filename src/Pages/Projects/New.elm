module Pages.Projects.New exposing (Model, Msg, page)

import Conf
import DataSources.SqlParser.ProjectAdapter exposing (buildSourceFromSql)
import Dict
import Gen.Params.Projects.New exposing (Params)
import Gen.Route as Route
import Html.Styled as Styled
import Libs.Bool as B
import Libs.String as S
import Libs.Task as T
import Models.Project as Project
import Page
import PagesComponents.Projects.New.Models as Models exposing (Msg(..), Tab(..))
import PagesComponents.Projects.New.View exposing (viewNewProject)
import Ports exposing (JsMsg(..), onJsMessage, readLocalFile, readRemoteFile, saveProject, track, trackPage)
import Request
import Services.ProjectParser as ProjectParser
import Services.SourceParsing.Models exposing (ParsingMsg(..))
import Services.SourceReader as SourceReader
import Shared
import Tracking
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init req
        , update = update req shared
        , view = view shared
        , subscriptions = subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : Request.With Params -> ( Model, Cmd Msg )
init req =
    ( { selectedMenu = "New project"
      , mobileMenuOpen = False
      , selectedTab = req.query |> Dict.get "sample" |> Maybe.map (\_ -> Sample) |> Maybe.withDefault Schema
      , selectedLocalFile = Nothing
      , selectedSample = Nothing
      , loadedFile = Nothing
      , parsedSchema = Nothing
      , parsedSource = Nothing
      , project = Nothing
      }
    , Cmd.batch
        ((req.query |> Dict.get "sample" |> Maybe.map (\sample -> [ T.send (SelectSample sample) ]) |> Maybe.withDefault [])
            ++ [ trackPage "new-project" ]
        )
    )



-- UPDATE


update : Request.With Params -> Shared.Model -> Msg -> Model -> ( Model, Cmd Msg )
update req shared msg model =
    case msg of
        SelectMenu menu ->
            ( { model | selectedMenu = menu }, Cmd.none )

        ToggleMobileMenu ->
            ( { model | mobileMenuOpen = not model.mobileMenuOpen }, Cmd.none )

        SelectTab tab ->
            ( { model | selectedTab = tab, selectedLocalFile = Nothing, selectedSample = Nothing, loadedFile = Nothing, parsedSchema = Nothing, parsedSource = Nothing, project = Nothing }, Cmd.none )

        SelectLocalFile file ->
            ( { model | selectedLocalFile = Just file, selectedSample = Nothing, loadedFile = Nothing, parsedSchema = Nothing, parsedSource = Nothing, project = Nothing }, readLocalFile Nothing Nothing file )

        SelectSample sample ->
            ( { model | selectedLocalFile = Nothing, selectedSample = Just sample, loadedFile = Nothing, parsedSchema = Nothing, parsedSource = Nothing, project = Nothing }, Conf.schemaSamples |> Dict.get sample |> Maybe.map (\s -> readRemoteFile Nothing Nothing s.url (Just s.key)) |> Maybe.withDefault Cmd.none )

        FileLoaded projectId sourceInfo fileContent ->
            ( { model | loadedFile = Just ( projectId, sourceInfo, fileContent ), parsedSchema = Just (ProjectParser.init fileContent ParseMsg BuildProject) }
            , T.send (ParseMsg BuildLines)
            )

        ParseMsg parseMsg ->
            model.parsedSchema
                |> Maybe.map
                    (\p ->
                        p
                            |> ProjectParser.update parseMsg
                            |> (\( parsed, message ) ->
                                    ( { model | parsedSchema = Just parsed }
                                    , B.cond ((parsed.cpt |> modBy 342) == 1) (T.sendAfter 1 message) (T.send message)
                                    )
                               )
                    )
                |> Maybe.withDefault ( model, Cmd.none )

        BuildProject ->
            model.parsedSchema
                |> Maybe.andThen (\parsedSchema -> Maybe.map3 (\( projectId, sourceInfo, _ ) lines schema -> ( parsedSchema, buildSourceFromSql sourceInfo lines schema, projectId )) model.loadedFile parsedSchema.lines parsedSchema.schema)
                |> Maybe.map (\( parsedSchema, source, projectId ) -> ( parsedSchema, source, Project.create projectId (S.unique (shared |> Shared.projects |> List.map .name) source.name) source ))
                |> Maybe.map (\( parsedSchema, source, project ) -> ( { model | parsedSource = Just source, project = Just project }, track (Tracking.events.parsedProject parsedSchema project) ))
                |> Maybe.withDefault ( model, Cmd.none )

        DropSchema ->
            ( { model | selectedLocalFile = Nothing, selectedSample = Nothing, loadedFile = Nothing, parsedSchema = Nothing, project = Nothing }, Cmd.none )

        CreateProject project ->
            ( model, Cmd.batch [ saveProject project, track (Tracking.events.createProject project), Request.pushRoute (Route.Projects__Id_ { id = project.id }) req ] )

        JsMessage jsMsg ->
            ( model, handleJsMessage jsMsg )

        Noop ->
            ( model, Cmd.none )


handleJsMessage : JsMsg -> Cmd Msg
handleJsMessage msg =
    case msg of
        GotLocalFile now projectId sourceId file content ->
            T.send (FileLoaded |> SourceReader.local now projectId sourceId file content)

        GotRemoteFile now projectId sourceId url content sample ->
            T.send (FileLoaded |> SourceReader.remote now projectId sourceId url content sample)

        _ ->
            T.send Noop



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
