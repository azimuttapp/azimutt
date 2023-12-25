module PagesComponents.Organization_.Project_.Views.Navbar.TitleTest exposing (..)

import Dict
import Expect
import Libs.Time as Time
import PagesComponents.Organization_.Project_.Models.ErdLayout as ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Views.Navbar.Title exposing (LayoutFolder(..), buildFolders)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "PagesComponents.Organization_.Project_.Views.Navbar.Title"
        [ describe "buildFolders"
            [ test "simple list"
                (\_ ->
                    ([ "a", "b", "c" ] |> List.map (\name -> ( name, layout )) |> Dict.fromList |> buildFolders)
                        |> Expect.equal
                            [ LayoutItem "a" ( "a", layout )
                            , LayoutItem "b" ( "b", layout )
                            , LayoutItem "c" ( "c", layout )
                            ]
                )
            , test "nested folders"
                (\_ ->
                    ([ "a/1", "a / 2", "a/3/a", "a/3/b" ] |> List.map (\name -> ( name, layout )) |> Dict.fromList |> buildFolders)
                        |> Expect.equal
                            [ LayoutFolder "a"
                                [ LayoutItem "1" ( "a/1", layout )
                                , LayoutItem "2" ( "a / 2", layout )
                                , LayoutFolder "3"
                                    [ LayoutItem "a" ( "a/3/a", layout )
                                    , LayoutItem "b" ( "a/3/b", layout )
                                    ]
                                ]
                            ]
                )
            , test "folder layout"
                (\_ ->
                    ([ "a", "a/1", "a / 2" ] |> List.map (\name -> ( name, layout )) |> Dict.fromList |> buildFolders)
                        |> Expect.equal
                            [ LayoutFolder "a"
                                [ LayoutItem "" ( "a", layout )
                                , LayoutItem "1" ( "a/1", layout )
                                , LayoutItem "2" ( "a / 2", layout )
                                ]
                            ]
                )
            , test "flattened folders"
                (\_ ->
                    ([ "a/1/a", "b/1/a", "b/1/b" ] |> List.map (\name -> ( name, layout )) |> Dict.fromList |> buildFolders)
                        |> Expect.equal
                            [ LayoutItem "a / 1 / a" ( "a/1/a", layout )
                            , LayoutFolder "b / 1"
                                [ LayoutItem "a" ( "b/1/a", layout )
                                , LayoutItem "b" ( "b/1/b", layout )
                                ]
                            ]
                )
            ]
        ]


layout : ErdLayout
layout =
    ErdLayout.empty Time.zero
