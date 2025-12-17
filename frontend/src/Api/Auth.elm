module Api.Auth exposing (..)

import Http
import Json.Decode as Decode
import Json.Encode as Encode


type alias LoginResponse =
    { ok : Bool
    , message : String
    , id : Maybe String
    , accessToken : Maybe String
    }


type alias UserResponse =
    { username : String
    , email : String
    , firstname : String
    , lastname : String
    , createdAt : String
    }


baseUrl : String
baseUrl =
    "http://localhost:3000"


loginDecoder : Decode.Decoder LoginResponse
loginDecoder =
    Decode.map4 LoginResponse
        (Decode.field "ok" Decode.bool)
        (Decode.field "message" Decode.string)
        (Decode.maybe (Decode.field "id" Decode.string))
        (Decode.maybe (Decode.field "accessToken" Decode.string))


userDecoder : Decode.Decoder UserResponse
userDecoder =
    Decode.map5 UserResponse
        (Decode.field "username" Decode.string)
        (Decode.field "email" Decode.string)
        (Decode.field "firstname" Decode.string)
        (Decode.field "lastname" Decode.string)
        (Decode.field "createdAt" Decode.string)


login : Encode.Value -> (Result Http.Error LoginResponse -> msg) -> Cmd msg
login body toMsg =
    Http.request
        { method = "POST"
        , headers = []
        , url = baseUrl ++ "/auth/login"
        , body = Http.jsonBody body
        , expect = Http.expectJson toMsg loginDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


signup : Encode.Value -> Cmd (Result Http.Error String)
signup body =
    Http.post
        { url = baseUrl ++ "/auth/signup"
        , body = Http.jsonBody body
        , expect = Http.expectString identity
        }





getUser : Maybe String -> Maybe String -> (Result Http.Error UserResponse -> msg) -> Cmd msg
getUser maybeAccessToken maybeId toMsg =
    case ( maybeAccessToken, maybeId ) of
        ( Just token, Just id ) ->
            Http.request
                { method = "GET"
                , headers = [ Http.header "Authorization" ("Bearer " ++ token) ]
                , url = baseUrl ++ "/users/" ++ id
                , body = Http.emptyBody
                , expect = Http.expectJson toMsg userDecoder
                , timeout = Nothing
                , tracker = Nothing
                }
        _ ->
            Cmd.none
getExerciseResults : Maybe String -> Maybe String -> (Result Http.Error UserResponse -> msg) -> Cmd msg
getExerciseResults maybeAccessToken maybeId toMsg =
    case ( maybeAccessToken, maybeId ) of
        ( Just token, Just id ) ->
            Http.request
                { method = "GET"
                , headers = [ Http.header "Authorization" ("Bearer " ++ token) ]
                , url = baseUrl ++ "/users/" ++ id
                , body = Http.emptyBody
                , expect = Http.expectJson toMsg userDecoder
                , timeout = Nothing
                , tracker = Nothing
                }
        _ ->
            Cmd.none






--refresh token, do i even need to return anything in the expectJson? i just need to update the accessToken stored in the cookie maybe
-- refreshToken : (Result Http.Error RefreshResponse -> msg) -> Cmd msg
-- refreshToken toMsg =
--     Http.request
--         { method = "POST"
--         , headers = []
--         , url = baseUrl ++ "/auth/refresh"
--         , body = Http.emptyBody
--         , expect = Http.expectJson toMsg accessTokenDecoder
--         , timeout = Nothing
--         , tracker = Nothing
--         }
