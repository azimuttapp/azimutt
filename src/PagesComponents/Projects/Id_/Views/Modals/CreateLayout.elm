module PagesComponents.Projects.Id_.Views.Modals.CreateLayout exposing (viewCreateLayout)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Modal as Modal
import Css
import Html.Styled exposing (Html, div, h3, input, label, p, text)
import Html.Styled.Attributes exposing (autofocus, css, for, id, name, tabindex, type_, value)
import Html.Styled.Events exposing (onClick, onInput)
import Libs.Html.Styled exposing (bText, extLink)
import Libs.Models.Color as Color
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import PagesComponents.Projects.Id_.Models exposing (LayoutDialog, LayoutMsg(..), Msg(..))
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw
import Url exposing (percentEncode)


viewCreateLayout : Theme -> Bool -> LayoutDialog -> Html Msg
viewCreateLayout theme opened model =
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
        [ div [ css [ Tw.px_6, Tw.pt_6, Bp.sm [ Tw.flex, Tw.items_start ] ] ]
            [ div [ css [ Tw.mx_auto, Tw.flex_shrink_0, Tw.flex, Tw.items_center, Tw.justify_center, Tw.h_12, Tw.w_12, Tw.rounded_full, Color.bg theme.color 100, Bp.sm [ Tw.mx_0, Tw.h_10, Tw.w_10 ] ] ]
                [ Icon.outline Template [ Color.text theme.color 600 ]
                ]
            , div [ css [ Tw.mt_3, Tw.text_center, Bp.sm [ Tw.mt_0, Tw.ml_4, Tw.text_left ] ] ]
                [ h3 [ id titleId, css [ Tw.text_lg, Tw.leading_6, Tw.font_medium, Tw.text_gray_900 ] ]
                    [ text "Save your layout" ]
                , div [ css [ Tw.mt_2 ] ]
                    [ label [ for inputId, css [ Tw.block, Tw.text_sm, Tw.font_medium, Tw.text_gray_700 ] ] [ text "Layout name" ]
                    , div [ css [ Tw.mt_1 ] ]
                        [ input [ type_ "text", name "layout-name", id inputId, value model.name, onInput (LEdit >> LayoutMsg), autofocus True, css [ Tw.form_input, Tw.shadow_sm, Tw.block, Tw.w_full, Tw.border_gray_300, Tw.rounded_md, Css.focus [ Tw.ring_indigo_500, Tw.border_indigo_500 ], Bp.sm [ Tw.text_sm ] ] ] []
                        ]
                    , p [ css [ Tw.text_sm, Tw.text_gray_500 ] ]
                        [ text "Do you like Azimutt ? Consider "
                        , extLink (sendTweet "Hi @azimuttapp team, well done with your app, I really like it 👍") [ tabindex -1 ] [ text "sending us a tweet" ]
                        , text ", it will help "
                        , bText "keep our motivation high"
                        , text " 🥰"
                        ]
                    ]
                ]
            ]
        , div [ css [ Tw.px_6, Tw.py_3, Tw.mt_6, Tw.flex, Tw.items_center, Tw.flex_row_reverse, Tw.bg_gray_50 ] ]
            [ Button.primary3 theme.color [ onClick (model.name |> LCreate |> LayoutMsg |> ModalClose), css [ Tw.w_full, Tw.text_base, Bp.sm [ Tw.ml_3, Tw.w_auto, Tw.text_sm ] ] ] [ text "Save layout" ]
            , Button.white3 Color.gray [ onClick (LCancel |> LayoutMsg |> ModalClose), css [ Tw.mt_3, Tw.w_full, Tw.text_base, Bp.sm [ Tw.mt_0, Tw.w_auto, Tw.text_sm ] ] ] [ text "Cancel" ]
            ]
        ]


sendTweet : String -> String
sendTweet text =
    "https://twitter.com/intent/tweet?text=" ++ percentEncode text
