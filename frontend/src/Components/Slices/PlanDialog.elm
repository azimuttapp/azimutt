module Components.Slices.PlanDialog exposing (ColorsModel, ColorsMsg(..), DocState, SharedDocState, aiDisabledAlert, amlDisabledAlert, amlWriteError, analysisResults, analysisWarning, colorsInit, colorsModalBody, colorsUpdate, doc, docInit, layoutTablesModalBody, layoutsModalBody, layoutsWarning, privateLinkWarning, projectExportWarning, projectsNoSaveAlert, projectsTooManyAlert, schemaExportWarning)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon)
import Components.Atoms.Link as Link
import Components.Molecules.Alert as Alert
import Conf
import ElmBook
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, blockquote, br, button, div, h3, input, label, p, span, text)
import Html.Attributes exposing (class, for, href, id, name, placeholder, rel, style, target, title, type_, value)
import Html.Events exposing (onBlur, onClick, onInput)
import Libs.Html exposing (bText, extLink, sendTweet)
import Libs.Html.Attributes exposing (ariaDescribedby, ariaHidden, css)
import Libs.Maybe as Maybe
import Libs.Models exposing (ErrorMessage, TweetText, TweetUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Nel as Nel
import Libs.Result as Result
import Libs.String as String exposing (pluralize)
import Libs.Tailwind as Tw exposing (Color, focus, sm)
import Models.Feature as Feature
import Models.Organization as Organization exposing (Organization)
import Models.OrganizationId as OrganizationId exposing (OrganizationId)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)
import Models.ProjectRef as ProjectRef exposing (ProjectRef)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import Services.Backend as Backend exposing (TableColorTweet)
import Services.Lenses exposing (setColors, setResult)
import Services.Urls as Urls


projectsNoSaveAlert : Organization -> Html msg
projectsNoSaveAlert organization =
    let
        ( color, feature ) =
            ( Tw.yellow, Feature.projects )
    in
    Alert.withDescription { color = color, icon = Icon.Exclamation, title = "Can't save project" }
        [ text ("You " ++ organization.plan.name ++ " plan can't save projects (see ")
        , extLink Urls.pricing [ class "link" ] [ text "pricing" ]
        , text "). "
        , br [] []
        , text "Please "
        , extLink (Backend.organizationBillingUrl (Just organization.id) ("feature_" ++ feature.name)) [ class "link" ] [ text "upgrade" ]
        , text " to save."
        ]


projectsTooManyAlert : Organization -> Int -> Html msg
projectsTooManyAlert organization savedProjects =
    let
        ( color, feature ) =
            ( Tw.yellow, Feature.projects )
    in
    Alert.withDescription { color = color, icon = Icon.Exclamation, title = "Can't save project" }
        [ text ("You already saved the " ++ (savedProjects |> pluralize "allowed project") ++ " in your plan.")
        , br [] []
        , text "You need "
        , extLink (Backend.organizationBillingUrl (Just organization.id) ("feature_" ++ feature.name)) [ class "link" ] [ text "to upgrade" ]
        , text " for more."
        ]


amlDisabledAlert : ProjectRef -> Html msg
amlDisabledAlert project =
    let
        ( color, feature ) =
            ( Tw.yellow, Feature.aml )
    in
    warning color
        ("Database design not available in " ++ planName project)
        [ p [] [ text "Azimutt allows database design with a ", extLink Urls.amlHome [ class "link" ] [ text "very simple DSL" ], text " called AML, here is how it looks:" ]
        , p [ class ("whitespace-pre font-mono " ++ Tw.bg_200 color ++ " p-2 my-3 rounded shadow") ]
            [ text "users\n  id uuid pk\n  name varchar\n  email varchar unique\n  created_at timestamp index\n\n"
            , text "posts\n  id uuid pk\n  title varchar index\n  status post_status(draft, published)\n  content text nullable\n  created_at timestamp index\n  created_by uuid fk users.id"
            ]
        ]
        [ subscribeButtonSecondary project color feature Icon.Puzzle "Do some magic" ]


amlWriteError : ProjectRef -> String
amlWriteError project =
    "AML is limited to "
        ++ (project.organization |> Maybe.andThen (.plan >> .aml) |> Maybe.withDefault Feature.aml.default |> String.fromInt)
        ++ " tables in "
        ++ planName project
        ++ ", use Solo free trial to continue"


aiDisabledAlert : ProjectRef -> Html msg
aiDisabledAlert project =
    let
        ( color, feature ) =
            ( Tw.purple, Feature.ai )
    in
    warning color
        ("AI not available in " ++ planName project)
        [ p [] [ text "AI features are available in the Team plan.", br [] [], text "You can generate a SQL query based on your database schema." ]
        ]
        [ subscribeButtonSecondary project color feature Icon.Sparkles "Boost your productivity" ]


layoutsWarning : ProjectRef -> Html msg
layoutsWarning project =
    let
        ( color, feature ) =
            ( Tw.rose, Feature.projectLayouts )
    in
    warning color
        "You've reached a plan limit!"
        [ p [] [ text "Hey! We are very happy you use and like layouts in Azimutt." ]
        , p [] [ text "They are an important feature but also a limited one. You've reached the limits of your current plan and will need to upgrade." ]
        , p [] [ text "We let you create one last layout so you can keep working but ", bText "please upgrade as soon as possible", text "." ]
        ]
        [ subscribeButtonSecondary project color feature Icon.Sparkles "More layouts" ]


layoutsModalBody : ProjectRef -> msg -> HtmlId -> Html msg
layoutsModalBody project close titleId =
    let
        ( color, feature ) =
            ( Tw.rose, Feature.projectLayouts )
    in
    modalBody color
        Icon.Template
        ( titleId, "New layout" )
        [ p [ class "text-sm text-gray-500" ] [ text "Hey! It's so great to see people using Azimutt and we are quite proud to make this tool for you. It's already great but we have so much more to do to make it at full potential, we need your support to make it grow and help more and more people." ]
        , p [ class "text-sm text-gray-500" ] [ text "That's why we created a paid plan. Please consider your contribution to this awesome Azimutt community, it will ", bText "bring us much further together", text "." ]
        ]
        [ subscribeButtonPrimary project color feature Icon.Sparkles "More layouts"
        , Button.white3 Tw.gray [ onClick close, css [ "mt-3 mr-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text "Cancel" ]
        ]


layoutTablesModalBody : ProjectRef -> msg -> HtmlId -> Html msg
layoutTablesModalBody project close titleId =
    let
        ( color, feature ) =
            ( Tw.sky, Feature.layoutTables )

        limit : Int
        limit =
            project.organization |> Maybe.andThen (.plan >> .layoutTables) |> Maybe.withDefault feature.default
    in
    modalBody color
        Icon.Calculator
        ( titleId, "Tables in layout" )
        [ p [ class "text-sm text-gray-500" ] [ bText ("Ooops, you just hit a plan limit, you can only add " ++ String.pluralize "table" limit ++ " per layout!") ]
        , p [ class "text-sm text-gray-500" ] [ text "We hope you like experimenting with Azimutt but, as you know, we have to make it sustainable to continue its long term development." ]
        , p [ class "text-sm text-gray-500" ] [ text "Please consider subscribing to a paid plan to contribute to it and unlock more features!" ]
        ]
        [ subscribeButtonPrimary project color feature Icon.CheckCircle "Expand your view"
        , Button.white3 Tw.gray [ onClick close, css [ "mt-3 mr-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text "Cancel" ]
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
        ( ( color, feature ), ( wrap, tweetInput ) ) =
            ( ( Tw.orange, Feature.colors ), ( update model, "change-color-tweet" ) )
    in
    modalBody color
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
        [ subscribeButtonPrimary project color feature Icon.Fire "Have style"
        , Button.white3 Tw.gray [ onClick close, css [ "mt-3 mr-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text "Cancel" ]
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
        ( color, feature ) =
            ( Tw.cyan, Feature.projectShare )
    in
    warning color
        "Private links are an enterprise feature!"
        [ p [] [ text "They hold a great power to easily share projects or embed them in documentation." ]
        , p [] [ text "And thus, we keep them fresh for users wise enough to use our best plan 😉" ]
        ]
        [ subscribeButtonSecondary project color feature Icon.UserGroup "Join us" ]


schemaExportWarning : ProjectRef -> Html msg
schemaExportWarning project =
    let
        ( color, feature ) =
            ( Tw.green, Feature.schemaExport )
    in
    warning color
        "SQL export is a paid feature!"
        [ p [] [ text "Getting a paid plan is the best support you could give to Azimutt, allowing us to invest even more to make it always better." ]
        , p [] [ text "It will unlock many features for you, check it out below. Or reach us if you have any question on ", span [ title "Azimutt" ] [ text "🧭" ] ]
        ]
        [ subscribeButtonSecondary project color feature Icon.TrendingUp "Unleash power" ]


projectExportWarning : ProjectRef -> Html msg
projectExportWarning project =
    let
        ( color, feature ) =
            ( Tw.pink, Feature.projectExport )
    in
    warning color
        ("Project export is not available on " ++ planName project ++ " 😕")
        [ p [] [ text "You need to upgrade to Team plan to unlock it, but you will have 2 weeks of trial 😊" ]
        , p [] [ text "You will also unlock many other features. Reach us if you have any question on Azimutt." ]
        ]
        [ subscribeButtonSecondary project color feature Icon.Download "Unlock it" ]


analysisWarning : ProjectRef -> Html msg
analysisWarning project =
    let
        ( color, feature ) =
            ( Tw.fuchsia, Feature.analysis )
    in
    warning color
        "Get full analysis with Team plan!"
        [ p [] [ text "Schema analysis is still an early feature but a very important one in Azimutt." ]
        , p [] [ text "It analyzes your schema to give you insights on possible improvements. In free mode you can only see limited results." ]
        , p [] [ text "Consider upgrading to access to the full analysis and support Azimutt expansion ❤️" ]
        ]
        [ subscribeButtonSecondary project color feature Icon.ShieldCheck "level up" ]


analysisResults : ProjectRef -> List a -> (a -> Html msg) -> Html msg
analysisResults project items render =
    let
        ( color, feature ) =
            ( if isDraft project then
                Tw.indigo

              else
                Tw.fuchsia
            , Feature.analysis
            )
    in
    if Organization.canAnalyse project || List.length items <= feature.limit then
        div [] (items |> List.map render)

    else
        div [ class "relative" ]
            ((items |> List.take feature.limit |> List.map render)
                ++ [ div [ class "absolute inset-x-0 pt-32 bg-gradient-to-t from-white text-center text-sm text-gray-500 pointer-events-none", style "bottom" "-2px" ]
                        [ text "See more with upgraded plan, "
                        , extLink (Backend.organizationBillingUrl (project.organization |> Maybe.map .id) ("feature_" ++ feature.name ++ "_results")) [ css [ Tw.text_500 color, "underline pointer-events-auto" ] ] [ text "start trial" ]
                        , text "."
                        ]
                   ]
            )


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


warning : Color -> String -> List (Html msg) -> List (Html msg) -> Html msg
warning color title content buttons =
    Alert.withActions { color = color, icon = Icon.Exclamation, title = title, actions = buttons } content


isDraft : ProjectRef -> Bool
isDraft project =
    project.id |> Maybe.mapOrElse (\id -> id == ProjectId.zero) True


planName : ProjectRef -> String
planName project =
    (project.organization |> Maybe.mapOrElse (.plan >> .name) "free") ++ " plan"


subscribeButtonPrimary : ProjectRef -> Color -> { f | name : String } -> Icon -> String -> Html msg
subscribeButtonPrimary project color feature icon action =
    Link.primary3 color
        [ href (Backend.organizationBillingUrl (project.organization |> Maybe.map .id) ("feature_" ++ feature.name)), target "_blank", rel "noopener" ]
        [ Icon.solid icon "mr-1"
        , text
            (if action == "" then
                "Start trial!"

             else
                action ++ ", start trial!"
            )
        ]


subscribeButtonSecondary : ProjectRef -> Color -> { f | name : String } -> Icon -> String -> Html msg
subscribeButtonSecondary project color feature icon action =
    Link.secondary3 color
        [ href (Backend.organizationBillingUrl (project.organization |> Maybe.map .id) ("feature_" ++ feature.name)), target "_blank", rel "noopener" ]
        [ Icon.outline icon "mr-1"
        , text
            (if action == "" then
                "Start trial!"

             else
                action ++ ", start trial!"
            )
        ]



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
            [ ( "layoutsWarning", \_ -> layoutsWarning docProjectRef )
            , ( "layoutsModalBody", \_ -> layoutsModalBody docProjectRef docClose docTitleId )
            , ( "layoutTablesModalBody", \_ -> layoutTablesModalBody docProjectRef docClose docTitleId )
            , ( "colorsModalBody", \s -> colorsModalBody docProjectRef docColorsUpdate s.planDialogDocState.colors docClose docTitleId )
            , ( "colorsModalBody success", \s -> colorsModalBody docProjectRef docColorsUpdate (s.planDialogDocState.colors |> setResult (Just (Ok "Tweet.."))) docClose docTitleId )
            , ( "privateLinkWarning", \_ -> privateLinkWarning docProjectRef )
            , ( "schemaExportWarning", \_ -> schemaExportWarning docProjectRef )
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
