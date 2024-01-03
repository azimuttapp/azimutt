module Components.Slices.NewLayoutBody exposing (DocState, Mode(..), Model, Msg, SharedDocState, doc, docInit, init, update, view)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Slices.ProPlan as ProPlan
import Conf
import ElmBook
import ElmBook.Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, div, h3, input, p, text)
import Html.Attributes exposing (autofocus, class, disabled, id, name, placeholder, tabindex, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Html exposing (bText, sendTweet)
import Libs.Html.Attributes exposing (css)
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw exposing (focus, sm)
import Models.Organization exposing (Organization)
import Models.Project.LayoutName exposing (LayoutName)
import Models.ProjectRef as ProjectRef exposing (ProjectRef)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)


type alias Model =
    { id : HtmlId
    , name : LayoutName
    , mode : Mode
    }


type Mode
    = Create
    | Duplicate LayoutName
    | Rename LayoutName


type Msg
    = UpdateLayoutName LayoutName


init : HtmlId -> Mode -> Model
init id mode =
    { id = id, name = mode |> foldMode "" identity identity, mode = mode }


update : Msg -> Model -> ( Model, Extra msg )
update msg model =
    case msg of
        UpdateLayoutName value ->
            ( { model | name = value }, Extra.none )


view : (Msg -> msg) -> (LayoutName -> msg) -> msg -> HtmlId -> List LayoutName -> ProjectRef -> Model -> Html msg
view wrap onSubmit onCancel titleId layouts project model =
    let
        inputId : HtmlId
        inputId =
            model.id ++ "-input"

        alreadyExists : Bool
        alreadyExists =
            layouts |> List.any (\l -> l == model.name)
    in
    div [ class "max-w-2xl" ]
        [ div [ css [ "px-6 pt-6", sm [ "flex items-start" ] ] ]
            [ div [ css [ "mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-primary-100", sm [ "mx-0 h-10 w-10" ] ] ]
                [ Icon.outline Template "text-primary-600"
                ]
            , div [ css [ "mt-3 text-center", sm [ "mt-0 ml-4 text-left" ] ] ]
                [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ]
                    [ text (model.mode |> foldMode "New empty layout" (\name -> "Duplicate layout '" ++ name ++ "'") (\name -> "Rename layout '" ++ name ++ "'")) ]
                , if project.organization.plan.layouts |> Maybe.any (\l -> List.length layouts >= l) then
                    div [ class "mt-2" ] [ ProPlan.layoutsWarning project ]

                  else
                    div [] []
                , div [ class "mt-2" ]
                    [ div [ class "mt-1" ]
                        [ input [ type_ "text", name inputId, id inputId, placeholder "Layout name (use / to create folders)", value model.name, onInput (UpdateLayoutName >> wrap), autofocus True, css [ "shadow-sm block w-full border-gray-300 rounded-md", focus [ "ring-indigo-500 border-indigo-500" ], sm [ "text-sm" ] ] ] []
                        ]
                    , if alreadyExists && model.mode /= Duplicate model.name && model.mode /= Rename model.name then
                        p [ class "mt-1 text-sm text-red-600" ] [ text ("Layout '" ++ model.name ++ "' already exists 😥") ]

                      else
                        p [ class "mt-1 text-sm text-gray-400" ] [ text "Use '/' in the name to create folders when several layouts have the same parents." ]
                    , p [ class "mt-2 text-sm text-gray-500" ]
                        [ text "Do you like Azimutt? Consider "
                        , sendTweet Conf.constants.cheeringTweet [ tabindex -1, class "link" ] [ text "sending us a tweet" ]
                        , text ", it will "
                        , bText "keep our motivation high"
                        , text " 🥰"
                        ]
                    ]
                ]
            ]
        , div [ class "px-6 py-3 mt-6 flex items-center flex-row-reverse bg-gray-50 rounded-b-lg" ]
            [ Button.primary3 Tw.primary
                [ onClick (model.name |> onSubmit), disabled alreadyExists, css [ "w-full text-base", sm [ "ml-3 w-auto text-sm" ] ] ]
                [ text (model.mode |> foldMode "Create layout" (\name -> "Duplicate '" ++ name ++ "'") (\name -> "Rename '" ++ name ++ "'")) ]
            , Button.white3 Tw.gray [ onClick onCancel, css [ "mt-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text "Cancel" ]
            ]
        ]


foldMode : a -> (LayoutName -> a) -> (LayoutName -> a) -> Mode -> a
foldMode onCreate onDuplicate onRename mode =
    case mode of
        Create ->
            onCreate

        Duplicate name ->
            onDuplicate name

        Rename name ->
            onRename name



-- DOCUMENTATION


type alias SharedDocState x =
    { x | newLayoutDocState : DocState }


type alias DocState =
    Model


docInit : DocState
docInit =
    { id = "modal-id", name = "", mode = Create }


updateDocState : Msg -> ElmBook.Msg (SharedDocState x)
updateDocState msg =
    ElmBook.Actions.updateState (\s -> { s | newLayoutDocState = s.newLayoutDocState |> update msg |> Tuple.first })


sampleOnCreate : LayoutName -> ElmBook.Msg state
sampleOnCreate name =
    ElmBook.Actions.logActionWithString "onCreate" name


sampleOnCancel : ElmBook.Msg state
sampleOnCancel =
    ElmBook.Actions.logAction "onCancel"


sampleTitleId : String
sampleTitleId =
    "modal-id-title"


sampleLayout : LayoutName
sampleLayout =
    "layout"


sampleLayouts1 : List LayoutName
sampleLayouts1 =
    [ sampleLayout ]


sampleLayouts3 : List LayoutName
sampleLayouts3 =
    [ sampleLayout, "initial layout", "exists" ]


component : String -> (DocState -> Html msg) -> ( String, SharedDocState x -> Html msg )
component name render =
    ( name, \{ newLayoutDocState } -> render newLayoutDocState )


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "NewLayoutBody"
        |> Chapter.renderStatefulComponentList
            [ component "create" (\m -> view updateDocState sampleOnCreate sampleOnCancel sampleTitleId sampleLayouts1 ProjectRef.zero m)
            , component "duplicate" (\m -> view updateDocState sampleOnCreate sampleOnCancel sampleTitleId sampleLayouts1 ProjectRef.zero { m | mode = Duplicate sampleLayout })
            , component "rename" (\m -> view updateDocState sampleOnCreate sampleOnCancel sampleTitleId sampleLayouts1 ProjectRef.zero { m | mode = Rename sampleLayout })
            , component "create limit" (\m -> view updateDocState sampleOnCreate sampleOnCancel sampleTitleId sampleLayouts3 ProjectRef.zero m)
            , component "duplicate limit" (\m -> view updateDocState sampleOnCreate sampleOnCancel sampleTitleId sampleLayouts3 ProjectRef.zero { m | mode = Duplicate sampleLayout })
            ]
