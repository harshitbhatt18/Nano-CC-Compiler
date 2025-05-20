%{
#include <stdio.h>
#include <string.h>
#include "cpp_parser.tab.h"

int lineCount=1;
int nestedCommentCount=0;
int commentFlag=0;
char *tablePtr;

void addToken(char *text) {
  int len = strlen(text);
  tablePtr = (char*)malloc((len+1)*sizeof(char));
  strcpy(tablePtr, text);
}

void makeList(char *t, char c, int l) {
  /* Function to track tokens */
}
%}

%%
"//".*    { /* Skip single-line comments */ }
"/*"      { nestedCommentCount++; }
"*/"      { if(nestedCommentCount>0) nestedCommentCount--; }

"#include"[ \t]*"<"[^>]*">"   { addToken(yytext); makeList(yytext, 'd', lineCount); }
"#include"[ \t]*\"[^\"]*\"    { addToken(yytext); makeList(yytext, 'd', lineCount); }

"std::cout"   { addToken(yytext); makeList(yytext, 'v', lineCount); return IDENTIFIER; }
"<<"          { addToken(yytext); makeList(yytext, 'o', lineCount); return LEFT_OP; }

"auto"    { addToken(yytext); makeList(yytext, 'k', lineCount); return AUTO; }
"break"   { addToken(yytext); makeList(yytext, 'k', lineCount); return BREAK; }
"case"    { addToken(yytext); makeList(yytext, 'k', lineCount); return CASE; }
"char"    { addToken(yytext); makeList(yytext, 'k', lineCount); return CHAR; }
"const"   { addToken(yytext); makeList(yytext, 'k', lineCount); return CONST; }
"continue" { addToken(yytext); makeList(yytext, 'k', lineCount); return CONTINUE; }
"default" { addToken(yytext); makeList(yytext, 'k', lineCount); return DEFAULT; }
"do"      { addToken(yytext); makeList(yytext, 'k', lineCount); return DO; }
"double"  { addToken(yytext); makeList(yytext, 'k', lineCount); return DOUBLE; }
"else"    { addToken(yytext); makeList(yytext, 'k', lineCount); return ELSE; }
"enum"    { addToken(yytext); makeList(yytext, 'k', lineCount); return ENUM; }
"extern"  { addToken(yytext); makeList(yytext, 'k', lineCount); return EXTERN; }
"float"   { addToken(yytext); makeList(yytext, 'k', lineCount); return FLOAT; }
"for"     { addToken(yytext); makeList(yytext, 'k', lineCount); return FOR; }
"goto"    { addToken(yytext); makeList(yytext, 'k', lineCount); return GOTO; }
"if"      { addToken(yytext); makeList(yytext, 'k', lineCount); return IF; }
"int"     { addToken(yytext); makeList(yytext, 'k', lineCount); return INT; }
"long"    { addToken(yytext); makeList(yytext, 'k', lineCount); return LONG; }
"register" { addToken(yytext); makeList(yytext, 'k', lineCount); return REGISTER; }
"return"  { addToken(yytext); makeList(yytext, 'k', lineCount); return RETURN; }
"short"   { addToken(yytext); makeList(yytext, 'k', lineCount); return SHORT; }
"signed"  { addToken(yytext); makeList(yytext, 'k', lineCount); return SIGNED; }
"sizeof"  { addToken(yytext); makeList(yytext, 'k', lineCount); return SIZEOF; }
"static"  { addToken(yytext); makeList(yytext, 'k', lineCount); return STATIC; }
"struct"  { addToken(yytext); makeList(yytext, 'k', lineCount); return STRUCT; }
"switch"  { addToken(yytext); makeList(yytext, 'k', lineCount); return SWITCH; }
"typedef" { addToken(yytext); makeList(yytext, 'k', lineCount); return TYPEDEF; }
"union"   { addToken(yytext); makeList(yytext, 'k', lineCount); return UNION; }
"unsigned" { addToken(yytext); makeList(yytext, 'k', lineCount); return UNSIGNED; }
"void"    { addToken(yytext); makeList(yytext, 'k', lineCount); return VOID; }
"volatile" { addToken(yytext); makeList(yytext, 'k', lineCount); return VOLATILE; }
"while"   { addToken(yytext); makeList(yytext, 'k', lineCount); return WHILE; }

"catch"   { addToken(yytext); makeList(yytext, 'k', lineCount); return CATCH; }
"class"   { addToken(yytext); makeList(yytext, 'k', lineCount); return CLASS; }
"delete"  { addToken(yytext); makeList(yytext, 'k', lineCount); return DELETE; }
"friend"  { addToken(yytext); makeList(yytext, 'k', lineCount); return FRIEND; }
"inline"  { addToken(yytext); makeList(yytext, 'k', lineCount); return INLINE; }
"namespace" { addToken(yytext); makeList(yytext, 'k', lineCount); return NAMESPACE; }
"new"     { addToken(yytext); makeList(yytext, 'k', lineCount); return NEW; }
"private" { addToken(yytext); makeList(yytext, 'k', lineCount); return PRIVATE; }
"protected" { addToken(yytext); makeList(yytext, 'k', lineCount); return PROTECTED; }
"public"  { addToken(yytext); makeList(yytext, 'k', lineCount); return PUBLIC; }
"template" { addToken(yytext); makeList(yytext, 'k', lineCount); return TEMPLATE; }
"this"    { addToken(yytext); makeList(yytext, 'k', lineCount); return THIS; }
"throw"   { addToken(yytext); makeList(yytext, 'k', lineCount); return THROW; }
"try"     { addToken(yytext); makeList(yytext, 'k', lineCount); return TRY; }
"using"   { addToken(yytext); makeList(yytext, 'k', lineCount); return USING; }
"virtual" { addToken(yytext); makeList(yytext, 'k', lineCount); return VIRTUAL; }
"bool"    { addToken(yytext); makeList(yytext, 'k', lineCount); return BOOL; }
"true"    { addToken(yytext); makeList(yytext, 'c', lineCount); return BOOL_LITERAL; }
"false"   { addToken(yytext); makeList(yytext, 'c', lineCount); return BOOL_LITERAL; }

[a-zA-Z_][a-zA-Z0-9_:]* { addToken(yytext); makeList(yytext, 'v', lineCount); return IDENTIFIER; }
\"[^"]*\"              { addToken(yytext); makeList(yytext, 's', lineCount); return STRING_LITERAL; }

[0-9]+                 { addToken(yytext); makeList(yytext, 'c', lineCount); return CONSTANT; }
[0-9]+\.[0-9]+         { addToken(yytext); makeList(yytext, 'c', lineCount); return CONSTANT; }
\'[^']*\'              { addToken(yytext); makeList(yytext, 'c', lineCount); return CONSTANT; }

"::"     { addToken(yytext); makeList(yytext, 'o', lineCount); return SCOPE_OP; }
"->"     { addToken(yytext); makeList(yytext, 'o', lineCount); return PTR_OP; }
"++"     { addToken(yytext); makeList(yytext, 'o', lineCount); return INC_OP; }
"--"     { addToken(yytext); makeList(yytext, 'o', lineCount); return DEC_OP; }
"<<"     { addToken(yytext); makeList(yytext, 'o', lineCount); return LEFT_OP; }
">>"     { addToken(yytext); makeList(yytext, 'o', lineCount); return RIGHT_OP; }
"<="     { addToken(yytext); makeList(yytext, 'o', lineCount); return LE_OP; }
">="     { addToken(yytext); makeList(yytext, 'o', lineCount); return GE_OP; }
"=="     { addToken(yytext); makeList(yytext, 'o', lineCount); return EQ_OP; }
"!="     { addToken(yytext); makeList(yytext, 'o', lineCount); return NE_OP; }
"&&"     { addToken(yytext); makeList(yytext, 'o', lineCount); return AND_OP; }
"||"     { addToken(yytext); makeList(yytext, 'o', lineCount); return OR_OP; }
"*="     { addToken(yytext); makeList(yytext, 'o', lineCount); return MUL_ASSIGN; }
"/="     { addToken(yytext); makeList(yytext, 'o', lineCount); return DIV_ASSIGN; }
"%="     { addToken(yytext); makeList(yytext, 'o', lineCount); return MOD_ASSIGN; }
"+="     { addToken(yytext); makeList(yytext, 'o', lineCount); return ADD_ASSIGN; }
"-="     { addToken(yytext); makeList(yytext, 'o', lineCount); return SUB_ASSIGN; }
"<<="    { addToken(yytext); makeList(yytext, 'o', lineCount); return LEFT_ASSIGN; }
">>="    { addToken(yytext); makeList(yytext, 'o', lineCount); return RIGHT_ASSIGN; }
"&="     { addToken(yytext); makeList(yytext, 'o', lineCount); return AND_ASSIGN; }
"^="     { addToken(yytext); makeList(yytext, 'o', lineCount); return XOR_ASSIGN; }
"|="     { addToken(yytext); makeList(yytext, 'o', lineCount); return OR_ASSIGN; }
"..."    { addToken(yytext); makeList(yytext, 'o', lineCount); return ELLIPSIS; }

";"      { addToken(yytext); makeList(yytext, 'p', lineCount); return ';'; }
"{"      { addToken(yytext); makeList(yytext, 'p', lineCount); return '{'; }
"}"      { addToken(yytext); makeList(yytext, 'p', lineCount); return '}'; }
","      { addToken(yytext); makeList(yytext, 'p', lineCount); return ','; }
":"      { addToken(yytext); makeList(yytext, 'p', lineCount); return ':'; }
"="      { addToken(yytext); makeList(yytext, 'o', lineCount); return '='; }
"("      { addToken(yytext); makeList(yytext, 'p', lineCount); return '('; }
")"      { addToken(yytext); makeList(yytext, 'p', lineCount); return ')'; }
"["      { addToken(yytext); makeList(yytext, 'p', lineCount); return '['; }
"]"      { addToken(yytext); makeList(yytext, 'p', lineCount); return ']'; }
"."      { addToken(yytext); makeList(yytext, 'p', lineCount); return '.'; }
"&"      { addToken(yytext); makeList(yytext, 'o', lineCount); return '&'; }
"!"      { addToken(yytext); makeList(yytext, 'o', lineCount); return '!'; }
"~"      { addToken(yytext); makeList(yytext, 'o', lineCount); return '~'; }
"-"      { addToken(yytext); makeList(yytext, 'o', lineCount); return '-'; }
"+"      { addToken(yytext); makeList(yytext, 'o', lineCount); return '+'; }
"*"      { addToken(yytext); makeList(yytext, 'o', lineCount); return '*'; }
"/"      { addToken(yytext); makeList(yytext, 'o', lineCount); return '/'; }
"%"      { addToken(yytext); makeList(yytext, 'o', lineCount); return '%'; }
"<"      { addToken(yytext); makeList(yytext, 'o', lineCount); return '<'; }
">"      { addToken(yytext); makeList(yytext, 'o', lineCount); return '>'; }
"^"      { addToken(yytext); makeList(yytext, 'o', lineCount); return '^'; }
"|"      { addToken(yytext); makeList(yytext, 'o', lineCount); return '|'; }
"?"      { addToken(yytext); makeList(yytext, 'o', lineCount); return '?'; }

[ \t\v\f]  { /* Skip whitespace */ }
\n      { lineCount++; }
.       { /* Skip unrecognized characters */ }

%%
int yywrap() {
  return 1;
} 