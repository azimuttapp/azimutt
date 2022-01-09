module PagesComponents.Projects.Id_.Views.Modals.SourceUpload exposing (viewSourceUpload)

import Components.Atoms.Button as Button
import Components.Molecules.FileInput as FileInput
import Components.Molecules.Modal as Modal
import Conf
import Html.Styled exposing (Html, br, div, h3, p, text)
import Html.Styled.Attributes exposing (css, disabled, id)
import Html.Styled.Events exposing (onClick)
import Libs.DateTime as DateTime
import Libs.Html.Styled exposing (bText, extLink)
import Libs.Maybe as M
import Libs.Models.Color as Color
import Libs.Models.FileName exposing (FileName)
import Libs.Models.FileUpdatedAt exposing (FileUpdatedAt)
import Libs.Models.FileUrl exposing (FileUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.Tailwind.Utilities as Tu
import Models.Project.Source exposing (Source)
import Models.Project.SourceKind exposing (SourceKind(..))
import PagesComponents.Projects.Id_.Models exposing (Msg(..), ProjectSettingsMsg(..), SourceUploadDialog)
import Services.SQLSource as SQLSource exposing (SQLSource, SQLSourceMsg(..))
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw
import Time


viewSourceUpload : Theme -> Time.Zone -> Time.Posix -> Bool -> SourceUploadDialog -> Html Msg
viewSourceUpload theme zone now opened model =
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
                            localFileModal theme zone now titleId source filename updatedAt model.parsing

                        RemoteFile url _ ->
                            remoteFileModal theme zone now titleId source url model.parsing

                        UserDefined ->
                            userDefinedModal theme titleId
                )
                (newSourceModal theme titleId model.parsing)
        )


localFileModal : Theme -> Time.Zone -> Time.Posix -> HtmlId -> Source -> FileName -> FileUpdatedAt -> SQLSource Msg -> List (Html Msg)
localFileModal theme zone now titleId source fileName updatedAt model =
    [ div [ css [ Tw.max_w_3xl, Tw.mx_6, Tw.mt_6 ] ]
        [ div [ css [ Tw.mt_3, Bp.sm [ Tw.mt_5 ] ] ]
            [ h3 [ id titleId, css [ Tw.text_lg, Tw.leading_6, Tw.text_center, Tw.font_medium, Tw.text_gray_900 ] ]
                [ text ("Refresh " ++ source.name ++ " source") ]
            , div [ css [ Tw.mt_2 ] ]
                [ p [ css [ Tw.text_sm, Tw.text_gray_500 ] ]
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
        , FileInput.basic theme "file-upload" (SelectLocalFile >> PSSQLSourceMsg >> ProjectSettingsMsg)
        , SQLSource.viewParsing model
        ]
    , div [ css [ Tw.px_6, Tw.py_3, Tw.mt_3, Tw.flex, Tw.items_center, Tw.justify_between, Tw.flex_row_reverse, Tw.bg_gray_50 ] ]
        [ primaryBtn theme (model.parsedSource |> Maybe.map (PSSourceRefresh >> ProjectSettingsMsg)) "Refresh"
        , closeBtn
        ]
    ]


remoteFileModal : Theme -> Time.Zone -> Time.Posix -> HtmlId -> Source -> FileUrl -> SQLSource Msg -> List (Html Msg)
remoteFileModal theme zone now titleId source fileUrl model =
    [ div [ css [ Tw.max_w_3xl, Tw.mx_6, Tw.mt_6 ] ]
        [ div [ css [ Tw.mt_3, Bp.sm [ Tw.mt_5 ] ] ]
            [ h3 [ id titleId, css [ Tw.text_lg, Tw.leading_6, Tw.text_center, Tw.font_medium, Tw.text_gray_900 ] ]
                [ text ("Refresh " ++ source.name ++ " source") ]
            , div [ css [ Tw.mt_2 ] ]
                [ p [ css [ Tw.text_sm, Tw.text_gray_500 ] ]
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
        , div [ css [ Tw.mt_3, Tw.flex, Tw.justify_center ] ]
            [ Button.primary5 theme.color [ onClick (fileUrl |> SelectRemoteFile |> PSSQLSourceMsg |> ProjectSettingsMsg) ] [ text "Fetch file again" ]
            ]
        , SQLSource.viewParsing model
        ]
    , div [ css [ Tw.px_6, Tw.py_3, Tw.mt_3, Tw.flex, Tw.items_center, Tw.justify_between, Tw.flex_row_reverse, Tw.bg_gray_50 ] ]
        [ primaryBtn theme (model.parsedSource |> Maybe.map (PSSourceRefresh >> ProjectSettingsMsg)) "Refresh"
        , closeBtn
        ]
    ]


userDefinedModal : Theme -> HtmlId -> List (Html Msg)
userDefinedModal theme titleId =
    [ div [ css [ Tw.max_w_3xl, Tw.mx_6, Tw.mt_6 ] ]
        [ div [ css [ Tw.mt_3, Tw.text_center, Bp.sm [ Tw.mt_5 ] ] ]
            [ h3 [ id titleId, css [ Tw.text_lg, Tw.leading_6, Tw.font_medium, Tw.text_gray_900 ] ]
                [ text "This is a user source, it can't be refreshed!" ]
            ]
        , p [ css [ Tw.mt_3 ] ]
            [ text """A user source is a source created by a user to add some information to the project.
                      For example relations, tables, columns or documentation that are useful and not present in the sources.
                      So it doesn't make sense to refresh it (not out of sync), just edit or delete it if needed."""
            , br [] []
            , text "You should not see this, so if you came here normally, this is a bug. Please help us and "
            , extLink Conf.constants.azimuttBugReport [ css [ Tu.link ] ] [ text "report it" ]
            , text ". What would be useful to fix it is what steps you did to get here."
            ]
        ]
    , div [ css [ Tw.px_6, Tw.py_3, Tw.mt_3, Tw.flex, Tw.items_center, Tw.justify_between, Tw.flex_row_reverse, Tw.bg_gray_50 ] ]
        [ primaryBtn theme (PSSourceUploadClose |> ProjectSettingsMsg |> ModalClose |> Just) "Close"
        ]
    ]


newSourceModal : Theme -> HtmlId -> SQLSource Msg -> List (Html Msg)
newSourceModal theme titleId model =
    [ div [ css [ Tw.max_w_3xl, Tw.mx_6, Tw.mt_6 ] ]
        [ div [ css [ Tw.mt_3, Tw.text_center, Bp.sm [ Tw.mt_5 ] ] ]
            [ h3 [ id titleId, css [ Tw.text_lg, Tw.leading_6, Tw.font_medium, Tw.text_gray_900 ] ]
                [ text "Add a new source" ]
            , div [ css [ Tw.mt_2 ] ]
                [ p [ css [ Tw.text_sm, Tw.text_gray_500 ] ]
                    [ text """A project can have several sources and they can be independently enabled or not.
                      It's a great way to explore multiple database at once if you project use multiple databases."""
                    ]
                ]
            ]
        , FileInput.basic theme "file-upload" (SelectLocalFile >> PSSQLSourceMsg >> ProjectSettingsMsg)
        , SQLSource.viewParsing model
        ]
    , div [ css [ Tw.px_6, Tw.py_3, Tw.mt_3, Tw.flex, Tw.items_center, Tw.justify_between, Tw.flex_row_reverse, Tw.bg_gray_50 ] ]
        [ primaryBtn theme (model.parsedSource |> Maybe.map (PSSourceAdd >> ProjectSettingsMsg)) "Add source"
        , closeBtn
        ]
    ]



-- helpers


primaryBtn : Theme -> Maybe Msg -> String -> Html Msg
primaryBtn theme clicked label =
    Button.primary3 theme.color (clicked |> M.mapOrElse (\c -> [ onClick c ]) [ disabled True ]) [ text label ]


closeBtn : Html Msg
closeBtn =
    Button.white3 Color.gray [ onClick (ModalClose (ProjectSettingsMsg PSSourceUploadClose)) ] [ text "Close" ]
