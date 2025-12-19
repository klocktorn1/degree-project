module Db.Exercises exposing (..)

import Http
import Json.Decode as Decode


type alias SubExercise =
    { exerciseId : Int
    , name : String
    , endpoints : List String
    }


baseUrl : String
baseUrl =
    "http://localhost:3000"


subExerciseDecoder : Decode.Decoder SubExercise
subExerciseDecoder =
    Decode.map3 SubExercise
        (Decode.field "exercise_id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "endpoints" (Decode.list Decode.string))


fetchSubExercises : String -> (Result Http.Error (List SubExercise) -> msg) -> Cmd msg
fetchSubExercises exerciseId toMsg =
    Http.get
        { url = baseUrl ++ "/sub-exercises/exercise-id/" ++ exerciseId
        , expect = Http.expectJson toMsg (Decode.list subExerciseDecoder)
        }
