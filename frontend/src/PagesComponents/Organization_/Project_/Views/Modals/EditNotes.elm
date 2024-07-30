module PagesComponents.Organization_.Project_.Views.Modals.EditNotes exposing (viewEditNotes)

import Components.Atoms.Badge as Badge
import Components.Atoms.Button as Button
import Components.Molecules.Modal as Modal
import Dict
import Html exposing (Html, div, label, span, text, textarea)
import Html.Attributes exposing (autofocus, class, for, id, name, placeholder, rows, value)
import Html.Events exposing (onClick, onInput)
import Libs.Html.Attributes exposing (ariaHidden, css)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw exposing (sm)
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.ColumnRef as ColumnRef
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Organization_.Project_.Models exposing (Msg(..), NotesDialog)
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdTable as ErdTable
import PagesComponents.Organization_.Project_.Models.NotesMsg exposing (NotesMsg(..))


viewEditNotes : Bool -> Erd -> NotesDialog -> Html Msg
viewEditNotes opened erd model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"

        inputId : HtmlId
        inputId =
            model.id ++ "-input"
    in
    Modal.modal
        { id = model.id
        , titleId = titleId
        , isOpen = opened
        , onBackgroundClick = ModalClose (NotesMsg NCancel)
        }
        [ div [ class "m-4 relative" ]
            [ label [ for inputId, class "block text-sm font-medium text-gray-700" ] [ text "Notes for ", buildName erd model.table model.column ]
            , div [ class "mt-2 border border-gray-300 rounded-lg shadow-sm overflow-hidden focus-within:border-indigo-500 focus-within:ring-1 focus-within:ring-indigo-500" ]
                [ textarea [ rows 4, name inputId, id inputId, value model.notes, onInput (NEdit >> NotesMsg), autofocus True, placeholder "Write your notes...", class "block w-full py-3 border-0 resize-none focus:ring-0 sm:text-sm" ] []
                , {- Spacer element to match the height of the toolbar -}
                  div [ class "py-2", ariaHidden True ]
                    [ {- Matches height of button in toolbar (1px border + 36px content height) -} div [ class "py-px" ] [ div [ class "h-9" ] [] ]
                    ]
                ]
            , div [ class "absolute bottom-0 inset-x-0 pl-3 pr-2 py-2 flex justify-end" ]
                [ div [ class "flex flex-shrink-0 flex-row-reverse" ]
                    [ Button.primary3 Tw.primary [ onClick (model.notes |> NSave model.table model.column model.initialNotes |> NotesMsg |> ModalClose), css [ "w-full text-base", sm [ "ml-2 w-auto text-sm" ] ] ] [ text "Save" ]
                    , Button.white3 Tw.gray [ onClick (NCancel |> NotesMsg |> ModalClose), css [ "mt-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text "Close" ]
                    ]
                ]
            ]
        ]


buildName : Erd -> TableId -> Maybe ColumnPath -> Html msg
buildName erd table column =
    case column of
        Nothing ->
            erd.tables
                |> Dict.get table
                |> Maybe.map (\_ -> span [] [ Badge.basicFlex Tw.gray [] [ text (TableId.show erd.settings.defaultSchema table) ], text " table" ])
                |> Maybe.withDefault (text ("unknown table " ++ TableId.show erd.settings.defaultSchema table))

        Just c ->
            erd.tables
                |> Dict.get table
                |> Maybe.andThen (ErdTable.getColumnI c)
                |> Maybe.map (\_ -> span [] [ Badge.basicFlex Tw.gray [] [ text (ColumnRef.show erd.settings.defaultSchema { table = table, column = c }) ], text " column" ])
                |> Maybe.withDefault (text ("unknown column " ++ ColumnRef.show erd.settings.defaultSchema { table = table, column = c }))
