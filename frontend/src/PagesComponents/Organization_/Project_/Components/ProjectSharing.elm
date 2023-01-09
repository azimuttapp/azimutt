module PagesComponents.Organization_.Project_.Components.ProjectSharing exposing (Model, Msg(..), TokenForm, init, update, view)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Modal as Modal
import Components.Molecules.Tooltip as Tooltip
import Components.Slices.ProPlan as ProPlan
import Conf
import Dict
import Gen.Route as Route
import Html exposing (Html, a, button, datalist, div, h3, iframe, img, input, label, option, p, select, span, text)
import Html.Attributes exposing (attribute, class, disabled, for, height, href, id, list, name, placeholder, rel, selected, src, style, target, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Lazy as Lazy
import Libs.Bool as Bool
import Libs.Html exposing (extLink, sendTweet)
import Libs.Html.Attributes exposing (ariaChecked, ariaHidden, ariaLabelledby, css, role)
import Libs.Maybe as Maybe
import Libs.Models.DateTime as DateTime
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Uuid as Uuid
import Libs.String as String
import Libs.Tailwind as Tw exposing (TwClass, focus, sm)
import Libs.Task as T
import Libs.Time as Time
import Libs.Url as Url
import Models.Organization exposing (Organization)
import Models.Plan exposing (Plan)
import Models.Project as Project exposing (Project)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectStorage as ProjectStorage
import Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import Models.ProjectToken exposing (ProjectToken)
import PagesComponents.Organization_.Project_.Models.EmbedKind as EmbedKind exposing (EmbedKind)
import PagesComponents.Organization_.Project_.Models.EmbedMode as EmbedMode exposing (EmbedModeId)
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import Ports
import Services.Backend as Backend
import Services.DatabaseSource as DatabaseSource
import Services.JsonSource as JsonSource
import Services.Lenses exposing (mapTokenFormM, setExpire, setName, setToken, setTokenForm, setTokens)
import Services.ProjectSource as ProjectSource
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts
import Time
import Time.Extra as Time exposing (Interval(..))
import Track
import Url exposing (Url)


type alias Model =
    { id : HtmlId
    , kind : EmbedKind
    , tokens : List ProjectToken
    , tokenForm : Maybe TokenForm
    , content : String
    , layout : LayoutName
    , mode : EmbedModeId
    }


type alias TokenForm =
    { name : String, expire : Maybe Interval, loading : Bool, error : Maybe String, token : Maybe ProjectToken }


type Msg
    = Open
    | Close
    | KindUpdate EmbedKind
    | ContentUpdate String
    | EnableTokenForm
    | DisableTokenForm
    | GotTokens (Result Backend.Error (List ProjectToken))
    | TokenNameUpdate String
    | TokenExpireUpdate (Maybe Interval)
    | CreateToken TokenForm
    | TokenCreated (Result Backend.Error ())
    | RevokeToken ProjectToken
    | TokenRevoked (Result Backend.Error ())
    | TokenUpdate (Maybe ProjectToken)
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
                , tokens = []
                , tokenForm = Nothing
                , content = erd.project.id
                , layout = erd.currentLayout
                , mode = EmbedMode.default
                }
            )
            { id = dialogId
            , kind = EmbedKind.EmbedProjectUrl
            , tokens = []
            , tokenForm = Nothing
            , content = ""
            , layout = maybeErd |> Maybe.mapOrElse .currentLayout ""
            , mode = EmbedMode.default
            }


initTokenForm : TokenForm
initTokenForm =
    { name = "", expire = Nothing, loading = False, error = Nothing, token = Nothing }



-- UPDATE


update : (Msg -> msg) -> (HtmlId -> msg) -> (Toasts.Msg -> msg) -> Time.Zone -> Time.Posix -> Maybe Erd -> Msg -> Maybe Model -> ( Maybe Model, Cmd msg )
update wrap modalOpen toast zone now erd msg model =
    case msg of
        Open ->
            ( Just (init Conf.ids.sharingDialog erd), Cmd.batch [ T.sendAfter 1 (modalOpen Conf.ids.sharingDialog) ] )

        Close ->
            ( Nothing, Cmd.none )

        KindUpdate kind ->
            ( model |> Maybe.map (\s -> { s | kind = kind, content = "", tokenForm = Nothing }), Cmd.none )

        ContentUpdate content ->
            ( model |> Maybe.map (\s -> { s | content = content }), Cmd.none )

        EnableTokenForm ->
            ( model |> Maybe.map (setTokenForm (Just initTokenForm))
            , if erd |> Erd.getOrganizationM Nothing |> .plan |> .privateLinks then
                erd |> Maybe.mapOrElse (\e -> Backend.getProjectTokens e.project (GotTokens >> wrap)) Cmd.none

              else
                Track.proPlanLimit Conf.features.privateLinks.name erd |> Ports.track
            )

        DisableTokenForm ->
            ( model |> Maybe.map (setTokenForm Nothing), Cmd.none )

        GotTokens (Ok tokens) ->
            ( model |> Maybe.map (setTokens tokens), Cmd.none )

        GotTokens (Err err) ->
            ( model, err |> Backend.errorToString |> Toasts.create "warning" |> toast |> T.send )

        TokenNameUpdate name ->
            ( model |> Maybe.map (mapTokenFormM (setName name)), Cmd.none )

        TokenExpireUpdate expire ->
            ( model |> Maybe.map (mapTokenFormM (setExpire expire)), Cmd.none )

        CreateToken form ->
            ( model |> Maybe.map (mapTokenFormM (\f -> { f | loading = True, error = Nothing }))
            , erd |> Maybe.mapOrElse (\e -> Backend.createProjectToken form.name (form.expire |> Maybe.map (\i -> Time.add i 1 zone now)) e.project (TokenCreated >> wrap)) Cmd.none
            )

        TokenCreated (Ok _) ->
            ( model |> Maybe.map (mapTokenFormM (\f -> { f | name = "", expire = Nothing, loading = False, error = Nothing }))
            , erd |> Maybe.mapOrElse (\e -> Backend.getProjectTokens e.project (GotTokens >> wrap)) Cmd.none
            )

        TokenCreated (Err err) ->
            ( model |> Maybe.map (mapTokenFormM (\f -> { f | loading = False, error = err |> Backend.errorToString |> Just })), Cmd.none )

        RevokeToken token ->
            ( model |> Maybe.map (mapTokenFormM (\f -> { f | error = Nothing })), erd |> Maybe.mapOrElse (\e -> Backend.revokeProjectToken token e.project (TokenRevoked >> wrap)) Cmd.none )

        TokenRevoked (Ok _) ->
            ( model, erd |> Maybe.mapOrElse (\e -> Backend.getProjectTokens e.project (GotTokens >> wrap)) Cmd.none )

        TokenRevoked (Err err) ->
            ( model |> Maybe.map (mapTokenFormM (\f -> { f | error = err |> Backend.errorToString |> Just })), Cmd.none )

        TokenUpdate token ->
            ( model |> Maybe.map (mapTokenFormM (setToken token)), Cmd.none )

        LayoutUpdate layout ->
            ( model |> Maybe.map (\s -> { s | layout = layout }), Cmd.none )

        ModeUpdate mode ->
            ( model |> Maybe.map (\s -> { s | mode = mode }), Cmd.none )



-- VIEW


view : (Msg -> msg) -> (Cmd msg -> msg) -> (msg -> msg) -> (String -> Html msg -> msg -> msg) -> Time.Zone -> Url -> Bool -> Erd -> Model -> Html msg
view wrap send modalClose confirm zone currentUrl opened erd model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"

        iframeUrl : Maybe String
        iframeUrl =
            buildIframeUrl currentUrl model.kind model.content model.layout model.mode (model.tokenForm |> Maybe.andThen .token)
    in
    Modal.modal { id = model.id, titleId = titleId, isOpen = opened, onBackgroundClick = Close |> wrap |> modalClose }
        [ div [ class "flex" ]
            [ Lazy.lazy viewIframe (iframeUrl |> Maybe.withDefault "")
            , div [ class "p-4", style "width" "70ch" ]
                [ viewHeader wrap modalClose titleId
                , viewBody wrap send confirm zone currentUrl erd model
                ]
            ]
        ]


viewIframe : String -> Html msg
viewIframe iframeUrl =
    iframeUrl
        |> String.nonEmptyMaybe
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
                [ text "Send it to people or embed it in your documentation or website." ]
            ]
        , span [ class "cursor-pointer text-gray-400", onClick (Close |> wrap |> modalClose) ] [ Icon.solid X "" ]
        ]


viewBody : (Msg -> msg) -> (Cmd msg -> msg) -> (String -> Html msg -> msg -> msg) -> Time.Zone -> Url -> Erd -> Model -> Html msg
viewBody wrap send confirm zone currentUrl erd model =
    div []
        [ case erd.project.storage of
            ProjectStorage.Local ->
                viewBodyLocalProject send erd

            ProjectStorage.Remote ->
                viewBodyRemoteProject
        , viewBodyKindContentInput wrap (model.id ++ "-input") model.kind model.content
        , if erd.project.storage == ProjectStorage.Remote && model.kind == EmbedKind.EmbedProjectId then
            viewBodyProjectTokens wrap confirm zone (model.id ++ "-input-token") (erd |> Erd.getOrganization Nothing) model.tokens model.tokenForm

          else
            div [] []
        , viewBodyLayoutInput wrap (model.id ++ "-input-layout") model.layout (erd.layouts |> Dict.keys)
        , viewBodyModeInput wrap (model.id ++ "-input-mode") model.mode
        , viewBodyLink currentUrl erd.project model
        , viewBodyIframe currentUrl model
        ]


viewBodyLocalProject : (Cmd msg -> msg) -> Erd -> Html msg
viewBodyLocalProject send erd =
    let
        project : Project
        project =
            erd |> Erd.unpack

        filename : String
        filename =
            project |> Project.downloadFilename
    in
    div [ class "mt-3" ]
        [ p []
            [ text "Local project are only on your machine, to share them you must download and host them ("
            , extLink "https://gist.github.com" [ class "link" ] [ text "secret gist" ]
            , text " are good for that), then fill the URL just below."
            ]
        , Button.primary3 Tw.primary
            [ onClick (project |> Project.downloadContent |> Ports.downloadFile filename |> send), class "mt-1 whitespace-nowrap" ]
            [ text "Download project" ]
        ]


viewBodyRemoteProject : Html msg
viewBodyRemoteProject =
    p [] []


viewBodyKindContentInput : (Msg -> msg) -> HtmlId -> EmbedKind -> String -> Html msg
viewBodyKindContentInput wrap inputId kind content =
    let
        ( kindInput, contentInput ) =
            ( inputId ++ "-kind", inputId ++ "-content" )
    in
    div [ class "mt-3" ]
        [ label [ for contentInput, class "block text-sm font-medium text-gray-700" ] [ text "Share" ]
        , div [ class "mt-1 relative rounded-md shadow-sm" ]
            [ div [ class "absolute inset-y-0 left-0 flex items-center" ]
                [ label [ for kindInput, class "sr-only" ] [ text "Content kind" ]
                , select [ id kindInput, name kindInput, onInput (EmbedKind.fromValue >> Maybe.withDefault EmbedKind.EmbedProjectUrl >> KindUpdate >> wrap), class "h-full py-0 pl-2 pr-7 border-transparent bg-transparent text-gray-500 rounded-md sm:text-sm focus:ring-indigo-500 focus:border-indigo-500" ]
                    (EmbedKind.all |> List.map (\k -> option [ value (EmbedKind.value k), selected (k == kind) ] [ text (EmbedKind.label k) ]))
                ]
            , input [ type_ "text", id contentInput, name contentInput, placeholder ("ex: " ++ embedKindPlaceholder kind), value content, onInput (ContentUpdate >> wrap), class "block w-full pl-36 border-gray-300 rounded-md sm:text-sm focus:ring-indigo-500 focus:border-indigo-500" ] []
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


viewBodyProjectTokens : (Msg -> msg) -> (String -> Html msg -> msg -> msg) -> Time.Zone -> HtmlId -> Organization -> List ProjectToken -> Maybe TokenForm -> Html msg
viewBodyProjectTokens wrap confirm zone inputId organization tokens form =
    div [ class "mt-3" ]
        [ div [ class "flex justify-between" ]
            [ label [ for inputId, class "block text-sm font-medium text-gray-700" ]
                [ text "Private link"
                , Icon.solid Icon.QuestionMarkCircle "h-4 opacity-50" |> Tooltip.t "Allow anyone with the token to access the project (read-only), it's great for quick sharing or embed in documentation."
                ]
            , button [ type_ "button", onClick (form |> Maybe.mapOrElse (\_ -> DisableTokenForm) EnableTokenForm |> wrap), role "switch", ariaChecked True, class "group relative inline-flex h-5 w-10 flex-shrink-0 cursor-pointer items-center justify-center rounded-full focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" ]
                [ span [ class "sr-only" ] [ text "Use private tokens" ]
                , span [ ariaHidden True, class "pointer-events-none absolute h-full w-full rounded-md bg-white" ] []
                , span [ ariaHidden True, css [ form |> Maybe.mapOrElse (\_ -> "bg-indigo-600") "bg-gray-200", "pointer-events-none absolute mx-auto h-4 w-9 rounded-full transition-colors duration-200 ease-in-out" ] ] []
                , span [ ariaHidden True, css [ form |> Maybe.mapOrElse (\_ -> "translate-x-5") "translate-x-0", "pointer-events-none absolute left-0 inline-block h-5 w-5 transform rounded-full border border-gray-200 bg-white shadow ring-0 transition-transform duration-200 ease-in-out" ] ] []
                ]
                |> Tooltip.tl "Enable private tokens"
            ]
        , form
            |> Maybe.mapOrElse
                (\f ->
                    if organization.plan.privateLinks then
                        div [ class "mt-1" ]
                            [ div [ class "-space-y-px shadow-sm bg-white" ]
                                ((tokens |> List.indexedMap (viewBodyProjectToken wrap confirm zone inputId f.token))
                                    ++ [ viewBodyProjectTokenCreation wrap inputId (tokens == []) f ]
                                )
                            , f.error |> Maybe.mapOrElse (\err -> p [ class "mt-2 text-sm text-red-600" ] [ text err ]) (p [] [])
                            ]

                    else
                        div [ class "mt-1" ] [ ProPlan.privateLinkWarning organization ]
                )
                (div [] [])
        ]


viewBodyProjectToken : (Msg -> msg) -> (String -> Html msg -> msg -> msg) -> Time.Zone -> HtmlId -> Maybe ProjectToken -> Int -> ProjectToken -> Html msg
viewBodyProjectToken wrap confirm zone inputId chosen i token =
    let
        labelId : HtmlId
        labelId =
            inputId ++ "-" ++ String.fromInt i ++ "-label"

        selected : Bool
        selected =
            chosen |> Maybe.any (\c -> c.id == token.id)

        ( created, accessed ) =
            ( "Created by " ++ token.createdBy.name ++ " on " ++ DateTime.formatDatetime zone token.createdAt
            , String.fromInt token.nbAccess ++ " access since creation" ++ (token.lastAccess |> Maybe.mapOrElse (\t -> " (last one on " ++ DateTime.formatDatetime zone t ++ ")") "")
            )
    in
    div [ css [ Bool.cond selected "bg-indigo-50 border-indigo-300 z-10" "border-gray-300", Bool.cond (i == 0) "rounded-t-md" "", "border flex" ] ]
        [ label [ class "grow relative flex px-3 py-2 cursor-pointer focus:outline-none" ]
            [ input [ type_ "radio", name inputId, value token.id, onInput (\_ -> Bool.cond selected Nothing (token |> Just) |> TokenUpdate |> wrap), ariaLabelledby labelId, class "mt-0.5 h-4 w-4 shrink-0 cursor-pointer text-indigo-600 focus:ring-indigo-500" ] []
            , span [ class "ml-3 flex flex-col" ]
                [ span [ id labelId, css [ Bool.cond selected "text-indigo-900" "text-gray-900", "block text-sm font-medium" ] ]
                    [ text (token.name ++ (token.expireAt |> Maybe.mapOrElse (\t -> " (expire on " ++ DateTime.formatDatetime zone t ++ ")") " (does not expire)")) ]
                    |> Tooltip.t (created ++ ", " ++ accessed)
                ]
            ]
        , button
            [ type_ "button"
            , onClick
                (RevokeToken token
                    |> wrap
                    |> confirm ("Revoke token '" ++ token.name ++ "'?")
                        (div []
                            [ p [] [ text created ]
                            , p [] [ text accessed ]
                            , p [ class "mt-3" ] [ text "People with this token won't be able to access this project anymore." ]
                            ]
                        )
                )
            , class "px-3 py-2"
            ]
            [ Icon.solid Icon.Trash "text-gray-300" ]
            |> Tooltip.tl "Revoke token"
        ]


viewBodyProjectTokenCreation : (Msg -> msg) -> HtmlId -> Bool -> TokenForm -> Html msg
viewBodyProjectTokenCreation wrap inputId roundFull f =
    let
        ( nameField, expireField ) =
            ( inputId ++ "-name", inputId ++ "-expire" )
    in
    div [ class "flex -space-x-px" ]
        [ div [ class "min-w-0 w-1/2 flex-1" ]
            [ label [ for nameField, class "sr-only" ] [ text "Token name" ]
            , input [ type_ "text", name nameField, id nameField, value f.name, onInput (TokenNameUpdate >> wrap), placeholder "Token name", css [ Bool.cond roundFull "rounded-l-md" "rounded-bl-md", "relative block w-full border border-gray-300 bg-transparent focus:z-10 focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" ] ] []
            ]
        , div [ class "min-w-0" ]
            [ label [ for expireField, class "sr-only" ] [ text "Expiration" ]
            , select [ name expireField, id expireField, onInput (Time.stringToInterval >> TokenExpireUpdate >> wrap), class "relative block w-full border border-gray-300 bg-transparent focus:z-10 focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" ]
                ([ ( Nothing, "does not expire" )
                 , ( Just Hour, "expire in 1 hour" )
                 , ( Just Day, "expire in 1 day" )
                 , ( Just Month, "expire in 1 month" )
                 ]
                    |> List.map (\( v, l ) -> option [ value (v |> Maybe.mapOrElse Time.intervalToString ""), selected (f.expire == v) ] [ text l ])
                )
            ]
        , button [ type_ "button", onClick (CreateToken f |> wrap), disabled (f.name == "" || f.loading), css [ Bool.cond roundFull "rounded-r-md" "rounded-br-md", "relative block border border-gray-300 px-4 py-2 text-sm font-medium bg-gray-50 text-gray-700 hover:bg-gray-100 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500 disabled:bg-gray-100 disabled:text-gray-400" ] ]
            [ text "Create token"
            ]
        ]


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


viewBodyLink : Url -> ProjectInfo -> Model -> Html msg
viewBodyLink currentUrl project model =
    buildShareUrl currentUrl project model.kind model.content model.layout (model.tokenForm |> Maybe.andThen .token)
        |> Maybe.mapOrElse
            (\url ->
                div [ class "mt-3" ]
                    [ span [ class "block text-sm font-medium text-gray-700" ] [ text "Private link:" ]
                    , div [ class "mt-1 bg-gray-100 text-gray-700 rounded text-sm px-3 py-2" ]
                        [ a [ href url, target "_blank", rel "noopener", class "hover:link" ] [ text url ]
                        ]
                    ]
            )
            (div [] [])


buildShareUrl : Url -> ProjectInfo -> EmbedKind -> String -> LayoutName -> Maybe ProjectToken -> Maybe String
buildShareUrl currentUrl project kind content layout token =
    if kind == EmbedKind.EmbedProjectId && content /= "" && token /= Nothing then
        Just
            (Url.domain currentUrl
                ++ Route.toHref (Route.Organization___Project_ { organization = ProjectInfo.organizationId project, project = content })
                ++ "?"
                ++ Url.buildQueryString
                    ([ ( "layout", layout )
                     , ( "token", token |> Maybe.mapOrElse .id "" )
                     ]
                        |> List.filter (\( _, v ) -> v /= "")
                    )
            )

    else
        Nothing


viewBodyIframe : Url -> Model -> Html msg
viewBodyIframe currentUrl model =
    buildIframeUrl currentUrl model.kind model.content model.layout model.mode (model.tokenForm |> Maybe.andThen .token)
        |> Maybe.mapOrElse
            (\url ->
                div [ class "mt-3" ]
                    [ span [ class "block text-sm font-medium text-gray-700" ] [ text "Embed iframe:" ]
                    , div [ class "mt-1 bg-gray-100 text-gray-700 rounded text-sm px-3 py-2" ] [ text (buildIframeHtml url) ]
                    , p [ class "mt-2 text-sm text-gray-500" ]
                        [ text "You are publishing your schema? Please "
                        , sendTweet Conf.constants.sharingTweet [ class "link" ] [ text "let us know" ]
                        , text " and we can help spread it 🤗"
                        ]
                    ]
            )
            (div [] [])


buildIframeUrl : Url -> EmbedKind -> String -> LayoutName -> EmbedModeId -> Maybe ProjectToken -> Maybe String
buildIframeUrl currentUrl kind content layout mode token =
    if content /= "" then
        Just (Url.domain currentUrl ++ Backend.embedUrl kind content layout mode token)

    else
        Nothing
