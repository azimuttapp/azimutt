module PagesComponents.Projects.Id_.Components.AmlSidebar exposing (Model, init, setSource, update, view)

import Array exposing (Array)
import Components.Atoms.Icon as Icon
import Components.Molecules.Editor as Editor
import Conf
import DataSources.AmlMiner.AmlAdapter as AmlAdapter
import DataSources.AmlMiner.AmlParser as AmlParser
import Dict
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
import Libs.Tailwind as Tw exposing (focus)
import Libs.Task as T
import Models.Position as Position
import Models.Project.ColumnId as ColumnId
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId
import Models.Project.SourceKind as SourceKind
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models exposing (AmlSidebar, AmlSidebarMsg(..), Msg(..), simplePrompt)
import PagesComponents.Projects.Id_.Models.CursorMode exposing (CursorMode)
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Projects.Id_.Models.PositionHint exposing (PositionHint(..))
import PagesComponents.Projects.Id_.Models.ShowColumns as ShowColumns
import Ports
import Services.Lenses exposing (mapAmlSidebarM, mapErdM, setAmlSidebar, setContent, setErrors, setSelected, setUpdatedAt)
import Time
import Track


type alias Model x =
    { x
        | erd : Maybe Erd
        , cursorMode : CursorMode
        , amlSidebar : Maybe AmlSidebar
    }



-- INIT


init : Maybe Erd -> AmlSidebar
init erd =
    let
        source : Maybe Source
        source =
            erd |> Maybe.andThen (.sources >> List.filter .enabled >> List.find (.kind >> SourceKind.isUser))
    in
    { id = Conf.ids.amlSidebarDialog
    , selected = source |> Maybe.map .id
    , errors = []
    }



-- UPDATE


update : Time.Posix -> AmlSidebarMsg -> Model x -> ( Model x, Cmd Msg )
update now msg model =
    case msg of
        AOpen ->
            ( model |> setAmlSidebar (Just (init model.erd)), Ports.track Track.openUpdateSchema )

        AClose ->
            ( model |> setAmlSidebar Nothing, Cmd.none )

        AToggle ->
            ( model, T.send (AmlSidebarMsg (Bool.cond (model.amlSidebar == Nothing) AOpen AClose)) )

        AChangeSource source ->
            ( model |> mapAmlSidebarM (setSelected source), Cmd.none )

        AUpdateSource id value ->
            model.erd
                |> Maybe.andThen (.sources >> List.find (\s -> s.id == id))
                |> Maybe.map (\s -> updateSource now s value model)
                |> Maybe.withDefault ( model |> mapAmlSidebarM (setErrors [ { row = 0, col = 0, problem = "Invalid source" } ]), Cmd.none )


updateSource : Time.Posix -> Source -> String -> Model x -> ( Model x, Cmd Msg )
updateSource now source input model =
    let
        tableLayouts : List ErdTableLayout
        tableLayouts =
            model.erd |> Maybe.mapOrElse (Erd.currentLayout >> .tables) []

        content : Array String
        content =
            contentSplit input

        ( errors, parsed ) =
            -- TODO: improve, `content` should be set in source inside the `buildSource`
            String.trim input ++ "\n" |> AmlParser.parse |> AmlAdapter.buildSource (source |> Source.toInfo) |> Tuple.mapSecond (setContent content)

        ( removed, bothPresent, added ) =
            List.diff .id (source.tables |> Dict.values) (parsed.tables |> Dict.values)

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
                            |> Maybe.andThen (\t -> tableLayouts |> List.findBy .id t.id)
                            |> Maybe.map (.props >> .position)
                            |> Maybe.filter (\p -> p /= Position.zeroGrid)
                            |> Maybe.map PlaceAt
                        )
                    )
    in
    if List.nonEmpty errors then
        ( model |> mapErdM (Erd.mapSource source.id (setContent content >> setUpdatedAt now)) |> mapAmlSidebarM (setErrors errors), Cmd.none )

    else
        ( model |> mapErdM (Erd.mapSource source.id (Source.refreshWith parsed)) |> mapAmlSidebarM (setErrors [])
        , Cmd.batch
            (List.map T.send
                ((toShow |> List.map (tupled ShowTable))
                    ++ (toHide |> List.map HideTable)
                    ++ (updated |> List.map (\( id, cols ) -> ShowColumns id (ShowColumns.List cols)))
                )
            )
        )


associateTables : List Table -> List Table -> List ( Table, Maybe Table )
associateTables removed added =
    if List.length added == 1 && List.length removed == 1 then
        added |> List.map (\t -> ( t, removed |> List.head ))

    else
        added |> List.map (\table -> ( table, Nothing ))


setSource : Maybe Source -> AmlSidebar -> AmlSidebar
setSource source model =
    model |> setSelected (source |> Maybe.map .id)


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

        warnings : List String
        warnings =
            selectedSource
                |> Maybe.mapOrElse .relations []
                |> List.concatMap (\r -> [ ColumnId.from r.src, ColumnId.from r.ref ])
                |> List.unique
                |> List.filterMap
                    (\( table, column ) ->
                        case erd.tables |> Dict.get table |> Maybe.map (\t -> t.columns |> Dict.get column) of
                            Just (Just _) ->
                                Nothing

                            Just Nothing ->
                                Just ("Column '" ++ column ++ "' not found in table '" ++ TableId.show Conf.schema.empty table ++ "'")

                            Nothing ->
                                Just ("Table '" ++ TableId.show Conf.schema.empty table ++ "' not found")
                    )
    in
    div []
        [ viewHeading
        , div [ class "px-3 py-2" ]
            [ viewChooseSource selectedSource userSources
            , selectedSource |> Maybe.mapOrElse (viewSourceEditor model warnings) (div [] [])
            ]
        ]


viewHeading : Html Msg
viewHeading =
    div [ class "px-6 py-5 border-b border-gray-200" ]
        [ div [ class "flex space-x-3" ]
            [ div [ class "flex-1" ]
                [ h3 [ class "text-lg leading-6 font-medium text-gray-900" ] [ text "Extend schema" ]
                ]
            , div [ class "flex-shrink-0 self-center flex" ]
                [ button [ onClick (AmlSidebarMsg AClose), class "-m-2 p-2 rounded-full flex items-center text-gray-400 hover:text-gray-600" ] [ Icon.solid Icon.X "" ]
                ]
            ]
        , p [ class "mt-1 text-sm text-gray-500" ]
            [ text "In Azimutt your schema is the union of all active sources. Create or update one with "
            , extLink "https://github.com/azimuttapp/azimutt/blob/main/docs/aml/README.md" [ class "link" ] [ text "AML syntax" ]
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
            , button [ onClick (simplePrompt "AML source name:" CreateUserSource), class "-ml-px relative inline-flex items-center space-x-2 px-4 py-2 border border-gray-300 text-sm font-medium rounded-r-md text-gray-700 bg-gray-50 hover:bg-gray-100 focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500" ]
                [ text "New source"
                ]
            ]
        ]


viewSourceEditor : AmlSidebar -> List String -> Source -> Html Msg
viewSourceEditor model warnings source =
    div [ class "mt-3" ]
        [ Editor.basic "source-editor" (contentStr source) (AUpdateSource source.id >> AmlSidebarMsg) """Write your schema using AML syntax

Ex:

users
  id uuid pk
  first_name varchar(128)
  last_name varchar(128)
  email varchar(128) nullable

credentials | used to authenticate users
  user_id pk fk users.id
  login varchar(128) unique
  password varchar(128) nullable
  role varchar(10)=guest index | possible values: admin or guest
  created_at timestamp

roles
  slug varchar(10)

# define a standalone relation
fk credentials.role -> roles.slug""" 30 (List.nonEmpty model.errors)
        , viewErrors (model.errors |> List.map (\err -> err.problem ++ " at line " ++ String.fromInt err.row ++ ", column " ++ String.fromInt err.col) |> List.unique)
        , viewWarnings (warnings |> List.unique)
        , viewHelp
        ]


viewErrors : List String -> Html msg
viewErrors errors =
    div []
        (errors |> List.map (\err -> p [ class "mt-2 text-sm text-red-600" ] [ text err ]))


viewWarnings : List String -> Html msg
viewWarnings warnings =
    div [] (warnings |> List.map (\warning -> p [ class "mt-2 text-sm text-yellow-600" ] [ text warning ]))


viewHelp : Html msg
viewHelp =
    p [ class "mt-2 text-sm text-gray-500" ]
        [ text "Write your schema using "
        , extLink "https://github.com/azimuttapp/azimutt/blob/main/docs/aml/README.md" [ class "link" ] [ text "AML syntax" ]
        , text "."
        ]
