module PagesComponents.Projects.Id_.Views.Modals.CreateLayout exposing (viewCreateLayout)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Modal as Modal
import Conf
import Html exposing (Html, div, h3, input, label, p, text)
import Html.Attributes exposing (autofocus, class, for, id, name, tabindex, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Html exposing (bText, sendTweet)
import Libs.Html.Attributes exposing (css)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw exposing (focus, sm)
import PagesComponents.Projects.Id_.Models exposing (LayoutDialog, LayoutMsg(..), Msg(..))


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
        [ div [ css [ "px-6 pt-6", sm [ "flex items-start" ] ] ]
            [ div [ css [ "mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-primary-100", sm [ "mx-0 h-10 w-10" ] ] ]
                [ Icon.outline Template "text-primary-600"
                ]
            , div [ css [ "mt-3 text-center", sm [ "mt-0 ml-4 text-left" ] ] ]
                [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ]
                    [ text "Save your layout" ]
                , div [ class "mt-2" ]
                    [ label [ for inputId, class "block text-sm font-medium text-gray-700" ] [ text "Layout name" ]
                    , div [ class "mt-1" ]
                        [ input [ type_ "text", name inputId, id inputId, value model.name, onInput (LEdit >> LayoutMsg), autofocus True, css [ "shadow-sm block w-full border-gray-300 rounded-md", focus [ "ring-indigo-500 border-indigo-500" ], sm [ "text-sm" ] ] ] []
                        ]
                    , p [ class "mt-1 text-sm text-gray-500" ]
                        [ text "Do you like Azimutt ? Consider "
                        , sendTweet Conf.constants.cheeringTweet [ tabindex -1, class "link" ] [ text "sending us a tweet" ]
                        , text ", it will help "
                        , bText "keep our motivation high"
                        , text " 🥰"
                        ]
                    ]
                ]
            ]
        , div [ class "px-6 py-3 mt-6 flex items-center flex-row-reverse bg-gray-50" ]
            [ Button.primary3 Tw.primary [ onClick (model.name |> LCreate |> LayoutMsg |> ModalClose), css [ "w-full text-base", sm [ "ml-3 w-auto text-sm" ] ] ] [ text "Save layout" ]
            , Button.white3 Tw.gray [ onClick (LCancel |> LayoutMsg |> ModalClose), css [ "mt-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text "Cancel" ]
            ]
        ]
