module PagesComponents.Projects.Id_.Views.Modals.EditNotes exposing (viewEditNotes)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Modal as Modal
import Dict
import Html exposing (Html, div, h3, input, label, text)
import Html.Attributes exposing (autofocus, class, for, id, name, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Html.Attributes exposing (css)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Ned as Ned
import Libs.Tailwind as Tw exposing (focus, sm)
import Models.Project.ColumnRef as ColumnRef
import Models.Project.TableId as TableId
import PagesComponents.Projects.Id_.Models exposing (Msg(..), NoteRef(..), NotesDialog, NotesMsg(..))
import PagesComponents.Projects.Id_.Models.Erd exposing (Erd)


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
        [ div [ css [ "px-6 pt-6", sm [ "flex items-start" ] ] ]
            [ div [ css [ "mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-primary-100", sm [ "mx-0 h-10 w-10" ] ] ]
                [ Icon.outline Template "text-primary-600"
                ]
            , div [ css [ "mt-3 text-center", sm [ "mt-0 ml-4 text-left" ] ] ]
                [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ]
                    [ text ("Writes some notes for " ++ refAsName erd model.ref) ]
                , div [ class "mt-2" ]
                    [ label [ for inputId, class "block text-sm font-medium text-gray-700" ] [ text "Your notes" ]
                    , div [ class "mt-1" ]
                        [ input [ type_ "text", name inputId, id inputId, value model.notes, onInput (NEdit >> NotesMsg), autofocus True, css [ "shadow-sm block w-full border-gray-300 rounded-md", focus [ "ring-indigo-500 border-indigo-500" ], sm [ "text-sm" ] ] ] []
                        ]
                    ]
                ]
            ]
        , div [ class "px-6 py-3 mt-6 flex items-center flex-row-reverse bg-gray-50" ]
            [ Button.primary3 Tw.primary [ onClick (model.notes |> NSave model.ref |> NotesMsg |> ModalClose), css [ "w-full text-base", sm [ "ml-3 w-auto text-sm" ] ] ] [ text "Save notes" ]
            , Button.white3 Tw.gray [ onClick (NCancel |> NotesMsg |> ModalClose), css [ "mt-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text "Cancel" ]
            ]
        ]


refAsName : Erd -> NoteRef -> String
refAsName erd ref =
    case ref of
        ColumnNote column ->
            erd.tables
                |> Dict.get column.table
                |> Maybe.andThen (\t -> t.columns |> Ned.get column.column)
                |> Maybe.map (\c -> c.name ++ " column of " ++ TableId.show column.table ++ " table")
                |> Maybe.withDefault ("unknown entity " ++ ColumnRef.show column)
