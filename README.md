# ask-my-notes
On-the-fly RAG for Craft (craft.do) notes exports

## Prerequisites

- Python 3.11
- llm (https://github.com/simonw/llm), install via pip.
- arc-cli (https://github.com/GeorgeSG/arc-cli), install via npm.

## Setup

- Create a directory for Ask My Notes data, scripts, and logs, e.g. `/Users/you/ask-my-notes`.
- Copy everything from this repository into that directory.
- `mkdir craft_notes_md` in that directory, this is where copies of your notes will be stored.
- `mkdir qlog` for question logs in that directory, for logs.
- Set `ASK_MY_NOTES_HOME` environment variable to the directory you created in the previous step.
- Add $ASK_MY_NOTES_HOME/bin to your shell's PATH.

## TODO

- An install script that installs the necessary prerequisites, adds to path, etc.
