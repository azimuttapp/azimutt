module PagesComponents.Projects.Id_.Views.Modals.Sharing exposing (viewSharing)

import Array
import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Modal as Modal
import Conf
import Dict
import Html exposing (Html, datalist, div, h3, iframe, img, input, label, option, p, select, span, text)
import Html.Attributes exposing (attribute, class, for, height, id, list, name, placeholder, selected, src, style, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Bool as Bool
import Libs.Html exposing (extLink, sendTweet)
import Libs.Html.Attributes exposing (css)
import Libs.Models.FileUrl exposing (FileUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw exposing (focus, sm)
import Models.Project as Project exposing (Project)
import Models.Project.LayoutName exposing (LayoutName)
import PagesComponents.Projects.Id_.Models exposing (Msg(..), SharingDialog, SharingMsg(..))
import PagesComponents.Projects.Id_.Models.EmbedMode as EmbedMode
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import Ports
import Services.Lenses exposing (mapLayout, mapRelations, mapSources, mapTables, setContent, setHiddenTables, setLayouts, setUsedLayout)


viewSharing : Bool -> Erd -> SharingDialog -> Html Msg
viewSharing opened erd model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"

        iframeUrl : String
        iframeUrl =
            buildIframeUrl model.url model.layout model.mode
    in
    Modal.modal { id = model.id, titleId = titleId, isOpen = opened, onBackgroundClick = ModalClose (SharingMsg SClose) }
        [ div [ class "flex" ]
            [ viewIframe iframeUrl
            , div [ class "p-4", style "width" "65ch" ]
                [ viewHeader titleId
                , viewBody erd model
                ]
            ]
        ]


viewIframe : String -> Html msg
viewIframe iframeUrl =
    if iframeUrl /= "" then
        div [ style "width" "1000px" ]
            [ iframe [ attribute "width" "100%", height 800, src iframeUrl, title "Embedded Azimutt diagram", attribute "frameborder" "0", attribute "allowtransparency" "true", attribute "allowfullscreen" "true", attribute "scrolling" "no", style "box-shadow" "0 2px 8px 0 rgba(63,69,81,0.16)", style "border-radius" "5px" ] []
            ]

    else
        div [ class "flex items-center" ] [ img [ src "/assets/images/illustrations/education.gif" ] [] ]


buildIframeHtml : String -> String
buildIframeHtml iframeUrl =
    if iframeUrl /= "" then
        "<iframe width=\"100%\" height=\"800px\" src=\"" ++ iframeUrl ++ "\" title=\"Embedded Azimutt diagram\" frameborder=\"0\" allowtransparency=\"true\" allowfullscreen=\"true\" scrolling=\"no\" style=\"box-shadow: 0 2px 8px 0 rgba(63,69,81,0.16); border-radius:5px;\"></iframe>"

    else
        ""


viewHeader : HtmlId -> Html Msg
viewHeader titleId =
    div [ css [ sm [ "flex justify-between" ] ] ]
        [ div [ css [ "mt-3 text-center", sm [ "mt-0 text-left" ] ] ]
            [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ] [ text "Embed diagram" ]
            , p [ class "text-sm text-gray-500" ]
                [ text "Show your schema in your documentation or in your website or blog." ]
            ]
        , span [ class "cursor-pointer text-gray-400", onClick (ModalClose (SharingMsg SClose)) ] [ Icon.solid X "" ]
        ]


viewBody : Erd -> SharingDialog -> Html Msg
viewBody erd model =
    div []
        [ viewBodyDownload erd
        , viewBodyUrlInput (model.id ++ "-url-input") model.url
        , viewBodyLayoutInput (model.id ++ "-layout-input") model.layout (erd.layouts |> Dict.keys)
        , viewBodyModeInput (model.id ++ "-mode-input") model.mode
        , viewBodyIframe model
        ]


viewBodyDownload : Erd -> Html Msg
viewBodyDownload erd =
    let
        project : Project
        project =
            erd |> Erd.unpack

        filename : String
        filename =
            project |> Project.downloadFilename

        smallProject : Project
        smallProject =
            project
                |> setUsedLayout Nothing
                |> setLayouts Dict.empty
                |> mapLayout (setHiddenTables [])
                |> mapSources
                    (List.map
                        (\s ->
                            s
                                |> setContent Array.empty
                                |> mapTables (Dict.filter (\id _ -> project.layout.tables |> List.any (\p -> p.id == id)))
                                |> mapRelations (List.filter (\r -> project.layout.tables |> List.any (\p -> p.id == r.src.table || p.id == r.ref.table)))
                        )
                    )
    in
    div [ class "mt-3" ]
        [ p []
            [ text "In Azimutt, everything stay on your browser, but to embed the diagram you need to make it available. "
            , text "For that, download it and host it whenever is fine for you ("
            , extLink "https://gist.github.com" [ class "link" ] [ text "secret gists" ]
            , text " are great for that), and then fill its URL just below."
            ]
        , div [ class "mt-1 flex justify-around" ]
            [ Button.primary3 Tw.primary
                [ onClick (Send (Ports.downloadFile filename (project |> Project.downloadContent))), class "mx-1 whitespace-nowrap" ]
                [ text "Download whole project" ]
            , Button.primary3 Tw.primary
                [ onClick (Send (Ports.downloadFile filename (smallProject |> Project.downloadContent))), class "mx-1 whitespace-nowrap" ]
                [ text "Download project with current layout only" ]
            ]
        ]


viewBodyUrlInput : HtmlId -> FileUrl -> Html Msg
viewBodyUrlInput inputId inputValue =
    div [ class "mt-3" ]
        [ label [ for inputId, class "block text-sm font-medium text-gray-700" ] [ text "Project url" ]
        , div [ class "mt-1" ]
            [ input
                [ type_ "url"
                , id inputId
                , name inputId
                , placeholder "https://azimutt.app/samples/gospeak.azimutt.json"
                , value inputValue
                , onInput (SProjectUrlUpdate >> SharingMsg)
                , css [ "block w-full border border-gray-300 rounded-md shadow-sm", sm [ "text-sm" ], focus [ "border-indigo-500 ring-indigo-500" ] ]
                ]
                []
            ]
        ]


viewBodyLayoutInput : HtmlId -> LayoutName -> List LayoutName -> Html Msg
viewBodyLayoutInput inputId inputValue layouts =
    let
        listId : HtmlId
        listId =
            inputId ++ "-list"
    in
    div [ class "mt-3" ]
        [ div [ class "flex justify-between" ]
            [ label [ for inputId, class "block text-sm font-medium text-gray-700" ] [ text "Layout" ]
            , span [ class "text-sm text-gray-500" ] [ text "Choose a layout to display or keep the default one." ]
            ]
        , div [ class "mt-1" ]
            [ input
                [ type_ "text"
                , id inputId
                , name inputId
                , list listId
                , value inputValue
                , onInput (SLayoutUpdate >> SharingMsg)
                , css [ "block w-full border border-gray-300 rounded-md shadow-sm", sm [ "text-sm" ], focus [ "border-indigo-500 ring-indigo-500" ] ]
                ]
                []
            , datalist [ id listId ] (layouts |> List.map (\l -> option [ value l ] []))
            ]
        ]


viewBodyModeInput : HtmlId -> String -> Html Msg
viewBodyModeInput inputId inputValue =
    div [ class "mt-3" ]
        [ label [ for inputId, class "block text-sm font-medium text-gray-700" ] [ text "Mode" ]
        , select
            [ id inputId
            , name inputId
            , onInput (SModeUpdate >> SharingMsg)
            , css [ "mt-1 block w-full py-2 px-3 bg-white border border-gray-300 rounded-md shadow-sm", sm [ "text-sm" ], focus [ "outline-none border-indigo-500 ring-indigo-500" ] ]
            ]
            (EmbedMode.all |> List.map (\m -> option [ value m.id, selected (inputValue == m.id) ] [ text (m.id ++ ": " ++ m.description) ]))
        ]


viewBodyIframe : SharingDialog -> Html msg
viewBodyIframe model =
    let
        iframeUrl : String
        iframeUrl =
            buildIframeUrl model.url model.layout model.mode
    in
    if iframeUrl /= "" then
        div [ class "mt-3" ]
            [ span [ class "block text-sm font-medium text-gray-700" ] [ text "Iframe" ]
            , div [ class "mt-1 bg-gray-100 text-gray-700 rounded text-sm px-3 py-2" ] [ text (buildIframeHtml iframeUrl) ]
            , p [ class "mt-2 text-sm text-gray-500" ]
                [ text "You are publishing your schema? Please "
                , sendTweet Conf.constants.sharingTweet [ class "link" ] [ text "let us know" ]
                , text " and we can help spread it 🤗"
                ]
            ]

    else
        div [] []


buildIframeUrl : FileUrl -> LayoutName -> String -> String
buildIframeUrl projectUrl layout mode =
    if projectUrl /= "" then
        Conf.constants.azimuttWebsite ++ "/embed?project_url=" ++ projectUrl ++ Bool.cond (layout /= "") ("&layout=" ++ layout) "" ++ Bool.cond (mode /= "") ("&mode=" ++ mode) ""

    else
        ""
