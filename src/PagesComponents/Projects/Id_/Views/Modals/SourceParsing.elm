module PagesComponents.Projects.Id_.Views.Modals.SourceParsing exposing (viewSourceParsing)

import Components.Atoms.Button as Button
import Components.Molecules.Modal as Modal
import Html exposing (Html, div, h3, text)
import Html.Attributes exposing (class, disabled)
import Html.Events exposing (onClick)
import Libs.Maybe as Maybe
import Libs.Models.FileUrl as FileUrl
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw
import PagesComponents.Projects.Id_.Models exposing (Msg(..), SourceParsingDialog)
import Services.SqlSource as SqlSource


viewSourceParsing : Bool -> SourceParsingDialog -> Html Msg
viewSourceParsing opened model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"

        sourceName : String
        sourceName =
            (model.sqlSource.selectedLocalFile |> Maybe.map .name)
                |> Maybe.orElse (model.sqlSource.selectedRemoteFile |> Maybe.andThen Result.toMaybe |> Maybe.map FileUrl.filename)
                |> Maybe.withDefault "your"
    in
    Modal.modal
        { id = model.id
        , titleId = titleId
        , isOpen = opened
        , onBackgroundClick = Noop "close-source-parsing"
        }
        [ h3 [ class "px-6 pt-6 text-lg leading-6 font-medium text-gray-900" ] [ text ("Parsing " ++ sourceName ++ " source...") ]
        , div [ class "px-6" ] [ SqlSource.viewParsing EmbedSourceParsing model.sqlSource ]
        , div [ class "px-6 py-3 mt-6 flex items-center justify-between flex-row-reverse bg-gray-50 rounded-b-lg" ]
            [ Button.primary3 Tw.primary (model.sqlSource.parsedSource |> Maybe.andThen Result.toMaybe |> Maybe.mapOrElse (\source -> [ onClick (ModalClose (SourceParsed source)) ]) [ disabled True ]) [ text "Open schema" ]
            ]
        ]
