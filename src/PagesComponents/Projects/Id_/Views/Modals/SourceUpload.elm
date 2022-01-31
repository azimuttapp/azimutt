module PagesComponents.Projects.Id_.Views.Modals.SourceUpload exposing (viewSourceUpload)

import Components.Atoms.Button as Button
import Components.Atoms.Icon exposing (Icon(..))
import Components.Molecules.Alert as Alert
import Components.Molecules.FileInput as FileInput
import Components.Molecules.Modal as Modal
import Conf
import Html exposing (Html, br, div, h3, li, p, text, ul)
import Html.Attributes exposing (class, id)
import Html.Styled as Styled exposing (toUnstyled)
import Html.Styled.Attributes as Styled
import Html.Styled.Events as Styled
import Libs.DateTime as DateTime
import Libs.Html exposing (bText, extLink)
import Libs.Html.Attributes exposing (role)
import Libs.Maybe as M
import Libs.Models.Color as Color
import Libs.Models.FileName exposing (FileName)
import Libs.Models.FileUpdatedAt exposing (FileUpdatedAt)
import Libs.Models.FileUrl exposing (FileUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Models.Project.Source exposing (Source)
import Models.Project.SourceKind exposing (SourceKind(..))
import PagesComponents.Projects.Id_.Models exposing (Msg(..), ProjectSettingsMsg(..), SourceUploadDialog)
import Services.SQLSource as SQLSource exposing (SQLSource, SQLSourceMsg(..))
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
            |> M.mapOrElse
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


localFileModal : Time.Zone -> Time.Posix -> HtmlId -> Source -> FileName -> FileUpdatedAt -> SQLSource Msg -> List (Html Msg)
localFileModal zone now titleId source fileName updatedAt model =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ class "mt-3 sm:mt-5" ]
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
        , div [ class "mt-3" ] [ FileInput.basic Conf.theme "file-upload" (SelectLocalFile >> PSSQLSourceMsg >> ProjectSettingsMsg) (Noop "file-over") |> toUnstyled ]
        , case ( source.kind, model.loadedFile |> Maybe.map (\( _, s, _ ) -> s.kind) ) of
            ( LocalFile name1 _ updated1, Just (LocalFile name2 _ updated2) ) ->
                [ Just [ text "Your file name changed from ", bText name1, text " to ", bText name2 ] |> M.filter (\_ -> name1 /= name2)
                , Just [ text "You file is ", bText "older", text " than the previous one" ] |> M.filter (\_ -> updated1 |> DateTime.greaterThan updated2)
                ]
                    |> List.filterMap identity
                    |> (\warnings ->
                            if warnings == [] then
                                div [] []

                            else
                                div [ class "mt-3" ]
                                    [ Alert.withDescription { color = Color.yellow, icon = Exclamation, title = "Found some strange things" }
                                        [ ul [ role "list", class "list-disc list-inside" ]
                                            (warnings |> List.map (\warning -> li [] warning))
                                        ]
                                    ]
                       )

            _ ->
                div [] []
        , SQLSource.viewParsing model
        ]
    , div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50" ]
        [ primaryBtn (model.parsedSource |> Maybe.map (PSSourceRefresh >> ProjectSettingsMsg)) "Refresh"
        , closeBtn
        ]
    ]


remoteFileModal : Time.Zone -> Time.Posix -> HtmlId -> Source -> FileUrl -> SQLSource Msg -> List (Html Msg)
remoteFileModal zone now titleId source fileUrl model =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ class "mt-3 sm:mt-5" ]
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
            [ Button.primary5 Conf.theme.color [ Styled.onClick (fileUrl |> SelectRemoteFile |> PSSQLSourceMsg |> ProjectSettingsMsg) ] [ Styled.text "Fetch file again" ] |> toUnstyled
            ]
        , SQLSource.viewParsing model
        ]
    , div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50" ]
        [ primaryBtn (model.parsedSource |> Maybe.map (PSSourceRefresh >> ProjectSettingsMsg)) "Refresh"
        , closeBtn
        ]
    ]


userDefinedModal : HtmlId -> List (Html Msg)
userDefinedModal titleId =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ class "mt-3 sm:mt-5" ]
            [ h3 [ id titleId, class "text-lg leading-6 text-center font-medium text-gray-900" ]
                [ text "This is a user source, it can't be refreshed!" ]
            ]
        , p [ class "mt-3" ]
            [ text """A user source is a source created by a user to add some information to the project.
                      For example relations, tables, columns or documentation that are useful and not present in the sources.
                      So it doesn't make sense to refresh it (not out of sync), just edit or delete it if needed."""
            , br [] []
            , text "You should not see this, so if you came here normally, this is a bug. Please help us and "
            , extLink Conf.constants.azimuttBugReport [ class "tw-link" ] [ text "report it" ]
            , text ". What would be useful to fix it is what steps you did to get here."
            ]
        ]
    , div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50" ]
        [ primaryBtn (PSSourceUploadClose |> ProjectSettingsMsg |> ModalClose |> Just) "Close"
        ]
    ]


newSourceModal : HtmlId -> SQLSource Msg -> List (Html Msg)
newSourceModal titleId model =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ class "mt-3 sm:mt-5" ]
            [ h3 [ id titleId, class "text-lg leading-6 text-center font-medium text-gray-900" ]
                [ text "Add a new source" ]
            , div [ class "mt-2" ]
                [ p [ class "text-sm text-gray-500" ]
                    [ text """A project can have several sources and they can be independently enabled or not.
                      It's a great way to explore multiple database at once if you project use multiple databases."""
                    ]
                ]
            ]
        , div [ class "mt-3" ] [ FileInput.basic Conf.theme "file-upload" (SelectLocalFile >> PSSQLSourceMsg >> ProjectSettingsMsg) (Noop "file-over") |> toUnstyled ]
        , SQLSource.viewParsing model
        ]
    , div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50" ]
        [ primaryBtn (model.parsedSource |> Maybe.map (PSSourceAdd >> ProjectSettingsMsg)) "Add source"
        , closeBtn
        ]
    ]



-- helpers


primaryBtn : Maybe Msg -> String -> Html Msg
primaryBtn clicked label =
    Button.primary3 Conf.theme.color (clicked |> M.mapOrElse (\c -> [ Styled.onClick c ]) [ Styled.disabled True ]) [ Styled.text label ] |> toUnstyled


closeBtn : Html Msg
closeBtn =
    Button.white3 Color.gray [ Styled.onClick (ModalClose (ProjectSettingsMsg PSSourceUploadClose)) ] [ Styled.text "Close" ] |> toUnstyled
