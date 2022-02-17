module Services.ProjectImport exposing (ProjectImport, ProjectImportMsg(..), gotLocalFile, init, update, viewParsing)

import Components.Atoms.Icon exposing (Icon(..))
import Components.Molecules.Alert as Alert
import Components.Molecules.Divider as Divider
import Conf
import FileValue exposing (File)
import Html exposing (Html, div, li, text, ul)
import Html.Attributes exposing (class)
import Json.Decode as Decode
import Libs.DateTime as DateTime
import Libs.Html exposing (extLink)
import Libs.Json.Decode as Decode
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models exposing (FileContent)
import Libs.Result as Result
import Libs.String as String
import Libs.Tailwind as Tw
import Models.FileKind exposing (FileKind(..))
import Models.Project as Project exposing (Project)
import Models.Project.ProjectId exposing (ProjectId)
import Ports
import Time


type alias ProjectImport =
    { selectedLocalFile : Maybe File
    , parsedProject : Maybe ( ProjectId, Result Decode.Error Project )
    }


type ProjectImportMsg
    = SelectLocalFile File
    | FileLoaded ProjectId FileContent



-- INIT


init : ProjectImport
init =
    { selectedLocalFile = Nothing
    , parsedProject = Nothing
    }



-- UPDATE


update : ProjectImportMsg -> ProjectImport -> ( ProjectImport, Cmd msg )
update msg model =
    case msg of
        SelectLocalFile file ->
            ( init |> (\m -> { m | selectedLocalFile = Just file })
            , Ports.readLocalFile Nothing Nothing file ProjectFile
            )

        FileLoaded projectId content ->
            ( { model | parsedProject = Just ( projectId, Decode.decodeString Project.decode content ) }, Cmd.none )



-- SUBSCRIPTIONS


gotLocalFile : ProjectId -> FileContent -> ProjectImportMsg
gotLocalFile projectId content =
    FileLoaded projectId content



-- VIEW


viewParsing : Time.Zone -> List Project -> ProjectImport -> Html msg
viewParsing zone currentProjects model =
    Maybe.mapOrElse
        (\file ->
            div []
                [ div [ class "mt-6" ] [ Divider.withLabel (model.parsedProject |> Maybe.mapOrElse (\_ -> "Parsed!") "Parsing ...") ]
                , viewLogs zone file model.parsedProject
                , model.parsedProject
                    |> Maybe.map Tuple.second
                    |> Maybe.andThen Result.toMaybe
                    |> Maybe.andThen (\project -> currentProjects |> List.find (\p -> p.id == project.id) |> Maybe.map (\p -> viewDiffAlert zone p project))
                    |> Maybe.withDefault (div [] [])
                ]
        )
        (div [] [])
        model.selectedLocalFile


viewLogs : Time.Zone -> File -> Maybe ( ProjectId, Result Decode.Error Project ) -> Html msg
viewLogs zone file parsedProject =
    div [ class "mt-6 px-4 py-2 max-h-96 overflow-y-auto font-mono text-xs bg-gray-50 shadow rounded-lg" ]
        [ div [] [ text ("Loaded " ++ file.name ++ " file.") ]
        , parsedProject |> Maybe.map Tuple.second |> Maybe.mapOrElse (Result.fold viewLogsError (viewLogsProject zone)) (div [] [])
        ]


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
