module PagesComponents.Projects.Id_.Views.Modals.SourceUpload exposing (viewSourceUpload)

import Components.Atoms.Button as Button
import Components.Atoms.Icon exposing (Icon(..))
import Components.Molecules.Alert as Alert
import Components.Molecules.Divider as Divider
import Components.Molecules.FileInput as FileInput
import Components.Molecules.Modal as Modal
import Conf
import Html exposing (Html, br, div, h3, input, li, p, span, text, ul)
import Html.Attributes exposing (class, disabled, id, name, placeholder, type_, value)
import Html.Events exposing (onBlur, onClick, onInput)
import Libs.DateTime as DateTime
import Libs.Html exposing (bText, extLink)
import Libs.Html.Attributes exposing (css, role)
import Libs.Maybe as Maybe
import Libs.Models.FileName exposing (FileName)
import Libs.Models.FileUpdatedAt exposing (FileUpdatedAt)
import Libs.Models.FileUrl exposing (FileUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw exposing (sm)
import Models.Project.Source exposing (Source)
import Models.Project.SourceKind exposing (SourceKind(..))
import PagesComponents.Projects.Id_.Models exposing (Msg(..), ProjectSettingsMsg(..), SourceUploadDialog)
import Services.SqlSourceUpload as SqlSourceUpload exposing (SqlSourceUpload, SqlSourceUploadMsg(..))
import Time


viewSourceUpload : Time.Zone -> Time.Posix -> Bool -> SourceUploadDialog -> Html Msg
viewSourceUpload zone now opened model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"
    in
    Modal.modal
        { id = model.id
        , titleId = titleId
        , isOpen = opened
        , onBackgroundClick = PSSourceUploadClose |> ProjectSettingsMsg |> ModalClose
        }
        (model.parsing.source
            |> Maybe.mapOrElse
                (\source ->
                    case source.kind of
                        LocalFile filename _ updatedAt ->
                            localFileModal zone now titleId source filename updatedAt model.parsing

                        RemoteFile url _ ->
                            remoteFileModal zone now titleId source url model.parsing

                        UserDefined ->
                            userDefinedModal titleId
                )
                (newSourceModal titleId model.parsing)
        )


localFileModal : Time.Zone -> Time.Posix -> HtmlId -> Source -> FileName -> FileUpdatedAt -> SqlSourceUpload Msg -> List (Html Msg)
localFileModal zone now titleId source fileName updatedAt model =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ css [ "mt-3", sm [ "mt-5" ] ] ]
            [ h3 [ id titleId, class "text-lg leading-6 text-center font-medium text-gray-900" ]
                [ text ("Refresh " ++ source.name ++ " source") ]
            , div [ class "mt-2" ]
                [ p [ class "text-sm text-gray-500" ]
                    [ text "This source came from the "
                    , bText (DateTime.formatDate zone updatedAt)
                    , text " version of "
                    , bText fileName
                    , text (" file (" ++ (updatedAt |> DateTime.human now) ++ ").")
                    , br [] []
                    , text "Please upload its new version to update the source."
                    ]
                ]
            ]
        , div [ class "mt-3" ] [ FileInput.schemaFile "file-upload" (SelectLocalFile >> PSSqlSourceMsg >> ProjectSettingsMsg) (Noop "update-source-local-file") ]
        , case ( source.kind, model.loadedFile |> Maybe.map (\( _, s, _ ) -> s.kind) ) of
            ( LocalFile name1 _ updated1, Just (LocalFile name2 _ updated2) ) ->
                [ Just [ text "Your file name changed from ", bText name1, text " to ", bText name2 ] |> Maybe.filter (\_ -> name1 /= name2)
                , Just [ text "You file is ", bText "older", text " than the previous one" ] |> Maybe.filter (\_ -> updated1 |> DateTime.greaterThan updated2)
                ]
                    |> List.filterMap identity
                    |> (\warnings ->
                            if warnings == [] then
                                div [] []

                            else
                                div [ class "mt-3" ]
                                    [ Alert.withDescription { color = Tw.yellow, icon = Exclamation, title = "Found some strange things" }
                                        [ ul [ role "list", class "list-disc list-inside" ]
                                            (warnings |> List.map (\warning -> li [] warning))
                                        ]
                                    ]
                       )

            _ ->
                div [] []
        , SqlSourceUpload.viewParsing (PSSqlSourceMsg >> ProjectSettingsMsg) model
        ]
    , div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50" ]
        [ primaryBtn (model.parsedSource |> Maybe.map (PSSourceRefresh >> ProjectSettingsMsg)) "Update source"
        , closeBtn
        ]
    ]


remoteFileModal : Time.Zone -> Time.Posix -> HtmlId -> Source -> FileUrl -> SqlSourceUpload Msg -> List (Html Msg)
remoteFileModal zone now titleId source fileUrl model =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ css [ "mt-3", sm [ "mt-5" ] ] ]
            [ h3 [ id titleId, class "text-lg leading-6 text-center font-medium text-gray-900" ]
                [ text ("Refresh " ++ source.name ++ " source") ]
            , div [ class "mt-2" ]
                [ p [ class "text-sm text-gray-500" ]
                    [ text "This source came from "
                    , bText fileUrl
                    , text " which was fetched the "
                    , bText (DateTime.formatDate zone source.updatedAt)
                    , text (" (" ++ (source.updatedAt |> DateTime.human now) ++ ").")
                    , br [] []
                    , text "Click on the button to fetch it again now."
                    ]
                ]
            ]
        , div [ class "mt-3 flex justify-center" ]
            [ Button.primary5 Tw.primary [ onClick (fileUrl |> SelectRemoteFile |> PSSqlSourceMsg |> ProjectSettingsMsg) ] [ text "Fetch file again" ]
            ]
        , SqlSourceUpload.viewParsing (PSSqlSourceMsg >> ProjectSettingsMsg) model
        ]
    , div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50" ]
        [ primaryBtn (model.parsedSource |> Maybe.map (PSSourceRefresh >> ProjectSettingsMsg)) "Update source"
        , closeBtn
        ]
    ]


userDefinedModal : HtmlId -> List (Html Msg)
userDefinedModal titleId =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ css [ "mt-3", sm [ "mt-5" ] ] ]
            [ h3 [ id titleId, class "text-lg leading-6 text-center font-medium text-gray-900" ]
                [ text "This is a user source, it can't be refreshed!" ]
            ]
        , p [ class "mt-3" ]
            [ text """A user source is a source created by a user to add some information to the project.
                      For example relations, tables, columns or documentation that are useful and not present in the sources.
                      So it doesn't make sense to refresh it (not out of sync), just edit or delete it if needed."""
            , br [] []
            , text "You should not see this, so if you came here normally, this is a bug. Please help us and "
            , extLink Conf.constants.azimuttBugReport [ class "link" ] [ text "report it" ]
            , text ". What would be useful to fix it is what steps you did to get here."
            ]
        ]
    , div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50" ]
        [ primaryBtn (PSSourceUploadClose |> ProjectSettingsMsg |> ModalClose |> Just) "Close"
        ]
    ]


newSourceModal : HtmlId -> SqlSourceUpload Msg -> List (Html Msg)
newSourceModal titleId model =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ css [ "mt-3", sm [ "mt-5" ] ] ]
            [ h3 [ id titleId, class "text-lg leading-6 text-center font-medium text-gray-900" ]
                [ text "Add a new source" ]
            , div [ class "mt-2" ]
                [ p [ class "text-sm text-gray-500" ]
                    [ text """A project can have several sources and they can be independently enabled or not.
                      It's a great way to explore multiple database at once if you project use multiple databases."""
                    ]
                ]
            ]
        , div [ class "mt-3" ] [ FileInput.schemaFile "file-upload" (SelectLocalFile >> PSSqlSourceMsg >> ProjectSettingsMsg) (Noop "new-source-local-file") ]
        , div [ class "my-3" ] [ Divider.withLabel "OR" ]
        , div [ class "flex rounded-md shadow-sm" ]
            [ span [ class "inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 sm:text-sm" ] [ text "Remote schema" ]
            , input
                [ type_ "text"
                , id "file-remote"
                , name "file-remote"
                , placeholder "https://azimutt.app/samples/gospeak.sql"
                , value (model.selectedRemoteFile |> Maybe.withDefault "")
                , onInput (UpdateRemoteFile >> PSSqlSourceMsg >> ProjectSettingsMsg)
                , onBlur (model.selectedRemoteFile |> Maybe.mapOrElse (SelectRemoteFile >> PSSqlSourceMsg >> ProjectSettingsMsg) (Noop "new-source-remote-file"))
                , class "flex-1 min-w-0 block w-full px-3 py-2 border-gray-300 rounded-none rounded-r-md sm:text-sm focus:ring-indigo-500 focus:border-indigo-500"
                ]
                []
            ]
        , SqlSourceUpload.viewParsing (PSSqlSourceMsg >> ProjectSettingsMsg) model
        ]
    , div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50" ]
        [ primaryBtn (model.parsedSource |> Maybe.map (PSSourceAdd >> ProjectSettingsMsg)) "Add source"
        , closeBtn
        ]
    ]



-- helpers


primaryBtn : Maybe Msg -> String -> Html Msg
primaryBtn clicked label =
    Button.primary3 Tw.primary (clicked |> Maybe.mapOrElse (\c -> [ onClick c ]) [ disabled True ]) [ text label ]


closeBtn : Html Msg
closeBtn =
    Button.white3 Tw.gray [ onClick (ModalClose (ProjectSettingsMsg PSSourceUploadClose)) ] [ text "Close" ]
