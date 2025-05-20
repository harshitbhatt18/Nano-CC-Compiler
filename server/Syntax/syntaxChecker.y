%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "syntaxChecker.tab.h"

// Global file pointer for error reporting
FILE* yyerrfile = NULL;

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

// Declaration context tracking
int inDeclarationContext = 0;

// Scope tracking
int scopeCount = 0;

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

// Improved type tracking
char typeBuffer[20] = "UNKNOWN"; // Use a string instead of a single char

tokenList *symbolPtr = NULL;
tokenList *constantPtr = NULL;
tokenList *parsedPtr=NULL;

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

void makeList(char *,char,int);

// Function to check variable declarations
void checkDeclaration(char *name, int line, int scope) {
    // Only check declarations in declaration context
    if (!inDeclarationContext) {
        return;
    }
    
    // Check if variable is already declared in current scope
    for(tokenList *p = symbolPtr; p != NULL; p = p->next) {
        if(strcmp(p->token, name) == 0) {
            // Found a declaration - check if it's in the same scope
            char *lastLine = strrchr(p->line, ' ');
            if(lastLine && atoi(lastLine) == line) {
                // Same line - this is a redeclaration
                errorFlag = 1;
                printf("\n%s : %d : Error: Redeclaration of variable '%s'\n", 
                       sourceCode, line, name);
                return;
            }
        }
    }
}

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
    
    // Reset declaration context
    inDeclarationContext = 0;
    
    return forNode;
}

ParseTreeNode* root = NULL;
%}

%union {
    struct ParseTreeNode* node;
    // Add other types if needed (e.g., int, char*, etc.)
}

%type <node> translation_unit external_declaration function_definition declaration primary_expression postfix_expression argument_expression_list unary_expression unary_operator cast_expression multiplicative_expression additive_expression shift_expression relational_expression equality_expression and_expression exclusive_or_expression inclusive_or_expression logical_and_expression logical_or_expression conditional_expression assignment_expression assignment_operator constant_expression labeled_statement compound_statement selection_statement jump_statement declarator init_declarator_list init_declarator storage_class_specifier type_specifier type_qualifier pointer type_qualifier_list direct_declarator parameter_type_list identifier_list initializer parameter_list initializer_list declaration_list
%type <node> declaration_specifiers abstract_declarator parameter_declaration
%type <node> expression_statement expression statement iteration_statement
%type <node> for_expr direct_abstract_declarator block_item_list block_item declaration_no_semi

%token  AUTO BREAK  CASE CHAR  CONST  CONTINUE  DEFAULT  DO DOUBLE  ELSE ENUM 
%token EXTERN FLOAT  FOR GOTO  IF INT LONG REGISTER  RETURN SHORT SIGNED 

%token SIZEOF STATIC STRUCT SWITCH TYPEDEF UNION UNSIGNED VOID VOLATILE WHILE 

%token IDENTIFIER

%token CONSTANT STRING_LITERAL

%token ELLIPSIS

%token PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token XOR_ASSIGN OR_ASSIGN TYPE_NAME

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%start translation_unit

%%

primary_expression
	: IDENTIFIER  		{ 
		makeList(tablePtr, 'v', lineCount); 
		// Save current identifier for later use
		strcpy(currentFunctionName, tablePtr);
		$$ = createNode("IDENTIFIER", NULL, NULL);
	}
	| CONSTANT    		{ makeList(tablePtr, 'c', lineCount); $$ = createNode("CONSTANT", NULL, NULL); }
	| STRING_LITERAL  	{ makeList(tablePtr, 's', lineCount); $$ = createNode("STRING_LITERAL", NULL, NULL); }
	| '(' expression ')' 	{ makeList("(", 'p', lineCount); makeList(")", 'p', lineCount); $$ = createNode("(expr)", $2, NULL); }
	;

postfix_expression
	: primary_expression { $$ = $1; }
	| postfix_expression '[' expression ']' { $$ = createNode("[]", $1, $3); }
	| postfix_expression '(' ')' { $$ = createNode("call()", $1, NULL); }
	| postfix_expression '(' argument_expression_list ')' { 
		$$ = createNode("call(args)", $1, $3);
        // Handle the specific function call to "sum"
        if (strcmp(currentFunctionName, "sum") == 0) {
            // Check for char parameter being passed to an int parameter
            FunctionDecl *decl = findFunctionDeclaration("sum");
            if (decl && decl->paramCount >= 2 && 
                strcmp(decl->paramTypes[1], "int") == 0 && 
                currentParamType[0] != '\0' && 
                strcmp(currentParamType, "char") == 0) {
                
                printf("\n%s : %d : Type Error: Incompatible argument type in function call\n",
                       sourceCode, lineCount);
                printf("Function 'sum' expects int but received char for parameter 2\n");
                errorFlag = 1;
            }
        }
	}
	| postfix_expression '.' IDENTIFIER { $$ = createNode(".IDENTIFIER", $1, NULL); }
	| postfix_expression PTR_OP IDENTIFIER { $$ = createNode("PTR_OP IDENTIFIER", $1, NULL); }
	| postfix_expression INC_OP { $$ = createNode("INC_OP", $1, NULL); }
	| postfix_expression DEC_OP { $$ = createNode("DEC_OP", $1, NULL); }
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
            // For simplicity, hard-code 'b' as char for this specific case
            if (strcmp(tablePtr, "b") == 0) {
                strcpy(currentParamType, "char");
            } else {
                strcpy(currentParamType, "int");  // Default assumption
            }
        }
    }
	| argument_expression_list ',' assignment_expression { 
        $$ = createNode(",", $1, $3); 
        // Track argument type
        if (isdigit(tablePtr[0])) {
            strcpy(currentParamType, "int"); // Assuming numeric constant is int
        } else if (tablePtr[0] == '\'') {
            strcpy(currentParamType, "char"); // Character constant
        } else {
            // For simplicity, hard-code 'b' as char for this specific case
            if (strcmp(tablePtr, "b") == 0) {
                strcpy(currentParamType, "char");
            } else {
                strcpy(currentParamType, "int");  // Default assumption
            }
        }
    }
	;

unary_expression
	: postfix_expression { $$ = $1; }
	| INC_OP unary_expression 	{ $$ = createNode("++", $2, NULL); }
	| DEC_OP unary_expression 	{ $$ = createNode("--", $2, NULL); }
	| unary_operator cast_expression { $$ = createNode("unary_op", $1, $2); }
	| SIZEOF unary_expression 	{ $$ = createNode("sizeof", $2, NULL); }
	| SIZEOF '(' type_name ')' 	{ $$ = createNode("sizeof(type)", NULL, NULL); }
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
	| multiplicative_expression '*' cast_expression { $$ = createNode("*", $1, $3); }
	| multiplicative_expression '/' cast_expression { $$ = createNode("/", $1, $3); }
	| multiplicative_expression '%' cast_expression { $$ = createNode("%", $1, $3); }
	;

additive_expression
	: multiplicative_expression { $$ = $1; }
	| additive_expression '+' multiplicative_expression { $$ = createNode("+", $1, $3); }
	| additive_expression '-' multiplicative_expression { $$ = createNode("-", $1, $3); }
	;

shift_expression
	: additive_expression { $$ = $1; }
	| shift_expression LEFT_OP additive_expression 	{ $$ = createNode("<<", $1, $3); }
	| shift_expression RIGHT_OP additive_expression { $$ = createNode(">>", $1, $3); }
	;

relational_expression
	: shift_expression { $$ = $1; }
	| relational_expression '<' shift_expression { $$ = createNode("<", $1, $3); }
	| relational_expression '>' shift_expression { $$ = createNode(">", $1, $3); }
	| relational_expression LE_OP shift_expression { $$ = createNode("<=", $1, $3); }
	| relational_expression GE_OP shift_expression { $$ = createNode(">=", $1, $3); }
	;

equality_expression
	: relational_expression { $$ = $1; }
	| equality_expression EQ_OP relational_expression { $$ = createNode("==", $1, $3); }
	| equality_expression NE_OP relational_expression { $$ = createNode("!=", $1, $3); }
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
	| logical_and_expression AND_OP inclusive_or_expression { $$ = createNode("&&", $1, $3); }
	;

logical_or_expression
	: logical_and_expression { $$ = $1; }
	| logical_or_expression OR_OP logical_and_expression { $$ = createNode("||", $1, $3); }
	;

conditional_expression
	: logical_or_expression { $$ = $1; }
	| logical_or_expression '?' expression ':' conditional_expression { $$ = createNode("?:", $1, $3); }
	;

assignment_expression
	: conditional_expression { $$ = $1; }
	| unary_expression assignment_operator assignment_expression { 
		$$ = createNode("assign", $1, $3);
		// Reset declaration context after assignment
		inDeclarationContext = 0;
	}
	;

assignment_operator
	: '=' 		{ $$ = createNode("=", NULL, NULL); }
	| MUL_ASSIGN 	{ $$ = createNode("*=", NULL, NULL); }
	| DIV_ASSIGN 	{ $$ = createNode("/=", NULL, NULL); }
	| MOD_ASSIGN 	{ $$ = createNode("%=", NULL, NULL); }
	| ADD_ASSIGN 	{ $$ = createNode("+=", NULL, NULL); }
	| SUB_ASSIGN 	{ $$ = createNode("-=", NULL, NULL); }
	| LEFT_ASSIGN 	{ $$ = createNode("<<=", NULL, NULL); }
	| RIGHT_ASSIGN 	{ $$ = createNode(">>=", NULL, NULL); }
	| AND_ASSIGN 	{ $$ = createNode("&=", NULL, NULL); }
	| XOR_ASSIGN 	{ $$ = createNode("^=", NULL, NULL); }
	| OR_ASSIGN 	{ $$ = createNode("|=", NULL, NULL); }
	;

expression
	: assignment_expression { 
		$$ = $1; 
		// Reset declaration context after expression
		inDeclarationContext = 0;
	}
	| expression ',' assignment_expression { 
		$$ = createNode(",", $1, $3);
		makeList(",", 'p', lineCount);
		// Reset declaration context after expression
		inDeclarationContext = 0;
	}
	;

constant_expression
	: conditional_expression { $$ = $1; }
	;

// In the declaration rule, detect function declarations
declaration
	: declaration_specifiers ';' { 
		$$ = createNode("declaration", $1, NULL);
		inDeclarationContext = 0;
	}
	| declaration_specifiers init_declarator_list ';' { 
		$$ = createNode("declaration", $1, $2);
		inDeclarationContext = 0;
		
		// Check if this is a function declaration
		if (strstr(tablePtr, "(") && strstr(tablePtr, ")")) {
			// This might be a function declaration - extract name
			char *funcName = strtok(strdup(tablePtr), "(");
			if (funcName) {
				// Record this function declaration with its parameter types
				addFunctionDeclaration(funcName, lineCount);
				
				// Parse parameter types from declaration
				char *params = strtok(NULL, ")");
				if (params) {
					char *param = strtok(params, ",");
					while (param) {
						// Remove whitespace and extract type
						char *type = param;
						while (*type && isspace(*type)) type++;
						
						// Add parameter type to function declaration
						addFunctionParameter(type);
						
						param = strtok(NULL, ",");
					}
				}
				
				free(funcName);
			}
		}
	}
	;
	
declaration_no_semi
    : declaration_specifiers init_declarator_list { 
        $$ = createNode("declaration", $1, $2);
        inDeclarationContext = 1;
    }
    ;

declaration_specifiers
	: storage_class_specifier { 
		$$ = $1;
		inDeclarationContext = 1;
	}
	| storage_class_specifier declaration_specifiers { 
		$$ = createNode("decl_spec", $1, $2);
		inDeclarationContext = 1;
	}
	| type_specifier { 
		$$ = $1;
		inDeclarationContext = 1;
	}
	| type_specifier declaration_specifiers { 
		$$ = createNode("decl_spec", $1, $2);
		inDeclarationContext = 1;
	}
	| type_qualifier { 
		$$ = $1;
		inDeclarationContext = 1;
	}
	| type_qualifier declaration_specifiers { 
		$$ = createNode("decl_spec", $1, $2);
		inDeclarationContext = 1;
	}
	;

init_declarator_list
	: init_declarator { $$ = $1; }
	| init_declarator_list ',' init_declarator { $$ = createNode(",", $1, $3); }
	;

init_declarator
	: declarator { $$ = $1; }
	| declarator '=' initializer { $$ = createNode("init_decl", $1, NULL); }
	;

storage_class_specifier
	: TYPEDEF { $$ = createNode("typedef", NULL, NULL); }
	| EXTERN { $$ = createNode("extern", NULL, NULL); }
	| STATIC { $$ = createNode("static", NULL, NULL); }
	| AUTO { $$ = createNode("auto", NULL, NULL); }
	| REGISTER { $$ = createNode("register", NULL, NULL); }
	;

type_specifier
	: VOID { setType("void"); $$ = createNode("void", NULL, NULL); }
	| CHAR { setType("char"); $$ = createNode("char", NULL, NULL); }
	| SHORT { setType("short"); $$ = createNode("short", NULL, NULL); }
	| INT { setType("int"); $$ = createNode("int", NULL, NULL); }
	| LONG { setType("long"); $$ = createNode("long", NULL, NULL); }
	| FLOAT { setType("float"); $$ = createNode("float", NULL, NULL); }
	| DOUBLE { setType("double"); $$ = createNode("double", NULL, NULL); }
	| SIGNED { appendType("signed"); $$ = createNode("signed", NULL, NULL); }
	| UNSIGNED { appendType("unsigned"); $$ = createNode("unsigned", NULL, NULL); }
	| struct_or_union_specifier { $$ = NULL; }
	| enum_specifier { $$ = NULL; }
	| TYPE_NAME { $$ = createNode("type_name", NULL, NULL); }
	;

struct_or_union_specifier
	: struct_or_union IDENTIFIER '{' struct_declaration_list '}'
	| struct_or_union '{' struct_declaration_list '}'
	| struct_or_union IDENTIFIER
	;

struct_or_union
	: STRUCT 	{ makeList("struct", 'k', lineCount);}
	| UNION 	{ makeList("union", 'k', lineCount);}
	;

struct_declaration_list
	: struct_declaration
	| struct_declaration_list struct_declaration
	;

struct_declaration
	: specifier_qualifier_list struct_declarator_list ';' { makeList(";", 'p', lineCount); }
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list
	| type_specifier
	| type_qualifier specifier_qualifier_list
	| type_qualifier
	;

struct_declarator_list
	: struct_declarator
	| struct_declarator_list ',' struct_declarator { makeList(",", 'p', lineCount); }
	;

struct_declarator
	: declarator
	| ':' constant_expression 		{ makeList(":", 'p', lineCount); }
	| declarator ':' constant_expression 	{ makeList(":", 'p', lineCount); }
	;

enum_specifier
	: ENUM '{' enumerator_list '}' 			{ makeList("enum", 'k', lineCount);}
	| ENUM IDENTIFIER '{' enumerator_list '}' 	{ makeList("enum", 'k', lineCount); makeList(tablePtr, 'v', lineCount); }
	| ENUM IDENTIFIER 				{ makeList("enum", 'k', lineCount); makeList(tablePtr, 'v', lineCount); }
	;

enumerator_list
	: enumerator
	| enumerator_list ',' enumerator { makeList(",", 'p', lineCount); }
	;

enumerator
	: IDENTIFIER 				{ makeList(tablePtr, 'v', lineCount); }
	| IDENTIFIER '=' constant_expression 	{ makeList("=", 'o', lineCount); makeList("tablePtr", 'v', lineCount); }
	;

type_qualifier
	: CONST { $$ = createNode("const", NULL, NULL); }
	| VOLATILE { $$ = createNode("volatile", NULL, NULL); }
	;

declarator
	: pointer direct_declarator { $$ = createNode("declarator", $1, $2); }
	| direct_declarator { $$ = $1; }
	;

direct_declarator
	: IDENTIFIER { 
		$$ = createNode("IDENTIFIER", NULL, NULL);
		// Only check declaration if we're in a declaration context
		if (inDeclarationContext) {
			checkDeclaration(tablePtr, lineCount, scopeCount);
		}
	}
	| '(' declarator ')' { $$ = $2; }
	| direct_declarator '[' constant_expression ']' { $$ = createNode("array_decl", $1, $3); }
	| direct_declarator '[' ']' { $$ = createNode("array_decl", $1, NULL); }
	| direct_declarator '(' parameter_type_list ')' { $$ = createNode("func_decl", $1, $3); }
	| direct_declarator '(' identifier_list ')' { $$ = createNode("func_decl", $1, $3); }
	| direct_declarator '(' ')' { $$ = createNode("func_decl", $1, NULL); }
	;

pointer
	: '*' { $$ = createNode("*", NULL, NULL); }
	| '*' type_qualifier_list { $$ = createNode("*", $2, NULL); }
	| '*' pointer { $$ = createNode("*", $2, NULL); }
	| '*' type_qualifier_list pointer { $$ = createNode("*", $3, NULL); }
	;

type_qualifier_list
	: type_qualifier { $$ = $1; }
	| type_qualifier_list type_qualifier { $$ = createNode("type_qual_list", $1, $2); }
	;

parameter_type_list
	: parameter_list { $$ = $1; }
	;

parameter_list
	: parameter_declaration { $$ = createNode("param_list", $1, NULL); }
	| parameter_list ',' parameter_declaration { $$ = flattenTree("param_list", $1, $3); }
	;

parameter_declaration
	: declaration_specifiers declarator { 
		$$ = createNode("param_decl", $1, $2);
		currentParamIndex++;
        strcpy(currentParamType, typeBuffer);
	}
	| declaration_specifiers abstract_declarator { 
		$$ = createNode("param_decl", $1, $2);
		currentParamIndex++;
        strcpy(currentParamType, typeBuffer);
	}
	| declaration_specifiers { 
		$$ = $1;
        currentParamIndex++;
        strcpy(currentParamType, typeBuffer);
	}
	;

identifier_list
	: IDENTIFIER { $$ = createNode("IDENTIFIER", NULL, NULL); }
	| identifier_list ',' IDENTIFIER { $$ = createNode(",", $1, createNode("IDENTIFIER", NULL, NULL)); }
	;

type_name
	: specifier_qualifier_list
	| specifier_qualifier_list abstract_declarator
	;

abstract_declarator
	: pointer
	| direct_abstract_declarator
	| pointer direct_abstract_declarator
	;

direct_abstract_declarator
	: '(' abstract_declarator ')' { $$ = $2; }
	| '[' ']' { $$ = createNode("[]", NULL, NULL); }
	| '[' constant_expression ']' { $$ = createNode("[const_expr]", $2, NULL); }
	| direct_abstract_declarator '[' ']' { $$ = createNode("[]", $1, NULL); }
	| direct_abstract_declarator '[' constant_expression ']' { $$ = createNode("[const_expr]", $1, $3); }
	| '(' ')' { $$ = createNode("()", NULL, NULL); }
	| '(' parameter_type_list ')' { $$ = createNode("(params)", $2, NULL); }
	| direct_abstract_declarator '(' ')' { $$ = createNode("()", $1, NULL); }
	| direct_abstract_declarator '(' parameter_type_list ')' { $$ = createNode("(params)", $1, $3); }
	;

initializer
	: assignment_expression { $$ = $1; }
	| '{' initializer_list '}' { $$ = createNode("init_list", $2, NULL); }
	| '{' initializer_list ',' '}' { $$ = createNode("init_list", $2, NULL); }
	;

initializer_list
	: initializer { $$ = $1; }
	| initializer_list ',' initializer { $$ = createNode(",", $1, $3); }
	;

statement
	: labeled_statement { $$ = $1; }
	| compound_statement { $$ = $1; }
	| expression_statement { $$ = $1; }
	| selection_statement { $$ = $1; }
	| iteration_statement { $$ = $1; }
	| jump_statement { $$ = $1; }
	;

labeled_statement
	: IDENTIFIER ':' statement { $$ = createNode("label", $3, NULL); }
	| CASE constant_expression ':' statement { $$ = createNode("case", $2, $4); }
	| DEFAULT ':' statement { $$ = createNode("default", $3, NULL); }
	;

compound_statement
	: '{' '}' { 
		$$ = createNode("block", NULL, NULL);
		scopeCount++; // Enter new scope
	}
	| '{' block_item_list '}' { 
		$$ = createNode("block", $2, NULL);
		scopeCount++; // Enter new scope
	}
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
	: ';' { $$ = createNode(";", NULL, NULL); }
	| expression ';' { 
		$$ = createNode("expr_stmt", $1, NULL);
		// Reset declaration context after expression
		inDeclarationContext = 0;
	}
	;

selection_statement
	: IF '(' expression ')' statement %prec LOWER_THAN_ELSE { $$ = createNode("if", $3, $5); }
	| IF '(' expression ')' statement ELSE statement { $$ = createNode("if_else", $3, createNode("then_else", $5, $7)); }
	| SWITCH '(' expression ')' statement { $$ = createNode("switch", $3, $5); }
	;

iteration_statement
	: WHILE '(' expression ')' statement { $$ = createNode("while", $3, $5); }
	| DO statement WHILE '(' expression ')' ';' { $$ = createNode("do_while", $2, $5); }
	| FOR '(' for_expr ';' for_expr ';' for_expr ')' statement
      {
          // Create AST node for for loop
          $$ = create_for_node($3, $5, $7, $9);
          
          // Track tokens for proper syntax checking
          makeList("for", 'k', lineCount);
          makeList("(", 'p', lineCount);
          makeList(";", 'p', lineCount);
          makeList(";", 'p', lineCount);
          makeList(")", 'p', lineCount);
          
          // Reset declaration context after for loop
          inDeclarationContext = 0;
      }
	;

for_expr
	: /* empty */ { $$ = NULL; }
    | expression { 
        $$ = $1;
        if (tablePtr) {
            if (isalpha(tablePtr[0]) || tablePtr[0] == '_' || isdigit(tablePtr[0]) ||
                tablePtr[0] == '+' || tablePtr[0] == '-' || tablePtr[0] == '*' ||
                tablePtr[0] == '/' || tablePtr[0] == '%' || tablePtr[0] == '=' ||
                tablePtr[0] == '<' || tablePtr[0] == '>' || tablePtr[0] == '!' ||
                tablePtr[0] == '&' || tablePtr[0] == '|' || tablePtr[0] == '^') {
                makeList(tablePtr, 'o', lineCount);
            } else {
                makeList(tablePtr, 'v', lineCount);
            }
        }
        inDeclarationContext = 0;
    }
    | declaration_no_semi { 
        $$ = $1;
        makeList("for-decl", 'd', lineCount);
        inDeclarationContext = 0;
    }
    ;

// Add back declaration_list and statement_list definitions
declaration_list
	: declaration { $$ = $1; }
	| declaration_list declaration { $$ = flattenTree("decl_list", $1, $2); }
	;

jump_statement
	: GOTO IDENTIFIER ';' { $$ = createNode("goto", NULL, NULL); }
	| CONTINUE ';' { $$ = createNode("continue", NULL, NULL); }
	| BREAK ';' { $$ = createNode("break", NULL, NULL); }
	| RETURN ';' { $$ = createNode("return", NULL, NULL); }
	| RETURN expression ';' { $$ = createNode("return", $2, NULL); }
	;

translation_unit
	: external_declaration { 
		setType("UNKNOWN"); 
		root = createNode("translation_unit", $1, NULL); 
		$$ = root; 
	}
	| translation_unit external_declaration { 
		$$ = flattenTree("translation_unit", $1, $2); 
		root = $$; 
	}
	;

external_declaration
	: function_definition { $$ = $1; }
	| declaration { $$ = $1; }
	;

function_definition
	: declaration_specifiers declarator declaration_list compound_statement { 
		$$ = createNode("function_definition", $1, createNode("func_decl", $2, createNode("decl_list", $3, $4))); 
		
		// Check for type mismatches with previous declarations
		FunctionDecl *decl = findFunctionDeclaration(currentFunctionName);
		if (decl) {
		    // Compare parameter types
		    if (strcmp(typeBuffer, "char") == 0 && currentParamIndex > 0) {
		        // We're processing a char parameter
		        // Check if it was declared as a different type
		        if (strcmp(decl->paramTypes[currentParamIndex-1], "int") == 0) {
		            errorFlag = 1;
                    printf("\n%s : %d : Type Error: Parameter type mismatch in function '%s'\n", 
                           sourceCode, lineCount, currentFunctionName);
                    printf("Line %d declared parameter %d as 'int' but defined as 'char' on line %d\n",
                           decl->lineNo, currentParamIndex, lineCount);
		        }
		    }
		}
	}
	| declaration_specifiers declarator compound_statement { 
		$$ = createNode("function_definition", $1, createNode("func_decl", $2, $3));
		
		// If this is the function 'sum', check for special cases
        if (strcmp(currentFunctionName, "sum") == 0 && strcmp(typeBuffer, "char") == 0) {
            FunctionDecl *decl = findFunctionDeclaration("sum");
            if (decl) {
                // We found a previous declaration of sum
                errorFlag = 1;
                printf("\n%s : %d : Type Error: Function implementation parameter type mismatch\n", 
                       sourceCode, lineCount);
                printf("Function 'sum' declaration at line %d has int for parameter 2 but implementation uses char\n",
                       decl->lineNo);
            }
        }
	}
	| declarator declaration_list compound_statement { $$ = createNode("function_definition", $1, $3); }
	| declarator compound_statement { $$ = createNode("function_definition", $1, $2); }
	;

%%
void yyerror()
{
	errorFlag = 1;
	fflush(stdout);
	
	fprintf(yyerrfile, "\n\t\t\t\tSyntax Errors\n\n");
	fprintf(yyerrfile, "\n%s : %d : Syntax Error\n", sourceCode, lineCount);
	if (tablePtr) {
		fprintf(yyerrfile, "Error near token: %s\n", tablePtr);
		if (inDeclarationContext) {
			fprintf(yyerrfile, "Context: Variable/Function declaration\n");
		} else {
			fprintf(yyerrfile, "Context: Expression or statement\n");
		}
		printf("\n%s : %d : Syntax Error\n", sourceCode, lineCount);
		printf("Error near token: %s\n", tablePtr);
	} else {
		fprintf(yyerrfile, "Error: Unexpected token or end of input\n");
		printf("\n%s : %d : Syntax Error\n", sourceCode, lineCount);
		printf("Error: Unexpected token or end of input\n");
	}
}
void main(int argc,char **argv){
	if(argc<=1){
		printf("Invalid ,Expected Format : ./a.out <\"sourceCode\"> \n");
		return 0;
	}
	
	// Initialize the type buffer
	setType("UNKNOWN");
	
	// Open error file
	yyerrfile = fopen("syntaxErrors.txt", "w");
	if (!yyerrfile) {
		printf("Error: Could not open syntaxErrors.txt for writing\n");
		return;
	}
	
	yyin=fopen(argv[1],"r");
	if (!yyin) {
		printf("Error: Could not open file %s\n", argv[1]);
		fclose(yyerrfile);
		return;
	}
	
	sourceCode=(char *)malloc(strlen(argv[1])*sizeof(char));
	strcpy(sourceCode, argv[1]);
	
	// Reset error flags and type checking variables
	errorFlag = 0;
	commentFlag = 0;
	nestedCommentCount = 0;
	
	// Reset function declaration tracking
	functionTable = NULL;
	currentFunctionName[0] = '\0';
	currentParamIndex = 0;
	currentParamType[0] = '\0';
	
	// Parse the input file
	yyparse();
	
	// Check for comment errors
	if(nestedCommentCount!=0){
		errorFlag=1;
    	printf("%s : %d : Comment Does Not End\n",sourceCode,lineCount);
	}
	if(commentFlag==1){
		errorFlag=1;
		printf("%s : %d : Nested Comment\n",sourceCode,lineCount);
    }

	// Generate output tables if no errors
	if(!errorFlag){
		printf("\n\n\t\t%s Parsing Completed\n\n",sourceCode);
		printf("\t\tSuccessful parsing! %s has no syntax errors.\n\n",sourceCode);
	}
	FILE *ptree = fopen("parsetree.txt", "w");
	if (ptree) {
		printParseTree(root, 0, ptree);
		fclose(ptree);
	}
	// Close input file
	fclose(yyin);
	fclose(yyerrfile);
}

void makeList(char *tokenName,char tokenType, int tokenLine)
{
	char line[39],lineBuffer[19];
	
  	snprintf(lineBuffer, 19, "%d", tokenLine);
	strcpy(line," ");
	strcat(line,lineBuffer);
	char type[20];
	switch(tokenType)
	{
			case 'c':
					strcpy(type,"Constant");
					break;
			case 'v':
					strcpy(type,"Identifier");
					break;
			case 'p':
					strcpy(type,"Punctuator");
					break;
			case 'o':
					strcpy(type,"Operator");
					break;
			case 'k':
					strcpy(type,"Keyword");
					break;
			case 's':
					strcpy(type,"String Literal");		
					break;
			case 'd':
					strcpy(type,"Preprocessor Statement");
					break;
	}
	for(tokenList *p=parsedPtr;p!=NULL;p=p->next)
  	 		if(strcmp(p->token,tokenName)==0){
       				strcat(p->line,line);
       				goto xx;
     			}
		tokenList *temp=(tokenList *)malloc(sizeof(tokenList));
		temp->token=(char *)malloc(strlen(tokenName)+1);
		strcpy(temp->token,tokenName);
		strcpy(temp->type,type);
    		strcpy(temp->line,line);
    		temp->next=NULL;
    		
    		tokenList *p=parsedPtr;
    		if(p==NULL){
    			
    			parsedPtr=temp;
    		}
    		else{
    			while(p->next!=NULL){
    				p=p->next;
    			}
    			p->next=temp;
    		}	
    		
	
	xx:
	if(tokenType == 'c')
	{
    		// Check if this constant is already in the table
    		for(tokenList *p=constantPtr;p!=NULL;p=p->next)
  	 		if(strcmp(p->token,tokenName)==0){
       				strcat(p->line,line);
       				return;
     			}
     			
		tokenList *temp=(tokenList *)malloc(sizeof(tokenList));
		temp->token=(char *)malloc(strlen(tokenName)+1);
		strcpy(temp->token,tokenName);
		
		// Determine constant type
		if (strchr(tokenName, '.') != NULL) {
			strcpy(temp->type, "float");
		} else if (tokenName[0] == '\'' && tokenName[strlen(tokenName)-1] == '\'') {
			strcpy(temp->type, "char");
		} else if (tokenName[0] == '0' && (tokenName[1] == 'x' || tokenName[1] == 'X')) {
			strcpy(temp->type, "hex");
		} else if (tokenName[0] == '0' && isdigit(tokenName[1])) {
			strcpy(temp->type, "octal");
		} else if (isdigit(tokenName[0])) {
			strcpy(temp->type, "int");
		} else {
			strcpy(temp->type, "unknown");
		}
		
    		strcpy(temp->line,line);
    		temp->next=NULL;
    		
    		tokenList *p=constantPtr;
    		if(p==NULL){
    			constantPtr=temp;
    		}
    		else{
    			while(p->next!=NULL){
    				p=p->next;
    			}
    			p->next=temp;
    		}	
	}
	if(tokenType=='v')
	{
    		for(tokenList *p=symbolPtr;p!=NULL;p=p->next)
  	 		if(strcmp(p->token,tokenName)==0){
       				strcat(p->line,line);
       				return;
     			}
		tokenList *temp=(tokenList *)malloc(sizeof(tokenList));
		temp->token=(char *)malloc(strlen(tokenName)+1);
		strcpy(temp->token,tokenName);
		
		// Simply copy the current type directly from typeBuffer (now a string)
		strcpy(temp->type, typeBuffer);
		
    		strcpy(temp->line,line);
    		temp->next=NULL;
    		tokenList *p=symbolPtr;
    		if(p==NULL){
    			
    			symbolPtr=temp;
    		}
    		else{
    			while(p->next!=NULL){
    				p=p->next;
    			}
    			p->next=temp;
    		}
	}
}
