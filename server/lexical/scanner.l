%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int line_no = 1;
FILE *outfile;

void write_token(char* lexeme, char* type, char* attribute) {
    fprintf(outfile, "%-20s | %-15s | %-15s | %-8d\n", 
            lexeme, type, attribute, line_no);
}
%}

%%
[ \t]           ; /* Skip whitespace */
\n              { line_no++; }
"//".*          ; /* Skip single line comments */
\/\*([^*]|\*+[^*/])*\*+\/ ; /* Skip multi-line comments */



"auto"          { write_token(yytext, "KEYWORD", "AUTO"); } /* C/C++ Keywords */
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


"class"         { write_token(yytext, "KEYWORD", "CLASS"); } /* C++ Specific Keywords */
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


[0-9]+          { write_token(yytext, "NUMBER", "INTEGER"); } /* Numbers */
[0-9]+\.[0-9]+  { write_token(yytext, "NUMBER", "FLOAT"); }
0[xX][0-9a-fA-F]+ { write_token(yytext, "NUMBER", "HEX"); }


\"([^\\\"]|\\.)*\" { write_token(yytext, "STRING", "LITERAL"); } /* Strings and Characters */
\'([^\\\']|\\.)\' { write_token(yytext, "CHAR", "LITERAL"); }


[a-zA-Z_][a-zA-Z0-9_]* { write_token(yytext, "IDENTIFIER", "VAR"); } /* Identifiers */


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
    
    
    /*fprintf(outfile, "%-20s | %-15s | %-15s | %-8s\n", 
            "Lexeme", "Type", "Attribute", "Line No");*/
    

    yylex();

    fclose(yyin);
    fclose(outfile);
    return 0;
}

int yywrap() {
    return 1;
} 