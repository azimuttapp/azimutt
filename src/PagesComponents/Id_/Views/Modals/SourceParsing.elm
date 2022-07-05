module PagesComponents.Id_.Views.Modals.SourceParsing exposing (viewSourceParsing)

import Components.Atoms.Button as Button
import Components.Molecules.Modal as Modal
import Html exposing (Html, div, h3, text)
import Html.Attributes exposing (class, disabled)
import Html.Events exposing (onClick)
import Libs.Maybe as Maybe
import Libs.Models.FileUrl as FileUrl
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.Source exposing (Source)
import PagesComponents.Id_.Models exposing (Msg(..), SourceParsingDialog)
import Services.SqlSourceUpload as SqlSourceUpload


viewSourceParsing : Bool -> SourceParsingDialog -> Html Msg
viewSourceParsing opened model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"

        sourceName : String
        sourceName =
            (model.parsing.selectedLocalFile |> Maybe.map .name)
                |> Maybe.orElse (model.parsing.selectedRemoteFile |> Maybe.map FileUrl.filename)
                |> Maybe.withDefault "your"

        result : Maybe ( ProjectId, Source )
        result =
            Maybe.map2 (\( projectId, _, _ ) source -> ( projectId, source )) model.parsing.loadedFile model.parsing.parsedSource
    in
    Modal.modal
        { id = model.id
        , titleId = titleId
        , isOpen = opened
        , onBackgroundClick = Noop "close-source-parsing"
        }
        [ h3 [ class "px-6 pt-6 text-lg leading-6 font-medium text-gray-900" ] [ text ("Parsing " ++ sourceName ++ " source...") ]
        , div [ class "px-6" ] [ SqlSourceUpload.viewParsing SourceParsing model.parsing ]
        , div [ class "px-6 py-3 mt-6 flex items-center justify-between flex-row-reverse bg-gray-50 rounded-b-lg" ]
            [ Button.primary3 Tw.primary (result |> Maybe.mapOrElse (\( projectId, source ) -> [ onClick (ModalClose (SourceParsed projectId source)) ]) [ disabled True ]) [ text "Open schema" ]
            ]
        ]
