module Components.Slices.ExportDialogBody exposing (DocState, ExportFormat, ExportInput, Model, Msg, SharedDocState, doc, docInit, init, update, view)

import Array
import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Radio as Radio
import Components.Slices.ProPlan as ProPlan
import Conf exposing (constants)
import DataSources.AmlMiner.AmlAdapter as AmlAdapter
import DataSources.AmlMiner.AmlGenerator as AmlGenerator
import DataSources.AmlMiner.AmlParser as AmlParser
import DataSources.JsonMiner.JsonGenerator as JsonGenerator
import DataSources.SqlMiner.MysqlGenerator as MysqlGenerator
import DataSources.SqlMiner.PostgreSqlGenerator as PostgreSqlGenerator
import Dict
import ElmBook
import ElmBook.Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, code, div, h3, p, pre, text)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import Libs.Html exposing (extLink)
import Libs.Html.Attributes exposing (css)
import Libs.Maybe as Maybe
import Libs.Models.FileName exposing (FileName)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Remote as Remote exposing (Remote(..))
import Libs.Tailwind as Tw exposing (sm)
import Libs.Task as T
import Libs.Time as Time
import Libs.Tuple3 as Tuple3
import Models.Organization exposing (Organization)
import Models.Plan as Plan
import Models.Position as Position
import Models.Project as Project exposing (Project)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPathStr)
import Models.Project.Schema as Schema exposing (Schema)
import Models.Project.SourceId as SourceId
import Models.Project.TableId as TableId exposing (TableIdStr)
import Models.ProjectRef as ProjectRef exposing (ProjectRef)
import Models.Size as Size
import Models.SourceInfo as SourceInfo
import Models.UrlInfos as UrlInfos exposing (UrlInfos)
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdColumnProps as ErdColumnProps
import PagesComponents.Organization_.Project_.Models.ErdLayout as ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.ErdTableProps exposing (ErdTableProps)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import Ports
import Services.Lenses exposing (mapOrganization, mapProject, setCurrentLayout, setLayouts, setOrganization, setTables)
import Track


type alias Model =
    { id : HtmlId
    , input : Maybe ExportInput
    , format : Maybe ExportFormat
    , output : Remote String ( FileName, String )
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
    | MySQL
    | JSON


init : HtmlId -> Model
init id =
    { id = id, input = Nothing, format = Nothing, output = Pending }


update : (Msg -> msg) -> UrlInfos -> Erd -> Msg -> Model -> ( Model, Extra msg )
update wrap urlInfos erd msg model =
    case msg of
        SetInput source ->
            { model | input = Just source } |> shouldGetOutput wrap

        SetFormat format ->
            { model | format = Just format } |> shouldGetOutput wrap

        GetOutput source format ->
            ( { model | output = Fetching }, getOutput wrap urlInfos erd source format )

        GotOutput file content ->
            ( { model | output = Fetched ( file, content ) }, Extra.none )


shouldGetOutput : (Msg -> msg) -> Model -> ( Model, Extra msg )
shouldGetOutput wrap model =
    if model.output /= Fetching then
        ( { model | output = Pending }
        , if model.input == Just Project then
            GetOutput Project JSON |> wrap |> Extra.msg

          else
            Maybe.map2 GetOutput model.input model.format |> Maybe.map wrap |> Extra.msgM
        )

    else
        ( model, Extra.none )


getOutput : (Msg -> msg) -> UrlInfos -> Erd -> ExportInput -> ExportFormat -> Extra msg
getOutput wrap urlInfos erd input format =
    let
        sqlExportAllowed : Bool
        sqlExportAllowed =
            erd |> Erd.getOrganization urlInfos.organization |> .plan |> .sqlExport
    in
    case input of
        Project ->
            erd |> Erd.unpack |> Project.downloadContent |> (GotOutput (erd.project.name ++ ".azimutt.json") >> wrap >> Extra.msg)

        AllTables ->
            if format /= AML && format /= JSON && not sqlExportAllowed then
                Extra.batch [ GotOutput "" "plan_limit" |> wrap |> T.send, Track.planLimit .sqlExport (Just erd) ]

            else
                erd |> Erd.toSchema |> generateTables format |> (\( output, ext ) -> output |> GotOutput (erd.project.name ++ "." ++ ext) |> wrap |> Extra.msg)

        CurrentLayout ->
            if format /= AML && format /= JSON && not sqlExportAllowed then
                Extra.batch [ GotOutput "" "plan_limit" |> wrap |> T.send, Track.planLimit .sqlExport (Just erd) ]

            else
                erd
                    |> Erd.toSchema
                    |> Schema.filter (erd.layouts |> Dict.get erd.currentLayout |> Maybe.mapOrElse (.tables >> List.map .id) [])
                    |> generateTables format
                    |> (\( output, ext ) -> output |> GotOutput (erd.project.name ++ "-" ++ erd.currentLayout ++ "." ++ ext) |> wrap |> Extra.msg)


generateTables : ExportFormat -> Schema -> ( String, String )
generateTables format schema =
    case format of
        AML ->
            ( AmlGenerator.generate schema, "aml" )

        PostgreSQL ->
            ( PostgreSqlGenerator.generate schema, "sql" )

        MySQL ->
            ( MysqlGenerator.generate schema, "sql" )

        JSON ->
            ( JsonGenerator.generate schema, "json" )


view : (Msg -> msg) -> (Cmd msg -> msg) -> msg -> HtmlId -> ProjectRef -> Model -> Html msg
view wrap send onClose titleId project model =
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
                                    , options =
                                        [ ( AML, "AML" ), ( PostgreSQL, "PostgreSQL" ), ( MySQL, "MySQL" ), ( JSON, "JSON" ) ]
                                            |> List.map (\( v, t ) -> { value = v, text = t, disabled = False })
                                    , value = model.format
                                    , link = Nothing
                                    }
                                ]
                        )
                    |> Maybe.withDefault (div [] [])
                , if model.output == Pending then
                    div [] []

                  else
                    model.output
                        |> Remote.fold
                            (\_ -> viewCode "Choose what you want to export and the format...")
                            (\_ -> viewCode "fetching...")
                            (\e -> viewCode ("Error: " ++ e))
                            (\( _, content ) ->
                                if content == "plan_limit" then
                                    div [ class "mt-3" ] [ ProPlan.sqlExportWarning project ]

                                else if model.format == Just PostgreSQL then
                                    div [] [ viewCode content, viewSuggestPR "https://github.com/azimuttapp/azimutt/blob/main/frontend/src/DataSources/SqlMiner/PostgreSqlGenerator.elm#L26" ]

                                else if model.format == Just MySQL then
                                    div [] [ viewCode content, viewSuggestPR "https://github.com/azimuttapp/azimutt/blob/main/frontend/src/DataSources/SqlMiner/MysqlGenerator.elm#L26" ]

                                else
                                    viewCode content
                            )
                ]
            ]
        , div [ class "px-6 py-3 mt-6 flex items-center flex-row-reverse bg-gray-50 rounded-b-lg" ]
            ((model.output
                |> Remote.toMaybe
                |> Maybe.filter (\( _, content ) -> content /= "plan_limit")
                |> Maybe.map
                    (\( file, content ) ->
                        [ Button.primary3 Tw.primary
                            [ onClick (content ++ "\n" |> Ports.downloadFile file |> send), css [ "w-full text-base", sm [ "ml-3 w-auto text-sm" ] ] ]
                            [ Icon.solid Icon.Download "mr-1", text "Download file" ]
                        , Button.primary3 Tw.primary
                            [ onClick (content ++ "\n" |> Ports.copyToClipboard |> send), css [ "w-full text-base", sm [ "ml-3 w-auto text-sm" ] ] ]
                            [ Icon.solid Icon.Duplicate "mr-1", text "Copy to clipboard" ]
                        ]
                    )
                |> Maybe.withDefault []
             )
                ++ [ Button.white3 Tw.gray [ onClick onClose, css [ "mt-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text "Close" ] ]
            )
        ]


viewCode : String -> Html msg
viewCode codeStr =
    pre [ class "mt-2 px-4 py-2 bg-gray-900 text-white text-sm font-mono rounded-md overflow-auto max-h-128 w-4xl" ]
        [ code [] [ text codeStr ] ]


viewSuggestPR : String -> Html msg
viewSuggestPR generatorUrl =
    p [ class "mt-2 text-sm text-gray-500" ]
        [ text "Do you see possible improvements? Please "
        , extLink constants.azimuttBugReport [ class "link" ] [ text "open an issue" ]
        , text " or even "
        , extLink generatorUrl [ class "link" ] [ text "send a PR" ]
        , text ". ❤️"
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | exportDialogDocState : DocState }


type alias DocState =
    { free : Model, pro : Model }


docInit : DocState
docInit =
    { free = { id = "free-modal-id", input = Nothing, format = Nothing, output = Pending }
    , pro = { id = "pro-modal-id", input = Nothing, format = Nothing, output = Pending }
    }


updateDocState : ProjectRef -> (DocState -> Model) -> (Model -> DocState -> DocState) -> Msg -> ElmBook.Msg (SharedDocState x)
updateDocState project get set msg =
    ElmBook.Actions.updateStateWithCmd
        (\s ->
            s.exportDialogDocState
                |> get
                |> update (updateDocState project get set) UrlInfos.empty (sampleErd |> mapProject (setOrganization (Just project.organization))) msg
                |> Tuple.mapBoth (\r -> { s | exportDialogDocState = s.exportDialogDocState |> set r }) Tuple.first
        )


updateDocFreeState : Msg -> ElmBook.Msg (SharedDocState x)
updateDocFreeState msg =
    updateDocState sampleFreePlan .free (\m s -> { s | free = m }) msg


updateDocProState : Msg -> ElmBook.Msg (SharedDocState x)
updateDocProState msg =
    updateDocState sampleProPlan .pro (\m s -> { s | pro = m }) msg


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


sampleFreePlan : ProjectRef
sampleFreePlan =
    ProjectRef.zero


sampleProPlan : ProjectRef
sampleProPlan =
    sampleFreePlan |> mapOrganization (\o -> { o | plan = Plan.full })


component : String -> (DocState -> Html msg) -> ( String, SharedDocState x -> Html msg )
component name render =
    ( name, \{ exportDialogDocState } -> render exportDialogDocState )


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "ExportDialogBody"
        |> Chapter.renderStatefulComponentList
            [ component "exportDialog" (\model -> view updateDocFreeState (\_ -> logAction "Download file") sampleOnClose sampleTitleId sampleFreePlan model.free)
            , component "exportDialog with pro org" (\model -> view updateDocProState (\_ -> logAction "Download file") sampleOnClose sampleTitleId sampleProPlan model.pro)
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
