module Components.Slices.ProjectSaveDialogBody exposing (DocState, Model, Msg(..), SharedDocState, doc, docInit, init, selectSave, signIn, update)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon
import Components.Atoms.Link as Link
import Components.Molecules.Alert as Alert
import Components.Molecules.FormLabel as FormLabel
import Components.Molecules.InputText as InputText
import Components.Molecules.Select as Select
import ElmBook
import ElmBook.Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, a, div, h3, input, label, p, span, text)
import Html.Attributes exposing (checked, class, classList, disabled, href, id, name, rel, target, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Bool as Bool
import Libs.Html exposing (bText)
import Libs.Html.Attributes exposing (ariaDescribedby, ariaHidden, ariaLabelledby, css)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String exposing (pluralize)
import Libs.Tailwind as Tw
import Libs.Time as Time
import Models.Feature as Feature
import Models.Organization as Organization exposing (Organization)
import Models.Plan as Plan exposing (Plan)
import Models.Project.ProjectName exposing (ProjectName)
import Models.Project.ProjectStorage as ProjectStorage exposing (ProjectStorage)
import Models.Project.ProjectVisibility as ProjectVisibility
import Models.ProjectInfo exposing (ProjectInfo)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import Services.Backend as Backend


type alias Model =
    { id : HtmlId
    , name : ProjectName
    , organization : Maybe Organization
    , storage : Maybe ProjectStorage
    }


type Msg
    = UpdateProjectName ProjectName
    | UpdateOrganization (Maybe Organization)
    | UpdateStorage (Maybe ProjectStorage)


init : HtmlId -> ProjectName -> Maybe Organization -> Model
init id name organization =
    { id = id, name = name, organization = organization, storage = Nothing }


update : Msg -> Model -> ( Model, Extra msg )
update msg model =
    case msg of
        UpdateProjectName value ->
            ( { model | name = value }, Extra.none )

        UpdateOrganization value ->
            ( { model | organization = value, storage = Nothing }, Extra.none )

        UpdateStorage value ->
            ( { model | storage = value }, Extra.none )


signIn : msg -> String -> HtmlId -> Html msg
signIn modalClose loginUrl titleId =
    div [ class "px-4 p-6 max-w-2xl" ]
        [ div []
            [ div [ class "mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-emerald-100" ]
                [ Icon.outline Icon.Login "text-emerald-600"
                ]
            , div [ class "mt-3 text-center sm:mt-5" ]
                [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ]
                    [ text "Sign in to save your project." ]
                , div [ class "mt-2" ]
                    [ p [ class "text-sm text-gray-500" ] [ text "Azimutt has ", bText "evolved", text "!" ]
                    , p [ class "text-sm text-gray-500" ] [ text "Projects are now registered in your Azimutt account." ]
                    , p [ class "text-sm text-gray-500" ] [ text "You can upload them and invite people to collaborate," ]
                    , p [ class "text-sm text-gray-500" ] [ text "or keep them local for total privacy!" ]
                    ]
                ]
            ]
        , div [ class "mt-5 sm:mt-6 sm:grid sm:grid-cols-2 sm:gap-3 sm:grid-flow-row-dense" ]
            [ Button.white3 Tw.default [ onClick modalClose ] [ text "No thanks" ]
            , Link.primary3 Tw.emerald [ href loginUrl, class "w-full" ] [ text "Sign in to save" ]
            ]
        ]


selectSave : (Msg -> msg) -> msg -> (ProjectName -> Organization -> ProjectStorage -> msg) -> HtmlId -> List Organization -> List ProjectInfo -> ProjectName -> Model -> Html msg
selectSave wrap modalClose save titleId organizations projects projectName model =
    let
        orgProjects : Int
        orgProjects =
            projects |> List.filter (\p -> Maybe.any2 (\o po -> o.id == po.id) model.organization p.organization) |> List.length

        tooManyProjects : Maybe (Html msg)
        tooManyProjects =
            model.organization
                |> Maybe.andThen
                    (\o ->
                        if o.plan.projects == Just 0 then
                            div [ class "mt-3" ]
                                [ Alert.withDescription { color = Tw.yellow, icon = Icon.Exclamation, title = "Can't save project" }
                                    [ text ("You plan (" ++ o.plan.name ++ ") can't save projects. ")
                                    , a [ href (Backend.organizationBillingUrl (Just o.id) Feature.projects.name), target "_blank", rel "noopener", class "link" ] [ text "Please upgrade" ]
                                    , text "."
                                    ]
                                ]
                                |> Just

                        else if o |> Organization.canSaveProject orgProjects |> not then
                            div [ class "mt-3" ]
                                [ Alert.withDescription { color = Tw.yellow, icon = Icon.Exclamation, title = "Can't save project" }
                                    [ text ("You already saved " ++ (orgProjects |> pluralize "project") ++ ", you need ")
                                    , a [ href (Backend.organizationBillingUrl (Just o.id) Feature.projects.name), target "_blank", rel "noopener", class "link" ] [ text "to upgrade" ]
                                    , text " for more."
                                    ]
                                ]
                                |> Just

                        else
                            Nothing
                    )
    in
    div [ class "px-4 p-6 max-w-2xl" ]
        [ div []
            [ div [ class "mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-primary-100" ]
                [ Icon.outline Icon.Save "text-primary-600"
                ]
            , div [ class "mt-3 sm:mt-5" ]
                [ h3 [ id titleId, class "text-lg leading-6 font-medium text-center text-gray-900" ]
                    [ text ("Save " ++ projectName) ]
                , div [ class "mt-2" ]
                    [ FormLabel.bold "mt-3" (model.id ++ "-project") "Name" (\fieldId -> InputText.simple fieldId "" model.name (UpdateProjectName >> wrap))
                    , FormLabel.bold "mt-3"
                        (model.id ++ "-organization")
                        "Organization"
                        (\fieldId ->
                            Select.simple fieldId
                                ({ value = "", label = "-- choose an organization" }
                                    :: (organizations
                                            |> List.sortBy .name
                                            |> List.map
                                                (\o ->
                                                    { value = o.id
                                                    , label =
                                                        o.name
                                                            ++ (if o.plan.id == "free" then
                                                                    ""

                                                                else
                                                                    " (" ++ o.plan.name ++ ")"
                                                               )
                                                    }
                                                )
                                       )
                                )
                                (model.organization |> Maybe.mapOrElse .id "")
                                (\orgId -> organizations |> List.findBy .id orgId |> UpdateOrganization |> wrap)
                        )
                    , tooManyProjects
                        |> Maybe.withDefault
                            (model.organization
                                |> Maybe.map
                                    (\o ->
                                        FormLabel.bold "mt-3"
                                            (model.id ++ "-storage")
                                            ("How do you want to save?" ++ (o.plan.projects |> Maybe.map (\p -> " (" ++ ((p - orgProjects) |> pluralize "remaining project") ++ ")") |> Maybe.withDefault ""))
                                            (\fieldId -> radioCards fieldId (stringToStorage >> UpdateStorage >> wrap) model.storage)
                                    )
                                |> Maybe.withDefault (div [] [])
                            )
                    , tooManyProjects
                        |> Maybe.map (\_ -> p [ class "mt-3 text-sm text-gray-500" ] [ text "If you just upgraded, refresh this page, your changes are saved." ])
                        |> Maybe.withDefault (text "")
                    ]
                ]
            ]
        , div [ class "mt-5 sm:mt-6 sm:grid sm:grid-cols-2 sm:gap-3 sm:grid-flow-row-dense" ]
            [ Button.white3 Tw.default [ onClick modalClose ] [ text "Stay in draft" ]
            , Maybe.map3 save (String.nonEmptyMaybe model.name) model.organization model.storage
                |> Maybe.map (\msg -> Button.primary3 Tw.primary [ onClick msg, class "w-full" ] [ text "Create project" ])
                |> Maybe.withDefault (Button.primary3 Tw.primary [ disabled True, class "w-full" ] [ text "Create project" ])
            ]
        ]


type alias Card msg =
    { value : ProjectStorage, description : String, notes : List (Html msg), enabled : Bool }


radioCards : HtmlId -> (String -> msg) -> Maybe ProjectStorage -> Html msg
radioCards fieldId fieldChange fieldValue =
    div [ class "grid grid-cols-1 gap-y-2" ]
        ([ Card ProjectStorage.Remote "Save project on Azimutt servers, share with your team." [ text "Enjoy collaboration!" ] True
         , Card ProjectStorage.Local "Save in your browser, highest privacy, but no sharing." [ text "Only this browser can access it." ] True
         ]
            |> List.indexedMap (radioCardLabel fieldId (storageToString fieldValue) fieldChange)
        )


radioCardLabel : String -> String -> (String -> msg) -> Int -> Card msg -> Html msg
radioCardLabel htmlId fieldValue fieldChange index card =
    let
        ( cardId, cardValue ) =
            ( htmlId ++ "-" ++ String.fromInt index, card.value |> Just |> storageToString )

        ( isChecked, isActive ) =
            ( cardValue == fieldValue, cardValue == fieldValue )
    in
    label [ css [ "relative flex rounded-lg border bg-white p-4 shadow-sm focus:outline-none", Bool.cond isChecked "border-transparent" "border-gray-300" ], classList [ ( "cursor-pointer", card.enabled ), ( "opacity-50", not card.enabled ), ( "border-indigo-500 ring-2 ring-indigo-500", isActive ) ] ]
        [ input [ type_ "radio", name htmlId, value cardValue, onInput fieldChange, checked isChecked, disabled (not card.enabled), class "sr-only", ariaLabelledby (cardId ++ "-label"), ariaDescribedby (cardId ++ "-description " ++ cardId ++ "-notes") ] []
        , span [ class "flex flex-1" ]
            [ span [ class "flex flex-col" ]
                [ span [ id (cardId ++ "-label"), class "block text-sm font-medium text-gray-900" ] [ text cardValue ]
                , span [ id (cardId ++ "-description"), class "mt-1 flex items-center text-sm text-gray-500" ] [ text card.description ]
                , span [ id (cardId ++ "-notes"), class "mt-6 text-sm font-medium text-gray-900" ] card.notes
                ]
            ]
        , Icon.solid Icon.CheckCircle (Bool.cond isChecked "text-indigo-600" "invisible")
        , span [ css [ "pointer-events-none absolute -inset-px rounded-lg border-2", Bool.cond isChecked "border-indigo-500" "border-transparent", Bool.cond isActive "border" "border-2" ], ariaHidden True ] []
        ]


storageToString : Maybe ProjectStorage -> String
storageToString storage =
    case storage of
        Just ProjectStorage.Local ->
            "Local"

        Just ProjectStorage.Remote ->
            "Remote"

        Nothing ->
            ""


stringToStorage : String -> Maybe ProjectStorage
stringToStorage value =
    case value of
        "Local" ->
            Just ProjectStorage.Local

        "Remote" ->
            Just ProjectStorage.Remote

        _ ->
            Nothing



-- DOCUMENTATION


type alias SharedDocState x =
    { x | projectSaveDocState : DocState }


type alias DocState =
    Model


docInit : DocState
docInit =
    { id = "modal-id", name = "MyProject", organization = Nothing, storage = Nothing }


updateDocState : Msg -> ElmBook.Msg (SharedDocState x)
updateDocState msg =
    ElmBook.Actions.updateState (\s -> { s | projectSaveDocState = s.projectSaveDocState |> update msg |> Tuple.first })


component : String -> (DocState -> Html msg) -> ( String, SharedDocState x -> Html msg )
component name render =
    ( name, \{ projectSaveDocState } -> render projectSaveDocState )


docCloseModal : ElmBook.Msg state
docCloseModal =
    ElmBook.Actions.logAction "modalClose"


docSave : ProjectName -> Organization -> ProjectStorage -> ElmBook.Msg state
docSave name orga storage =
    ElmBook.Actions.logAction ("save: " ++ name ++ ", " ++ orga.name ++ ", " ++ (storage |> Just |> storageToString))


docLoginUrl : String
docLoginUrl =
    "#login"


docTitleId : String
docTitleId =
    "modal-id-title"


docProjectName : String
docProjectName =
    "MyProject"


docOrga1 : Organization
docOrga1 =
    Organization "00000000-0000-0000-0000-000000000001" "orga-1" "Orga 1" Plan.docSample "logo" Nothing Nothing Nothing


docOrga2 : Organization
docOrga2 =
    Organization "00000000-0000-0000-0000-000000000002" "orga-2" "Orga 2" Plan.docSample "logo" Nothing Nothing Nothing


docOrga3 : Organization
docOrga3 =
    Organization "00000000-0000-0000-0000-000000000003" "orga-3" "Orga 3" Plan.docSample "logo" Nothing Nothing Nothing


docOrganizations : List Organization
docOrganizations =
    [ docOrga1, docOrga2, docOrga3 ]


docProjects : List ProjectInfo
docProjects =
    [ ProjectInfo (Just docOrga2) "00000000-0000-0000-0000-000000000001" "prj1" "Projet 1" Nothing ProjectStorage.Remote ProjectVisibility.None 2 1 0 0 0 0 0 0 0 0 Time.zero Time.zero
    , ProjectInfo (Just docOrga3) "00000000-0000-0000-0000-000000000002" "prj2" "Projet 2" Nothing ProjectStorage.Remote ProjectVisibility.None 2 1 0 0 0 0 0 0 0 0 Time.zero Time.zero
    , ProjectInfo (Just docOrga3) "00000000-0000-0000-0000-000000000003" "prj3" "Projet 3" Nothing ProjectStorage.Remote ProjectVisibility.None 2 1 0 0 0 0 0 0 0 0 Time.zero Time.zero
    ]


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "ProjectSaveDialogBody"
        |> Chapter.renderStatefulComponentList
            [ component "signIn" (\_ -> signIn docCloseModal docLoginUrl docTitleId)
            , component "selectSave" (selectSave updateDocState docCloseModal docSave docTitleId docOrganizations docProjects docProjectName)
            ]
