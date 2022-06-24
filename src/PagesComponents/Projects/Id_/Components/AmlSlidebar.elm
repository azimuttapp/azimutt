module PagesComponents.Projects.Id_.Components.AmlSlidebar exposing (Model, setSource, update, view)

import Array exposing (Array)
import Components.Atoms.Icon as Icon
import Components.Molecules.Editor as Editor
import Conf
import DataSources.AmlParser.AmlAdapter as AmlAdapter exposing (AmlSchema, AmlSchemaError)
import DataSources.AmlParser.AmlParser as AmlParser
import Dict exposing (Dict)
import Html exposing (Html, button, div, h3, label, option, p, select, text)
import Html.Attributes exposing (class, disabled, for, id, name, selected, value)
import Html.Events exposing (onClick, onInput)
import Libs.Basics exposing (tupled)
import Libs.Bool as Bool
import Libs.Html exposing (extLink)
import Libs.Html.Attributes exposing (css)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position as Position
import Libs.Tailwind as Tw exposing (focus)
import Libs.Task as T
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.SourceKind as SourceKind
import Models.Project.SourceLine exposing (SourceLine)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models exposing (AmlSidebar, AmlSidebarMsg(..), Msg(..), simplePrompt)
import PagesComponents.Projects.Id_.Models.CursorMode exposing (CursorMode)
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdTableProps exposing (ErdTableProps)
import PagesComponents.Projects.Id_.Models.PositionHint exposing (PositionHint(..))
import PagesComponents.Projects.Id_.Models.ShowColumns as ShowColumns
import Ports
import Services.Lenses exposing (mapAmlSidebarM, mapErdM, setAmlSidebar, setContent, setErrors, setInput, setRelations, setSelected, setTables, setUpdatedAt)
import Time
import Track


type alias Model x =
    { x
        | erd : Maybe Erd
        , cursorMode : CursorMode
        , amlSidebar : Maybe AmlSidebar
    }



-- INIT


init : Model x -> AmlSidebar
init model =
    let
        source : Maybe Source
        source =
            model.erd |> Maybe.andThen (.sources >> List.filter .enabled >> List.find (.kind >> SourceKind.isUser))
    in
    { id = Conf.ids.amlSidebarDialog
    , selected = source |> Maybe.map .id
    , input = source |> Maybe.mapOrElse contentStr ""
    , errors = []
    }



-- UPDATE


update : Time.Posix -> AmlSidebarMsg -> Model x -> ( Model x, Cmd Msg )
update now msg model =
    case msg of
        AOpen ->
            ( model |> setAmlSidebar (Just (init model)), Ports.track Track.openUserSourceUpdate )

        AClose ->
            ( model |> setAmlSidebar Nothing, Cmd.none )

        AToggle ->
            ( model, T.send (AmlSidebarMsg (Bool.cond (model.amlSidebar == Nothing) AOpen AClose)) )

        AChangeSource source ->
            ( model |> mapAmlSidebarM (setSelected source >> setInput (model.erd |> Maybe.andThen (.sources >> List.find (\s -> source == Just s.id)) |> Maybe.mapOrElse contentStr "")), Cmd.none )

        AUpdateSource id value ->
            updateSource now id value model


updateSource : Time.Posix -> SourceId -> String -> Model x -> ( Model x, Cmd Msg )
updateSource now sourceId input model =
    let
        currentTables : Dict TableId Table
        currentTables =
            model.erd |> Maybe.andThen (.sources >> List.find (\s -> s.id == sourceId)) |> Maybe.mapOrElse .tables Dict.empty

        tableProps : Dict TableId ErdTableProps
        tableProps =
            model.erd |> Maybe.mapOrElse .tableProps Dict.empty

        content : Array String
        content =
            contentSplit input

        parsed : AmlSchema
        parsed =
            String.trim input ++ "\n" |> AmlParser.parse |> AmlAdapter.adapt sourceId

        ( removed, bothPresent, added ) =
            List.diff .id (currentTables |> Dict.values) (parsed.tables |> Dict.values)

        toHide : List TableId
        toHide =
            removed |> List.map .id

        updated : List ( TableId, List ColumnName )
        updated =
            bothPresent |> List.filter (\( t1, t2 ) -> t1 /= t2) |> List.map (\( _, t ) -> ( t.id, t.columns |> Dict.keys ))

        toShow : List ( TableId, Maybe PositionHint )
        toShow =
            added
                |> associateTables removed
                |> List.map
                    (\( table, previous ) ->
                        ( table.id
                        , previous
                            |> Maybe.andThen (\t -> tableProps |> Dict.get t.id)
                            |> Maybe.map .position
                            |> Maybe.filter (\p -> p /= Position.zero)
                            |> Maybe.map PlaceAt
                        )
                    )

        -- FIXME: migrate virtual relations to aml
        -- TODO: better select with enabled indicator and disabled non user sources
    in
    if List.isEmpty parsed.errors then
        ( model |> mapErdM (mapErdSource now sourceId content parsed) |> mapAmlSidebarM (setInput input >> setErrors [])
        , Cmd.batch
            (List.map T.send
                ((toShow |> List.map (tupled ShowTable))
                    ++ (toHide |> List.map HideTable)
                    ++ (updated |> List.map (\( id, cols ) -> ShowColumns id (ShowColumns.List cols)))
                )
            )
        )

    else
        ( model |> mapAmlSidebarM (setInput input >> setErrors parsed.errors), Cmd.none )


associateTables : List Table -> List Table -> List ( Table, Maybe Table )
associateTables removed added =
    if List.length added == 1 && List.length removed == 1 then
        added |> List.map (\t -> ( t, removed |> List.head ))

    else
        added |> List.map (\table -> ( table, Nothing ))


mapErdSource : Time.Posix -> SourceId -> Array SourceLine -> AmlSchema -> Erd -> Erd
mapErdSource now sourceId content parsed erd =
    erd |> Erd.mapSource sourceId (setContent content >> setTables parsed.tables >> setRelations parsed.relations >> setUpdatedAt now)


setSource : Maybe Source -> AmlSidebar -> AmlSidebar
setSource source model =
    model |> setSelected (source |> Maybe.map .id) |> setInput (source |> Maybe.mapOrElse contentStr "")


contentSplit : String -> Array String
contentSplit input =
    input |> String.split "\n" |> Array.fromList


contentStr : Source -> String
contentStr source =
    source.content |> Array.toList |> String.join "\n"



-- VIEW


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
        , p [ class "mt-1 text-sm text-gray-500" ]
            [ text "In Azimutt your schema is the union of enabled sources. Create or update one with "
            , extLink "https://azimutt.app/blog/aml-a-language-to-define-your-database-schema" [ class "link" ] [ text "AML syntax" ]
            , text " to extend it."
            ]
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
                    (option [] [ text (Bool.cond (List.isEmpty userSources) "-- no edit source, create one →" "-- select a source to edit") ]
                        :: (userSources |> List.map (\s -> option [ selected (Maybe.map .id selectedSource == Just s.id), value (SourceId.toString s.id) ] [ text s.name ]))
                    )
                ]
            , button [ onClick (simplePrompt "New source name" CreateUserSource), class "-ml-px relative inline-flex items-center space-x-2 px-4 py-2 border border-gray-300 text-sm font-medium rounded-r-md text-gray-700 bg-gray-50 hover:bg-gray-100 focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500" ]
                [ text "New source"
                ]
            ]
        ]


viewSourceEditor : AmlSidebar -> Source -> Html Msg
viewSourceEditor model source =
    div [ class "mt-3" ]
        [ Editor.basic "source-editor" model.input (AUpdateSource source.id >> AmlSidebarMsg) """Write your schema using AML syntax

Ex:

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
  created_at timestamp""" 30 (List.nonEmpty model.errors)
        , viewErrors model.errors
        , viewHelp
        ]


viewErrors : List AmlSchemaError -> Html msg
viewErrors errors =
    div []
        (errors
            |> List.map (\err -> err.problem ++ " at line " ++ String.fromInt err.row ++ ", column " ++ String.fromInt err.col)
            |> List.unique
            |> List.map
                (\err ->
                    p [ class "mt-2 text-sm text-red-600" ]
                        [ text err
                        ]
                )
        )


viewHelp : Html msg
viewHelp =
    p [ class "mt-2 text-sm text-gray-500" ]
        [ text "Write your schema using "
        , extLink "https://azimutt.app/blog/aml-a-language-to-define-your-database-schema" [ class "link" ] [ text "AML syntax" ]
        , text "."
        ]
