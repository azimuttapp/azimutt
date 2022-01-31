module PagesComponents.Projects.Id_.Views.Modals.CreateLayout exposing (viewCreateLayout)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Modal as Modal
import Conf
import Html exposing (Html, div, h3, input, label, p, text)
import Html.Attributes exposing (autofocus, class, for, id, name, tabindex, type_, value)
import Html.Events exposing (onInput)
import Html.Styled as Styled exposing (toUnstyled)
import Html.Styled.Attributes as Styled
import Html.Styled.Events as Styled
import Libs.Html exposing (bText, sendTweet)
import Libs.Models.Color as Color
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind exposing (bg_100)
import PagesComponents.Projects.Id_.Models exposing (LayoutDialog, LayoutMsg(..), Msg(..))
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


viewCreateLayout : Bool -> LayoutDialog -> Html Msg
viewCreateLayout opened model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"

        inputId : HtmlId
        inputId =
            model.id ++ "-input"
    in
    Modal.modal
        { id = model.id
        , titleId = titleId
        , isOpen = opened
        , onBackgroundClick = ModalClose (LayoutMsg LCancel)
        }
        [ div [ class "px-6 pt-6 sm:flex sm:items-start" ]
            [ div [ class ("mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full " ++ bg_100 Conf.theme.color ++ " sm:mx-0 sm:h-10 sm:w-10") ]
                [ Icon.outline Template [ Color.text Conf.theme.color 600 ] |> toUnstyled
                ]
            , div [ class "mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left" ]
                [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ]
                    [ text "Save your layout" ]
                , div [ class "mt-2" ]
                    [ label [ for inputId, class "block text-sm font-medium text-gray-700" ] [ text "Layout name" ]
                    , div [ class "mt-1" ]
                        [ input [ type_ "text", name "layout-name", id inputId, value model.name, onInput (LEdit >> LayoutMsg), autofocus True, class "shadow-sm block w-full border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" ] []
                        ]
                    , p [ class "mt-1 text-sm text-gray-500" ]
                        [ text "Do you like Azimutt ? Consider "
                        , sendTweet Conf.constants.cheeringTweet [ tabindex -1, class "tw-link" ] [ text "sending us a tweet" ]
                        , text ", it will help "
                        , bText "keep our motivation high"
                        , text " 🥰"
                        ]
                    ]
                ]
            ]
        , div [ class "px-6 py-3 mt-6 flex items-center flex-row-reverse bg-gray-50" ]
            [ Button.primary3 Conf.theme.color [ Styled.onClick (model.name |> LCreate |> LayoutMsg |> ModalClose), Styled.css [ Tw.w_full, Tw.text_base, Bp.sm [ Tw.ml_3, Tw.w_auto, Tw.text_sm ] ] ] [ Styled.text "Save layout" ] |> toUnstyled
            , Button.white3 Color.gray [ Styled.onClick (LCancel |> LayoutMsg |> ModalClose), Styled.css [ Tw.mt_3, Tw.w_full, Tw.text_base, Bp.sm [ Tw.mt_0, Tw.w_auto, Tw.text_sm ] ] ] [ Styled.text "Cancel" ] |> toUnstyled
            ]
        ]
