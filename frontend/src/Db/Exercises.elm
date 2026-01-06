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

type alias CompletedSubExercises =
    {
        completedSubExercises : List CompletedSubExercise
    }
type alias CompletedSubExercise =
    { id : Int
    , subExerciseId : Int
    , difficulty : Int
    , shuffled : Int
    }


baseUrl : String
baseUrl =
    "https://degree-project-production-6775.up.railway.app"


completedDecoder : Decode.Decoder CompletedResponse
completedDecoder =
    Decode.map2 CompletedResponse
        (Decode.field "ok" Decode.bool)
        (Decode.field "message" Decode.string)


subExerciseDecoder : Decode.Decoder SubExercise
subExerciseDecoder =
    Decode.map4 SubExercise
        (Decode.field "id" Decode.int)
        (Decode.field "exercise_id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "endpoints" (Decode.list Decode.string))




completedExercisesDecoder : Decode.Decoder CompletedSubExercises
completedExercisesDecoder =
    Decode.map CompletedSubExercises
        (Decode.field "completed_exercises" (Decode.list completedExerciseDecoder))



completedExerciseDecoder : Decode.Decoder CompletedSubExercise
completedExerciseDecoder =
    Decode.map4 CompletedSubExercise
        (Decode.field "id" Decode.int)
        (Decode.field "sub_exercise_id" Decode.int)
        (Decode.field "difficulty" Decode.int)
        (Decode.field "shuffled" Decode.int)



fetchSubExercises : String -> (Result Http.Error (List SubExercise) -> msg) -> Cmd msg
fetchSubExercises exerciseId toMsg =
    Http.get
        { url = baseUrl ++ "/sub-exercises/exercise-id/" ++ exerciseId
        , expect = Http.expectJson toMsg (Decode.list subExerciseDecoder)
        }


fetchCompletedExercises : (Result Http.Error  CompletedSubExercises -> msg) -> Cmd msg
fetchCompletedExercises toMsg =
    Http.request
        { method = "GET"
        , headers = []
        , url = baseUrl ++ "/completed-exercises"
        , body = Http.emptyBody
        , expect = Http.expectJson toMsg completedExercisesDecoder
        , timeout = Nothing
        , tracker = Nothing
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



buildErrorMessage : Http.Error -> String
buildErrorMessage httpError =
    case httpError of
        Http.BadUrl message ->
            "BadUrl: " ++ message

        Http.Timeout ->
            "Server is taking too long to respond. Please try again later"

        Http.NetworkError ->
            "Unable to reach server"

        Http.BadStatus statusCode ->
            "Request failed with status code: " ++ (statusCode |> String.fromInt)

        Http.BadBody message ->
            "BadBody: " ++ message
