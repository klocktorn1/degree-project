module Db.Exercises exposing (..)

import Http
import Json.Decode as Decode
import Json.Encode as Encode


type alias SubExercise =
    { id : Int
    , exerciseId : Int
    , name : String
    , endpoints : List String
    }

type alias CompletedResponse =
    { ok : Bool
    , message : String
    }

completedDecoder : Decode.Decoder CompletedResponse
completedDecoder =
    Decode.map2 CompletedResponse
        (Decode.field "ok" Decode.bool)
        (Decode.field "message" Decode.string)


baseUrl : String
baseUrl =
    "http://localhost:3000"


subExerciseDecoder : Decode.Decoder SubExercise
subExerciseDecoder =
    Decode.map4 SubExercise
        (Decode.field "id" Decode.int)
        (Decode.field "exercise_id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "endpoints" (Decode.list Decode.string))


fetchSubExercises : String -> (Result Http.Error (List SubExercise) -> msg) -> Cmd msg
fetchSubExercises exerciseId toMsg =
    Http.get
        { url = baseUrl ++ "/sub-exercises/exercise-id/" ++ exerciseId
        , expect = Http.expectJson toMsg (Decode.list subExerciseDecoder)
        }


createCompletedExerciseEntry : Encode.Value -> (Result Http.Error CompletedResponse -> msg) -> Cmd msg
createCompletedExerciseEntry body toMsg =
    Http.request
        { method = "POST"
        , headers = []
        , url = baseUrl ++ "/completed-exercises"
        , body = Http.jsonBody body
        , expect = Http.expectJson toMsg completedDecoder
        , timeout = Nothing
        , tracker = Nothing
        }
