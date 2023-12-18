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
        [ test "buildFolders"
            (\_ ->
                [ "c/1", " a / 2 ", "a", "b", "a/1", "d/1", "d/2", "d/3/a", "d/3/b" ]
                    |> List.map (\name -> ( name, layout ))
                    |> Dict.fromList
                    |> buildFolders
                    |> Expect.equal
                        [ LayoutFolder "a"
                            [ LayoutItem "" ( "a", layout )
                            , LayoutItem "1" ( "a/1", layout )
                            , LayoutItem "2" ( " a / 2 ", layout )
                            ]
                        , LayoutItem "b" ( "b", layout )
                        , LayoutItem "c/1" ( "c/1", layout )
                        , LayoutFolder "d"
                            [ LayoutItem "1" ( "d/1", layout )
                            , LayoutItem "2" ( "d/2", layout )
                            , LayoutFolder "3"
                                [ LayoutItem "a" ( "d/3/a", layout )
                                , LayoutItem "b" ( "d/3/b", layout )
                                ]
                            ]
                        ]
            )
        ]


layout : ErdLayout
layout =
    ErdLayout.empty Time.zero
