#!/usr/bin/env bash

# The model must be capable of structured output
# LLM_MODEL="claude-3.5-sonnet"
# LLM_MODEL="gemini-2.0-flash-exp"
LLM_MODEL="gemini-2.5-pro-exp-03-25"
# LLM_MODEL="gemini-2.0-pro-exp-02-05"
# LLM_MODEL="claude-3.7-sonnet"

# Check if ASK_MY_NOTES_HOME is set
if [ -z "$ASK_MY_NOTES_HOME" ]; then
    echo "Error: ASK_MY_NOTES_HOME environment variable is not set"
    exit 1
fi

ASK_MY_NOTES_MD_DIR="$ASK_MY_NOTES_HOME/craft_notes_md"
ASK_MY_NOTES_LOG_DIR="$ASK_MY_NOTES_HOME/qlog"

# Check if the notes directory exists (the actual directory, not the environment variable)
if [ ! -d "$ASK_MY_NOTES_MD_DIR" ]; then
    echo "Error: Notes directory $ASK_MY_NOTES_MD_DIR does not exist"
    exit 1
fi

# Check if the log directory exists (the actual directory, not the environment variable)
if [ ! -d "$ASK_MY_NOTES_LOG_DIR" ]; then
    echo "Error: Log directory $ASK_MY_NOTES_LOG_DIR does not exist"
    exit 1
fi


if [ "$#" -lt 1 ]; then
    echo "Usage: $0 SEARCH_TERM [PROMPT]"
    exit 1
fi

SEARCH_TERM=$1
PROMPT=${2:-$SEARCH_TERM}  # Use SEARCH_TERM as PROMPT if PROMPT is not provided

INSTRUCTIONS=$(cat <<EOP
## INSTRUCTIONS
- You are my memory agent that has access to a collection of notes documents.
- Your task is to answer my questions based on the information provided in these notes documents.
- Refer to me in the second person singular (you), not in the third person.

## RESPONSE FORMAT
- Provide your answer as an HTML page.  Remember to use <br/> tags for line breaks.
- In addition to paragraphs, feel free to use sections, headers, and lists to make the answer more readable.

### CITATIONS
- Within your response, include citations to the notes documents that were used to generate your answer.
- The citations should be linked to the list of references at the end of your output.
- Use the following format for citations within the answer: [document_index] where document_index is the index of the document in the list of citations.
- Following your completed answer, provide a list of documents used in the following format.  Do not repeat any citations!  The format is:

References:
- [document_index] <a href="document_filename">document_filename</a>

## PROMPT
Using the information provided from my notes documents above,
answer the following question in markdown format: $PROMPT
EOP
)


# llm command is in the virtualenv in ASK_MY_NOTES_HOME, so go there
cd "$ASK_MY_NOTES_HOME" || { echo "Failed to change directory to $ASK_MY_NOTES_HOME"; exit 1; }

outfile="$ASK_MY_NOTES_LOG_DIR/q_$(date +"%Y-%m-%d_%H-%M-%S").html"
tmpfile="$ASK_MY_NOTES_LOG_DIR/q_$(date +"%Y-%m-%d_%H-%M-%S")_tmp.html"

clear; echo -e "Asking your notes: $PROMPT\nusing: $LLM_MODEL\n"

# Run the command with the most recent directory

ack -il "$SEARCH_TERM" "$ASK_MY_NOTES_MD_DIR" \
    | tr '\n' '\0' | xargs -0 files-to-prompt -c \
    | cat - <(echo "$INSTRUCTIONS") \
    | llm -m $LLM_MODEL --schema "html: The html content of the response" | tee $tmpfile

jq -r '.html' < $tmpfile > $outfile
rm $tmpfile
echo "<hr>Search was: $SEARCH_TERM<br/>Question was: $PROMPT<br/>Model was: $LLM_MODEL" | tee -a $outfile

arc-cli new-tab file://$outfile
