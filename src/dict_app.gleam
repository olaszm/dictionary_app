import components
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import lustre
import lustre/effect.{type Effect}
import rsvp

import api.{get_word_data}
import types.{
  type Model, type Msg, ApiReturnedWord, AudioEnded, Model, UserClickedOnSynonym,
  UserPausedAudio, UserPlayedAudio, UserPressedEnter, UserSearch, UserSetText,
}

@external(javascript, "./js_wrapper/index.js", "tryPlayAudio")
fn try_play_audio(element_id: String, cb: fn() -> Nil) -> Nil

@external(javascript, "./js_wrapper/index.js", "tryPause")
fn try_pause_audio(element_id: String, cb: fn() -> Nil) -> Nil

fn init(_flags) -> #(Model, Effect(Msg)) {
  #(Model(False, "", None, False, None), effect.none())
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserSetText(s) -> {
      let t = s |> string.trim()
      #(Model(..model, txt: t), effect.none())
    }
    UserSearch -> {
      case string.length(model.txt) {
        0 -> #(model, effect.none())
        _ -> #(
          Model(..model, loading: True, error_text: None),
          get_word_data(model.txt),
        )
      }
    }
    ApiReturnedWord(Ok(data)) -> {
      case list.first(data) {
        Ok(word) -> #(
          Model(..model, loading: False, data: Some(word), error_text: None),
          effect.none(),
        )
        Error(_) -> {
          #(
            Model(..model, loading: False, data: None, error_text: None),
            effect.none(),
          )
        }
      }
    }
    ApiReturnedWord(Error(err)) -> {
      case err {
        rsvp.HttpError(data) -> {
          case api.decode_error(data.body) {
            Ok(data) -> #(
              Model(..model, loading: False, error_text: Some(data)),
              effect.none(),
            )

            Error(_) -> {
              #(Model(..model, loading: False, error_text: None), effect.none())
            }
          }
        }
        _ -> #(Model(..model, loading: False), effect.none())
      }
    }

    UserClickedOnSynonym(str) -> {
      #(
        Model(..model, txt: str, loading: True, data: None, error_text: None),
        get_word_data(str),
      )
    }
    UserPressedEnter(str) -> {
      case str {
        "Enter" -> #(
          Model(
            ..model,
            txt: model.txt,
            loading: True,
            data: None,
            error_text: None,
          ),
          get_word_data(model.txt),
        )
        _ -> #(model, effect.none())
      }
    }
    UserPausedAudio(str) -> {
      let ended_effect =
        effect.from(fn(send) { try_pause_audio(str, fn() { send(AudioEnded) }) })
      #(Model(..model, is_playing: False), ended_effect)
    }
    UserPlayedAudio(str) -> {
      let ended_effect =
        effect.from(fn(send) { try_play_audio(str, fn() { send(AudioEnded) }) })
      #(Model(..model, is_playing: True), ended_effect)
    }
    AudioEnded -> {
      #(Model(..model, is_playing: False), effect.none())
    }
  }
}

pub fn main() {
  let app = lustre.application(init, update, components.view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
