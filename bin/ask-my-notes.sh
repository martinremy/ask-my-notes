#!/usr/bin/env bash

# The model must be capable of structured output
# DEFAULT_MODEL="claude-3.5-sonnet"
DEFAULT_MODEL="gemini-2.0-flash-exp"
# DEFAULT_MODEL="gemini-2.5-pro-exp-03-25"
# DEFAULT_MODEL="gemini-2.0-pro-exp-02-05"
# DEFAULT_MODEL="claude-3.7-sonnet"

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

FILE_MATCH_PATTERN=""
PROMPT=""
LLM_MODEL=""

while getopts "f:p:m:" opt; do
  case $opt in
    f) FILE_MATCH_PATTERN="$OPTARG" ;;
    g) GREP_REGEX="$OPTARG" ;;
    p) PROMPT="$OPTARG" ;;
    m) LLM_MODEL="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
  esac
done

shift $((OPTIND-1))

if [ -z "$FILE_MATCH_PATTERN" ]; then
  FILE_MATCH_PATTERN=".*\.md"
else
  FILE_MATCH_PATTERN="$FILE_MATCH_PATTERN.*\.md"
fi

if [ -z "$GREP_REGEX" ]; then
  GREP_REGEX=".*"
fi

if [ -z "$PROMPT" ] && [ -z "$GREP_REGEX" ]; then
  echo "Usage: $0 [-f \"file_match_pattern\"] [-p \"prompt\"][-m model] [-g \"search_regex\"]"
  echo "You must specify either a prompt or a grep regex"
  exit 1
fi

if [ -z "$LLM_MODEL" ]; then
  LLM_MODEL="$DEFAULT_MODEL"
fi

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

echo "Asking your notes: -f [$FILE_MATCH_PATTERN] -p [$PROMPT] SEARCH:[$GREP_REGEX]"

files_to_search=$(find "$ASK_MY_NOTES_MD_DIR" -print | egrep -i "$FILE_MATCH_PATTERN")
echo -e "\nSearching files:\n$files_to_search"

echo -e "\nUsing model: $LLM_MODEL ..."

echo "$files_to_search" | ack -xil "$GREP_REGEX" \
    | xargs files-to-prompt -c \
    | cat - <(echo "$INSTRUCTIONS") \
    | llm -m $LLM_MODEL --schema "html: The html content of the response" | tee $tmpfile

jq -r '.html' < $tmpfile > $outfile
rm $tmpfile
echo "<hr>Parameters<br/>-f [$FILE_MATCH_PATTERN]</br>-p [$PROMPT]<br/>-g [$GREP_REGEX]<br/>SEARCH:[$SEARCH_REGEX]" | tee -a $outfile

arc-cli new-tab file://$outfile
