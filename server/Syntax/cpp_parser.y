%expect 2
%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "cpp_parser.tab.h"

/*
* This parser defines the tables and shares them with the lexical analyzer
* The makeList function is defined in the lexical analyzer to avoid multiple definition errors
* We define the variables here and make the lexical analyzer reference them using extern declarations
*/
FILE* yyerrfile=NULL;

// Function declaration structure
typedef struct FunctionDecl {
    char name[64];
    char paramTypes[10][64];
    int paramCount;
    int lineNo;
    struct FunctionDecl *next;
} FunctionDecl;

// Global symbol table for function declarations
FunctionDecl *functionTable = NULL;

struct tokenList
{
	char *token,type[20],line[100];
	struct tokenList *next;
};
typedef struct tokenList tokenList;

// External declaration of makeList function defined in the lexical analyzer
extern void makeList(char *tokenName, char tokenType, int tokenLine);

// Function declaration tracker
void addFunctionDeclaration(const char *name, int lineNo) {
    FunctionDecl *newDecl = (FunctionDecl *)malloc(sizeof(FunctionDecl));
    strncpy(newDecl->name, name, 63);
    newDecl->name[63] = '\0';
    newDecl->paramCount = 0;
    newDecl->lineNo = lineNo;
    newDecl->next = functionTable;
    functionTable = newDecl;
}

// Add parameter to most recent function declaration
void addFunctionParameter(const char *type) {
    if (functionTable && functionTable->paramCount < 10) {
        strncpy(functionTable->paramTypes[functionTable->paramCount], type, 63);
        functionTable->paramTypes[functionTable->paramCount][63] = '\0';
        functionTable->paramCount++;
    }
}

// Check if function was previously declared
FunctionDecl* findFunctionDeclaration(const char *name) {
    FunctionDecl *current = functionTable;
    while (current) {
        if (strcmp(current->name, name) == 0) {
            return current;
        }
        current = current->next;
    }
    return NULL;
}

// Current function being defined or declared
char currentFunctionName[64] = "";

// Current parameter being processed
int currentParamIndex = 0;
char currentParamType[64] = "";

extern FILE *yyin;
extern int lineCount;
extern char *tablePtr;
extern int nestedCommentCount;
extern int commentFlag;

// Define table pointers directly, they will be shared with the lexical analyzer
tokenList *symbolPtr = NULL;
tokenList *constantPtr = NULL;
tokenList *parsedPtr = NULL;

// Improved type tracking
char typeBuffer[20] = "UNKNOWN"; // Use a string instead of a single char

char *sourceCode=NULL;
int errorFlag=0;

// Set the current type based on type specifiers
void setType(const char* type) {
    strncpy(typeBuffer, type, 19);
    typeBuffer[19] = '\0'; // Ensure null termination
}

// Type combination helper - combine qualifiers with types
void appendType(const char* additional) {
    char newType[20];
    if (strcmp(typeBuffer, "UNKNOWN") == 0) {
        strncpy(typeBuffer, additional, 19);
    } else {
        snprintf(newType, 20, "%s %s", typeBuffer, additional);
        strncpy(typeBuffer, newType, 19);
    }
    typeBuffer[19] = '\0'; // Ensure null termination
}

// makeList function is now defined in the lexical analyzer

typedef struct ParseTreeNode {
    char name[64];
    struct ParseTreeNode *child;
    struct ParseTreeNode *sibling;
} ParseTreeNode;

ParseTreeNode* createNode(const char* name, ParseTreeNode* child, ParseTreeNode* sibling) {
    ParseTreeNode* node = (ParseTreeNode*)malloc(sizeof(ParseTreeNode));
    strcpy(node->name, name);
    node->child = child;
    node->sibling = sibling;
    return node;
}

// Added function to flatten recursive structures
ParseTreeNode* flattenTree(const char* nodeName, ParseTreeNode* first, ParseTreeNode* second) {
    // If both are NULL, just create a simple node
    if (!first && !second) {
        return createNode(nodeName, NULL, NULL);
    }
    
    // If first node has the same name, don't nest it, append second as sibling
    if (first && strcmp(first->name, nodeName) == 0) {
        // Find the last sibling of first
        ParseTreeNode* lastSibling = first;
        while (lastSibling->sibling != NULL) {
            lastSibling = lastSibling->sibling;
        }
        // Append second as sibling (or second's children if second has same name)
        if (second && strcmp(second->name, nodeName) == 0) {
            lastSibling->sibling = second->child;
            // Don't forget any siblings second might have
            ParseTreeNode* temp = lastSibling;
            while (temp->sibling != NULL) {
                temp = temp->sibling;
            }
            temp->sibling = second->sibling;
            free(second); // Free the redundant node
        } else {
            lastSibling->sibling = second;
        }
        return first;
    }
    
    // If second has the same name, flatten it
    if (second && strcmp(second->name, nodeName) == 0) {
        ParseTreeNode* node = createNode(nodeName, first, second->child);
        // Connect any siblings second might have
        ParseTreeNode* temp = node;
        while (temp->sibling != NULL) {
            temp = temp->sibling;
        }
        temp->sibling = second->sibling;
        free(second); // Free the redundant node
        return node;
    }
    
    // Neither has the same name, create a normal node
    return createNode(nodeName, first, second);
}

void printParseTree(ParseTreeNode* node, int level, FILE* fp) {
    if (!node) return;
    for (int i = 0; i < level; ++i) fprintf(fp, "  ");
    fprintf(fp, "%s\n", node->name);
    printParseTree(node->child, level + 1, fp);
    printParseTree(node->sibling, level, fp);
}

ParseTreeNode* create_for_node(ParseTreeNode* init, ParseTreeNode* cond, ParseTreeNode* iter, ParseTreeNode* stmt) {
    // Create main for loop node
    ParseTreeNode* forNode = createNode("for_statement", NULL, NULL);
    
    // Create a components node to hold all parts of the for loop
    ParseTreeNode* components = createNode("components", NULL, NULL);
    forNode->child = components;
    
    // Create parts in sequence, even if some are NULL
    ParseTreeNode* initNode = createNode("initialization", init, NULL);
    components->child = initNode;
    
    ParseTreeNode* condNode = createNode("condition", cond, NULL);
    initNode->sibling = condNode;
    
    ParseTreeNode* iterNode = createNode("iteration", iter, NULL);
    condNode->sibling = iterNode;
    
    // Add the body as sibling to the components
    ParseTreeNode* bodyNode = createNode("body", stmt, NULL);
    components->sibling = bodyNode;
    
    return forNode;
}

ParseTreeNode* root = NULL;
%}

%union {
    struct ParseTreeNode* node;
    // Add other types if needed (e.g., int, char*, etc.)
}

/* All types properly defined here */
%type <node> translation_unit external_declaration function_definition declaration primary_expression 
%type <node> postfix_expression argument_expression_list unary_expression unary_operator cast_expression 
%type <node> multiplicative_expression additive_expression shift_expression relational_expression equality_expression 
%type <node> and_expression exclusive_or_expression inclusive_or_expression logical_and_expression logical_or_expression 
%type <node> conditional_expression assignment_expression assignment_operator constant_expression 
%type <node> labeled_statement compound_statement selection_statement jump_statement
%type <node> declarator init_declarator_list init_declarator storage_class_specifier 
%type <node> type_specifier type_qualifier pointer type_qualifier_list direct_declarator 
%type <node> parameter_type_list identifier_list initializer parameter_list initializer_list declaration_list
%type <node> declaration_specifiers abstract_declarator parameter_declaration
%type <node> expression_statement expression statement iteration_statement
%type <node> for_expr direct_abstract_declarator block_item_list block_item
%type <node> specifier_qualifier_list try_catch_statement type_name
%type <node> struct_or_union_specifier struct_declaration_list struct_declaration struct_declarator_list
%type <node> enum_specifier enumerator_list enumerator

/* C++ specific types */
%type <node> class_definition class_head class_body base_clause access_specifier member_list member_declaration
%type <node> constructor_definition destructor_definition

/* C tokens */
%token AUTO BREAK CASE CHAR CONST CONTINUE DEFAULT DO DOUBLE ELSE ENUM 
%token EXTERN FLOAT FOR GOTO IF INT LONG REGISTER RETURN SHORT SIGNED 
%token SIZEOF STATIC STRUCT SWITCH TYPEDEF UNION UNSIGNED VOID VOLATILE WHILE 

/* C++ specific tokens */
%token CATCH CLASS DELETE FRIEND INLINE NAMESPACE NEW PRIVATE PROTECTED PUBLIC
%token TEMPLATE THIS THROW TRY USING VIRTUAL BOOL BOOL_LITERAL SCOPE_OP

%token IDENTIFIER CONSTANT STRING_LITERAL ELLIPSIS

%token PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token XOR_ASSIGN OR_ASSIGN TYPE_NAME

%nonassoc LOWER_THAN_ELSE
%right ELSE

%left OR_OP
%left AND_OP
%left '|'
%left '^'
%left '&'
%left EQ_OP NE_OP
%left '<' '>' LE_OP GE_OP
%left LEFT_OP RIGHT_OP
%left '+' '-'
%left '*' '/' '%'
%right INC_OP DEC_OP
%left PTR_OP '.'
%right NEW DELETE

%start translation_unit

%%

/* Basic expressions and statements adapted from syntaxChecker.y */
primary_expression
	: IDENTIFIER  		{ 
		makeList(tablePtr, 'v', lineCount); 
		strcpy(currentFunctionName, tablePtr);
		$$ = createNode("IDENTIFIER", NULL, NULL); 
	}
	| CONSTANT    		{ makeList(tablePtr, 'c', lineCount); $$ = createNode("CONSTANT", NULL, NULL); }
	| STRING_LITERAL  	{ makeList(tablePtr, 's', lineCount); $$ = createNode("STRING_LITERAL", NULL, NULL); }
	| '(' expression ')' 	{ makeList("(", 'p', lineCount); makeList(")", 'p', lineCount); $$ = createNode("(expr)", $2, NULL); }
	| BOOL_LITERAL      { makeList(tablePtr, 'c', lineCount); $$ = createNode("BOOL_LITERAL", NULL, NULL); } /* C++ specific */
	| THIS             { makeList(tablePtr, 'k', lineCount); $$ = createNode("this", NULL, NULL); } /* C++ specific */
	;

postfix_expression
	: primary_expression { $$ = $1; }
	| postfix_expression '[' expression ']' { $$ = createNode("[]", $1, $3); }
	| postfix_expression '(' ')' { $$ = createNode("call()", $1, NULL); }
	| postfix_expression '(' argument_expression_list ')' { 
		$$ = createNode("call(args)", $1, $3);
        // Function type checking
        FunctionDecl *decl = findFunctionDeclaration(currentFunctionName);
        if (decl && currentParamType[0] != '\0') {
            // Type checking logic would go here
        }
	}
	| postfix_expression '.' IDENTIFIER { $$ = createNode(".IDENTIFIER", $1, NULL); }
	| postfix_expression PTR_OP IDENTIFIER { $$ = createNode("PTR_OP IDENTIFIER", $1, NULL); }
	| postfix_expression INC_OP { $$ = createNode("INC_OP", $1, NULL); }
	| postfix_expression DEC_OP { $$ = createNode("DEC_OP", $1, NULL); }
    | IDENTIFIER SCOPE_OP IDENTIFIER { $$ = createNode("SCOPE_OP", NULL, NULL); } /* C++ specific */
    | postfix_expression LEFT_OP primary_expression { $$ = createNode("<<", $1, $3); } /* C++ iostream */
	;

argument_expression_list
	: assignment_expression { 
        $$ = $1; 
        // Track argument type
        if (isdigit(tablePtr[0])) {
            strcpy(currentParamType, "int"); // Assuming numeric constant is int
        } else if (tablePtr[0] == '\'') {
            strcpy(currentParamType, "char"); // Character constant
        } else {
            // This is a variable - need to look up its type
            strcpy(currentParamType, "unknown");
        }
    }
	| argument_expression_list ',' assignment_expression { 
        $$ = createNode(",", $1, $3); 
    }
	;

unary_expression
	: postfix_expression { $$ = $1; }
	| INC_OP unary_expression 	{ $$ = createNode("++", $2, NULL); }
	| DEC_OP unary_expression 	{ $$ = createNode("--", $2, NULL); }
	| unary_operator cast_expression { $$ = createNode("unary_op", $1, $2); }
	| SIZEOF unary_expression 	{ $$ = createNode("sizeof", $2, NULL); }
	| SIZEOF '(' type_name ')' 	{ $$ = createNode("sizeof(type)", NULL, NULL); }
    | NEW cast_expression       { $$ = createNode("new", $2, NULL); } /* C++ specific */
    | DELETE cast_expression    { $$ = createNode("delete", $2, NULL); } /* C++ specific */
	;

unary_operator
	: '&' { $$ = createNode("&", NULL, NULL); }
	| '*' { $$ = createNode("*", NULL, NULL); }
	| '+' { $$ = createNode("+", NULL, NULL); }
	| '-' { $$ = createNode("-", NULL, NULL); }
	| '~' { $$ = createNode("~", NULL, NULL); }
	| '!' { $$ = createNode("!", NULL, NULL); }
	;

cast_expression
	: unary_expression { $$ = $1; }
	| '(' type_name ')' cast_expression { $$ = createNode("cast", $4, NULL); }
	;

multiplicative_expression
	: cast_expression { $$ = $1; }
	| multiplicative_expression '*' cast_expression { makeList("*", 'o', lineCount); $$ = createNode("*", $1, $3); }
	| multiplicative_expression '/' cast_expression { makeList("/", 'o', lineCount); $$ = createNode("/", $1, $3); }
	| multiplicative_expression '%' cast_expression { makeList("%", 'o', lineCount); $$ = createNode("%", $1, $3); }
	;

additive_expression
	: multiplicative_expression { $$ = $1; }
	| additive_expression '+' multiplicative_expression { makeList("+", 'o', lineCount); $$ = createNode("+", $1, $3); }
	| additive_expression '-' multiplicative_expression { makeList("-", 'o', lineCount); $$ = createNode("-", $1, $3); }
	;

shift_expression
	: additive_expression { $$ = $1; }
	| shift_expression LEFT_OP additive_expression 	{ $$ = createNode("<<", $1, $3); }
	| shift_expression RIGHT_OP additive_expression { $$ = createNode(">>", $1, $3); }
	;

relational_expression
	: shift_expression { $$ = $1; }
	| relational_expression '<' shift_expression { 
		makeList("<", 'o', lineCount); 
		$$ = createNode("<", $1, $3); 
	}
	| relational_expression '>' shift_expression { 
		makeList(">", 'o', lineCount); 
		$$ = createNode(">", $1, $3); 
	}
	| relational_expression LE_OP shift_expression { 
		makeList("<=", 'o', lineCount); 
		$$ = createNode("<=", $1, $3); 
	}
	| relational_expression GE_OP shift_expression { 
		makeList(">=", 'o', lineCount); 
		$$ = createNode(">=", $1, $3); 
	}
	;

equality_expression
	: relational_expression { $$ = $1; }
	| equality_expression EQ_OP relational_expression { 
		makeList("==", 'o', lineCount); 
		$$ = createNode("==", $1, $3); 
	}
	| equality_expression NE_OP relational_expression { 
		makeList("!=", 'o', lineCount); 
		$$ = createNode("!=", $1, $3); 
	}
	;

and_expression
	: equality_expression { $$ = $1; }
	| and_expression '&' equality_expression 	{ $$ = createNode("&", $1, $3); }
	;

exclusive_or_expression
	: and_expression { $$ = $1; }
	| exclusive_or_expression '^' and_expression 	{ $$ = createNode("^", $1, $3); }
	;

inclusive_or_expression
	: exclusive_or_expression { $$ = $1; }
	| inclusive_or_expression '|' exclusive_or_expression { $$ = createNode("|", $1, $3); }
	;

logical_and_expression
	: inclusive_or_expression { $$ = $1; }
	| logical_and_expression AND_OP inclusive_or_expression { 
		makeList("&&", 'o', lineCount); 
		$$ = createNode("&&", $1, $3); 
	}
	;

logical_or_expression
	: logical_and_expression { $$ = $1; }
	| logical_or_expression OR_OP logical_and_expression { 
		makeList("||", 'o', lineCount); 
		$$ = createNode("||", $1, $3); 
	}
	;

conditional_expression
	: logical_or_expression { $$ = $1; }
	| logical_or_expression '?' expression ':' conditional_expression { 
		makeList("?", 'o', lineCount); 
		makeList(":", 'o', lineCount); 
		$$ = createNode("?:", $1, $3); 
	}
	;

assignment_expression
	: conditional_expression { $$ = $1; }
	| unary_expression assignment_operator assignment_expression { 
		$$ = createNode("assign", $1, $3); 
	}
	;

assignment_operator
	: '=' { makeList("=", 'o', lineCount); $$ = createNode("=", NULL, NULL); }
	| MUL_ASSIGN { makeList("*=", 'o', lineCount); $$ = createNode("*=", NULL, NULL); }
	| DIV_ASSIGN { makeList("/=", 'o', lineCount); $$ = createNode("/=", NULL, NULL); }
	| MOD_ASSIGN { makeList("%=", 'o', lineCount); $$ = createNode("%=", NULL, NULL); }
	| ADD_ASSIGN { makeList("+=", 'o', lineCount); $$ = createNode("+=", NULL, NULL); }
	| SUB_ASSIGN { makeList("-=", 'o', lineCount); $$ = createNode("-=", NULL, NULL); }
	| LEFT_ASSIGN { makeList("<<=", 'o', lineCount); $$ = createNode("<<=", NULL, NULL); }
	| RIGHT_ASSIGN { makeList(">>=", 'o', lineCount); $$ = createNode(">>=", NULL, NULL); }
	| AND_ASSIGN { makeList("&=", 'o', lineCount); $$ = createNode("&=", NULL, NULL); }
	| XOR_ASSIGN { makeList("^=", 'o', lineCount); $$ = createNode("^=", NULL, NULL); }
	| OR_ASSIGN { makeList("|=", 'o', lineCount); $$ = createNode("|=", NULL, NULL); }
	;

expression
	: assignment_expression { $$ = $1; }
	| expression ',' assignment_expression { 
		makeList(",", 'p', lineCount); 
		$$ = createNode(",", $1, $3); 
	}
	;

constant_expression
	: conditional_expression { $$ = $1; }
	;

/* Add C++ specific syntax */
class_definition
    : class_head '{' class_body '}' { 
        makeList("{", 'p', lineCount);
        makeList("}", 'p', lineCount);
        $$ = createNode("class_definition", $1, $3); 
    }
    ;

class_head
    : CLASS IDENTIFIER { 
        makeList("class", 'k', lineCount);
        makeList(tablePtr, 'v', lineCount);
        char classType[64] = "class ";
        strcat(classType, tablePtr);
        setType(classType);
        $$ = createNode("class", NULL, NULL); 
    }
    | CLASS IDENTIFIER base_clause { 
        makeList("class", 'k', lineCount);
        makeList(tablePtr, 'v', lineCount);
        char classType[64] = "class ";
        strcat(classType, tablePtr);
        setType(classType);
        $$ = createNode("class_with_base", $3, NULL); 
    }
    ;

base_clause
    : ':' access_specifier IDENTIFIER { 
        makeList(":", 'p', lineCount);
        makeList(tablePtr, 'v', lineCount);
        $$ = createNode("base_clause", NULL, NULL); 
    }
    ;

access_specifier
    : PUBLIC { makeList("public", 'k', lineCount); $$ = createNode("public", NULL, NULL); }
    | PRIVATE { makeList("private", 'k', lineCount); $$ = createNode("private", NULL, NULL); }
    | PROTECTED { makeList("protected", 'k', lineCount); $$ = createNode("protected", NULL, NULL); }
    ;

class_body
    : member_list { $$ = $1; }
    | /* empty */ { $$ = NULL; }
    ;

member_list
    : member_declaration { $$ = $1; }
    | member_list member_declaration { $$ = flattenTree("member_list", $1, $2); }
    ;

member_declaration
    : access_specifier ':' { $$ = $1; }
    | declaration { $$ = $1; }
    | constructor_definition { $$ = $1; }
    | destructor_definition { $$ = $1; }
    ;

constructor_definition
    : IDENTIFIER '(' parameter_list ')' compound_statement { $$ = createNode("constructor", $3, $5); }
    | IDENTIFIER '(' ')' compound_statement { $$ = createNode("constructor", NULL, $4); }
    ;

destructor_definition
    : '~' IDENTIFIER '(' ')' compound_statement { $$ = createNode("destructor", NULL, $5); }
    ;

/* Namespace support */
translation_unit
    : external_declaration { 
        setType("UNKNOWN"); 
        $$ = $1; 
        root = $$; 
    }
    | translation_unit external_declaration { 
        $$ = flattenTree("translation_unit", $1, $2); 
        root = $$; 
    }
    | NAMESPACE IDENTIFIER '{' translation_unit '}' { 
        makeList("namespace", 'k', lineCount);
        makeList(tablePtr, 'v', lineCount);
        makeList("{", 'p', lineCount);
        makeList("}", 'p', lineCount);
        $$ = createNode("namespace", $4, NULL); 
        root = $$; 
    }
    | USING NAMESPACE IDENTIFIER ';' { 
        makeList("using", 'k', lineCount);
        makeList("namespace", 'k', lineCount);
        makeList(tablePtr, 'v', lineCount);
        makeList(";", 'p', lineCount);
        $$ = createNode("using_namespace", NULL, NULL); 
        root = $$; 
    }
    | '#' IDENTIFIER STRING_LITERAL { 
        makeList("#", 'p', lineCount);
        makeList(tablePtr, 'v', lineCount);
        $$ = createNode("preprocessor", NULL, NULL); 
        root = $$; 
    } 
    | '#' IDENTIFIER '<' IDENTIFIER '>' { 
        makeList("#", 'p', lineCount);
        makeList(tablePtr, 'v', lineCount);
        makeList("<", 'p', lineCount);
        makeList(">", 'p', lineCount);
        $$ = createNode("preprocessor_include", NULL, NULL); 
        root = $$; 
    }
    ;

/* Additional rules from syntaxChecker.y needed for the parser to work */
external_declaration
	: function_definition { $$ = $1; }
	| declaration { $$ = $1; }
    | class_definition { $$ = $1; } /* C++ specific */
	;

function_definition
	: declaration_specifiers declarator declaration_list compound_statement {
		$$ = flattenTree("function_definition", $1, flattenTree("function_parts", $2, flattenTree("function_parts", $3, $4)));
	}
	| declaration_specifiers declarator compound_statement {
		$$ = flattenTree("function_definition", $1, flattenTree("function_parts", $2, $3));
        
        // Function implementation checks
        FunctionDecl* decl = findFunctionDeclaration(currentFunctionName);
        if (decl) {
            // Check existing declaration against current implementation
            // (would add parameter type checking here)
        }
        // Otherwise this is a new function without a prior declaration
	}
	| declarator declaration_list compound_statement {
		$$ = flattenTree("function_definition", $1, flattenTree("function_parts", $2, $3));
	}
	| declarator compound_statement {
		$$ = flattenTree("function_definition", $1, $2);
	}
	;

declaration
	: declaration_specifiers ';' { 
		makeList(";", 'p', lineCount);
		$$ = flattenTree("declaration", $1, NULL); 
	}
	| declaration_specifiers init_declarator_list ';' { 
		makeList(";", 'p', lineCount);
		$$ = flattenTree("declaration", $1, $2); 
	}
	;

declaration_specifiers
    : storage_class_specifier { $$ = $1; }
    | storage_class_specifier declaration_specifiers { $$ = flattenTree("declaration_specifiers", $1, $2); }
    | type_specifier { $$ = $1; }
    | type_specifier declaration_specifiers { $$ = flattenTree("declaration_specifiers", $1, $2); }
    | type_qualifier { $$ = $1; }
    | type_qualifier declaration_specifiers { $$ = flattenTree("declaration_specifiers", $1, $2); }
    ;

storage_class_specifier
    : TYPEDEF { makeList("typedef", 'k', lineCount); $$ = createNode("TYPEDEF", NULL, NULL); }
    | EXTERN { makeList("extern", 'k', lineCount); $$ = createNode("EXTERN", NULL, NULL); }
    | STATIC { makeList("static", 'k', lineCount); $$ = createNode("STATIC", NULL, NULL); }
    | AUTO { makeList("auto", 'k', lineCount); $$ = createNode("AUTO", NULL, NULL); }
    | REGISTER { makeList("register", 'k', lineCount); $$ = createNode("REGISTER", NULL, NULL); }
    ;

type_specifier
    : VOID { setType("void"); $$ = createNode("VOID", NULL, NULL); }
    | CHAR { setType("char"); $$ = createNode("CHAR", NULL, NULL); }
    | SHORT { setType("short"); $$ = createNode("SHORT", NULL, NULL); }
    | INT { setType("int"); $$ = createNode("INT", NULL, NULL); }
    | LONG { setType("long"); $$ = createNode("LONG", NULL, NULL); }
    | FLOAT { setType("float"); $$ = createNode("FLOAT", NULL, NULL); }
    | DOUBLE { setType("double"); $$ = createNode("DOUBLE", NULL, NULL); }
    | SIGNED { appendType("signed"); $$ = createNode("SIGNED", NULL, NULL); }
    | UNSIGNED { appendType("unsigned"); $$ = createNode("UNSIGNED", NULL, NULL); }
    | BOOL { setType("bool"); $$ = createNode("BOOL", NULL, NULL); } /* C++ specific */
    | struct_or_union_specifier { $$ = $1; }
    | enum_specifier { $$ = $1; }
    | TYPE_NAME { $$ = createNode("TYPE_NAME", NULL, NULL); }
    ;

struct_or_union_specifier
    : STRUCT IDENTIFIER { 
        char structType[64] = "struct ";
        strcat(structType, tablePtr); 
        setType(structType);
        $$ = createNode("struct", NULL, NULL); 
    }
    | UNION IDENTIFIER { 
        char unionType[64] = "union ";
        strcat(unionType, tablePtr);
        setType(unionType);
        $$ = createNode("union", NULL, NULL); 
    }
    | STRUCT IDENTIFIER '{' struct_declaration_list '}' { 
        char structType[64] = "struct ";
        strcat(structType, tablePtr);
        setType(structType);
        $$ = createNode("struct_def", NULL, NULL); 
    }
    | UNION IDENTIFIER '{' struct_declaration_list '}' { 
        char unionType[64] = "union ";
        strcat(unionType, tablePtr);
        setType(unionType);
        $$ = createNode("union_def", NULL, NULL); 
    }
    | STRUCT '{' struct_declaration_list '}' { 
        setType("anonymous_struct");
        $$ = createNode("anon_struct", NULL, NULL); 
    }
    | UNION '{' struct_declaration_list '}' { 
        setType("anonymous_union");
        $$ = createNode("anon_union", NULL, NULL); 
    }
    ;

struct_declaration_list
    : struct_declaration { $$ = $1; }
    | struct_declaration_list struct_declaration { $$ = flattenTree("struct_declarations", $1, $2); }
    ;

struct_declaration
    : specifier_qualifier_list struct_declarator_list ';' { $$ = flattenTree("struct_declaration", $1, $2); }
    ;

specifier_qualifier_list
    : type_specifier { $$ = $1; }
    | type_specifier specifier_qualifier_list { $$ = flattenTree("specifier_qualifier_list", $1, $2); }
    | type_qualifier { $$ = $1; }
    | type_qualifier specifier_qualifier_list { $$ = flattenTree("specifier_qualifier_list", $1, $2); }
    ;

struct_declarator_list
    : declarator { $$ = $1; }
    | struct_declarator_list ',' declarator { $$ = flattenTree("struct_declarator_list", $1, $3); }
    ;

enum_specifier
    : ENUM IDENTIFIER { $$ = createNode("enum", NULL, NULL); }
    | ENUM '{' enumerator_list '}' { $$ = createNode("enum_def", NULL, NULL); }
    | ENUM IDENTIFIER '{' enumerator_list '}' { $$ = createNode("named_enum_def", NULL, NULL); }
    ;

enumerator_list
    : enumerator { $$ = $1; }
    | enumerator_list ',' enumerator { $$ = flattenTree("enumerator_list", $1, $3); }
    ;

enumerator
    : IDENTIFIER { $$ = createNode("enumerator", NULL, NULL); }
    | IDENTIFIER '=' constant_expression { $$ = createNode("enumerator_value", NULL, NULL); }
    ;

type_qualifier
    : CONST { $$ = createNode("CONST", NULL, NULL); }
    | VOLATILE { $$ = createNode("VOLATILE", NULL, NULL); }
    ;

declarator
    : pointer direct_declarator { $$ = flattenTree("declarator", $1, $2); }
    | direct_declarator { $$ = $1; }
    ;

direct_declarator
    : IDENTIFIER { 
        // Track the identifier and add it to symbol table
        makeList(tablePtr, 'v', lineCount);
        $$ = createNode("identifier", NULL, NULL); 
    }
    | '(' declarator ')' { 
        makeList("(", 'p', lineCount);
        makeList(")", 'p', lineCount);
        $$ = $2; 
    }
    | direct_declarator '[' ']' { 
        makeList("[", 'p', lineCount);
        makeList("]", 'p', lineCount);
        $$ = createNode("array_declarator", $1, NULL); 
    }
    | direct_declarator '[' constant_expression ']' { 
        makeList("[", 'p', lineCount);
        makeList("]", 'p', lineCount);
        $$ = createNode("array_size_declarator", $1, $3); 
    }
    | direct_declarator '(' parameter_type_list ')' { 
        makeList("(", 'p', lineCount);
        makeList(")", 'p', lineCount);
        $$ = createNode("function_declarator", $1, $3); 
    }
    | direct_declarator '(' identifier_list ')' { 
        makeList("(", 'p', lineCount);
        makeList(")", 'p', lineCount);
        $$ = createNode("function_declarator", $1, $3); 
    }
    | direct_declarator '(' ')' { 
        makeList("(", 'p', lineCount);
        makeList(")", 'p', lineCount);
        $$ = createNode("function_declarator", $1, NULL); 
    }
    ;

pointer
    : '*' { $$ = createNode("pointer", NULL, NULL); }
    | '*' type_qualifier_list { $$ = createNode("qualified_pointer", NULL, NULL); }
    | '*' pointer { $$ = createNode("pointer_to_pointer", NULL, NULL); }
    | '*' type_qualifier_list pointer { $$ = createNode("qualified_pointer_to_pointer", NULL, NULL); }
    ;

type_qualifier_list
    : type_qualifier { $$ = $1; }
    | type_qualifier_list type_qualifier { $$ = flattenTree("type_qualifier_list", $1, $2); }
    ;

parameter_type_list
    : parameter_list { $$ = $1; }
    | parameter_list ',' ELLIPSIS { $$ = flattenTree("variadic_params", $1, NULL); }
    ;

parameter_list
    : parameter_declaration { $$ = $1; }
    | parameter_list ',' parameter_declaration { $$ = flattenTree("parameter_list", $1, $3); }
    ;

parameter_declaration
    : declaration_specifiers declarator { $$ = flattenTree("parameter", $1, $2); }
    | declaration_specifiers abstract_declarator { $$ = flattenTree("abstract_parameter", $1, $2); }
    | declaration_specifiers { $$ = $1; }
    ;

identifier_list
    : IDENTIFIER { $$ = createNode("identifier", NULL, NULL); }
    | identifier_list ',' IDENTIFIER { $$ = flattenTree("identifier_list", $1, NULL); }
    ;

type_name
	: specifier_qualifier_list { $$ = $1; }
    | specifier_qualifier_list abstract_declarator { $$ = flattenTree("type_name", $1, $2); }
	;

abstract_declarator
    : pointer { $$ = $1; }
    | direct_abstract_declarator { $$ = $1; }
    | pointer direct_abstract_declarator { $$ = flattenTree("abstract_declarator", $1, $2); }
    ;

direct_abstract_declarator
    : '(' abstract_declarator ')' { $$ = $2; }
    | '[' ']' { $$ = createNode("abstract_array", NULL, NULL); }
    | '[' constant_expression ']' { $$ = createNode("abstract_array_size", $2, NULL); }
    | direct_abstract_declarator '[' ']' { $$ = createNode("abstract_array", $1, NULL); }
    | direct_abstract_declarator '[' constant_expression ']' { $$ = createNode("abstract_array_size", $1, $3); }
    | '(' ')' { $$ = createNode("abstract_function", NULL, NULL); }
    | '(' parameter_type_list ')' { $$ = createNode("abstract_function_params", $2, NULL); }
    | direct_abstract_declarator '(' ')' { $$ = createNode("abstract_function", $1, NULL); }
    | direct_abstract_declarator '(' parameter_type_list ')' { $$ = createNode("abstract_function_params", $1, $3); }
    ;

init_declarator_list
    : init_declarator { $$ = $1; }
    | init_declarator_list ',' init_declarator { $$ = flattenTree("init_declarator_list", $1, $3); }
    ;

init_declarator
    : declarator { $$ = $1; }
    | declarator '=' initializer { $$ = createNode("init", $1, $3); }
    ;

initializer
    : assignment_expression { $$ = $1; }
    | '{' initializer_list '}' { $$ = $2; }
    | '{' initializer_list ',' '}' { $$ = $2; }
    ;

initializer_list
    : initializer { $$ = $1; }
    | initializer_list ',' initializer { $$ = flattenTree("initializer_list", $1, $3); }
    ;

statement
    : labeled_statement { $$ = $1; }
    | compound_statement { $$ = $1; }
    | expression_statement { $$ = $1; }
    | selection_statement { $$ = $1; }
    | iteration_statement { $$ = $1; }
    | jump_statement { $$ = $1; }
    | try_catch_statement { $$ = $1; } /* C++ specific */
    ;

labeled_statement
    : IDENTIFIER ':' statement { $$ = createNode("labeled", NULL, $3); }
    | CASE constant_expression ':' statement { $$ = createNode("case", $2, $4); }
    | DEFAULT ':' statement { $$ = createNode("default", NULL, $3); }
    ;

compound_statement
    : '{' '}' { makeList("{", 'p', lineCount); makeList("}", 'p', lineCount); $$ = createNode("compound", NULL, NULL); }
    | '{' block_item_list '}' { makeList("{", 'p', lineCount); makeList("}", 'p', lineCount); $$ = createNode("compound", $2, NULL); }
    ;

block_item_list
    : block_item { $$ = $1; }
    | block_item_list block_item { $$ = flattenTree("block_items", $1, $2); }
    ;

block_item
    : declaration { $$ = $1; }
    | statement { $$ = $1; }
    ;

expression_statement
    : ';' { makeList(";", 'p', lineCount); $$ = createNode("empty", NULL, NULL); }
    | expression ';' { makeList(";", 'p', lineCount); $$ = $1; }
    ;

selection_statement
    : IF '(' expression ')' statement { 
        makeList("if", 'k', lineCount);
        makeList("(", 'p', lineCount);
        makeList(")", 'p', lineCount);
        $$ = createNode("if", $3, $5); 
    }
    | IF '(' expression ')' statement ELSE statement { 
        makeList("if", 'k', lineCount);
        makeList("(", 'p', lineCount);
        makeList(")", 'p', lineCount);
        makeList("else", 'k', lineCount);
        $$ = createNode("if-else", $3, flattenTree("if-else", $5, $7)); 
    }
    | SWITCH '(' expression ')' statement { 
        makeList("switch", 'k', lineCount);
        makeList("(", 'p', lineCount);
        makeList(")", 'p', lineCount);
        $$ = createNode("switch", $3, $5); 
    }
    ;

iteration_statement
    : WHILE '(' expression ')' statement { 
        makeList("while", 'k', lineCount);
        makeList("(", 'p', lineCount);
        makeList(")", 'p', lineCount);
        $$ = createNode("while", $3, $5); 
    }
    | DO statement WHILE '(' expression ')' ';' { 
        makeList("do", 'k', lineCount);
        makeList("while", 'k', lineCount);
        makeList("(", 'p', lineCount);
        makeList(")", 'p', lineCount);
        makeList(";", 'p', lineCount);
        $$ = createNode("do-while", $2, $5); 
    }
    | FOR '(' for_expr ';' for_expr ';' for_expr ')' statement { 
        makeList("for", 'k', lineCount);
        makeList("(", 'p', lineCount);
        makeList(";", 'p', lineCount);
        makeList(";", 'p', lineCount);
        makeList(")", 'p', lineCount);
        $$ = create_for_node($3, $5, $7, $9); 
    }
    ;

for_expr
    : /* empty */ { $$ = NULL; }
    | expression { $$ = $1; }
    ;

jump_statement
    : GOTO IDENTIFIER ';' { 
        makeList("goto", 'k', lineCount); 
        makeList(";", 'p', lineCount);
        $$ = createNode("goto", NULL, NULL); 
    }
    | CONTINUE ';' { 
        makeList("continue", 'k', lineCount); 
        makeList(";", 'p', lineCount);
        $$ = createNode("continue", NULL, NULL); 
    }
    | BREAK ';' { 
        makeList("break", 'k', lineCount);
        makeList(";", 'p', lineCount);
        $$ = createNode("break", NULL, NULL); 
    }
    | RETURN ';' { 
        makeList("return", 'k', lineCount);
        makeList(";", 'p', lineCount);
        $$ = createNode("return", NULL, NULL); 
    }
    | RETURN expression ';' { 
        makeList("return", 'k', lineCount);
        makeList(";", 'p', lineCount);
        $$ = createNode("return_value", $2, NULL); 
    }
    ;

declaration_list
    : declaration { $$ = $1; }
    | declaration_list declaration { $$ = flattenTree("declaration_list", $1, $2); }
    ;

try_catch_statement
    : TRY compound_statement CATCH '(' parameter_declaration ')' compound_statement {
        makeList("try", 'k', lineCount);
        makeList("catch", 'k', lineCount);
        makeList("(", 'p', lineCount);
        makeList(")", 'p', lineCount);
        $$ = createNode("try_catch", $2, $7);
    }
    ;

%%

int main(int argc, char *argv[])
{
    // Initialize the table pointers
    symbolPtr = NULL;
    constantPtr = NULL;
    parsedPtr = NULL;
    errorFlag = 0;
    
    // Set default type
    strcpy(typeBuffer, "UNKNOWN");

    // Open error file
	yyerrfile = fopen("syntaxErrors.txt", "w");
	if (!yyerrfile) {
		printf("Error: Could not open syntaxErrors.txt for writing\n");
		return;
	}
	
    if(argc > 1) {
        FILE *fp = fopen(argv[1], "r");
        if(fp) {
            sourceCode = (char *)malloc(strlen(argv[1]) * sizeof(char));
            strcpy(sourceCode, argv[1]);
            yyin = fp;
        } else {
            printf("Error opening file: %s\n", argv[1]);
            return 1;
        }
    } else {
        printf("No input file specified\n");
        return 1;
    }

    // Run the parser
    yyparse();

    if(!errorFlag) {
        printf("\n\n\t\t%s Parsing Completed\n\n", sourceCode);
        printf("\t\tSuccessful parsing! %s has no syntax errors.\n\n",sourceCode);

        // Print parse tree
        FILE *parseTree = fopen("parsetree.txt", "w");
        if(parseTree) {
            printParseTree(root, 0, parseTree);
            fclose(parseTree);
        }
    }
    // Close the input file
    if (yyin) fclose(yyin);
    
    return 0;
}

void yyerror(const char *s) {
    errorFlag = 1;
	fprintf(yyerrfile,"\n\t\t\t\tSyntax Errors\n\n");
    fprintf(yyerrfile,"\n%s : %d : %s\n", sourceCode, lineCount, s);
}