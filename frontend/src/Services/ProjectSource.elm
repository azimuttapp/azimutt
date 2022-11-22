module Services.ProjectSource exposing (Model, Msg(..), init, kind, update, viewLocalInput, viewParsing)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Alert as Alert
import Components.Molecules.Divider as Divider
import Components.Molecules.FileInput as FileInput
import Conf
import FileValue exposing (File)
import Html exposing (Html, div, li, p, span, text, ul)
import Html.Attributes exposing (class)
import Http
import Json.Decode as Decode
import Libs.Bool as B
import Libs.Html exposing (extLink)
import Libs.Html.Attributes exposing (css)
import Libs.Http as Http
import Libs.Json.Decode as Decode
import Libs.Maybe as Maybe
import Libs.Models exposing (FileContent)
import Libs.Models.DateTime as DateTime
import Libs.Models.FileUrl exposing (FileUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Result as Result
import Libs.String as String
import Libs.Tailwind as Tw
import Libs.Task as T
import Models.Project as Project exposing (Project)
import Ports
import Services.Lenses exposing (mapShow, setProject)
import Services.SourceLogs as SourceLogs
import Time


type alias Model =
    { selectedLocalFile : Maybe File
    , selectedRemoteFile : Maybe FileUrl
    , loadedProject : Maybe (Result Http.Error FileContent)
    , parsedProject : Maybe (Result Decode.Error Project)
    , project : Maybe (Result String Project)
    , show : HtmlId
    }


type Msg
    = GetRemoteFile FileUrl
    | GotRemoteFile (Result Http.Error FileContent)
    | GetLocalFile File
    | GotFile FileContent
    | ParseProject
    | BuildProject
    | UiToggle HtmlId



-- INIT


kind : String
kind =
    "import-project"


init : Model
init =
    { selectedLocalFile = Nothing
    , selectedRemoteFile = Nothing
    , loadedProject = Nothing
    , parsedProject = Nothing
    , project = Nothing
    , show = ""
    }



-- UPDATE


update : (Msg -> msg) -> Msg -> Model -> ( Model, Cmd msg )
update wrap msg model =
    case msg of
        GetLocalFile file ->
            ( init |> (\m -> { m | selectedLocalFile = Just file })
            , Ports.readLocalFile kind file
            )

        GetRemoteFile url ->
            ( init |> (\m -> { m | selectedRemoteFile = Just url })
            , Http.get { url = url, expect = Http.expectString (GotRemoteFile >> wrap) }
            )

        GotRemoteFile result ->
            case result of
                Ok content ->
                    ( model, T.send (GotFile content |> wrap) )

                Err err ->
                    ( { model | loadedProject = err |> Err |> Just } |> setProject (err |> Http.errorToString |> Err |> Just), Cmd.none )

        GotFile content ->
            ( { model | loadedProject = content |> Ok |> Just }, T.send (ParseProject |> wrap) )

        ParseProject ->
            model.loadedProject
                |> Maybe.andThen Result.toMaybe
                |> Maybe.map
                    (\loadedProject ->
                        case loadedProject |> Decode.decodeString Project.decode of
                            Ok project ->
                                ( { model | parsedProject = project |> Ok |> Just }, T.send (BuildProject |> wrap) )

                            Err err ->
                                ( { model | parsedProject = err |> Err |> Just } |> setProject (err |> Decode.errorToString |> Err |> Just), Cmd.none )
                    )
                |> Maybe.withDefault ( model, Cmd.none )

        BuildProject ->
            model.parsedProject
                |> Maybe.andThen Result.toMaybe
                |> Maybe.map (\parsedProject -> ( model |> setProject (parsedProject |> Ok |> Just), Cmd.none ))
                |> Maybe.withDefault ( model, Cmd.none )

        UiToggle htmlId ->
            ( model |> mapShow (\s -> B.cond (s == htmlId) "" htmlId), Cmd.none )



-- VIEW


viewLocalInput : (Msg -> msg) -> (String -> msg) -> HtmlId -> Html msg
viewLocalInput wrap noop htmlId =
    FileInput.input
        { id = htmlId
        , onDrop = \f _ -> f |> GetLocalFile |> wrap
        , onOver = \_ _ -> noop htmlId
        , onLeave = Nothing
        , onSelect = GetLocalFile >> wrap
        , content =
            div [ css [ "space-y-1 text-center" ] ]
                [ Icon.outline2x FolderAdd "mx-auto"
                , p [] [ span [ css [ "text-primary-600" ] ] [ text "Upload a project file" ], text " or drag and drop" ]
                , p [ css [ "text-xs" ] ] [ text ".json file only" ]
                ]
        , mimes = [ ".json" ]
        }


viewParsing : (Msg -> msg) -> Time.Zone -> Maybe Project -> Model -> Html msg
viewParsing wrap zone currentProject model =
    (model.selectedLocalFile |> Maybe.map (\f -> f.name ++ " file"))
        |> Maybe.orElse (model.selectedRemoteFile |> Maybe.map (\url -> url ++ " file"))
        |> Maybe.mapOrElse
            (\fileName ->
                div []
                    [ div [ class "mt-6" ]
                        [ Divider.withLabel
                            ((model.project |> Maybe.map (\_ -> "Loaded!"))
                                |> Maybe.orElse (model.parsedProject |> Maybe.map (\_ -> "Building..."))
                                |> Maybe.orElse (model.loadedProject |> Maybe.map (\_ -> "Parsing..."))
                                |> Maybe.withDefault "Fetching..."
                            )
                        ]
                    , SourceLogs.viewContainer
                        [ SourceLogs.viewFile UiToggle model.show fileName (model.loadedProject |> Maybe.andThen Result.toMaybe) |> Html.map wrap
                        , model.loadedProject |> Maybe.mapOrElse (Result.mapError Http.errorToString >> SourceLogs.viewError) (div [] [])
                        , model.parsedProject |> Maybe.mapOrElse (Result.fold viewLogsError (viewLogsProject zone)) (div [] [])
                        , model.project |> Maybe.mapOrElse SourceLogs.viewResult (div [] [])
                        ]
                    , model.parsedProject
                        |> Maybe.andThen Result.toMaybe
                        |> Maybe.andThen (\project -> currentProject |> Maybe.map (\p -> viewDiffAlert zone p project))
                        |> Maybe.withDefault (div [] [])
                    ]
            )
            (div [] [])


viewLogsError : Decode.Error -> Html msg
viewLogsError error =
    div []
        [ div [] [ text "Failed to decode project 😱" ]
        , div [ class "text-red-500" ] [ text (Decode.errorToStringNoValue error) ]
        , div [] [ text "This is quite sad, you can try to fix the format yourself or ", extLink Conf.constants.azimuttBugReport [ class "link" ] [ text "open an issue on GitHub" ], text "." ]
        ]


viewLogsProject : Time.Zone -> Project -> Html msg
viewLogsProject zone project =
    div []
        [ div [] [ text ("Successfully decoded project " ++ project.name ++ ".") ]
        , div [] [ text ("It was created on " ++ DateTime.formatDate zone project.createdAt ++ " and last modified on " ++ DateTime.formatDate zone project.updatedAt ++ ".") ]
        , div [] [ text ("It has " ++ String.pluralizeD "layout" project.layouts ++ " and " ++ String.pluralizeL "source" project.sources ++ ", containing " ++ String.pluralizeD "table" project.tables ++ " and " ++ String.pluralizeL "relation" project.relations ++ ".") ]
        ]


viewDiffAlert : Time.Zone -> Project -> Project -> Html msg
viewDiffAlert zone old new =
    div [ class "mt-6" ]
        [ Alert.withDescription { color = Tw.yellow, icon = Exclamation, title = "Oh! You already have this project here." }
            [ div [] [ text "This project already exist in Azimutt (same id), compare the differences below to decide what to do:" ]
            , ul [ class "list-disc list-inside" ]
                [ li [] [ text ("Existing project has been last modified on " ++ DateTime.formatDate zone old.updatedAt ++ " while imported one was updated on " ++ DateTime.formatDate zone new.updatedAt) ]
                , li [] [ text ("Existing project has " ++ String.pluralizeD "table" old.tables ++ " and " ++ String.pluralizeL "relation" old.relations ++ ", the imported one has " ++ String.pluralizeD "table" new.tables ++ " and " ++ String.pluralizeL "relation" new.relations ++ ".") ]
                , li [] [ text ("Existing project has " ++ String.pluralizeD "layout" old.layouts ++ ", the imported one has " ++ String.pluralizeD "layout" new.layouts ++ ".") ]
                ]
            ]
        ]
