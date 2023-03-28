module Components.Slices.ExportDialogBody exposing (DocState, ExportFormat, ExportInput, Model, Msg, SharedDocState, doc, init, initDocState, update, view)

import Array
import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Radio as Radio
import DataSources.AmlMiner.AmlAdapter as AmlAdapter
import DataSources.AmlMiner.AmlGenerator as AmlGenerator
import DataSources.AmlMiner.AmlParser as AmlParser
import DataSources.JsonMiner.JsonGenerator as JsonGenerator
import DataSources.SqlMiner.PostgreSqlGenerator as PostgreSqlGenerator
import Dict
import ElmBook
import ElmBook.Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, code, div, h3, pre, text)
import Html.Attributes exposing (class, disabled, id)
import Html.Events exposing (onClick)
import Libs.Html.Attributes exposing (css)
import Libs.Maybe as Maybe
import Libs.Models.FileName exposing (FileName)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Remote as Remote exposing (Remote(..))
import Libs.Tailwind as Tw exposing (sm)
import Libs.Task as T
import Libs.Time as Time
import Libs.Tuple3 as Tuple3
import Models.Position as Position
import Models.Project as Project exposing (Project)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPathStr)
import Models.Project.Schema as Schema exposing (Schema)
import Models.Project.SourceId as SourceId
import Models.Project.TableId as TableId exposing (TableIdStr)
import Models.Size as Size
import Models.SourceInfo as SourceInfo
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdColumnProps as ErdColumnProps
import PagesComponents.Organization_.Project_.Models.ErdLayout as ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.ErdTableProps exposing (ErdTableProps)
import Ports
import Services.Lenses exposing (setCurrentLayout, setLayouts, setTables)


type alias Model =
    { id : HtmlId
    , input : Maybe ExportInput
    , format : Maybe ExportFormat
    , output : Remote String ( String, String )
    }


type Msg
    = SetInput ExportInput
    | SetFormat ExportFormat
    | GetOutput ExportInput ExportFormat
    | GotOutput FileName String


type ExportInput
    = Project
    | AllTables
    | CurrentLayout


type ExportFormat
    = AML
    | PostgreSQL
    | JSON


init : HtmlId -> Model
init id =
    { id = id, input = Nothing, format = Nothing, output = Pending }


update : (Msg -> msg) -> Erd -> Msg -> Model -> ( Model, Cmd msg )
update wrap erd msg model =
    case msg of
        SetInput source ->
            { model | input = Just source } |> shouldGetOutput wrap

        SetFormat format ->
            { model | format = Just format } |> shouldGetOutput wrap

        GetOutput source format ->
            ( { model | output = Fetching }, getOutput wrap source format erd )

        GotOutput file content ->
            ( { model | output = Fetched ( file, content ) }, Cmd.none )


shouldGetOutput : (Msg -> msg) -> Model -> ( Model, Cmd msg )
shouldGetOutput wrap model =
    if model.output /= Fetching then
        ( { model | output = Pending }
        , if model.input == Just Project then
            GetOutput Project JSON |> wrap |> T.send

          else
            Maybe.map2 (\input format -> GetOutput input format |> wrap |> T.send) model.input model.format
                |> Maybe.withDefault Cmd.none
        )

    else
        ( model, Cmd.none )


getOutput : (Msg -> msg) -> ExportInput -> ExportFormat -> Erd -> Cmd msg
getOutput wrap input format erd =
    case input of
        Project ->
            erd |> Erd.unpack |> Project.downloadContent |> (\output -> output |> GotOutput (erd.project.name ++ ".azimutt.json") |> wrap |> T.send)

        AllTables ->
            erd |> Erd.unpack |> Schema.from |> generateTables format |> (\( output, ext ) -> output |> GotOutput (erd.project.name ++ "." ++ ext) |> wrap |> T.send)

        CurrentLayout ->
            erd
                |> Erd.unpack
                |> Schema.from
                |> Schema.filter (erd.layouts |> Dict.get erd.currentLayout |> Maybe.mapOrElse (.tables >> List.map .id) [])
                |> generateTables format
                |> (\( output, ext ) -> output |> GotOutput (erd.project.name ++ "-" ++ erd.currentLayout ++ "." ++ ext) |> wrap |> T.send)


generateTables : ExportFormat -> Schema -> ( String, String )
generateTables format schema =
    case format of
        AML ->
            ( AmlGenerator.generate schema, "aml" )

        PostgreSQL ->
            ( PostgreSqlGenerator.generate schema, "sql" )

        JSON ->
            ( JsonGenerator.generate schema, "json" )


view : (Msg -> msg) -> (Cmd msg -> msg) -> msg -> HtmlId -> Model -> Html msg
view wrap send onClose titleId model =
    let
        inputId : HtmlId
        inputId =
            model.id ++ "-radio"
    in
    div [ class "w-5xl" ]
        [ div [ css [ "px-6 pt-6", sm [ "flex items-start" ] ] ]
            [ div [ css [ "mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-primary-100", sm [ "mx-0 h-10 w-10" ] ] ]
                [ Icon.outline Icon.Logout "text-primary-600"
                ]
            , div [ css [ "mt-3 text-center", sm [ "mt-0 ml-4 text-left" ] ] ]
                [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ]
                    [ text "Export your diagram" ]
                , div [ class "mt-2" ]
                    [ Radio.smallCards (.value >> SetInput >> wrap)
                        { name = inputId ++ "-source"
                        , label = "Export"
                        , legend = "Choose what to export"
                        , options = [ ( Project, "Full project" ), ( AllTables, "All tables" ), ( CurrentLayout, "Current layout" ) ] |> List.map (\( v, t ) -> { value = v, text = t, disabled = False })
                        , value = model.input
                        , link = Nothing
                        }
                    ]
                , model.input
                    |> Maybe.filter (\i -> i /= Project)
                    |> Maybe.map
                        (\_ ->
                            div [ class "mt-2" ]
                                [ Radio.smallCards (.value >> SetFormat >> wrap)
                                    { name = inputId ++ "-output"
                                    , label = "Output format"
                                    , legend = "Choose an output format"
                                    , options = [ ( AML, "AML" ), ( PostgreSQL, "PostgreSQL" ), ( JSON, "JSON" ) ] |> List.map (\( v, t ) -> { value = v, text = t, disabled = False })
                                    , value = model.format
                                    , link = Nothing
                                    }
                                ]
                        )
                    |> Maybe.withDefault (div [] [])
                , if model.output == Pending then
                    pre [] []

                  else
                    pre [ class "mt-2 px-4 py-2 bg-gray-900 text-white text-sm font-mono rounded-md overflow-auto max-h-128 w-4xl" ]
                        [ code []
                            [ model.output
                                |> Remote.fold
                                    (\_ -> text "Choose what you want to export and the format...")
                                    (\_ -> text "fetching...")
                                    (\e -> text ("Error: " ++ e))
                                    (\( _, content ) -> text content)
                            ]
                        ]
                ]
            ]
        , div [ class "px-6 py-3 mt-6 flex items-center flex-row-reverse bg-gray-50 rounded-b-lg" ]
            ((model.output
                |> Remote.toList
                |> List.map
                    (\( file, content ) ->
                        Button.primary3 Tw.primary
                            [ onClick (content ++ "\n" |> Ports.downloadFile file |> send), disabled False, css [ "w-full text-base", sm [ "ml-3 w-auto text-sm" ] ] ]
                            [ Icon.solid Icon.Download "mr-1", text "Download file" ]
                    )
             )
                ++ [ Button.white3 Tw.gray [ onClick onClose, css [ "mt-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text "Close" ] ]
            )
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | exportDialogDocState : DocState }


type alias DocState =
    Model


initDocState : DocState
initDocState =
    { id = "modal-id", input = Nothing, format = Nothing, output = Pending }


updateDocState : Msg -> ElmBook.Msg (SharedDocState x)
updateDocState msg =
    ElmBook.Actions.updateStateWithCmd (\s -> s.exportDialogDocState |> update updateDocState sampleErd msg |> Tuple.mapFirst (\r -> { s | exportDialogDocState = r }))


sampleOnClose : ElmBook.Msg state
sampleOnClose =
    ElmBook.Actions.logAction "onClose"


sampleTitleId : String
sampleTitleId =
    "modal-id-title"


sampleErd : Erd
sampleErd =
    """users
  id uuid pk
  name varchar
  age int check="age > 0"
  created_at datetime

organizations
  id uuid pk
  slug varchar nullable unique
  name varchar
  created_at datetime

organization_members
  organization_id uuid pk fk organizations.id
  user_id uuid pk fk users.id
"""
        |> AmlParser.parse
        |> AmlAdapter.buildSource (SourceInfo.aml Time.zero SourceId.zero "test") Array.empty
        |> Tuple3.second
        |> Project.create [] "Project name"
        |> Erd.create
        |> setLayouts (Dict.fromList [ ( "init layout", docBuildLayout [ ( "users", [ "id", "name" ] ) ] ) ])
        |> setCurrentLayout "init layout"


component : String -> (DocState -> Html msg) -> ( String, SharedDocState x -> Html msg )
component name render =
    ( name, \{ exportDialogDocState } -> render exportDialogDocState )


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "ExportDialogBody"
        |> Chapter.renderStatefulComponentList
            [ component "exportDialog" (\model -> view updateDocState (\_ -> logAction "Download file") sampleOnClose sampleTitleId model)
            ]


docBuildLayout : List ( TableIdStr, List ColumnPathStr ) -> ErdLayout
docBuildLayout tables =
    ErdLayout.empty Time.zero
        |> setTables
            (tables
                |> List.map
                    (\( table, columns ) ->
                        { id = TableId.parse table
                        , props = ErdTableProps Nothing Position.zeroGrid Size.zeroCanvas Tw.red True True True
                        , columns = columns |> List.map ColumnPath.fromString |> ErdColumnProps.createAll
                        , relatedTables = Dict.empty
                        }
                    )
            )
