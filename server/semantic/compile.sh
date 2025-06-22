#!/bin/sh

cd "$(dirname "$0")"

INPUT_FILE="../lexical/input.cc"

# Check if the input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File '$INPUT_FILE' not found."
    exit 1
fi

lex lexicalAnalyzer.l
win_bison -d syntaxChecker.y
g++ lex.yy.c syntaxChecker.tab.c -w -g
./a.exe "$INPUT_FILE"
rm syntaxChecker.tab.c syntaxChecker.tab.h lex.yy.c

cd ..
