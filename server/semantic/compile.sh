#!/bin/sh

cd "$(dirname "$0")"

INPUT_FILE="../lexical/input.cc"

# Clean up previous output files
rm -f symbolTable constantTable parsedTable
rm -f *.tab.c *.tab.h lex.yy.c
rm -f a.exe

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

# Ensure output files exist (create empty ones if they don't)
if [ ! -f "symbolTable" ]; then
    echo "No symbols found" > symbolTable
fi
if [ ! -f "constantTable" ]; then
    echo "No constants found" > constantTable
fi
if [ ! -f "parsedTable" ]; then
    echo "No parsed tokens found" > parsedTable
fi

cd ..
