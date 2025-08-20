# ask-my-notes
On-the-fly RAG for Craft (craft.do) notes exports

## Prerequisites

- Python 3.11
- llm (https://github.com/simonw/llm), install via pip.
- arc-cli (https://github.com/GeorgeSG/arc-cli), install via npm.

## Setup (WIP)

- Create a directory for Ask My Notes data, scripts, and logs, e.g. `/Users/you/ask-my-notes`.
- Copy everything from this repository into that directory.
- `mkdir craft_notes_md` in that directory, this is where copies of your notes will be stored.
- `mkdir qlog` for question logs in that directory, for logs.
- Set `ASK_MY_NOTES_HOME` environment variable to the directory you created in the previous step.
- Add $ASK_MY_NOTES_HOME/bin to your shell's PATH.
- Create a virtualenv in that directory.
- Pip install llm and npm install arc-cli.

## Updating the index

- Export all notes from Craft, e.g. to `/Users/you/tmp/Craft_Export_20250421_TextBundle`
- Run `pull_craft_notes.sh ~/Users/you/tmp/Craft_Notes_Exports/Export_20250421_TextBundle`

## Querying the index

- Just using a search expression: `ask-my-notes.sh -g reranking`
- Search expression and prompt: `ask-my-notes.sh -g 2025 -p "What books have I read this year?"`
- A file match pattern and prompt: `ask-my-notes.sh -f 2025 -p "Summarize all of the articles I've linked this year"`

## TODO

- An install script that installs the necessary prerequisites, adds to path, etc.
