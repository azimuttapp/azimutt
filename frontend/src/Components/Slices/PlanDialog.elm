module Components.Slices.PlanDialog exposing (ColorsModel, ColorsMsg(..), DocState, SharedDocState, analysisResults, analysisWarning, colorsInit, colorsModalBody, colorsUpdate, doc, docInit, layoutTablesModalBody, layoutsModalBody, layoutsWarning, privateLinkWarning, projectsModalBody, sqlExportWarning)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon)
import Components.Atoms.Link as Link
import Components.Molecules.Alert as Alert
import Conf
import ElmBook
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, a, blockquote, button, div, h3, input, label, p, span, text)
import Html.Attributes exposing (class, for, href, id, name, placeholder, rel, style, target, title, type_, value)
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
import Models.Feature as Feature
import Models.Organization as Organization exposing (Organization)
import Models.OrganizationId as OrganizationId exposing (OrganizationId)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)
import Models.ProjectRef as ProjectRef exposing (ProjectRef)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import Services.Backend as Backend exposing (TableColorTweet)
import Services.Lenses exposing (setColors, setResult)


draftProjectWarning : Html msg
draftProjectWarning =
    warning Tw.indigo
        "Oh no! You are limited by your draft project 😕"
        [ p [] [ text "As your project is ", bText "still in draft", text ", you have free plan limitations." ]
        , p [] [ text "Save it to an organization with a ", bText "paid plan", text " to unlock them." ]
        , p [] [ text "Subscribing to Azimutt paid plans will unlock more power, ", extLink "/pricing" [ class "link" ] [ text "check it out" ], text "." ]
        ]
        []


draftProjectModalBody : msg -> HtmlId -> Html msg
draftProjectModalBody close titleId =
    modalBody Tw.indigo
        Icon.CubeTransparent
        ( titleId, "Oh no! You are limited by your draft project 😕" )
        [ p [ class "text-sm text-gray-500" ] [ text "As your project is ", bText "still in draft", text ", you have free plan limitations." ]
        , p [ class "text-sm text-gray-500" ] [ text "Save it to an organization with a ", bText "paid plan", text " to unlock them." ]
        , p [ class "text-sm text-gray-500" ] [ text "Subscribing to Azimutt paid plan will unlock more power, ", extLink "/pricing" [ class "link" ] [ text "check it out" ], text "." ]
        ]
        [ Button.white3 Tw.gray [ onClick close, css [ "mt-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text "Close" ]
        ]


projectsModalBody : ProjectRef -> msg -> HtmlId -> Html msg
projectsModalBody project close titleId =
    let
        ( color, limit ) =
            ( Tw.teal, project.organization |> Maybe.andThen (.plan >> .projects) |> Maybe.withDefault Feature.projects.default )
    in
    showModalBody ( project, close, color )
        Icon.Collection
        ( titleId, "Projects" )
        [ p [ class "text-sm text-gray-500" ] [ bText ("Oh! Free plans are limited to " ++ String.pluralize "project" limit ++ ".") ]
        , p [ class "text-sm text-gray-500" ] [ text "We are making Azimutt free for exploration but heavy use of it needs to also contribute to its development in order to make it sustainable." ]
        , p [ class "text-sm text-gray-500" ] [ text "Please consider subscribing to a paid plan to contribute to it and unlock all the features!" ]
        ]
        [ Link.primary3 color [ href (Backend.organizationBillingUrl (project.organization |> Maybe.map .id) Feature.projects.name), target "_blank", rel "noopener", css [ "w-full text-base", sm [ "ml-3 w-auto text-sm" ] ] ] [ Icon.solid Icon.Sun "mr-1", text "Start trial" ]
        , Button.white3 Tw.gray [ onClick close, css [ "mt-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text "Cancel" ]
        ]


layoutsWarning : ProjectRef -> Html msg
layoutsWarning project =
    let
        color : Color
        color =
            Tw.rose
    in
    -- don't use `showWarning` to avoid the "draft project" state as it's not blocking
    warning color
        "You've reached a plan limit!"
        [ p [] [ text "Hey! We are very happy you use and like layouts in Azimutt." ]
        , p [] [ text "They are an important feature but also a limited one. You've reached the limits of your current plan and will need to upgrade. We will let you create one last layout so you can keep working but ", bText "please upgrade as soon as possible", text "." ]
        ]
        [ Link.secondary3 color [ href (Backend.organizationBillingUrl (project.organization |> Maybe.map .id) (Feature.projectLayouts.name ++ "_warning")), target "_blank", rel "noopener" ] [ Icon.outline Icon.Sparkles "mr-1", text "Start trial" ] ]


layoutsModalBody : ProjectRef -> msg -> HtmlId -> Html msg
layoutsModalBody project close titleId =
    let
        color : Color
        color =
            Tw.rose
    in
    showModalBody ( project, close, color )
        Icon.Template
        ( titleId, "New layout" )
        [ p [ class "text-sm text-gray-500" ] [ text "Hey! It's so great to see people using Azimutt and we are quite proud to make this tool for you. It's already great but we have so much more to do to make it at full potential, we need your support to make it grow and help more and more people." ]
        , p [ class "text-sm text-gray-500" ] [ text "That's why we created a paid plan. Please consider your contribution to this awesome Azimutt community, it will ", bText "bring us much further together", text "." ]
        ]
        [ Link.primary3 color [ href (Backend.organizationBillingUrl (project.organization |> Maybe.map .id) Feature.projectLayouts.name), target "_blank", rel "noopener", css [ "w-full text-base", sm [ "ml-3 w-auto text-sm" ] ] ] [ Icon.solid Icon.Sparkles "mr-1", text "Start trial" ]
        , Button.white3 Tw.gray [ onClick close, css [ "mt-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text "Cancel" ]
        ]


layoutTablesModalBody : ProjectRef -> msg -> HtmlId -> Html msg
layoutTablesModalBody project close titleId =
    let
        ( color, limit ) =
            ( Tw.sky, project.organization |> Maybe.andThen (.plan >> .layoutTables) |> Maybe.withDefault Feature.layoutTables.default )
    in
    showModalBody ( project, close, color )
        Icon.Calculator
        ( titleId, "Tables in layout" )
        [ p [ class "text-sm text-gray-500" ] [ bText ("Ooops, you just hit a plan limit, you can only add " ++ String.pluralize "table" limit ++ " per layout!") ]
        , p [ class "text-sm text-gray-500" ] [ text "We hope you like experimenting with Azimutt but, as you know, we have to make it sustainable to continue its long term development." ]
        , p [ class "text-sm text-gray-500" ] [ text "Please consider subscribing to a paid plan to contribute to it and unlock more features!" ]
        ]
        [ Link.primary3 color [ href (Backend.organizationBillingUrl (project.organization |> Maybe.map .id) Feature.layoutTables.name), target "_blank", rel "noopener", css [ "w-full text-base", sm [ "ml-3 w-auto text-sm" ] ] ] [ Icon.solid Icon.CheckCircle "mr-1", text "Start trial" ]
        , Button.white3 Tw.gray [ onClick close, css [ "mt-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text "Cancel" ]
        ]


type alias ColorsModel =
    { tweetOpen : Bool, tweetUrl : String, result : Maybe (Result ErrorMessage TweetText) }


type ColorsMsg
    = ToggleTweet
    | UpdateTweetUrl String
    | GetTableColorTweet (Maybe OrganizationId) TweetUrl
    | GotTableColorTweet (Result Backend.Error TableColorTweet)
    | EnableTableChangeColor


colorsInit : ColorsModel
colorsInit =
    { tweetOpen = False, tweetUrl = "", result = Nothing }


colorsUpdate : (ColorsModel -> ColorsMsg -> msg) -> ColorsMsg -> ColorsModel -> ( ColorsModel, Extra msg )
colorsUpdate update msg model =
    let
        wrap : ColorsMsg -> msg
        wrap =
            update model
    in
    case msg of
        ToggleTweet ->
            ( { model | tweetOpen = not model.tweetOpen }, Extra.none )

        UpdateTweetUrl value ->
            ( { model | tweetUrl = value }, Extra.none )

        GetTableColorTweet idM url ->
            if url == "" then
                ( { model | result = Nothing }, Extra.none )

            else
                ( { model | result = Nothing }, Backend.getTableColorTweet (idM |> Maybe.withDefault OrganizationId.zero) url (GotTableColorTweet >> wrap) |> Extra.cmd )

        GotTableColorTweet res ->
            let
                result : Result ErrorMessage TweetText
                result =
                    res |> Result.mapError Backend.errorToString |> Result.andThen colorsTweetResult
            in
            ( { model | result = Just result }, result |> Result.map (\_ -> EnableTableChangeColor |> wrap) |> Extra.msgR )

        EnableTableChangeColor ->
            -- never called, should be intercepted in the higher level to update the global model
            ( model, Extra.none )


colorsTweetResult : TableColorTweet -> Result ErrorMessage TweetText
colorsTweetResult r =
    r.errors |> Nel.fromList |> Maybe.map (Nel.join ", ") |> Maybe.toResultErr r.tweet


colorsModalBody : ProjectRef -> (ColorsModel -> ColorsMsg -> msg) -> ColorsModel -> msg -> HtmlId -> Html msg
colorsModalBody project update model close titleId =
    let
        ( wrap, color, tweetInput ) =
            ( update model, Tw.orange, "change-color-tweet" )
    in
    showModalBody ( project, close, color )
        Icon.ColorSwatch
        ( titleId, "Change colors" )
        [ p [ class "text-sm text-gray-500" ] [ bText "Oh! You found an paid feature!" ]
        , p [ class "mt-2 text-sm text-gray-500" ] [ text "I'm glad you are exploring Azimutt. We want to make it the ultimate tool to understand and analyze your database, and will bring much more in the coming months." ]
        , p [ class "text-sm text-gray-500" ] [ text "This would need a lot of resources and having a small contribution from you would be awesome. Onboard in Azimutt community, it will ", bText "bring us much further together", text "." ]
        , colorsTweetDivider wrap color
        , (model.result |> Maybe.andThen Result.toMaybe)
            |> Maybe.map (\_ -> colorsTweetSuccess close)
            |> Maybe.withDefault
                (if model.tweetOpen then
                    div []
                        [ colorsTweetInput wrap (project.organization |> Maybe.map .id) tweetInput model.tweetUrl color
                        , (model.result |> Maybe.andThen Result.toError)
                            |> Maybe.map (\err -> p [ id (tweetInput ++ "-description"), class "mt-2 h-10 text-sm text-red-600" ] [ text err ])
                            |> Maybe.withDefault (p [ id (tweetInput ++ "-description"), class "mt-2 h-10 text-sm text-gray-500" ] [ text "Your tweet has to be published within the last 10 minutes, mention ", extLink Conf.constants.azimuttTwitter [ class "link" ] [ text "@azimuttapp" ], text " and have a link to ", extLink Conf.constants.azimuttWebsite [ class "link" ] [ text "azimutt.app" ], text "." ])
                        , colorsTweetInspiration color
                        ]

                 else
                    div [] []
                )
        ]
        [ Link.primary3 color [ href (Backend.organizationBillingUrl (project.organization |> Maybe.map .id) Feature.colors.name), target "_blank", rel "noopener", css [ "w-full text-base", sm [ "ml-3 w-auto text-sm" ] ] ] [ Icon.solid Icon.Fire "mr-1", text "Start trial" ]
        , Button.white3 Tw.gray [ onClick close, css [ "mt-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text "Cancel" ]
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


colorsTweetInput : (ColorsMsg -> msg) -> Maybe OrganizationId -> HtmlId -> String -> Color -> Html msg
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


privateLinkWarning : ProjectRef -> Html msg
privateLinkWarning project =
    let
        color : Color
        color =
            Tw.cyan
    in
    showWarning ( project, color )
        "Private links are an enterprise feature!"
        [ p [] [ text "They hold a great power to easily share projects or embed them in documentation." ]
        , p [] [ text "And thus, we keep them fresh for users wise enough to use our best plan 😉" ]
        ]
        [ Link.secondary3 color [ href (Backend.organizationBillingUrl (project.organization |> Maybe.map .id) Feature.projectShare.name), target "_blank", rel "noopener" ] [ Icon.outline Icon.UserGroup "mr-1", text "Join us, start trial!" ] ]


sqlExportWarning : ProjectRef -> Html msg
sqlExportWarning project =
    let
        color : Color
        color =
            Tw.green
    in
    showWarning ( project, color )
        "SQL export is a paid feature!"
        [ p [] [ text "Getting a paid plan is the best support you could give to Azimutt, allowing us to invest even more to make it always better." ]
        , p [] [ text "It will unlock many features for you, check it out below. Or reach us if you have any question on ", span [ title "Azimutt" ] [ text "🧭" ] ]
        ]
        [ Link.secondary3 color [ href (Backend.organizationBillingUrl (project.organization |> Maybe.map .id) Feature.schemaExport.name), target "_blank", rel "noopener" ] [ Icon.outline Icon.TrendingUp "mr-1", text "Unleash power, start trial!" ] ]


analysisWarning : ProjectRef -> Html msg
analysisWarning project =
    let
        color : Color
        color =
            Tw.fuchsia
    in
    showWarning ( project, color )
        "Get full analysis with Team plan!"
        [ p [] [ text "Schema analysis is still an early feature but a very important one in Azimutt." ]
        , p [] [ text "It analyzes your schema to give you insights on possible improvements. In free mode you can only see limited results." ]
        , p [] [ text "Consider upgrading to access to the full analysis and support Azimutt expansion ❤️" ]
        ]
        [ Link.secondary3 color
            [ href (Backend.organizationBillingUrl (project.organization |> Maybe.map .id) Feature.analysis.name), target "_blank", rel "noopener" ]
            [ Icon.outline Icon.ShieldCheck "mr-1"
            , text "Start trial"
            ]
        ]


analysisResults : ProjectRef -> List a -> (a -> Html msg) -> Html msg
analysisResults project items render =
    if Organization.canAnalyse project || List.length items <= Feature.analysis.limit then
        div [] (items |> List.map render)

    else
        let
            color : Color
            color =
                if isDraft project then
                    Tw.indigo

                else
                    Tw.fuchsia
        in
        div [ class "relative" ]
            ((items |> List.take Feature.analysis.limit |> List.map render)
                ++ [ div [ class "absolute inset-x-0 pt-32 bg-gradient-to-t from-white text-center text-sm text-gray-500 pointer-events-none", style "bottom" "-2px" ]
                        [ text "See more with upgraded plan, "
                        , a [ href (Backend.organizationBillingUrl (project.organization |> Maybe.map .id) (Feature.analysis.name ++ "_results")), target "_blank", rel "noopener", css [ Tw.text_500 color, "underline pointer-events-auto" ] ] [ text "start trial" ]
                        , text "."
                        ]
                   ]
            )


showModalBody : ( ProjectRef, msg, Color ) -> Icon -> ( HtmlId, String ) -> List (Html msg) -> List (Html msg) -> Html msg
showModalBody ( project, close, color ) icon ( titleId, title ) content buttons =
    if isDraft project then
        draftProjectModalBody close titleId

    else
        modalBody color icon ( titleId, title ) content buttons


modalBody : Color -> Icon -> ( HtmlId, String ) -> List (Html msg) -> List (Html msg) -> Html msg
modalBody color icon ( titleId, title ) content buttons =
    div [ class "max-w-2xl" ]
        [ div [ css [ "px-6 pt-6", sm [ "flex items-start" ] ] ]
            [ div [ css [ Tw.bg_100 color, "mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full", sm [ "mx-0 h-10 w-10" ] ] ]
                [ Icon.outline icon (Tw.text_600 color)
                ]
            , div [ css [ "mt-3 text-center", sm [ "mt-0 ml-4 text-left" ] ] ]
                [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ] [ text title ]
                , div [ class "mt-3" ] content
                ]
            ]
        , div [ class "px-6 py-3 mt-6 flex items-center flex-row-reverse bg-gray-50 rounded-b-lg" ] buttons
        ]


showWarning : ( ProjectRef, Color ) -> String -> List (Html msg) -> List (Html msg) -> Html msg
showWarning ( project, color ) title content buttons =
    if isDraft project then
        draftProjectWarning

    else
        warning color title content buttons


warning : Color -> String -> List (Html msg) -> List (Html msg) -> Html msg
warning color title content buttons =
    Alert.withActions { color = color, icon = Icon.Exclamation, title = title, actions = buttons } content


isDraft : ProjectRef -> Bool
isDraft project =
    project.id |> Maybe.mapOrElse (\id -> id == ProjectId.zero) True



-- DOCUMENTATION


type alias SharedDocState x =
    { x | planDialogDocState : DocState }


type alias DocState =
    { colors : ColorsModel }


docInit : DocState
docInit =
    { colors = colorsInit }


type DocMsg
    = ColorsMsg ColorsModel ColorsMsg


updateDocState : DocMsg -> ElmBook.Msg (SharedDocState x)
updateDocState msg =
    case msg of
        ColorsMsg model message ->
            Actions.updateState (\s -> { s | planDialogDocState = s.planDialogDocState |> setColors (colorsUpdate docColorsUpdate message model |> Tuple.first) })


docProjectRef : ProjectRef
docProjectRef =
    ProjectRef.one


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "PlanDialog"
        |> Chapter.renderStatefulComponentList
            [ ( "draftProjectWarning", \_ -> draftProjectWarning )
            , ( "draftProjectModalBody", \_ -> draftProjectModalBody docClose docTitleId )
            , ( "projectsModalBody", \_ -> projectsModalBody docProjectRef docClose docTitleId )
            , ( "layoutsWarning", \_ -> layoutsWarning docProjectRef )
            , ( "layoutsModalBody", \_ -> layoutsModalBody docProjectRef docClose docTitleId )
            , ( "layoutTablesModalBody", \_ -> layoutTablesModalBody docProjectRef docClose docTitleId )
            , ( "colorsModalBody", \s -> colorsModalBody docProjectRef docColorsUpdate s.planDialogDocState.colors docClose docTitleId )
            , ( "colorsModalBody success", \s -> colorsModalBody docProjectRef docColorsUpdate (s.planDialogDocState.colors |> setResult (Just (Ok "Tweet.."))) docClose docTitleId )
            , ( "privateLinkWarning", \_ -> privateLinkWarning docProjectRef )
            , ( "sqlExportWarning", \_ -> sqlExportWarning docProjectRef )
            , ( "analysisWarning", \_ -> analysisWarning docProjectRef )
            , ( "analysisResults", \_ -> analysisResults docProjectRef [ 1, 2, 3, 4, 5, 6 ] (\i -> p [] [ text ("Item " ++ String.fromInt i) ]) )
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
