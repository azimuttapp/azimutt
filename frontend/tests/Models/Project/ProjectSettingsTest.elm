module Models.Project.ProjectSettingsTest exposing (..)

import Expect
import Libs.Nel as Nel
import Models.Project.ProjectSettings as ProjectSettings
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "ProjectSettings"
        [ describe "removeColumn"
            [ test "created_by" (\_ -> "created_by" |> Nel.from |> ProjectSettings.removeColumn "created_by, updated_.+" |> Expect.equal True)
            , test "created_at" (\_ -> "created_at" |> Nel.from |> ProjectSettings.removeColumn "created_by, updated_.+" |> Expect.equal False)
            , test "updated_by" (\_ -> "updated_by" |> Nel.from |> ProjectSettings.removeColumn "created_by, updated_.+" |> Expect.equal True)
            , test "updated_at" (\_ -> "updated_at" |> Nel.from |> ProjectSettings.removeColumn "created_by, updated_.+" |> Expect.equal True)
            , test "data.updated_at" (\_ -> "data.updated_at" |> Nel.from |> ProjectSettings.removeColumn "updated_.+" |> Expect.equal True)
            , test "data.updated_by" (\_ -> "data.updated_by" |> Nel.from |> ProjectSettings.removeColumn "^updated_.+" |> Expect.equal False)
            ]
        ]
