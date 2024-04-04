module PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis exposing (viewSchemaAnalysis)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Modal as Modal
import Components.Slices.ProPlan as ProPlan
import Dict exposing (Dict)
import Html exposing (Html, div, h3, h4, p, span, text)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import Libs.Bool as B
import Libs.Html exposing (extLink)
import Libs.Html.Attributes exposing (css)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw exposing (sm)
import Models.Organization exposing (Organization)
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.Relation exposing (Relation)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Models.ProjectRef exposing (ProjectRef)
import PagesComponents.Organization_.Project_.Models exposing (Msg(..), SchemaAnalysisDialog, SchemaAnalysisMsg(..))
import PagesComponents.Organization_.Project_.Models.ErdRelation as ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdTable as ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis.InconsistentTypeOnColumns as InconsistentTypeOnColumns
import PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis.InconsistentTypeOnRelations as InconsistentTypeOnRelations
import PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis.IndexDuplicated as IndexDuplicated
import PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis.IndexOnForeignKeys as IndexOnForeignKeys
import PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis.NamingConsistency as NamingConsistency
import PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis.PrimaryKeyMissing as PrimaryKeyMissing
import PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis.RelationMissing as RelationMissing
import PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis.TableTooBig as TableTooBig
import PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis.TableWithoutIndex as TableWithoutIndex



{-
   Improve analysis:
    - '_at' columns not of date type
    - '_ids' columns not of array type (ex: profiles.additional_organization_ids)
    - % of nullable columns in a table (warn if > 50%)
    - ?identify PII

   https://schemaspy.org/sample/anomalies.html
   - Tables that contain a single column
   - Tables without indexes
   - Columns whose default value is the word 'NULL' or 'null'
   - Tables with incrementing column names, potentially indicating denormalization

   https://www.databasestar.com/database-design-mistakes
-}


viewSchemaAnalysis : ProjectRef -> Bool -> SchemaName -> List Source -> Dict TableId ErdTable -> List ErdRelation -> Dict TableId (List ColumnPath) -> SchemaAnalysisDialog -> Html Msg
viewSchemaAnalysis project opened defaultSchema sources tables relations ignoredRelations model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"
    in
    Modal.modal { id = model.id, titleId = titleId, isOpen = opened, onBackgroundClick = ModalClose (SchemaAnalysisMsg SAClose) }
        [ viewHeader titleId
        , if project.organization.plan.dbAnalysis then
            div [] []

          else
            div [ class "max-w-5xl px-6 mt-3" ] [ ProPlan.analysisWarning project ]
        , viewAnalysis project model.opened defaultSchema sources tables relations ignoredRelations
        , viewFooter
        ]


viewHeader : HtmlId -> Html msg
viewHeader titleId =
    div [ css [ "max-w-5xl px-6 mt-3", sm [ "flex items-start" ] ] ]
        [ div [ css [ "mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-primary-100", sm [ "mx-0 h-10 w-10" ] ] ]
            [ Icon.outline Beaker "text-primary-600"
            ]
        , div [ css [ "mt-3 text-center", sm [ "mt-0 ml-4 text-left" ] ] ]
            [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ] [ text "Schema analysis" ]
            , p [ class "text-sm text-gray-500" ]
                [ text "Let's find out if you can make improvements on your schema..." ]
            ]
        ]


viewAnalysis : ProjectRef -> HtmlId -> SchemaName -> List Source -> Dict TableId ErdTable -> List ErdRelation -> Dict TableId (List ColumnPath) -> Html Msg
viewAnalysis project opened defaultSchema sources erdTables erdRelations ignoredRelations =
    let
        tables : Dict TableId Table
        tables =
            erdTables |> Dict.map (\_ -> ErdTable.unpack)

        relations : List Relation
        relations =
            erdRelations |> List.map ErdRelation.unpack
    in
    div [ class "max-w-5xl px-6 mt-3" ]
        [ PrimaryKeyMissing.compute tables |> viewSection "missing-pks" opened PrimaryKeyMissing.heading (PrimaryKeyMissing.view ShowTable project defaultSchema)
        , RelationMissing.compute ignoredRelations tables relations |> viewSection "missing-relations" opened RelationMissing.heading (RelationMissing.view CreateRelations IgnoreRelation project defaultSchema)
        , InconsistentTypeOnRelations.compute defaultSchema erdTables erdRelations |> viewSection "relations-with-different-types" opened InconsistentTypeOnRelations.heading (InconsistentTypeOnRelations.view project defaultSchema sources Send)
        , InconsistentTypeOnColumns.compute erdTables |> viewSection "heterogeneous-types" opened InconsistentTypeOnColumns.heading (InconsistentTypeOnColumns.view project defaultSchema)
        , TableTooBig.compute tables |> viewSection "big-tables" opened TableTooBig.heading (TableTooBig.view ShowTable project defaultSchema)
        , TableWithoutIndex.compute tables |> viewSection "tables-no-index" opened TableWithoutIndex.heading (TableWithoutIndex.view ShowTable project defaultSchema)
        , IndexOnForeignKeys.compute tables relations |> viewSection "index-on-fk" opened IndexOnForeignKeys.heading (IndexOnForeignKeys.view ShowTable project defaultSchema)
        , IndexDuplicated.compute tables |> viewSection "duplicated-index" opened IndexDuplicated.heading (IndexDuplicated.view project defaultSchema)
        , NamingConsistency.compute tables |> viewSection "table-name-inconsistent" opened NamingConsistency.heading (NamingConsistency.view project defaultSchema)
        ]


viewSection : HtmlId -> HtmlId -> (List a -> String) -> (List a -> Html Msg) -> List a -> Html Msg
viewSection htmlId opened heading content errors =
    let
        isOpen : Bool
        isOpen =
            opened == htmlId
    in
    if errors |> List.isEmpty then
        div [ class "mt-3" ]
            [ h4 [ class "leading-5 font-medium" ]
                [ Icon.solid Check "inline mr-3 text-green-500"
                , text (heading errors)
                ]
            ]

    else
        div [ class "mt-3" ]
            [ h4 [ class "mb-1 leading-5 font-medium cursor-pointer", onClick (SchemaAnalysisMsg (SASectionToggle htmlId)) ]
                [ Icon.solid LightBulb "inline mr-3 text-yellow-500"
                , text (heading errors)
                , Icon.solid ChevronDown ("inline transform transition " ++ B.cond isOpen "-rotate-180" "")
                ]
            , if isOpen then
                div [ class "ml-8" ] [ content errors ]

              else
                div [] []
            ]


viewFooter : Html Msg
viewFooter =
    div [ class "max-w-5xl px-6 mt-3 py-3 flex items-center justify-between flex-row-reverse bg-gray-50 rounded-b-lg" ]
        [ Button.primary3 Tw.primary [ class "ml-3", onClick (ModalClose (SchemaAnalysisMsg SAClose)) ] [ text "Close" ]
        , span [] [ text "If you've got any ideas for improvements, ", extLink "https://github.com/azimuttapp/azimutt/discussions/75" [ class "link" ] [ text "please let us know" ], text "." ]
        ]
