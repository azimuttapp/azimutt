module Components.Molecules.Editor exposing (DocState, Highlight, Model, Msg(..), Scroll, SharedDocState, aml, basic, doc, docInit, init, json, sql, update)

import Dict exposing (Dict)
import ElmBook
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Attribute, Html, div, text, textarea)
import Html.Attributes exposing (class, classList, id, name, placeholder, rows, spellcheck, style, value)
import Html.Events exposing (onBlur, onInput)
import Html.Lazy as Lazy
import Json.Decode as Json
import Libs.Dict as Dict
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Result as Result
import Libs.Tailwind exposing (TwClass)
import Parser
import Services.Lenses exposing (setContent, setScroll)
import SyntaxHighlight as SH



-- https://package.elm-lang.org/packages/jxxcarlson/elm-editor/latest


basic : String -> String -> (String -> msg) -> msg -> String -> Int -> Bool -> Html msg
basic fieldId fieldValue fieldUpdate updateEnd fieldPlaceholder lines hasErrors =
    let
        colors : TwClass
        colors =
            if hasErrors then
                "text-red-900 placeholder-red-300 border-red-300 focus:border-red-500 focus:ring-red-500"

            else
                "border-gray-300 focus:border-indigo-500 focus:ring-indigo-500"
    in
    textarea
        [ rows lines
        , name fieldId
        , id fieldId
        , value fieldValue
        , onInput fieldUpdate
        , onBlur updateEnd
        , placeholder fieldPlaceholder
        , spellcheck False
        , class ("block w-full shadow-sm rounded-md sm:text-sm " ++ colors)
        ]
        []


type alias Model =
    { content : String, scroll : Scroll, highlights : List Highlight }


type alias Scroll =
    { top : Float, left : Float }


type alias Highlight =
    { mode : Maybe SH.Highlight, start : Int, end : Int }


init : String -> Model
init content =
    { content = content, scroll = { top = 0, left = 0 }, highlights = [] }


type Msg
    = SetContent String
    | OnScroll Scroll


update : Msg -> Model -> Model
update msg model =
    case msg of
        SetContent content ->
            model |> setContent content

        OnScroll scroll ->
            model |> setScroll scroll


sql : (Msg -> msg) -> HtmlId -> Model -> Html msg
sql wrap inputId model =
    viewEditor wrap inputId (parsers |> Dict.getOrElse "Sql" SH.noLang) True (Just 1) model


aml : (Msg -> msg) -> HtmlId -> Model -> Html msg
aml wrap inputId model =
    viewEditor wrap inputId (parsers |> Dict.getOrElse "Aml" SH.noLang) True (Just 1) model


json : (Msg -> msg) -> HtmlId -> Model -> Html msg
json wrap inputId model =
    viewEditor wrap inputId (parsers |> Dict.getOrElse "Json" SH.noLang) True (Just 1) model



-- INTERNALS


type alias LangName =
    String


type alias LangParser =
    String -> Result (List Parser.DeadEnd) SH.HCode


parsers : Dict LangName LangParser
parsers =
    [ ( "Elm", SH.elm )
    , ( "Xml", SH.xml )
    , ( "Javascript", SH.javascript )
    , ( "Css", SH.css )
    , ( "Python", SH.python )
    , ( "Sql", SH.sql )
    , ( "Json", SH.json )
    , ( "Nix", SH.nix )
    , ( "NoLang", SH.noLang )
    ]
        |> Dict.fromList


viewEditor : (Msg -> msg) -> HtmlId -> LangParser -> Bool -> Maybe Int -> Model -> Html msg
viewEditor wrap inputId parser showLineCount lineCount model =
    -- needs CSS in backend/priv/static/elm/styles.css to work properly
    div [ class "elmsh container rounded-md border border-gray-300" ]
        [ div
            [ class "view-container min-w-full text-sm"
            , style "transform" ("translate(" ++ String.fromFloat -model.scroll.left ++ "px, " ++ String.fromFloat -model.scroll.top ++ "px)")
            , style "will-change" "transform"
            ]
            [ Lazy.lazy4 viewContent parser lineCount model.content model.highlights
            ]
        , textarea
            [ name inputId
            , id inputId
            , value model.content
            , onInput (SetContent >> wrap)
            , spellcheck False
            , onScroll (OnScroll >> wrap)
            , class "textarea min-w-full text-sm"
            , classList [ ( "textarea-lc", showLineCount ) ]
            ]
            []
        ]


viewContent : (String -> Result (List Parser.DeadEnd) SH.HCode) -> Maybe Int -> String -> List Highlight -> Html msg
viewContent parser lineCountStart content highlights =
    parser content
        |> Result.map (\code -> highlights |> List.foldl (\h -> SH.highlightLines h.mode h.start h.end) code)
        |> Result.map (SH.toBlockHtml lineCountStart)
        |> Result.mapError Parser.deadEndsToString
        |> Result.fold text identity


onScroll : (Scroll -> msg) -> Attribute msg
onScroll msg =
    Html.Events.on "scroll"
        (Json.map2 Scroll
            (Json.at [ "target", "scrollTop" ] Json.float)
            (Json.at [ "target", "scrollLeft" ] Json.float)
            |> Json.map msg
        )



-- DOCUMENTATION


type alias SharedDocState x =
    { x | editorDocState : DocState }


type alias DocState =
    { basic : String, sql : Model, aml : Model, json : Model }


docInit : DocState
docInit =
    { basic = "Hello, "
    , sql = init """SELECT * FROM users;
"""
    , aml = init """users | this table store all the application users, it's very useful to know who is using the application and what they did, look at `created_by` columns, they should link to this table
  id uuid
  name varchar
  email varchar
  created_at timestamp

roles
  id int
  name varchar
  created_at timestamp
  created_by uuid fk users.id

user_roles
  user_id uuid fk users.id
  role_id int fk roles.id
"""
    , json = init """{
  "id": 1,
  "name": "Loïc",
  "tags": []
}
"""
    }


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "Editor"
        |> Chapter.renderStatefulComponentList
            [ ( "SQL editor", \{ editorDocState } -> div [ style "height" "150px" ] [ sql (\m -> docStateUpdate (\s -> { s | sql = update m editorDocState.sql })) "sql-editor" editorDocState.sql ] )
            , ( "AML editor", \{ editorDocState } -> div [ style "height" "150px" ] [ aml (\m -> docStateUpdate (\s -> { s | aml = update m editorDocState.aml })) "aml-editor" editorDocState.aml ] )
            , ( "JSON editor", \{ editorDocState } -> div [ style "height" "150px" ] [ json (\m -> docStateUpdate (\s -> { s | json = update m editorDocState.json })) "json-editor" editorDocState.json ] )
            , ( "basic", \{ editorDocState } -> basic "basic" editorDocState.basic (\v -> docStateUpdate (\s -> { s | basic = v })) (logAction "updateEnd") "placeholder value" 3 False )
            , ( "basic with error", \{ editorDocState } -> basic "basic" editorDocState.basic (\v -> docStateUpdate (\s -> { s | basic = v })) (logAction "updateEnd") "placeholder value" 3 True )
            ]


docStateUpdate : (DocState -> DocState) -> ElmBook.Msg (SharedDocState x)
docStateUpdate f =
    Actions.updateState (\s -> { s | editorDocState = f s.editorDocState })
