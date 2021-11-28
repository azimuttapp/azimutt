module PagesComponents.Projects.New.View exposing (viewNewProject)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Atoms.Link as Link
import Components.Molecules.Alert as Alert
import Components.Molecules.Divider as Divider
import Conf exposing (constants)
import Css
import DataSources.SqlParser.FileParser exposing (SchemaError)
import DataSources.SqlParser.Utils.Types exposing (ParseError, SqlStatement)
import Dict
import Gen.Route as Route
import Html.Styled exposing (Html, a, aside, br, div, form, h2, label, nav, p, span, text)
import Html.Styled.Attributes exposing (css, for, href)
import Html.Styled.Events exposing (onClick)
import Libs.FileInput as FileInput
import Libs.Html.Styled exposing (bText)
import Libs.Html.Styled.Attributes exposing (ariaCurrent, role)
import Libs.Maybe as M
import Libs.Models.FileName exposing (FileName)
import Libs.Models.Theme exposing (Theme)
import Libs.Models.TwColor as TwColor exposing (TwColor(..), TwColorLevel(..), TwColorPosition(..))
import Libs.Result as R
import Libs.Tailwind.Utilities as Tu
import Models.Project exposing (Project)
import PagesComponents.Helpers exposing (appShell)
import PagesComponents.Projects.New.Models exposing (Model, Msg(..), Tab(..))
import PagesComponents.Projects.New.Updates.ProjectParser as ProjectParser
import Shared
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw
import Url exposing (percentEncode)


viewNewProject : Shared.Model -> Model -> List (Html Msg)
viewNewProject shared model =
    appShell shared.theme
        (\link -> SelectMenu link.text)
        ToggleMobileMenu
        model
        [ a [ href (Route.toHref Route.Projects) ] [ Icon.outline ArrowLeft [ Tw.inline_block ], text " ", text model.navigationActive ] ]
        [ viewContent shared.theme
            model
            { tabs =
                [ { tab = Schema, icon = DocumentText, text = "From SQL schema" }
                , { tab = Sample, icon = Collection, text = "From sample" }
                ]
            }
        ]
        []


type alias PageModel =
    { tabs : List (TabModel Tab)
    }


type alias TabModel tab =
    { tab : tab, icon : Icon, text : String }


viewContent : Theme -> Model -> PageModel -> Html Msg
viewContent theme model page =
    div [ css [ Tw.divide_y, Bp.lg [ Tw.grid, Tw.grid_cols_12, Tw.divide_x ] ] ]
        [ aside [ css [ Tw.py_6, Bp.lg [ Tw.col_span_3 ] ] ]
            [ nav [ css [ Tw.space_y_1 ] ] (page.tabs |> List.map (viewTab theme model.tabActive)) ]
        , div [ css [ Tw.px_4, Tw.py_6, Bp.sm [ Tw.p_6 ], Bp.lg [ Tw.pb_8, Tw.col_span_9, Tw.rounded_r_lg ] ] ]
            [ viewTabContent theme model ]
        ]


viewTab : Theme -> Tab -> TabModel Tab -> Html Msg
viewTab theme selected tab =
    if tab.tab == selected then
        a [ href "", css [ TwColor.render Bg theme.color L50, TwColor.render Border theme.color L500, TwColor.render Text theme.color L700, Tw.border_l_4, Tw.px_3, Tw.py_2, Tw.flex, Tw.items_center, Tw.text_sm, Tw.font_medium, Css.hover [ TwColor.render Bg theme.color L50, TwColor.render Text theme.color L700 ] ], ariaCurrent "page" ]
            [ Icon.outline tab.icon [ TwColor.render Text theme.color L500, Tw.flex_shrink_0, Tw.neg_ml_1, Tw.mr_3, Tw.h_6, Tw.w_6 ]
            , span [ css [ Tw.truncate ] ] [ text tab.text ]
            ]

    else
        a [ href "", onClick (SelectTab tab.tab), css [ Tw.border_transparent, Tw.text_gray_900, Tw.border_l_4, Tw.px_3, Tw.py_2, Tw.flex, Tw.items_center, Tw.text_sm, Tw.font_medium, Css.hover [ Tw.bg_gray_50, Tw.text_gray_900 ] ] ]
            [ Icon.outline tab.icon [ Tw.text_gray_400, Tw.flex_shrink_0, Tw.neg_ml_1, Tw.mr_3, Tw.h_6, Tw.w_6 ]
            , span [ css [ Tw.truncate ] ] [ text tab.text ]
            ]


viewTabContent : Theme -> Model -> Html Msg
viewTabContent theme model =
    case model.tabActive of
        Schema ->
            viewSchemaUpload theme model

        Sample ->
            viewSample


viewSchemaUpload : Theme -> Model -> Html Msg
viewSchemaUpload theme model =
    div []
        ([ form []
            [ div []
                [ h2 [ css [ Tw.text_lg, Tw.leading_6, Tw.font_medium, Tw.text_gray_900 ] ] [ text "Import your SQL schema" ]
                , p [ css [ Tw.mt_1, Tw.text_sm, Tw.text_gray_500 ] ] [ text "Everything stay on your machine, don't worry about your schema privacy." ]
                ]
            , div [ css [ Tw.mt_6, Tw.grid, Tw.grid_cols_1, Tw.gap_y_6, Tw.gap_x_4, Bp.sm [ Tw.grid_cols_6 ] ] ]
                [ div [ css [ Bp.sm [ Tw.col_span_6 ] ] ]
                    [ viewFileUpload theme
                    ]
                ]
            ]
         ]
            ++ (Maybe.map2
                    (\file p ->
                        [ div [ css [ Tw.mt_6 ] ] [ Divider.withLabel (model.project |> M.mapOrElse (\_ -> "Parsed!") "Parsing ...") ]
                        , viewLogs file.name p
                        , viewErrorAlert p
                        ]
                    )
                    model.schemaFile
                    model.schemaParser
                    |> Maybe.withDefault []
               )
            ++ (model.project |> M.mapOrElse (\p -> [ viewActions theme p ]) [])
        )


viewFileUpload : Theme -> Html Msg
viewFileUpload theme =
    let
        id : String
        id =
            "file-upload"
    in
    label
        ([ for id, role "button", css [ Tw.mt_1, Tw.flex, Tw.justify_center, Tw.px_6, Tw.pt_5, Tw.pb_6, Tw.border_2, Tw.border_gray_300, Tw.border_dashed, Tw.rounded_md, Tw.text_gray_600, Tu.focusWithinRing ( theme.color, L600 ) ( White, L600 ), Css.hover [ TwColor.render Border theme.color L400, TwColor.render Text theme.color L600 ] ] ]
            ++ FileInput.onDrop
                { onOver = \_ _ -> FileDragOver
                , onLeave = Just { id = id ++ "-label", msg = FileDragLeave }
                , onDrop = \head _ -> LoadLocalFile head
                }
        )
        [ div [ css [ Tw.space_y_1, Tw.text_center ] ]
            [ Icon.outline DocumentAdd [ Tw.mx_auto, Tw.h_12, Tw.w_12 ]
            , div [ css [ Tw.flex, Tw.text_sm ] ]
                [ span [ css [ Tw.relative, Tw.cursor_pointer, Tw.bg_white, Tw.rounded_md, Tw.font_medium, TwColor.render Text theme.color L600 ] ]
                    [ span [] [ text "Upload a file" ]
                    , FileInput.hiddenInputSingle id [ ".sql" ] LoadLocalFile
                    ]
                , p [ css [ Tw.pl_1 ] ] [ text "or drag and drop" ]
                ]
            , p [ css [ Tw.text_xs ] ] [ text "SQL only" ]
            ]
        ]


viewLogs : FileName -> ProjectParser.Model msg -> Html msg
viewLogs fileName model =
    div [ css [ Tw.mt_6, Tw.px_4, Tw.py_2, Tw.max_h_96, Tw.overflow_y_auto, Tw.font_mono, Tw.text_xs, Tw.bg_gray_50, Tw.shadow, Tw.rounded_lg ] ]
        ([ div [] [ text ("Loaded file " ++ fileName ++ ".") ] ]
            ++ (model.lines |> M.mapOrElse (\l -> [ div [] [ text ("The file has " ++ (l |> List.length |> String.fromInt) ++ " lines.") ] ]) [])
            ++ (model.statements |> M.mapOrElse (\s -> [ div [] [ text ("Found " ++ (s |> Dict.size |> String.fromInt) ++ " SQL statements in it.") ] ]) [])
            ++ (model.commands
                    |> M.mapOrElse
                        (\commands ->
                            commands
                                |> Dict.toList
                                |> List.sortBy (\( i, _ ) -> i)
                                |> List.map (\( _, ( s, r ) ) -> r |> R.bimap (\e -> ( s, e )) (\c -> ( s, c )))
                                |> R.partition
                                |> (\( errs, cmds ) ->
                                        if errs |> List.isEmpty then
                                            [ div [] [ text "All statements are correctly parsed." ] ]

                                        else
                                            (errs |> List.map (\( s, e ) -> viewParseError s e))
                                                ++ [ div [] [ text ((cmds |> List.length |> String.fromInt) ++ " statements are correctly parsed, " ++ (errs |> List.length |> String.fromInt) ++ " are in error.") ] ]
                                   )
                        )
                        []
               )
            ++ (if model.schemaErrors |> List.isEmpty then
                    []

                else
                    (model.schemaErrors |> List.map viewSchemaError) ++ [ div [] [ text ((model.schemaErrors |> List.length |> String.fromInt) ++ " statements can't be added to the schema.") ] ]
               )
            ++ (model.schema |> M.mapOrElse (\s -> [ div [] [ text ("The built schema has " ++ (s |> Dict.size |> String.fromInt) ++ " tables.") ] ]) [])
        )


viewParseError : SqlStatement -> List ParseError -> Html msg
viewParseError statement errors =
    div [ css [ Tw.text_red_500 ] ]
        (div [] [ text ("Paring error line " ++ (statement.head.line |> String.fromInt) ++ ":") ]
            :: (errors |> List.map (\error -> div [ css [ Tw.pl_3 ] ] [ text error ]))
        )


viewSchemaError : List SchemaError -> Html msg
viewSchemaError errors =
    div [ css [ Tw.text_red_500 ] ]
        (div [] [ text "Schema error:" ]
            :: (errors |> List.map (\error -> div [ css [ Tw.pl_3 ] ] [ text error ]))
        )


viewErrorAlert : ProjectParser.Model msg -> Html Msg
viewErrorAlert model =
    let
        parseErrors : List (List ParseError)
        parseErrors =
            model.commands |> Maybe.map (\commands -> commands |> Dict.values |> List.filterMap (\( _, r ) -> r |> R.toErrMaybe)) |> Maybe.withDefault []
    in
    if (parseErrors |> List.isEmpty) && (model.schemaErrors |> List.isEmpty) then
        div [] []

    else
        div [ css [ Tw.mt_6 ] ]
            [ Alert.withActions
                { color = Red
                , icon = XCircle
                , title = "Oh no! We had " ++ (((parseErrors |> List.length) + (model.schemaErrors |> List.length)) |> String.fromInt) ++ " errors."
                , description = p [] [ text "Parsing every SQL dialect is not a trivial task. But every error report allows to improve it.", br [] [], bText "Please send it", text ", you will be able to edit it if needed to remove your private information." ]
                , actions = [ Link.light2 Red [ href (sendErrorReport parseErrors model.schemaErrors) ] [ text "Send error report" ] ]
                }
            ]


sendErrorReport : List (List ParseError) -> List (List SchemaError) -> String
sendErrorReport parseErrors schemaErrors =
    let
        email : String
        email =
            constants.azimuttEmail

        subject : String
        subject =
            "[Azimutt] SQL Parser error report"

        body : String
        body =
            "Hi Azimutt team!\nGot some errors using the Azimutt SQL parser.\nHere are the details..."
                ++ (if parseErrors |> List.isEmpty then
                        ""

                    else
                        "\n\n\n------------------------------------------------------------- Parsing errors -------------------------------------------------------------\n\n"
                            ++ (parseErrors |> List.indexedMap (\i errors -> String.fromInt (i + 1) ++ ".\n" ++ (errors |> String.join "\n")) |> String.join "\n\n")
                   )
                ++ (if schemaErrors |> List.isEmpty then
                        ""

                    else
                        "\n\n\n------------------------------------------------------------- Schema errors -------------------------------------------------------------\n\n"
                            ++ (schemaErrors |> List.indexedMap (\i errors -> String.fromInt (i + 1) ++ ".\n" ++ (errors |> String.join "\n")) |> String.join "\n\n")
                   )
    in
    "mailto:" ++ email ++ "?subject=" ++ percentEncode subject ++ "&body=" ++ percentEncode body


viewActions : Theme -> Project -> Html Msg
viewActions theme project =
    div [ css [ Tw.mt_6 ] ]
        [ div [ css [ Tw.flex, Tw.justify_end ] ]
            [ Button.white3 theme.color [ onClick DropSchema ] [ text "Trash this schema" ]
            , Button.primary3 theme.color [ onClick (CreateProject project), css [ Tw.ml_3 ] ] [ text "Create project!" ]
            ]
        ]


viewSample : Html msg
viewSample =
    div [] [ text "Sample" ]
