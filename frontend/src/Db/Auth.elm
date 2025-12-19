module Db.Auth exposing (..)

import Http
import Json.Decode as Decode
import Json.Encode as Encode


type alias LoginResponse =
    { ok : Bool
    , message : String
    }


type alias RegisterResponse =
    { ok : Bool
    , message : String
    }


type alias UserResponse =
    { user : Maybe User
    }


type alias User =
    { email : String
    , firstname : String
    , lastname : String
    , createdAt : String
    }


baseUrl : String
baseUrl =
    "http://localhost:3000"


loginDecoder : Decode.Decoder LoginResponse
loginDecoder =
    Decode.map2 LoginResponse
        (Decode.field "ok" Decode.bool)
        (Decode.field "message" Decode.string)


registerDecoder : Decode.Decoder RegisterResponse
registerDecoder =
    Decode.map2 RegisterResponse
        (Decode.field "ok" Decode.bool)
        (Decode.field "message" Decode.string)


userResponseDecoder : Decode.Decoder UserResponse
userResponseDecoder =
    Decode.map UserResponse
        (Decode.field "user" (Decode.maybe userDecoder))


userDecoder : Decode.Decoder User
userDecoder =
    Decode.map4 User
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


register : Encode.Value -> (Result Http.Error RegisterResponse -> msg) -> Cmd msg
register body toMsg =
    Http.request
        { method = "POST"
        , headers = []
        , url = baseUrl ++ "/auth/register"
        , body = Http.jsonBody body
        , expect = Http.expectJson toMsg registerDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


getMe : (Result Http.Error UserResponse -> msg) -> Cmd msg
getMe toMsg =
    Http.request
        { method = "GET"
        , headers = []
        , url = baseUrl ++ "/users/me"
        , body = Http.emptyBody
        , expect = Http.expectJson toMsg userResponseDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


getExerciseResults : Maybe String -> Maybe String -> (Result Http.Error UserResponse -> msg) -> Cmd msg
getExerciseResults maybeAccessToken maybeId toMsg =
    case ( maybeAccessToken, maybeId ) of
        ( Just token, Just id ) ->
            Http.request
                { method = "GET"
                , headers = [ Http.header "Authorization" ("Bearer " ++ token) ]
                , url = baseUrl ++ "/users/" ++ id
                , body = Http.emptyBody
                , expect = Http.expectJson toMsg userResponseDecoder
                , timeout = Nothing
                , tracker = Nothing
                }

        _ ->
            Cmd.none


refreshToken : (Result Http.Error () -> msg) -> Cmd msg
refreshToken toMsg =
    Http.request
        { method = "POST"
        , headers = []
        , url = baseUrl ++ "/auth/refresh"
        , body = Http.emptyBody
        , expect = Http.expectWhatever toMsg
        , timeout = Nothing
        , tracker = Nothing
        }


logout : (Result Http.Error () -> msg) -> Cmd msg
logout toMsg =
    Http.post
        { url = baseUrl ++ "/auth/logout"
        , body = Http.emptyBody
        , expect = Http.expectWhatever toMsg
        }
