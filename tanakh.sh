#!/bin/bash

# explore the hebrew bible; tanakh
# usage: tanakh.sh <book> <chapter:verse or chapter>, or nothing for random verse
# examples: 
#   tanakh.sh
#   tanakh.sh genesis 1:1
#   tanakh.sh genesis 1

# Automatically detect tanakh.txt in the same directory as the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEXT_FILE="$SCRIPT_DIR/tanakh.txt"

if [ ! -f "$TEXT_FILE" ]; then
    echo "error: complete text file not found at $TEXT_FILE"
    exit 1
fi

if [ $# -eq 0 ]; then
    # no arguments random verse
    # Find all verse references (lines that end with chapter:verse pattern)
    VERSE_LINES=$(grep -n " [0-9]*:[0-9]*$" "$TEXT_FILE")
    TOTAL_VERSES=$(echo "$VERSE_LINES" | wc -l)
    RANDOM_LINE_NUM=$(shuf -i 1-$TOTAL_VERSES -n 1)
    
    # random verse line
    MATCH_LINE=$(echo "$VERSE_LINES" | sed -n "${RANDOM_LINE_NUM}p")
    LINE_NUM=$(echo "$MATCH_LINE" | cut -d: -f1)
    
    # get hebrew and english text (next 2 lines)
    HEBREW=$(sed -n "$((LINE_NUM + 1))p" "$TEXT_FILE" | sed 's/^HE: //')
    ENGLISH=$(sed -n "$((LINE_NUM + 2))p" "$TEXT_FILE" | sed 's/^EN: //')
    VERSE_REF=$(sed -n "${LINE_NUM}p" "$TEXT_FILE" | tr '[:upper:]' '[:lower:]')
    
    # display 
    echo "$HEBREW"
    echo "$ENGLISH"
    echo "($VERSE_REF)"
    exit 0
fi

if [ $# -lt 2 ]; then
    echo "usage: $0 <book> <reference>"
    echo "examples: $0 Genesis 1:1"
    echo "          $0 genesis 1"
    echo "          $0 (no args for random verse)"
    exit 1
fi

# handle multi-word book names by joining all args except the last one
ARGS=("$@")
REFERENCE="${ARGS[-1]}"
unset 'ARGS[-1]'
BOOK="${ARGS[*]}"

# capitalize book name properly (first letter of each word, except prepositions)
BOOK=$(echo "$BOOK" | awk '{
    for(i=1;i<=NF;i++){
        word = tolower($i)
        if(word == "of" || word == "the" || word == "and" || word == "in" || word == "on"){
            $i = word
        } else {
            $i = toupper(substr($i,1,1))tolower(substr($i,2))
        }
    }
    # Always capitalize first word
    $1 = toupper(substr($1,1,1))tolower(substr($1,2))
}1')

# check if reference is just a chapter number (no colon)
if [[ "$REFERENCE" =~ ^[0-9]+$ ]]; then
    # Chapter mode - search for all verses in the chapter
    CHAPTER="$REFERENCE"
    SEARCH_PATTERN="^$BOOK $CHAPTER:"
    
    # Find all verses in the chapter
    MATCHES=$(grep -n "$SEARCH_PATTERN" "$TEXT_FILE")
    
    if [ -z "$MATCHES" ]; then
        echo "Chapter not found: $BOOK $CHAPTER"
        exit 1
    fi
    
    # Display all verses in the chapter
    echo "$MATCHES" | while read -r line; do
        LINE_NUM=$(echo "$line" | cut -d: -f1)
        HEBREW=$(sed -n "$((LINE_NUM + 1))p" "$TEXT_FILE" | sed 's/^HE: //')
        ENGLISH=$(sed -n "$((LINE_NUM + 2))p" "$TEXT_FILE" | sed 's/^EN: //')
        
        echo "$HEBREW"
        echo "$ENGLISH"
        echo ""
    done
    exit 0
fi

# verse mode - search for specific verse
ESCAPED_BOOK=$(echo "$BOOK" | sed 's/[[\.*^$()+?{|]/\\&/g')
SEARCH_PATTERN="^$ESCAPED_BOOK $REFERENCE$"

# search for the reference
MATCH_LINE=$(grep -n "$SEARCH_PATTERN" "$TEXT_FILE")

if [ -z "$MATCH_LINE" ]; then
    echo "quote not found: $BOOK $REFERENCE"
    echo ""
    
    # try to find the book first
    BOOK_FOUND=$(grep -i "\[$ESCAPED_BOOK\]" "$TEXT_FILE")
    if [ -z "$BOOK_FOUND" ]; then
        # Try finding book in section headers
        BOOK_FOUND=$(grep -i ": $ESCAPED_BOOK\]" "$TEXT_FILE")
        if [ -z "$BOOK_FOUND" ]; then
            echo "book '$BOOK' not found in database."
            echo ""
            echo "available books:"
            grep "^\[.*:" "$TEXT_FILE" | sed 's/\[.*: \(.*\)\]/\1/' | sort | uniq | head -20
        else
            echo "book found, but reference '$REFERENCE' not available."
            echo "available references for $BOOK (showing first 10):"
            grep "^$ESCAPED_BOOK " "$TEXT_FILE" | head -10 | cut -d' ' -f2-
        fi
    else
        echo "book found, but reference '$REFERENCE' not available."
        echo "available references for $BOOK (showing first 10):"
        grep "^$ESCAPED_BOOK " "$TEXT_FILE" | head -10 | cut -d' ' -f2-
    fi
    exit 1
fi

# get line number and extract the quote
LINE_NUM=$(echo "$MATCH_LINE" | cut -d: -f1)

# get Hebrew and english text (next 2 lines)
HEBREW=$(sed -n "$((LINE_NUM + 1))p" "$TEXT_FILE" | sed 's/^HE: //')
ENGLISH=$(sed -n "$((LINE_NUM + 2))p" "$TEXT_FILE" | sed 's/^EN: //')

# display the result
echo "$HEBREW"
echo "$ENGLISH"
