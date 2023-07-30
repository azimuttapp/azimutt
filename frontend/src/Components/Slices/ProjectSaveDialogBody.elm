module Components.Slices.ProjectSaveDialogBody exposing (DocState, Model, Msg(..), SharedDocState, doc, docInit, init, selectSave, signIn, update)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon
import Components.Atoms.Link as Link
import Components.Molecules.FormLabel as FormLabel
import Components.Molecules.InputText as InputText
import Components.Molecules.Select as Select
import ElmBook
import ElmBook.Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, div, h3, input, label, p, span, text)
import Html.Attributes exposing (checked, class, classList, disabled, href, id, name, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Bool as Bool
import Libs.Html exposing (bText)
import Libs.Html.Attributes exposing (ariaDescribedby, ariaHidden, ariaLabelledby, css)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Libs.Tailwind as Tw
import Models.Organization exposing (Organization)
import Models.Plan as Plan exposing (Plan)
import Models.Project.ProjectName exposing (ProjectName)
import Models.Project.ProjectStorage as ProjectStorage exposing (ProjectStorage)


type alias Model =
    { id : HtmlId
    , name : ProjectName
    , organization : Maybe Organization
    , storage : ProjectStorage
    }


type Msg
    = UpdateProjectName ProjectName
    | UpdateOrganization (Maybe Organization)
    | UpdateStorage ProjectStorage


init : HtmlId -> ProjectName -> Maybe Organization -> Model
init id name organization =
    { id = id, name = name, organization = organization, storage = ProjectStorage.Remote }


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        UpdateProjectName value ->
            ( { model | name = value }, Cmd.none )

        UpdateOrganization value ->
            ( { model | organization = value }, Cmd.none )

        UpdateStorage value ->
            ( { model | storage = value }, Cmd.none )


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


selectSave : (Msg -> msg) -> msg -> (ProjectName -> Organization -> ProjectStorage -> msg) -> HtmlId -> List Organization -> ProjectName -> Model -> Html msg
selectSave wrap modalClose save titleId organizations projectName model =
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
                                ({ value = "", label = "-- choose an organization" } :: (organizations |> List.sortBy .name |> List.map (\o -> { value = o.id, label = o.name })))
                                (model.organization |> Maybe.mapOrElse .id "")
                                (\orgId -> organizations |> List.findBy .id orgId |> UpdateOrganization |> wrap)
                        )
                    , FormLabel.bold "mt-3"
                        (model.id ++ "-storage")
                        "How do you want to save?"
                        (\fieldId -> radioCards fieldId (stringToStorage >> UpdateStorage >> wrap) model.storage)
                    ]
                ]
            ]
        , div [ class "mt-5 sm:mt-6 sm:grid sm:grid-cols-2 sm:gap-3 sm:grid-flow-row-dense" ]
            [ Button.white3 Tw.default [ onClick modalClose ] [ text "Stay in draft" ]
            , Maybe.map2 (\name orga -> save name orga model.storage) (String.nonEmptyMaybe model.name) model.organization
                |> Maybe.map (\msg -> Button.primary3 Tw.primary [ onClick msg, class "w-full" ] [ text "Create project" ])
                |> Maybe.withDefault (Button.primary3 Tw.primary [ disabled True, class "w-full" ] [ text "Create project" ])
            ]
        ]


type alias Card =
    { value : String, description : String, notes : String }


radioCards : HtmlId -> (String -> msg) -> ProjectStorage -> Html msg
radioCards fieldId fieldChange fieldValue =
    div [ class "grid grid-cols-1 gap-y-2" ]
        ([ Card (storageToString ProjectStorage.Remote) "Save in Azimutt and share it with other people" "Free up to 3 people"
         , Card (storageToString ProjectStorage.Local) "Keep your project in your browser" "Free forever"
         ]
            |> List.indexedMap (radioCardLabel fieldId (storageToString fieldValue) fieldChange)
        )


radioCardLabel : String -> String -> (String -> msg) -> Int -> Card -> Html msg
radioCardLabel htmlId fieldValue fieldChange index card =
    let
        cardId : HtmlId
        cardId =
            htmlId ++ "-" ++ String.fromInt index

        ( isChecked, isActive ) =
            ( card.value == fieldValue, card.value == fieldValue )
    in
    label [ css [ "relative flex cursor-pointer rounded-lg border bg-white p-4 shadow-sm focus:outline-none", Bool.cond isChecked "border-transparent" "border-gray-300" ], classList [ ( "border-indigo-500 ring-2 ring-indigo-500", isActive ) ] ]
        [ input [ type_ "radio", name htmlId, value card.value, onInput fieldChange, checked isChecked, class "sr-only", ariaLabelledby (cardId ++ "-label"), ariaDescribedby (cardId ++ "-description " ++ cardId ++ "-notes") ] []
        , span [ class "flex flex-1" ]
            [ span [ class "flex flex-col" ]
                [ span [ id (cardId ++ "-label"), class "block text-sm font-medium text-gray-900" ] [ text card.value ]
                , span [ id (cardId ++ "-description"), class "mt-1 flex items-center text-sm text-gray-500" ] [ text card.description ]
                , span [ id (cardId ++ "-notes"), class "mt-6 text-sm font-medium text-gray-900" ] [ text card.notes ]
                ]
            ]
        , Icon.solid Icon.CheckCircle (Bool.cond isChecked "text-indigo-600" "invisible")
        , span [ css [ "pointer-events-none absolute -inset-px rounded-lg border-2", Bool.cond isChecked "border-indigo-500" "border-transparent", Bool.cond isActive "border" "border-2" ], ariaHidden True ] []
        ]


storageToString : ProjectStorage -> String
storageToString storage =
    case storage of
        ProjectStorage.Local ->
            "Local"

        ProjectStorage.Remote ->
            "Remote"


stringToStorage : String -> ProjectStorage
stringToStorage value =
    case value of
        "Local" ->
            ProjectStorage.Local

        "Remote" ->
            ProjectStorage.Remote

        _ ->
            ProjectStorage.Remote



-- DOCUMENTATION


type alias SharedDocState x =
    { x | projectSaveDocState : DocState }


type alias DocState =
    Model


docInit : DocState
docInit =
    { id = "modal-id", name = "MyProject", organization = Nothing, storage = ProjectStorage.Remote }


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
    ElmBook.Actions.logAction ("save: " ++ name ++ ", " ++ orga.name ++ ", " ++ storageToString storage)


docLoginUrl : String
docLoginUrl =
    "#login"


docTitleId : String
docTitleId =
    "modal-id-title"


docProjectName : String
docProjectName =
    "MyProject"


docOrganizations : List Organization
docOrganizations =
    [ Organization "00000000-0000-0000-0000-000000000001" "orga-1" "Orga 1" Plan.free "logo" Nothing Nothing Nothing
    , Organization "00000000-0000-0000-0000-000000000002" "orga-2" "Orga 2" Plan.free "logo" Nothing Nothing Nothing
    , Organization "00000000-0000-0000-0000-000000000003" "orga-3" "Orga 3" Plan.free "logo" Nothing Nothing Nothing
    ]


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "ProjectSaveDialogBody"
        |> Chapter.renderStatefulComponentList
            [ component "signIn" (\_ -> signIn docCloseModal docLoginUrl docTitleId)
            , component "selectSave" (selectSave updateDocState docCloseModal docSave docTitleId docOrganizations docProjectName)
            ]
