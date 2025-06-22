%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int line_no = 1;
FILE *outfile;
FILE *symbolFile;
FILE *constFile;

/* --- Parse Table Output --- */
void write_token(const char* lexeme, const char* type, const char* attribute) {
    fprintf(outfile, "%-20s | %-15s | %-15s | %-8d\n", 
            lexeme, type, attribute, line_no);
}

/* --- Symbol Table  --- */
#define MAX_LINES 100

typedef struct Symbol {
    char name[100];
    int lines[MAX_LINES];
    int line_count;
    struct Symbol* next;
} Symbol;

Symbol* symbol_table = NULL;

void insert_symbol(const char* name) {
    Symbol* current = symbol_table;
    while (current) {
        if (strcmp(current->name, name) == 0) {
            if (current->line_count < MAX_LINES && current->lines[current->line_count - 1] != line_no) {
                current->lines[current->line_count++] = line_no;
            }
            return;
        }
        current = current->next;
    }

    Symbol* new_sym = (Symbol*)malloc(sizeof(Symbol));
    strcpy(new_sym->name, name);
    new_sym->lines[0] = line_no;
    new_sym->line_count = 1;
    new_sym->next = symbol_table;
    symbol_table = new_sym;
}

void write_symbol_table() {
    fprintf(symbolFile, "%-20s | %-30s\n", "Identifier", "Line Nos");
    Symbol* current = symbol_table;
    while (current) {
        fprintf(symbolFile, "%-20s | ", current->name);
        for (int i = 0; i < current->line_count; i++) {
            fprintf(symbolFile, "%d", current->lines[i]);
            if (i != current->line_count - 1) fprintf(symbolFile, ", ");
        }
        fprintf(symbolFile, "\n");
        current = current->next;
    }
}

/* --- Constant Table --- */
#define MAX_LINES 100

typedef struct Constant {
    char value[100];
    char type[20];
    int lines[MAX_LINES];
    int line_count;
    struct Constant* next;
} Constant;

Constant* constant_table = NULL;

void insert_constant(const char* val, const char* type) {
    Constant* current = constant_table;
    while (current) {
        if (strcmp(current->value, val) == 0 && strcmp(current->type, type) == 0) {
            if (current->line_count < MAX_LINES && current->lines[current->line_count - 1] != line_no) {
                current->lines[current->line_count++] = line_no;
            }
            return;
        }
        current = current->next;
    }

    Constant* new_const = (Constant*)malloc(sizeof(Constant));
    strcpy(new_const->value, val);
    strcpy(new_const->type, type);
    new_const->lines[0] = line_no;
    new_const->line_count = 1;
    new_const->next = constant_table;
    constant_table = new_const;
}

void write_constant_table() {
    fprintf(constFile, "%-20s | %-10s | %-20s\n", "Value", "Type", "Line Nos");
    Constant* current = constant_table;
    while (current) {
        fprintf(constFile, "%-20s | %-10s | ", current->value, current->type);
        for (int i = 0; i < current->line_count; i++) {
            fprintf(constFile, "%d", current->lines[i]);
            if (i != current->line_count - 1) fprintf(constFile, ", ");
        }
        fprintf(constFile, "\n");
        current = current->next;
    }
}

%}

%%

[ \t]           ;
\n              { line_no++; }
"//".*          ;
\/\*([^*]|\*+[^*/])*\*+\/ ;

"auto"          { write_token(yytext, "KEYWORD", "AUTO"); }
"break"         { write_token(yytext, "KEYWORD", "BREAK"); }
"case"          { write_token(yytext, "KEYWORD", "CASE"); }
"char"          { write_token(yytext, "KEYWORD", "CHAR"); }
"const"         { write_token(yytext, "KEYWORD", "CONST"); }
"continue"      { write_token(yytext, "KEYWORD", "CONTINUE"); }
"default"       { write_token(yytext, "KEYWORD", "DEFAULT"); }
"do"            { write_token(yytext, "KEYWORD", "DO"); }
"double"        { write_token(yytext, "KEYWORD", "DOUBLE"); }
"else"          { write_token(yytext, "KEYWORD", "ELSE"); }
"enum"          { write_token(yytext, "KEYWORD", "ENUM"); }
"extern"        { write_token(yytext, "KEYWORD", "EXTERN"); }
"float"         { write_token(yytext, "KEYWORD", "FLOAT"); }
"for"           { write_token(yytext, "KEYWORD", "FOR"); }
"goto"          { write_token(yytext, "KEYWORD", "GOTO"); }
"if"            { write_token(yytext, "KEYWORD", "IF"); }
"int"           { write_token(yytext, "KEYWORD", "INT"); }
"long"          { write_token(yytext, "KEYWORD", "LONG"); }
"register"      { write_token(yytext, "KEYWORD", "REGISTER"); }
"return"        { write_token(yytext, "KEYWORD", "RETURN"); }
"short"         { write_token(yytext, "KEYWORD", "SHORT"); }
"signed"        { write_token(yytext, "KEYWORD", "SIGNED"); }
"sizeof"        { write_token(yytext, "KEYWORD", "SIZEOF"); }
"static"        { write_token(yytext, "KEYWORD", "STATIC"); }
"struct"        { write_token(yytext, "KEYWORD", "STRUCT"); }
"switch"        { write_token(yytext, "KEYWORD", "SWITCH"); }
"typedef"       { write_token(yytext, "KEYWORD", "TYPEDEF"); }
"union"         { write_token(yytext, "KEYWORD", "UNION"); }
"unsigned"      { write_token(yytext, "KEYWORD", "UNSIGNED"); }
"void"          { write_token(yytext, "KEYWORD", "VOID"); }
"volatile"      { write_token(yytext, "KEYWORD", "VOLATILE"); }
"while"         { write_token(yytext, "KEYWORD", "WHILE"); }

"class"         { write_token(yytext, "KEYWORD", "CLASS"); }
"namespace"     { write_token(yytext, "KEYWORD", "NAMESPACE"); }
"try"           { write_token(yytext, "KEYWORD", "TRY"); }
"catch"         { write_token(yytext, "KEYWORD", "CATCH"); }
"throw"         { write_token(yytext, "KEYWORD", "THROW"); }
"new"           { write_token(yytext, "KEYWORD", "NEW"); }
"delete"        { write_token(yytext, "KEYWORD", "DELETE"); }
"private"       { write_token(yytext, "KEYWORD", "PRIVATE"); }
"protected"     { write_token(yytext, "KEYWORD", "PROTECTED"); }
"public"        { write_token(yytext, "KEYWORD", "PUBLIC"); }
"this"          { write_token(yytext, "KEYWORD", "THIS"); }
"virtual"       { write_token(yytext, "KEYWORD", "VIRTUAL"); }
"friend"        { write_token(yytext, "KEYWORD", "FRIEND"); }
"inline"        { write_token(yytext, "KEYWORD", "INLINE"); }
"operator"      { write_token(yytext, "KEYWORD", "OPERATOR"); }
"template"      { write_token(yytext, "KEYWORD", "TEMPLATE"); }
"typename"      { write_token(yytext, "KEYWORD", "TYPENAME"); }
"using"         { write_token(yytext, "KEYWORD", "USING"); }
"bool"          { write_token(yytext, "KEYWORD", "BOOL"); }
"true"          { write_token(yytext, "KEYWORD", "TRUE"); }
"false"         { write_token(yytext, "KEYWORD", "FALSE"); }
"nullptr"       { write_token(yytext, "KEYWORD", "NULLPTR"); }

[0-9]+          { insert_constant(yytext, "INTEGER"); write_token(yytext, "NUMBER", "INTEGER"); }
[0-9]+\.[0-9]+  { insert_constant(yytext, "FLOAT"); write_token(yytext, "NUMBER", "FLOAT"); }
0[xX][0-9a-fA-F]+ { insert_constant(yytext, "HEX"); write_token(yytext, "NUMBER", "HEX"); }

\"([^\\\"]|\\.)*\" { insert_constant(yytext, "STRING"); write_token(yytext, "STRING", "LITERAL"); }
\'([^\\\']|\\.)\'  { insert_constant(yytext, "CHAR"); write_token(yytext, "CHAR", "LITERAL"); }

[a-zA-Z_][a-zA-Z0-9_]* { insert_symbol(yytext); write_token(yytext, "IDENTIFIER", "VAR"); }

"+"             { write_token(yytext, "OPERATOR", "ADD"); } /* Operators */
"-"             { write_token(yytext, "OPERATOR", "SUB"); }
"*"             { write_token(yytext, "OPERATOR", "MUL"); }
"/"             { write_token(yytext, "OPERATOR", "DIV"); }
"%"             { write_token(yytext, "OPERATOR", "MOD"); }
"++"            { write_token(yytext, "OPERATOR", "INC"); }
"--"            { write_token(yytext, "OPERATOR", "DEC"); }
"="             { write_token(yytext, "OPERATOR", "ASSIGN"); }
"+="            { write_token(yytext, "OPERATOR", "ADD_ASSIGN"); }
"-="            { write_token(yytext, "OPERATOR", "SUB_ASSIGN"); }
"*="            { write_token(yytext, "OPERATOR", "MUL_ASSIGN"); }
"/="            { write_token(yytext, "OPERATOR", "DIV_ASSIGN"); }
"%="            { write_token(yytext, "OPERATOR", "MOD_ASSIGN"); }
"=="            { write_token(yytext, "OPERATOR", "EQ"); }
"!="            { write_token(yytext, "OPERATOR", "NEQ"); }
"<"             { write_token(yytext, "OPERATOR", "LT"); }
">"             { write_token(yytext, "OPERATOR", "GT"); }
"<="            { write_token(yytext, "OPERATOR", "LTE"); }
">="            { write_token(yytext, "OPERATOR", "GTE"); }
"&&"            { write_token(yytext, "OPERATOR", "AND"); }
"||"            { write_token(yytext, "OPERATOR", "OR"); }
"!"             { write_token(yytext, "OPERATOR", "NOT"); }
"&"             { write_token(yytext, "OPERATOR", "BIT_AND"); }
"|"             { write_token(yytext, "OPERATOR", "BIT_OR"); }
"^"             { write_token(yytext, "OPERATOR", "BIT_XOR"); }
"~"             { write_token(yytext, "OPERATOR", "BIT_NOT"); }
"<<"            { write_token(yytext, "OPERATOR", "SHIFT_LEFT"); }
">>"            { write_token(yytext, "OPERATOR", "SHIFT_RIGHT"); }
"->"            { write_token(yytext, "OPERATOR", "ARROW"); }
"::"            { write_token(yytext, "OPERATOR", "SCOPE"); }


"("             { write_token(yytext, "PUNCTUATION", "LPAREN"); } /* Punctuation */
")"             { write_token(yytext, "PUNCTUATION", "RPAREN"); }
"{"             { write_token(yytext, "PUNCTUATION", "LBRACE"); }
"}"             { write_token(yytext, "PUNCTUATION", "RBRACE"); }
"["             { write_token(yytext, "PUNCTUATION", "LBRACKET"); }
"]"             { write_token(yytext, "PUNCTUATION", "RBRACKET"); }
";"             { write_token(yytext, "PUNCTUATION", "SEMICOLON"); }
","             { write_token(yytext, "PUNCTUATION", "COMMA"); }
"."             { write_token(yytext, "PUNCTUATION", "DOT"); }
":"             { write_token(yytext, "PUNCTUATION", "COLON"); }
"?"             { write_token(yytext, "PUNCTUATION", "QUESTION"); }

"#include"      { write_token(yytext, "PREPROCESSOR", "INCLUDE"); } /* Preprocessor Directives */
"#define"       { write_token(yytext, "PREPROCESSOR", "DEFINE"); }
"#ifdef"        { write_token(yytext, "PREPROCESSOR", "IFDEF"); }
"#ifndef"       { write_token(yytext, "PREPROCESSOR", "IFNDEF"); }
"#endif"        { write_token(yytext, "PREPROCESSOR", "ENDIF"); }
"#if"           { write_token(yytext, "PREPROCESSOR", "IF"); }
"#else"         { write_token(yytext, "PREPROCESSOR", "ELSE"); }
"#elif"         { write_token(yytext, "PREPROCESSOR", "ELIF"); }

.               { write_token(yytext, "ERROR", "INVALID"); }
%%

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    yyin = fopen(argv[1], "r");
    if (!yyin) {
        printf("Cannot open input file %s\n", argv[1]);
        return 1;
    }

    outfile = fopen("parseTable", "w");
    symbolFile = fopen("symbolTable", "w");
    constFile = fopen("constantTable", "w");

    yylex();

    write_symbol_table();
    write_constant_table();

    fclose(yyin);
    fclose(outfile);
    fclose(symbolFile);
    fclose(constFile);

    return 0;
}

int yywrap() {
    return 1;
}
