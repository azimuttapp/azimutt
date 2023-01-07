module Components.Slices.ProPlan exposing (ColorsModel, ColorsMsg(..), DocState, SharedDocState, analysisResults, analysisWarning, colorsInit, colorsModalBody, colorsUpdate, doc, initDocState, layoutsModalBody, layoutsWarning, memosModalBody)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon
import Components.Atoms.Link as Link
import Components.Molecules.Alert as Alert
import Conf
import ElmBook
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, a, blockquote, button, div, h3, input, label, p, text)
import Html.Attributes exposing (class, for, href, id, name, placeholder, rel, style, target, type_, value)
import Html.Events exposing (onBlur, onClick, onInput)
import Libs.Html exposing (bText, extLink, sendTweet)
import Libs.Html.Attributes exposing (ariaDescribedby, ariaHidden, css)
import Libs.Maybe as Maybe
import Libs.Models exposing (ErrorMessage, TweetText, TweetUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Nel as Nel
import Libs.Result as Result
import Libs.String as String
import Libs.Tailwind as Tw exposing (Color, focus, sm)
import Libs.Task as T
import Models.Organization as Organization exposing (Organization)
import Models.OrganizationId exposing (OrganizationId)
import Services.Backend as Backend exposing (TableColorTweet)
import Services.Lenses exposing (setColors, setResult)


layoutsWarning : Organization -> Html msg
layoutsWarning organization =
    Alert.withActions
        { color = Tw.red
        , icon = Icon.Exclamation
        , title = "You've reached plan limit!"
        , actions = [ Link.secondary3 Tw.red [ href (Backend.organizationBillingUrl organization.id (Conf.features.layouts.name ++ "_warning")), target "_blank", rel "noopener" ] [ Icon.outline Icon.Sparkles "mr-1", text "Upgrade plan" ] ]
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
            [ Link.primary3 Tw.rose [ href (Backend.organizationBillingUrl organization.id Conf.features.layouts.name), target "_blank", rel "noopener", css [ "w-full text-base", sm [ "ml-3 w-auto text-sm" ] ] ] [ Icon.solid Icon.Sparkles "mr-1", text "Upgrade plan" ]
            , Button.white3 Tw.gray [ onClick close, css [ "mt-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text "Cancel" ]
            ]
        ]


memosModalBody : Organization -> msg -> HtmlId -> Html msg
memosModalBody organization close titleId =
    let
        limit : Int
        limit =
            organization.plan.memos |> Maybe.withDefault Conf.features.memos.free
    in
    div [ class "max-w-2xl" ]
        [ div [ css [ "px-6 pt-6", sm [ "flex items-start" ] ] ]
            [ div [ css [ "mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-amber-100", sm [ "mx-0 h-10 w-10" ] ] ]
                [ Icon.outline Icon.Newspaper "text-amber-600"
                ]
            , div [ css [ "mt-3 text-center", sm [ "mt-0 ml-4 text-left" ] ] ]
                [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ] [ text "Layout memos" ]
                , div [ class "mt-3" ]
                    [ p [ class "text-sm text-gray-500" ] [ bText ("You just hit a plan limit, you have only " ++ String.pluralize "memo" limit ++ " per layout!") ]
                    , p [ class "mt-2 text-sm text-gray-500" ] [ text "I'm a huge fan of memos and it seems you too. They are awesome for documentation, quick notes or even branding as you can write any markdown, including links and images." ]
                    , p [ class "text-sm text-gray-500" ] [ text "We see this as a long term feature to document database schema so it's reserved for pro accounts. ", bText "Consider subscribing", text " or ", a [ href ("mailto:" ++ Conf.constants.azimuttEmail), target "_blank", rel "noopener", class "link" ] [ text "reach at us" ], text " to contribute improving Azimutt." ]
                    ]
                ]
            ]
        , div [ class "px-6 py-3 mt-6 flex items-center flex-row-reverse bg-gray-50 rounded-b-lg" ]
            [ Link.primary3 Tw.amber [ href (Backend.organizationBillingUrl organization.id Conf.features.memos.name), target "_blank", rel "noopener", css [ "w-full text-base", sm [ "ml-3 w-auto text-sm" ] ] ] [ Icon.solid Icon.ThumbUp "mr-1", text "Upgrade plan" ]
            , Button.white3 Tw.gray [ onClick close, css [ "mt-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text "Cancel" ]
            ]
        ]


type alias ColorsModel =
    { tweetOpen : Bool, tweetUrl : String, result : Maybe (Result ErrorMessage TweetText) }


type ColorsMsg
    = ToggleTweet
    | UpdateTweetUrl String
    | GetTableColorTweet OrganizationId TweetUrl
    | GotTableColorTweet (Result Backend.Error TableColorTweet)
    | EnableTableChangeColor


colorsInit : ColorsModel
colorsInit =
    { tweetOpen = False, tweetUrl = "", result = Nothing }


colorsUpdate : (ColorsModel -> ColorsMsg -> msg) -> ColorsMsg -> ColorsModel -> ( ColorsModel, Cmd msg )
colorsUpdate update msg model =
    let
        wrap : ColorsMsg -> msg
        wrap =
            update model
    in
    case msg of
        ToggleTweet ->
            ( { model | tweetOpen = not model.tweetOpen }, Cmd.none )

        UpdateTweetUrl value ->
            ( { model | tweetUrl = value }, Cmd.none )

        GetTableColorTweet id url ->
            if url == "" then
                ( { model | result = Nothing }, Cmd.none )

            else
                ( { model | result = Nothing }, Backend.getTableColorTweet id url (GotTableColorTweet >> wrap) )

        GotTableColorTweet res ->
            let
                result : Result ErrorMessage TweetText
                result =
                    res |> Result.mapError Backend.errorToString |> Result.andThen colorsTweetResult
            in
            ( { model | result = Just result }, result |> Result.map (\_ -> EnableTableChangeColor |> wrap |> T.send) |> Result.withDefault Cmd.none )

        EnableTableChangeColor ->
            -- never called, should be intercepted in the higher level to update the global model
            ( model, Cmd.none )


colorsTweetResult : TableColorTweet -> Result ErrorMessage TweetText
colorsTweetResult r =
    r.errors |> Nel.fromList |> Maybe.map (Nel.join ", ") |> Maybe.toResultErr r.tweet


colorsModalBody : Organization -> (ColorsModel -> ColorsMsg -> msg) -> ColorsModel -> msg -> HtmlId -> Html msg
colorsModalBody organization update model close titleId =
    let
        ( wrap, color, tweetInput ) =
            ( update model, Tw.orange, "change-color-tweet" )
    in
    div [ class "max-w-2xl" ]
        [ div [ css [ "px-6 pt-6", sm [ "flex items-start" ] ] ]
            [ div [ css [ "mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full", Tw.bg_100 color, sm [ "mx-0 h-10 w-10" ] ] ]
                [ Icon.outline Icon.ColorSwatch (Tw.text_600 color)
                ]
            , div [ css [ "mt-3 text-center", sm [ "mt-0 ml-4 text-left" ] ] ]
                [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ] [ text "Change colors" ]
                , div [ class "mt-3" ]
                    [ p [ class "text-sm text-gray-500" ] [ bText "Oh! You found a Pro feature!" ]
                    , p [ class "mt-2 text-sm text-gray-500" ] [ text "I'm glad you are exploring Azimutt. We want to make it the ultimate tool to understand and analyze your database, and will bring much more in the coming months." ]
                    , p [ class "text-sm text-gray-500" ] [ text "This would need a lot of resources and having a small contribution from you would be awesome. Onboard in Azimutt community, it will ", bText "bring us much further together", text "." ]
                    ]
                , colorsTweetDivider wrap color
                , (model.result |> Maybe.andThen Result.toMaybe)
                    |> Maybe.map (\_ -> colorsTweetSuccess close)
                    |> Maybe.withDefault
                        (if model.tweetOpen then
                            div []
                                [ colorsTweetInput wrap organization.id tweetInput model.tweetUrl color
                                , (model.result |> Maybe.andThen Result.toError)
                                    |> Maybe.map (\err -> p [ id (tweetInput ++ "-description"), class "mt-2 h-10 text-sm text-red-600" ] [ text err ])
                                    |> Maybe.withDefault (p [ id (tweetInput ++ "-description"), class "mt-2 h-10 text-sm text-gray-500" ] [ text "Your tweet has to be published within the last 10 minutes, mention ", extLink Conf.constants.azimuttTwitter [ class "link" ] [ text "@azimuttapp" ], text " and have a link to ", extLink Conf.constants.azimuttWebsite [ class "link" ] [ text "azimutt.app" ], text "." ])
                                , colorsTweetInspiration color
                                ]

                         else
                            div [] []
                        )
                ]
            ]
        , div [ class "px-6 py-3 mt-6 flex items-center flex-row-reverse bg-gray-50 rounded-b-lg" ]
            [ Link.primary3 color [ href (Backend.organizationBillingUrl organization.id Conf.features.tableColor.name), target "_blank", rel "noopener", css [ "w-full text-base", sm [ "ml-3 w-auto text-sm" ] ] ] [ Icon.solid Icon.Fire "mr-1", text "Upgrade plan" ]
            , Button.white3 Tw.gray [ onClick close, css [ "mt-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text "Cancel" ]
            ]
        ]


colorsTweetDivider : (ColorsMsg -> msg) -> Color -> Html msg
colorsTweetDivider wrap color =
    div [ class "mt-3 relative" ]
        [ div [ class "absolute inset-0 flex items-center", ariaHidden True ]
            [ div [ class "w-full border-t border-gray-300" ] []
            ]
        , div [ class "relative flex justify-center" ]
            [ button [ type_ "button", onClick (ToggleTweet |> wrap), css [ "inline-flex items-center rounded-full border border-gray-300 bg-white px-4 py-1.5 text-sm font-medium leading-5 text-gray-700 shadow-sm hover:bg-gray-50", Tw.focus_ring_500 color ] ]
                [ text "Or tweet to unlock feature"
                ]
            ]
        ]


colorsTweetInput : (ColorsMsg -> msg) -> OrganizationId -> HtmlId -> String -> Color -> Html msg
colorsTweetInput wrap organizationId inputId inputValue color =
    div []
        [ label [ for inputId, class "block text-sm font-medium text-gray-700" ] [ text "Your tweet url" ]
        , div [ class "mt-1" ]
            [ input
                [ type_ "url"
                , name inputId
                , id inputId
                , value inputValue
                , onInput (UpdateTweetUrl >> wrap)
                , onBlur (GetTableColorTweet organizationId inputValue |> wrap)
                , placeholder "ex: https://twitter.com/azimuttapp/status/1442355066636161032"
                , ariaDescribedby (inputId ++ "-description")
                , css [ "block w-full rounded-md border-gray-300 shadow-sm sm:text-sm", focus [ Tw.border_500 color, Tw.ring_500 color ] ]
                ]
                []
            ]
        ]


colorsTweetInspiration : Color -> Html msg
colorsTweetInspiration color =
    div []
        [ p [ class "mt-3 block text-sm font-medium text-gray-700" ] [ text "Some inspiration if you need:" ]
        , div []
            ([ "Hey @azimuttapp, please unlock table colors on https://azimutt.app 🙏"
             , "I'm discovering @azimuttapp to explore my database, I can recommend it: https://azimutt.app"
             , "Azimutt (@azimuttapp) is a visual database exploration tool, made for big real world databases. Try it out: https://azimutt.app"
             ]
                |> List.map
                    (\tweet ->
                        sendTweet tweet
                            []
                            [ blockquote [ class "mt-3 relative font-medium text-gray-500" ]
                                [ Icon.quote ("absolute top-0 left-0 transform -translate-x-3 -translate-y-2 " ++ Tw.text_100 color)
                                , p [ class "relative" ] [ text tweet ]
                                ]
                            ]
                    )
            )
        ]


colorsTweetSuccess : msg -> Html msg
colorsTweetSuccess close =
    div [ class "mt-3 py-12 bg-green-500 rounded shadow text-center text-white" ]
        [ Icon.solid Icon.Check "w-16 h-16 inline"
        , div [ class "text-lg font-bold" ] [ text "CHANGE TABLE COLOR ENABLED 👌" ]
        , button [ type_ "button", onClick close, class "mt-12 inline-flex items-center rounded-md border border-green-300 bg-white px-6 py-3 text-base font-medium text-green-500 shadow-sm hover:bg-green-50" ] [ text "Back to editor" ]
        ]


analysisWarning : Organization -> Html msg
analysisWarning organization =
    Alert.withActions
        { color = Tw.fuchsia
        , icon = Icon.Exclamation
        , title = "Get full analysis with Pro plan!"
        , actions =
            [ Link.secondary3 Tw.fuchsia
                [ href (Backend.organizationBillingUrl organization.id Conf.features.dbAnalysis.name), target "_blank", rel "noopener" ]
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
                        , a [ href (Backend.organizationBillingUrl organization.id (Conf.features.dbAnalysis.name ++ "_results")), target "_blank", rel "noopener", class "underline text-fuchsia-500 pointer-events-auto" ] [ text "upgraded plan" ]
                        , text "."
                        ]
                   ]
            )



-- DOCUMENTATION


type alias SharedDocState x =
    { x | proPlanDocState : DocState }


type alias DocState =
    { colors : ColorsModel }


initDocState : DocState
initDocState =
    { colors = colorsInit }


type DocMsg
    = ColorsMsg ColorsModel ColorsMsg


updateDocState : DocMsg -> ElmBook.Msg (SharedDocState x)
updateDocState msg =
    case msg of
        ColorsMsg model message ->
            Actions.updateState (\s -> { s | proPlanDocState = s.proPlanDocState |> setColors (colorsUpdate docColorsUpdate message model |> Tuple.first) })


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "ProPlan"
        |> Chapter.renderStatefulComponentList
            [ ( "layoutsWarning", \_ -> layoutsWarning Organization.zero )
            , ( "layoutsModalBody", \_ -> layoutsModalBody Organization.zero docClose docTitleId )
            , ( "memosModalBody", \_ -> memosModalBody Organization.zero docClose docTitleId )
            , ( "colorsModalBody", \s -> colorsModalBody Organization.zero docColorsUpdate s.proPlanDocState.colors docClose docTitleId )
            , ( "colorsModalBody success", \s -> colorsModalBody Organization.zero docColorsUpdate (s.proPlanDocState.colors |> setResult (Just (Ok "Tweet.."))) docClose docTitleId )
            , ( "analysisWarning", \_ -> analysisWarning Organization.zero )
            , ( "analysisResults", \_ -> analysisResults Organization.zero [ 1, 2, 3, 4, 5, 6 ] (\i -> p [] [ text ("Item " ++ String.fromInt i) ]) )
            ]


docColorsUpdate : ColorsModel -> ColorsMsg -> ElmBook.Msg (SharedDocState x)
docColorsUpdate model msg =
    ColorsMsg model msg |> updateDocState


docClose : ElmBook.Msg state
docClose =
    Actions.logAction "onClose"


docTitleId : String
docTitleId =
    "modal-id-title"
