module Services.ProjectImport exposing (ProjectImport, ProjectImportMsg(..), gotLocalFile, gotRemoteFile, init, update, viewParsing)

import Components.Atoms.Icon exposing (Icon(..))
import Components.Molecules.Alert as Alert
import Components.Molecules.Divider as Divider
import Conf
import FileValue exposing (File)
import Html exposing (Html, div, li, text, ul)
import Html.Attributes exposing (class)
import Json.Decode as Decode
import Libs.Html exposing (extLink)
import Libs.Json.Decode as Decode
import Libs.Maybe as Maybe
import Libs.Models exposing (FileContent)
import Libs.Models.DateTime as DateTime
import Libs.Models.FileUrl exposing (FileUrl)
import Libs.Result as Result
import Libs.String as String
import Libs.Tailwind as Tw
import Models.Project as Project exposing (Project)
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.SampleKey exposing (SampleKey)
import Ports
import Time


type alias ProjectImport =
    { selectedLocalFile : Maybe File
    , selectedRemoteFile : Maybe { url : FileUrl, sample : Maybe SampleKey }
    , parsedProject : Maybe ( ProjectId, Result Decode.Error Project )
    }


type ProjectImportMsg
    = SelectLocalFile File
    | SelectRemoteFile FileUrl (Maybe SampleKey)
    | FileLoaded ProjectId FileContent



-- INIT


init : ProjectImport
init =
    { selectedLocalFile = Nothing
    , selectedRemoteFile = Nothing
    , parsedProject = Nothing
    }



-- UPDATE


update : ProjectImportMsg -> ProjectImport -> ( ProjectImport, Cmd msg )
update msg model =
    case msg of
        SelectLocalFile file ->
            ( init |> (\m -> { m | selectedLocalFile = Just file })
            , Ports.readLocalFile Nothing Nothing file
            )

        SelectRemoteFile url sample ->
            ( init |> (\m -> { m | selectedRemoteFile = Just { url = url, sample = sample } })
            , Ports.readRemoteFile Nothing Nothing url sample
            )

        FileLoaded projectId content ->
            ( { model | parsedProject = Just ( projectId, Decode.decodeString Project.decode content ) }, Cmd.none )



-- SUBSCRIPTIONS


gotLocalFile : ProjectId -> FileContent -> ProjectImportMsg
gotLocalFile projectId content =
    FileLoaded projectId content


gotRemoteFile : ProjectId -> FileContent -> ProjectImportMsg
gotRemoteFile projectId content =
    FileLoaded projectId content



-- VIEW


viewParsing : Time.Zone -> Maybe Project -> ProjectImport -> Html msg
viewParsing zone currentProject model =
    let
        isSample : Bool
        isSample =
            (model.selectedRemoteFile |> Maybe.andThen .sample) /= Nothing
    in
    (model.selectedLocalFile |> Maybe.map (\f -> f.name ++ " file"))
        |> Maybe.orElse (model.selectedRemoteFile |> Maybe.map (\{ url, sample } -> sample |> Maybe.withDefault (url ++ " file")))
        |> Maybe.mapOrElse
            (\fileName ->
                div []
                    [ div [ class "mt-6" ] [ Divider.withLabel (model.parsedProject |> Maybe.mapOrElse (\_ -> "Parsed!") "Parsing ...") ]
                    , viewLogs zone isSample fileName model.parsedProject
                    , model.parsedProject
                        |> Maybe.map Tuple.second
                        |> Maybe.andThen Result.toMaybe
                        |> Maybe.andThen (\project -> currentProject |> Maybe.map (\p -> viewDiffAlert zone isSample p project))
                        |> Maybe.withDefault (div [] [])
                    ]
            )
            (div [] [])


viewLogs : Time.Zone -> Bool -> String -> Maybe ( ProjectId, Result Decode.Error Project ) -> Html msg
viewLogs zone isSample fileName parsedProject =
    div [ class "mt-6 px-4 py-2 max-h-96 overflow-y-auto font-mono text-xs bg-gray-50 shadow rounded-lg" ]
        [ div [] [ text ("Loaded " ++ fileName ++ ".") ]
        , parsedProject |> Maybe.map Tuple.second |> Maybe.mapOrElse (Result.fold viewLogsError (viewLogsProject zone isSample)) (div [] [])
        ]


viewLogsError : Decode.Error -> Html msg
viewLogsError error =
    div []
        [ div [] [ text "Failed to decode project 😱" ]
        , div [ class "text-red-500" ] [ text (Decode.errorToStringNoValue error) ]
        , div [] [ text "This is quite sad, you can try to fix the format yourself or ", extLink Conf.constants.azimuttBugReport [ class "link" ] [ text "open an issue on GitHub" ], text "." ]
        ]


viewLogsProject : Time.Zone -> Bool -> Project -> Html msg
viewLogsProject zone isSample project =
    if isSample then
        div []
            [ div [] [ text "Successfully decoded project." ] ]

    else
        div []
            [ div [] [ text ("Successfully decoded project " ++ project.name ++ ".") ]
            , div [] [ text ("It was created on " ++ DateTime.formatDate zone project.createdAt ++ " and last modified on " ++ DateTime.formatDate zone project.updatedAt ++ ".") ]
            , div [] [ text ("It has " ++ String.pluralizeD "layout" project.layouts ++ " and " ++ String.pluralizeL "source" project.sources ++ ", containing " ++ String.pluralizeD "table" project.tables ++ " and " ++ String.pluralizeL "relation" project.relations ++ ".") ]
            ]


viewDiffAlert : Time.Zone -> Bool -> Project -> Project -> Html msg
viewDiffAlert zone isSample old new =
    div [ class "mt-6" ]
        [ Alert.withDescription { color = Tw.yellow, icon = Exclamation, title = "Oh! You already have this project here." }
            (if isSample then
                []

             else
                [ div [] [ text "This project already exist in Azimutt (same id), compare the differences below to decide what to do:" ]
                , ul [ class "list-disc list-inside" ]
                    [ li [] [ text ("Existing project has been last modified on " ++ DateTime.formatDate zone old.updatedAt ++ " while imported one was updated on " ++ DateTime.formatDate zone new.updatedAt) ]
                    , li [] [ text ("Existing project has " ++ String.pluralizeD "table" old.tables ++ " and " ++ String.pluralizeL "relation" old.relations ++ ", the imported one has " ++ String.pluralizeD "table" new.tables ++ " and " ++ String.pluralizeL "relation" new.relations ++ ".") ]
                    , li [] [ text ("Existing project has " ++ String.pluralizeD "layout" old.layouts ++ ", the imported one has " ++ String.pluralizeD "layout" new.layouts ++ ".") ]
                    ]
                ]
            )
        ]
