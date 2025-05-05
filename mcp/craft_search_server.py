# server.py
from fastmcp import FastMCP
import os
import re
import sys

# Check if ASK_MY_NOTES_HOME is set
if "ASK_MY_NOTES_HOME" not in os.environ:
    print("Error: ASK_MY_NOTES_HOME environment variable is not set")
    sys.exit(1)

ASK_MY_NOTES_MD_DIR = os.path.join(os.environ["ASK_MY_NOTES_HOME"], "craft_notes_md")
ASK_MY_NOTES_LOG_DIR = os.path.join(os.environ["ASK_MY_NOTES_HOME"], "qlog")

mcp = FastMCP("Craft Search")


def regex_search_in_files(directory: str, pattern: str) -> list[str]:
    matching_files = []
    regex = re.compile(pattern, re.IGNORECASE)

    for filename in os.listdir(directory):
        if filename.endswith(".md"):
            file_path = os.path.join(directory, filename)
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    contents = f.read()
                    if regex.search(contents):
                        matching_files.append(filename)
            except Exception as e:
                print(f"Could not read {file_path}: {e}")

    return matching_files


def gen_note_context(directory: str, files: list[str]) -> str:
    note_context = "<documents>\n"
    doc_index = 1
    for file in files:
        with open(os.path.join(directory, file), "r") as f:
            note_context += f"""
<document index="{doc_index}">
<source>{file}</source>
{f.read()}
</document>
"""
        doc_index += 1

    note_context += "</documents>"
    return note_context


# @mcp.tool()
# def add(a: int, b: int) -> int:
#     """Add two numbers"""
#     return a * b


# @mcp.tool()
# def reverse(word: str) -> str:
#     """Reverse a word"""
#     return word[::-1]


@mcp.tool()
def search_notes_by_filename(pattern: str) -> str:
    """Get all notes where the filename contains or matches a pattern.
    If the user asks for notes CALLED "reading.*2025", this tool will return all notes containing "reading.*2025".
    """

    regex = re.compile(pattern, re.IGNORECASE)
    matching_files = [f for f in os.listdir(ASK_MY_NOTES_MD_DIR) if regex.search(f)]
    matching_files_content = gen_note_context(ASK_MY_NOTES_MD_DIR, matching_files)
    return matching_files_content


@mcp.tool()
def search_notes_by_content(pattern: str) -> str:
    """Get notes where the content contains or matches a pattern.
    If the user asks for notes ABOUT "reading", this tool will return all notes containing "reading".
    """

    matching_files = regex_search_in_files(ASK_MY_NOTES_MD_DIR, pattern)
    matching_files_content = gen_note_context(ASK_MY_NOTES_MD_DIR, matching_files)
    return matching_files_content


if __name__ == "__main__":
    # tool_output = search_notes_by_filename("reading.*2025")
    # print(tool_output)

    # tool_output = search_notes_by_content("trump")
    # print(tool_output)

    mcp.run()
