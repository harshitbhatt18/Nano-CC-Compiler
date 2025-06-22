#!/bin/bash

# Navigate to the directory of the script (Syntax Analyzer/)
cd "$(dirname "$0")"

INPUT_FILE="../lexical/input.cc"


# Check if the input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File '$INPUT_FILE' not found."
    exit 1
fi

# Create a temporary file with comments removed
TEMP_FILE=$(mktemp)
# Remove C and C++ style comments before checking headers
sed -e 's|//.*$||g' -e 's|/\*.*\*/||g' "$INPUT_FILE" > "$TEMP_FILE"

# Check for C/C++ headers in the file without comments
CPP_HEADERS=0
if grep -q "#include *<iostream>" "$TEMP_FILE" || grep -q "#include *<bits/stdc++.h>" "$TEMP_FILE"; then
    CPP_HEADERS=1
fi

# Clean up temp file
rm "$TEMP_FILE"

if [ $CPP_HEADERS -eq 0 ] && grep -q "#include *<stdio.h>" "$INPUT_FILE"; then
    # echo "Detected C file. Using C compiler..."
    lex -w lexicalAnalyzer.l
    win_bison -t -d -v syntaxChecker.y
    gcc -w lex.yy.c syntaxChecker.tab.c
    ./a.exe "$INPUT_FILE"
    rm -f syntaxChecker.tab.c syntaxChecker.tab.h lex.yy.c
    node parse_tree_to_dot.js
    dot -Tpng  parseTree.dot -o "parseTree.png" 
else
    # echo "Detected C++ file. Using C++ compiler..."
    lex -w cpp_lexer.l
    win_bison -t -d -v cpp_parser.y
    gcc -w lex.yy.c cpp_parser.tab.c
    ./a.exe "$INPUT_FILE"
    rm -f cpp_parser.tab.c cpp_parser.tab.h lex.yy.c
    node parse_tree_to_dot.js
    dot -Tpng  parseTree.dot -o "parseTree.png"
fi
echo -----------------------------------------------------------------------------------------
cd ..

