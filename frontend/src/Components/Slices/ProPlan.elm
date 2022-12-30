module Components.Slices.ProPlan exposing (analysisResults, analysisWarning, colorsModalBody, doc, layoutsModalBody, layoutsWarning, memosModalBody)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon
import Components.Atoms.Link as Link
import Components.Molecules.Alert as Alert
import Conf
import ElmBook
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, a, div, h3, p, text)
import Html.Attributes exposing (class, href, id, rel, style, target)
import Html.Events exposing (onClick)
import Libs.Html exposing (bText)
import Libs.Html.Attributes exposing (css)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Libs.Tailwind as Tw exposing (sm)
import Models.Organization as Organization exposing (Organization)
import Services.Backend as Backend


layoutsWarning : Organization -> Html msg
layoutsWarning organization =
    Alert.withActions
        { color = Tw.red
        , icon = Icon.Exclamation
        , title = "You've reached plan limit!"
        , actions = [ Link.secondary3 Tw.red [ href (Backend.organizationBillingUrl organization.id "new-layout-warning"), target "_blank", rel "noopener" ] [ Icon.outline Icon.Sparkles "mr-1", text "Upgrade plan" ] ]
        }
        [ p [] [ text "Hey! We are very happy you use and like layouts in Azimutt." ]
        , p [] [ text "They are an important feature but also a limited one. You've reached the limits of your current plan and will need to upgrade. We will let you create one last layout so you can keep working but ", bText "please upgrade as soon as possible", text "." ]
        ]


layoutsModalBody : Organization -> msg -> HtmlId -> Html msg
layoutsModalBody organization close titleId =
    div [ class "max-w-2xl" ]
        [ div [ css [ "px-6 pt-6", sm [ "flex items-start" ] ] ]
            [ div [ css [ "mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-rose-100", sm [ "mx-0 h-10 w-10" ] ] ]
                [ Icon.outline Icon.Template "text-rose-600"
                ]
            , div [ css [ "mt-3 text-center", sm [ "mt-0 ml-4 text-left" ] ] ]
                [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ] [ text "New layout" ]
                , div [ class "mt-3" ]
                    [ p [ class "text-sm text-gray-500" ] [ text "Hey! It's so great to see people using Azimutt and we are quite proud to make this tool for you. It's already great but we have so much more to do to make it at full potential, we need your support to make it grow and help more and more people." ]
                    , p [ class "text-sm text-gray-500" ] [ text "That's why we created a paid plan. Please consider your contribution to this awesome Azimutt community, it will ", bText "bring us much further together", text "." ]
                    ]
                ]
            ]
        , div [ class "px-6 py-3 mt-6 flex items-center flex-row-reverse bg-gray-50 rounded-b-lg" ]
            [ Link.primary3 Tw.rose [ href (Backend.organizationBillingUrl organization.id "new-layout-limit"), target "_blank", rel "noopener", css [ "w-full text-base", sm [ "ml-3 w-auto text-sm" ] ] ] [ Icon.solid Icon.Sparkles "mr-1", text "Upgrade plan" ]
            , Button.white3 Tw.gray [ onClick close, css [ "mt-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text "Cancel" ]
            ]
        ]


memosModalBody : Organization -> msg -> HtmlId -> Html msg
memosModalBody organization close titleId =
    let
        limit : Int
        limit =
            organization.plan.memos |> Maybe.withDefault Conf.constants.freePlanMemos
    in
    div [ class "max-w-2xl" ]
        [ div [ css [ "px-6 pt-6", sm [ "flex items-start" ] ] ]
            [ div [ css [ "mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-amber-100", sm [ "mx-0 h-10 w-10" ] ] ]
                [ Icon.outline Icon.Newspaper "text-amber-600"
                ]
            , div [ css [ "mt-3 text-center", sm [ "mt-0 ml-4 text-left" ] ] ]
                [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ] [ text "Layout memos" ]
                , div [ class "mt-3" ]
                    [ p [ class "text-sm text-gray-500" ] [ bText ("You just hit a plan limit, you are limited to " ++ String.pluralize "memo" limit ++ " per layout!") ]
                    , p [ class "mt-2 text-sm text-gray-500" ] [ text "I'm a huge fan of memos and it seems you too. They are awesome for documentation, quick notes or even branding as you can write any markdown, including links and images." ]
                    , p [ class "text-sm text-gray-500" ] [ text "We see this as a long term feature to document database schema so it's reserved for pro accounts. ", bText "Consider subscribing", text " or reach at us to bring Azimutt one step further." ]
                    ]
                ]
            ]
        , div [ class "px-6 py-3 mt-6 flex items-center flex-row-reverse bg-gray-50 rounded-b-lg" ]
            [ Link.primary3 Tw.amber [ href (Backend.organizationBillingUrl organization.id "new-memo-limit"), target "_blank", rel "noopener", css [ "w-full text-base", sm [ "ml-3 w-auto text-sm" ] ] ] [ Icon.solid Icon.ThumbUp "mr-1", text "Upgrade plan" ]
            , Button.white3 Tw.gray [ onClick close, css [ "mt-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text "Cancel" ]
            ]
        ]


colorsModalBody : Organization -> msg -> HtmlId -> Html msg
colorsModalBody organization close titleId =
    div [ class "max-w-2xl" ]
        [ div [ css [ "px-6 pt-6", sm [ "flex items-start" ] ] ]
            [ div [ css [ "mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-orange-100", sm [ "mx-0 h-10 w-10" ] ] ]
                [ Icon.outline Icon.ColorSwatch "text-orange-600"
                ]
            , div [ css [ "mt-3 text-center", sm [ "mt-0 ml-4 text-left" ] ] ]
                [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ] [ text "Change colors" ]
                , div [ class "mt-3" ]
                    [ p [ class "text-sm text-gray-500" ] [ bText "Oh! You found a Pro feature!" ]
                    , p [ class "mt-2 text-sm text-gray-500" ] [ text "I'm glad you are exploring Azimutt. We want to make it the ultimate tool to understand and analyze your database, and will bring much more in the coming months." ]
                    , p [ class "text-sm text-gray-500" ] [ text "This would need a lot of resources and having a small contribution from you would be awesome. Please onboard in Azimutt community, it will ", bText "bring us much further together", text "." ]
                    ]
                ]
            ]
        , div [ class "px-6 py-3 mt-6 flex items-center flex-row-reverse bg-gray-50 rounded-b-lg" ]
            [ Link.primary3 Tw.orange [ href (Backend.organizationBillingUrl organization.id "color-change"), target "_blank", rel "noopener", css [ "w-full text-base", sm [ "ml-3 w-auto text-sm" ] ] ] [ Icon.solid Icon.Fire "mr-1", text "Upgrade plan" ]
            , Button.white3 Tw.gray [ onClick close, css [ "mt-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text "Cancel" ]
            ]
        ]


analysisWarning : Organization -> Html msg
analysisWarning organization =
    Alert.withActions
        { color = Tw.fuchsia
        , icon = Icon.Exclamation
        , title = "Get full analysis with Pro plan!"
        , actions =
            [ Link.secondary3 Tw.fuchsia
                [ href (Backend.organizationBillingUrl organization.id "analysis-alert"), target "_blank", rel "noopener" ]
                [ Icon.outline Icon.ShieldCheck "mr-1"
                , text "Upgrade plan"
                ]
            ]
        }
        [ p [] [ text "Schema analysis is still an early feature but a very important one in Azimutt." ]
        , p [] [ text "It analyzes your schema to give you insights on possible improvements. In free mode you can only see limited results." ]
        , p [] [ text "Consider upgrading to access to the full analysis and support Azimutt expansion ❤️" ]
        ]


analysisResults : Organization -> List a -> (a -> Html msg) -> Html msg
analysisResults organization items render =
    if organization.plan.dbAnalysis || List.length items <= 5 then
        div [] (items |> List.map render)

    else
        div [ class "relative" ]
            ((items |> List.take 5 |> List.map render)
                ++ [ div [ class "absolute inset-x-0 pt-32 bg-gradient-to-t from-white text-center text-sm text-gray-500 pointer-events-none", style "bottom" "-2px" ]
                        [ text "See more with "
                        , a [ href (Backend.organizationBillingUrl organization.id "analysis-results"), target "_blank", rel "noopener", class "underline text-fuchsia-500 pointer-events-auto" ] [ text "upgraded plan" ]
                        , text "."
                        ]
                   ]
            )



-- DOCUMENTATION


sampleCancel : ElmBook.Msg state
sampleCancel =
    Actions.logAction "onCancel"


sampleTitleId : String
sampleTitleId =
    "modal-id-title"


doc : Chapter x
doc =
    Chapter.chapter "ProPlan"
        |> Chapter.renderComponentList
            [ ( "layoutsWarning", layoutsWarning Organization.zero )
            , ( "layoutsModalBody", layoutsModalBody Organization.zero sampleCancel sampleTitleId )
            , ( "memosModalBody", memosModalBody Organization.zero sampleCancel sampleTitleId )
            , ( "colorsModalBody", colorsModalBody Organization.zero sampleCancel sampleTitleId )
            , ( "analysisWarning", analysisWarning Organization.zero )
            , ( "analysisResults", analysisResults Organization.zero [ 1, 2, 3, 4, 5, 6 ] (\i -> p [] [ text ("Item " ++ String.fromInt i) ]) )
            ]
