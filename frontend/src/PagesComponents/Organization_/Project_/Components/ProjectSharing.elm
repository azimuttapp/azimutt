module PagesComponents.Organization_.Project_.Components.ProjectSharing exposing (Model, Msg(..), init, update, view)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Modal as Modal
import Conf
import Dict
import Html exposing (Html, datalist, div, h3, iframe, img, input, label, option, p, select, span, text)
import Html.Attributes exposing (attribute, class, for, height, id, list, name, placeholder, selected, src, style, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Html exposing (sendTweet)
import Libs.Html.Attributes exposing (css)
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Uuid as Uuid
import Libs.Tailwind exposing (focus, sm)
import Libs.Task as T
import Libs.Url as Url
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectStorage as ProjectStorage
import Models.ProjectToken exposing (ProjectToken)
import PagesComponents.Organization_.Project_.Models.EmbedKind as EmbedKind exposing (EmbedKind)
import PagesComponents.Organization_.Project_.Models.EmbedMode as EmbedMode exposing (EmbedModeId)
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
import Services.Backend as Backend
import Services.DatabaseSource as DatabaseSource
import Services.JsonSource as JsonSource
import Services.ProjectSource as ProjectSource
import Services.SqlSource as SqlSource
import Url exposing (Url)


type alias Model =
    { id : HtmlId
    , kind : EmbedKind
    , content : String
    , layout : LayoutName
    , mode : EmbedModeId
    , tokens : List ProjectToken
    }


type Msg
    = Open
    | Close
    | KindUpdate EmbedKind
    | ContentUpdate String
    | LayoutUpdate LayoutName
    | ModeUpdate EmbedModeId



-- INIT


init : HtmlId -> Maybe Erd -> Model
init dialogId maybeErd =
    maybeErd
        |> Maybe.filter (\erd -> erd.project.storage == ProjectStorage.Remote)
        |> Maybe.mapOrElse
            (\erd ->
                { id = dialogId
                , kind = EmbedKind.EmbedProjectId
                , content = erd.project.id
                , layout = erd.currentLayout
                , mode = EmbedMode.default
                , tokens = []
                }
            )
            { id = dialogId
            , kind = EmbedKind.EmbedProjectUrl
            , content = ""
            , layout = maybeErd |> Maybe.mapOrElse .currentLayout ""
            , mode = EmbedMode.default
            , tokens = []
            }



-- UPDATE


update : (HtmlId -> msg) -> Maybe Erd -> Msg -> Maybe Model -> ( Maybe Model, Cmd msg )
update modalOpen erd msg model =
    case msg of
        Open ->
            ( Just (init Conf.ids.sharingDialog erd), Cmd.batch [ T.sendAfter 1 (modalOpen Conf.ids.sharingDialog) ] )

        Close ->
            ( Nothing, Cmd.none )

        KindUpdate kind ->
            ( model |> Maybe.map (\s -> { s | kind = kind, content = "" }), Cmd.none )

        ContentUpdate content ->
            ( model |> Maybe.map (\s -> { s | content = content }), Cmd.none )

        LayoutUpdate layout ->
            ( model |> Maybe.map (\s -> { s | layout = layout }), Cmd.none )

        ModeUpdate mode ->
            ( model |> Maybe.map (\s -> { s | mode = mode }), Cmd.none )



-- VIEW


view : (Msg -> msg) -> (msg -> msg) -> Url -> Bool -> Erd -> Model -> Html msg
view wrap modalClose currentUrl opened erd model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"

        iframeUrl : Maybe String
        iframeUrl =
            buildIframeUrl currentUrl model.kind model.content model.layout model.mode
    in
    Modal.modal { id = model.id, titleId = titleId, isOpen = opened, onBackgroundClick = Close |> wrap |> modalClose }
        [ div [ class "flex" ]
            [ viewIframe iframeUrl
            , div [ class "p-4", style "width" "65ch" ]
                [ viewHeader wrap modalClose titleId
                , viewBody wrap currentUrl erd model
                ]
            ]
        ]


viewIframe : Maybe String -> Html msg
viewIframe iframeUrl =
    iframeUrl
        |> Maybe.map (\url -> div [ style "width" "1000px" ] [ iframe [ attribute "width" "100%", height 800, src url, title "Embedded Azimutt diagram", attribute "frameborder" "0", attribute "allowtransparency" "true", attribute "allowfullscreen" "true", attribute "scrolling" "no", style "box-shadow" "0 2px 8px 0 rgba(63,69,81,0.16)", style "border-radius" "5px" ] [] ])
        |> Maybe.withDefault (div [ class "flex items-center" ] [ img [ class "rounded-l-lg", src (Backend.resourceUrl "/assets/images/education.gif") ] [] ])


buildIframeHtml : String -> String
buildIframeHtml iframeUrl =
    if iframeUrl /= "" then
        "<iframe width=\"100%\" height=\"800px\" src=\"" ++ iframeUrl ++ "\" title=\"Embedded Azimutt diagram\" frameborder=\"0\" allowtransparency=\"true\" allowfullscreen=\"true\" scrolling=\"no\" style=\"box-shadow: 0 2px 8px 0 rgba(63,69,81,0.16); border-radius:5px;\"></iframe>"

    else
        ""


viewHeader : (Msg -> msg) -> (msg -> msg) -> HtmlId -> Html msg
viewHeader wrap modalClose titleId =
    div [ css [ sm [ "flex justify-between" ] ] ]
        [ div [ css [ "mt-3 text-center", sm [ "mt-0 text-left" ] ] ]
            [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ] [ text "Share your project" ]
            , p [ class "text-sm text-gray-500" ]
                [ text "Send it to other people or embed it in your documentation or website." ]
            ]
        , span [ class "cursor-pointer text-gray-400", onClick (Close |> wrap |> modalClose) ] [ Icon.solid X "" ]
        ]


viewBody : (Msg -> msg) -> Url -> Erd -> Model -> Html msg
viewBody wrap currentUrl erd model =
    div []
        [ p [ class "mt-3" ]
            [ text "The easiest way to collaborate on your project is to invite new members in your organization. "
            , text "Still you can share it in read only using a private link or even embed it anywhere (with or without a private link)."
            ]
        , viewBodyKindContentInput wrap (model.id ++ "-input") model.kind model.content
        , viewBodyLayoutInput wrap (model.id ++ "-input-layout") model.layout (erd.layouts |> Dict.keys)
        , viewBodyModeInput wrap (model.id ++ "-input-mode") model.mode
        , viewBodyIframe currentUrl model
        ]


viewBodyKindContentInput : (Msg -> msg) -> HtmlId -> EmbedKind -> String -> Html msg
viewBodyKindContentInput wrap inputId kind content =
    let
        ( kindInput, contentInput ) =
            ( inputId ++ "-kind", inputId ++ "-content" )
    in
    div [ class "mt-3" ]
        [ label [ for contentInput, class "block text-sm font-medium text-gray-700" ] [ text "Embed" ]
        , div [ class "mt-1 relative rounded-md shadow-sm" ]
            [ div [ class "absolute inset-y-0 left-0 flex items-center" ]
                [ label [ for kindInput, class "sr-only" ] [ text "Content kind" ]
                , select [ id kindInput, name kindInput, onInput (EmbedKind.fromValue >> Maybe.withDefault EmbedKind.EmbedProjectUrl >> KindUpdate >> wrap), class "h-full py-0 pl-3 pr-7 border-transparent bg-transparent text-gray-500 rounded-md sm:text-sm focus:ring-indigo-500 focus:border-indigo-500" ]
                    (EmbedKind.all |> List.map (\k -> option [ value (EmbedKind.value k), selected (k == kind) ] [ text (EmbedKind.label k) ]))
                ]
            , input [ type_ "text", id contentInput, name contentInput, placeholder ("ex: " ++ embedKindPlaceholder kind), value content, onInput (ContentUpdate >> wrap), class "block w-full pl-32 border-gray-300 rounded-md sm:text-sm focus:ring-indigo-500 focus:border-indigo-500" ] []
            ]
        ]


embedKindPlaceholder : EmbedKind -> String
embedKindPlaceholder kind =
    case kind of
        EmbedKind.EmbedProjectId ->
            Uuid.zero

        EmbedKind.EmbedProjectUrl ->
            ProjectSource.example

        EmbedKind.EmbedDatabaseSource ->
            DatabaseSource.example

        EmbedKind.EmbedSqlSource ->
            SqlSource.example

        EmbedKind.EmbedJsonSource ->
            JsonSource.example


viewBodyLayoutInput : (Msg -> msg) -> HtmlId -> LayoutName -> List LayoutName -> Html msg
viewBodyLayoutInput wrap inputId inputValue layouts =
    let
        listId : HtmlId
        listId =
            inputId ++ "-list"
    in
    div [ class "mt-3" ]
        [ div [ class "flex justify-between" ]
            [ label [ for inputId, class "block text-sm font-medium text-gray-700" ] [ text "Layout" ]
            , span [ class "text-sm text-gray-500" ] [ text "Choose a layout to display." ]
            ]
        , div [ class "mt-1" ]
            [ input
                [ type_ "text"
                , id inputId
                , name inputId
                , list listId
                , value inputValue
                , onInput (LayoutUpdate >> wrap)
                , css [ "block w-full border border-gray-300 rounded-md shadow-sm", sm [ "text-sm" ], focus [ "border-indigo-500 ring-indigo-500" ] ]
                ]
                []
            , datalist [ id listId ] (layouts |> List.map (\l -> option [ value l ] []))
            ]
        ]


viewBodyModeInput : (Msg -> msg) -> HtmlId -> EmbedModeId -> Html msg
viewBodyModeInput wrap inputId inputValue =
    div [ class "mt-3" ]
        [ label [ for inputId, class "block text-sm font-medium text-gray-700" ] [ text "Mode" ]
        , select
            [ id inputId
            , name inputId
            , onInput (ModeUpdate >> wrap)
            , css [ "mt-1 block w-full py-2 px-3 bg-white border border-gray-300 rounded-md shadow-sm", sm [ "text-sm" ], focus [ "outline-none border-indigo-500 ring-indigo-500" ] ]
            ]
            (EmbedMode.all |> List.map (\m -> option [ value m.id, selected (inputValue == m.id) ] [ text (m.id ++ ": " ++ m.description) ]))
        ]


viewBodyIframe : Url -> Model -> Html msg
viewBodyIframe currentUrl model =
    let
        iframeUrl : Maybe String
        iframeUrl =
            buildIframeUrl currentUrl model.kind model.content model.layout model.mode
    in
    iframeUrl
        |> Maybe.map
            (\url ->
                div [ class "mt-3" ]
                    [ span [ class "block text-sm font-medium text-gray-700" ] [ text "Iframe" ]
                    , div [ class "mt-1 bg-gray-100 text-gray-700 rounded text-sm px-3 py-2" ] [ text (buildIframeHtml url) ]
                    , p [ class "mt-2 text-sm text-gray-500" ]
                        [ text "You are publishing your schema? Please "
                        , sendTweet Conf.constants.sharingTweet [ class "link" ] [ text "let us know" ]
                        , text " and we can help spread it 🤗"
                        ]
                    ]
            )
        |> Maybe.withDefault (div [] [])


buildIframeUrl : Url -> EmbedKind -> String -> LayoutName -> EmbedModeId -> Maybe String
buildIframeUrl currentUrl kind content layout mode =
    if content /= "" then
        Just (Url.domain currentUrl ++ Backend.embedUrl kind content layout mode)

    else
        Nothing
