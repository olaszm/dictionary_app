import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import types.{
  type Definition, type ErrorResponse, type Model, type Msg, type Phonetic,
  UserClickedOnSynonym, UserPausedAudio, UserPlayedAudio, UserPressedEnter,
  UserSearch, UserSetText,
}

pub fn error_display(err: Option(ErrorResponse)) -> Element(Msg) {
  html.div([], [
    case err {
      None -> {
        element.none()
      }
      Some(e) -> {
        html.text(e.message)
      }
    },
  ])
}

pub fn def_view(def: List(Definition)) -> Element(Msg) {
  case list.length(def) {
    0 -> element.none()
    _ ->
      html.div([attribute.class("mt-2")], [
        html.p([attribute.class("italic")], [html.text("Meaning")]),
        html.ul(
          [attribute.class("list-disc")],
          list.map(def, fn(s) {
            html.li([attribute.class("ml-4")], [html.text(s.def)])
          }),
        ),
      ])
  }
}

pub fn synonym_view(syn: List(String)) -> Element(Msg) {
  case list.length(syn) {
    0 -> element.none()
    _ ->
      html.div([attribute.class("mt-2 flex gap-2 flex-wrap")], [
        html.p([attribute.class("italic")], [html.text("Synonyms: ")]),
        ..list.map(syn, fn(s) {
          html.p([], [
            html.a(
              [
                attribute.class("text-purple-500 cursor-pointer"),
                event.on_click(UserClickedOnSynonym(s)),
              ],
              [html.text(s)],
            ),
          ])
        })
      ])
  }
}

pub fn audio_view(
  model: Model,
  phonetics: List(Phonetic),
  word: String,
) -> Element(Msg) {
  let phonetic = list.find(phonetics, fn(x) { x.audio != "" })
  case phonetic {
    Error(_) -> {
      element.none()
    }
    Ok(p) -> {
      html.div(
        [attribute.class("flex gap-4 w-full items-center justify-between")],
        [
          html.div([], [
            html.h1([attribute.class("text-4xl")], [html.text(word)]),
            case p.text {
              None -> element.none()
              Some(t) -> {
                html.p([attribute.class("text-purple-500")], [html.text(t)])
              }
            },
          ]),
          html.div(
            [
              attribute.class(
                "aspect-square size-10 flex align-center  select-none  cursor-pointer justify-center align-center border border-purple-500 bg-purple-500 rounded-4xl p-2",
              ),
              case model.is_playing {
                False -> event.on_click(UserPlayedAudio("phonetic-audio"))
                True -> event.on_click(UserPausedAudio("phonetic-audio"))
              },
            ],
            [
              case model.is_playing {
                False -> html.p([attribute.class("h-auto")], [html.text("⏵")])
                True -> html.p([attribute.class("h-auto")], [html.text("⏸")])
              },
              html.audio(
                [attribute.id("phonetic-audio"), attribute.src(p.audio)],
                [],
              ),
            ],
          ),
        ],
      )
    }
  }
}

fn loader(is_loading: Bool) -> Element(Msg) {
  html.div([attribute.class("loader")], [
    case is_loading {
      True -> html.text("Loading..")
      False -> element.none()
    },
  ])
}

fn word_input(txt: String) -> Element(Msg) {
  html.div(
    [attribute.class("flex gap-2 my-4 bg-gray-400 rounded-xl py-2 px-3")],
    [
      html.input([
        attribute.class("w-full"),
        attribute.placeholder("Enter a word"),
        attribute.value(txt),
        event.on_input(UserSetText),
        event.on_keydown(UserPressedEnter),
      ]),
      html.button(
        [event.on_click(UserSearch), attribute.class("px-2 text-white-500")],
        [html.text("Search")],
      ),
    ],
  )
}

fn content_area(model: Model) -> Element(Msg) {
  html.div([attribute.class("content")], [
    case model.data {
      None -> {
        element.none()
      }
      Some(word) -> {
        html.div([attribute.class("main")], [
          audio_view(model, word.phonetics, word.word),
          html.div([], [
            html.div(
              [attribute.class("synonyms")],
              list.map(word.meanings, fn(m) {
                html.div([attribute.class("my-4")], [
                  html.p([attribute.class("italic font-bold")], [
                    html.text(m.part_of_speech),
                  ]),
                  def_view(m.definitions),
                  synonym_view(m.synonyms),
                ])
              }),
            ),
          ]),
        ])
      }
    },
  ])
}

fn header() -> Element(Msg) {
  html.div([attribute.class("text-4xl mt-4 text-center text-white-500")], [
    html.text("Dictionary App"),
  ])
}

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("w-responsive container mx-auto h-screen px-2")], [
    header(),
    word_input(model.txt),
    loader(model.loading),
    error_display(model.error_text),
    content_area(model),
  ])
}
