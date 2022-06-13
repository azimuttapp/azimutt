module PagesComponents.Projects.Id_.Components.AmlSlidebar exposing (Model, update, view)

import Array exposing (Array)
import Components.Atoms.Icon as Icon
import Components.Molecules.Editor as Editor
import Conf
import DataSources.AmlParser.AmlAdapter as AmlAdapter exposing (AmlSchema, AmlSchemaError)
import DataSources.AmlParser.AmlParser as AmlParser
import Dict
import Html exposing (Html, button, div, h3, label, option, p, select, text)
import Html.Attributes exposing (class, disabled, for, id, name, selected, value)
import Html.Events exposing (onClick, onInput)
import Libs.Bool as Bool
import Libs.Html exposing (extLink)
import Libs.Html.Attributes exposing (css)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw exposing (focus)
import Libs.Task as T
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId
import Models.Project.SourceKind as SourceKind
import PagesComponents.Projects.Id_.Models exposing (AmlSidebar, AmlSidebarMsg(..), Msg(..), simplePrompt)
import PagesComponents.Projects.Id_.Models.CursorMode exposing (CursorMode)
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import Ports
import Services.Lenses exposing (mapAmlSidebarM, mapErdM, mapSourcesL, setAmlSidebar, setContent, setErrors, setRelations, setSelected, setTables)
import Track


type alias Model x =
    { x
        | erd : Maybe Erd
        , cursorMode : CursorMode
        , amlSidebar : Maybe AmlSidebar
    }


init : Model x -> AmlSidebar
init model =
    { id = Conf.ids.amlSidebarDialog
    , selected = model.erd |> Maybe.andThen (.sources >> List.filter .enabled >> List.find (.kind >> SourceKind.isUser) >> Maybe.map .id)
    , errors = []
    }


update : AmlSidebarMsg -> Model x -> ( Model x, Cmd Msg )
update msg model =
    case msg of
        AOpen ->
            ( model |> setAmlSidebar (Just (init model)), Ports.track Track.openUserSourceUpdate )

        AClose ->
            ( model |> setAmlSidebar Nothing, Cmd.none )

        AToggle ->
            ( model, T.send (AmlSidebarMsg (Bool.cond (model.amlSidebar == Nothing) AOpen AClose)) )

        AChangeSource source ->
            ( model |> mapAmlSidebarM (setSelected source), Cmd.none )

        AUpdateSource id value ->
            let
                content : Array String
                content =
                    value |> String.split "\n" |> Array.fromList

                parsed : AmlSchema
                parsed =
                    value ++ "\n" |> AmlParser.parse |> AmlAdapter.adapt id
            in
            if List.isEmpty parsed.errors then
                ( model
                    |> mapErdM
                        (Erd.mapSource
                            id
                            (setContent content
                                >> setTables parsed.tables
                                >> setRelations parsed.relations
                            )
                        )
                    |> mapAmlSidebarM (setErrors parsed.errors)
                  -- FIXME: problem with show/hide and table name change
                , T.send (ShowTables (parsed.tables |> Dict.keys) Nothing)
                )

            else
                ( model |> mapErdM (mapSourcesL .id id (setContent content)) |> mapAmlSidebarM (setErrors parsed.errors), Cmd.none )


view : Erd -> AmlSidebar -> Html Msg
view erd model =
    let
        userSources : List Source
        userSources =
            erd.sources |> List.filter (.kind >> SourceKind.isUser)

        selectedSource : Maybe Source
        selectedSource =
            model.selected |> Maybe.andThen (\id -> userSources |> List.find (\s -> s.id == id))
    in
    div []
        [ viewHeading
        , div [ class "px-3 py-2" ]
            [ viewChooseSource selectedSource userSources
            , selectedSource |> Maybe.mapOrElse (viewSourceEditor model) (div [] [])
            ]
        ]


viewHeading : Html Msg
viewHeading =
    div [ class "px-6 py-5 border-b border-gray-200" ]
        [ div [ class "flex space-x-3" ]
            [ div [ class "flex-1" ]
                [ h3 [ class "text-lg leading-6 font-medium text-gray-900" ] [ text "Update schema" ]
                ]
            , div [ class "flex-shrink-0 self-center flex" ]
                [ button [ onClick (AmlSidebarMsg AClose), class "-m-2 p-2 rounded-full flex items-center text-gray-400 hover:text-gray-600" ] [ Icon.solid Icon.X "" ]
                ]
            ]
        , p [ class "mt-1 text-sm text-gray-500" ] [ text "In Azimutt your schema is the union of enabled sources. Create or update one with AML syntax to extend it." ]
        ]


viewChooseSource : Maybe Source -> List Source -> Html Msg
viewChooseSource selectedSource userSources =
    let
        selectId : HtmlId
        selectId =
            "sources"
    in
    div []
        [ label [ for selectId, class "block text-sm font-medium text-gray-700 sr-only" ] [ text "Sources" ]
        , div [ class "mt-1 flex rounded-md shadow-sm" ]
            [ div [ class "relative flex items-stretch flex-grow focus-within:z-10" ]
                [ select [ id selectId, name selectId, onInput (SourceId.fromString >> AChangeSource >> AmlSidebarMsg), disabled (List.isEmpty userSources), css [ "block w-full text-sm border-gray-300 rounded-none rounded-l-md", focus [ "ring-indigo-500 border-indigo-500" ], Tw.disabled [ "bg-slate-50 text-slate-500 shadow-none" ] ] ]
                    (option [] [ text "-- select a source to edit" ]
                        :: (userSources |> List.map (\s -> option [ selected (Maybe.map .id selectedSource == Just s.id), value (SourceId.toString s.id) ] [ text s.name ]))
                    )
                ]
            , button [ onClick (simplePrompt "New source name" CreateUserSource), class "-ml-px relative inline-flex items-center space-x-2 px-4 py-2 border border-gray-300 text-sm font-medium rounded-r-md text-gray-700 bg-gray-50 hover:bg-gray-100 focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500" ]
                [ text "Create source"
                ]
            ]
        ]


viewSourceEditor : AmlSidebar -> Source -> Html Msg
viewSourceEditor model source =
    let
        content : String
        content =
            source.content |> Array.toList |> String.join "\n"
    in
    div [ class "mt-3" ]
        [ Editor.basic "source-editor" content (AUpdateSource source.id >> AmlSidebarMsg) """Write your schema using AML syntax. Ex:

users
  id uuid pk
  first_name varchar(128)
  last_name varchar(128)
  email varchar(128) nullable

credentials
  user_id pk fk users.id
  login varchar(128) unique
  password varchar(128) nullable
  role varchar(10)=guest
  created_at timestamp"""
        , viewErrors model.errors
        , viewHelp
        ]


viewErrors : List AmlSchemaError -> Html msg
viewErrors errors =
    div [] (errors |> List.map (\err -> p [ class "mt-2 text-sm text-red-600" ] [ text err ]))


viewHelp : Html msg
viewHelp =
    p [ class "mt-2 text-sm text-gray-500" ]
        [ text "Write your schema using "
        , extLink "https://azimutt.app/blog/aml-a-language-to-define-your-database-schema" [ class "link" ] [ text "AML syntax" ]
        , text "."
        ]
