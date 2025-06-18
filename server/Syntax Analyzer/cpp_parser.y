%expect 3
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

// Declaration context tracking
int inDeclarationContext = 0;

// Scope tracking
int scopeCount = 0;

// External declarations for variables used in checkDeclaration
extern tokenList *symbolPtr;
extern int errorFlag;
extern char *sourceCode;

// Define these variables to ensure they're available in this file
tokenList *symbolPtr = NULL;
int errorFlag = 0;
char *sourceCode = NULL;

// External declaration of makeList function defined in the lexical analyzer
extern void makeList(char *tokenName, char tokenType, int tokenLine);
int yylex(void);
void yyerror(const char *s);

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

// Current function being defined or declared
char currentFunctionName[64] = "";

// Current parameter being processed
int currentParamIndex = 0;
char currentParamType[64] = "";

// Stream operator tracking for error detection
int lastStreamOpIsLeft = 0;  // 1 for <<, 0 for >>
int lastStreamObjIsCout = 0; // 1 for cout, 0 for cin
int mixedStreamOps = 0;      // Flag to detect mixed << and >> in the same stream

// Namespace tracking
int stdNamespaceUsed = 0;    // Flag to track if "using namespace std;" is present
int namespaceCheckEnabled = 1; // Enable namespace checking by default

// Current token for error reporting
char lastToken[64] = "";

extern FILE *yyin;
extern int lineCount;
extern char *tablePtr;
extern int nestedCommentCount;
extern int commentFlag;

// Define table pointers directly, they will be shared with the lexical analyzer
tokenList *constantPtr = NULL;
tokenList *parsedPtr = NULL;

// Improved type tracking
char typeBuffer[20] = "UNKNOWN"; // Use a string instead of a single char

int errorCount=0; // Track the number of syntax errors

// Extended error information
typedef struct ErrorInfo {
    int line;
    char message[256];
    struct ErrorInfo *next;
} ErrorInfo;

ErrorInfo *errorList = NULL;

// Add error to the list for later reporting
void addError(int line, const char *message) {
    ErrorInfo *newError = (ErrorInfo*)malloc(sizeof(ErrorInfo));
    newError->line = line;
    strncpy(newError->message, message, 255);
    newError->message[255] = '\0';
    newError->next = errorList;
    errorList = newError;
    errorCount++;
}

// Set the current type based on type specifiers
void setType(const char* type) {
    strncpy(typeBuffer, type, 19);
    typeBuffer[19] = '\0'; // Ensure null termination
}

// Track the current token for error reporting
void trackToken(const char* token) {
    if (token != NULL) {
        strncpy(lastToken, token, 63);
        lastToken[63] = '\0';
    }
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

// parse tree node structure
typedef struct ParseTreeNode {
    char name[64];
    struct ParseTreeNode *child;
    struct ParseTreeNode *sibling;
} ParseTreeNode;

//allocate memory for the node and initialize it
ParseTreeNode* createNode(const char* name, ParseTreeNode* child, ParseTreeNode* sibling) {
    ParseTreeNode* node = (ParseTreeNode*)malloc(sizeof(ParseTreeNode));
    strcpy(node->name, name);
    node->child = child;
    node->sibling = sibling;
    return node;
}

// Added function to combine related nodes or same name nodes
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
    for (int i = 0; i < level; ++i) fprintf(fp, "\t");
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
%type <node> stream_expression

/* C tokens */
%token AUTO BREAK CASE CHAR CONST CONTINUE DEFAULT DO DOUBLE ELSE ENUM 
%token EXTERN FLOAT FOR GOTO IF INT LONG REGISTER RETURN SHORT SIGNED 
%token SIZEOF STATIC STRUCT SWITCH TYPEDEF UNION UNSIGNED VOID VOLATILE WHILE 

/* C++ specific tokens */
%token CATCH CLASS DELETE FRIEND INLINE NAMESPACE NEW PRIVATE PROTECTED PUBLIC
%token TEMPLATE THIS THROW TRY USING VIRTUAL BOOL BOOL_LITERAL SCOPE_OP
%token IOSTREAM_IN IOSTREAM_OUT
%token IOSTREAM_IN_MISSPELLED IOSTREAM_OUT_MISSPELLED

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
		trackToken(tablePtr);
		// Check for variable use (not a declaration)
		if (!inDeclarationContext) {
		    // This is a variable use, not a declaration
		    // Could check if variable is declared before use
		}
		$$ = createNode("IDENTIFIER", NULL, NULL); 
	}
	| CONSTANT    		{ makeList(tablePtr, 'c', lineCount); trackToken(tablePtr); $$ = createNode("CONSTANT", NULL, NULL); }
	| STRING_LITERAL  	{ makeList(tablePtr, 's', lineCount); trackToken(tablePtr); $$ = createNode("STRING_LITERAL", NULL, NULL); }
	| '(' expression ')' 	{ makeList("(", 'p', lineCount); makeList(")", 'p', lineCount); trackToken(")"); $$ = createNode("(expr)", $2, NULL); }
	| BOOL_LITERAL      { makeList(tablePtr, 'c', lineCount); trackToken(tablePtr); $$ = createNode("BOOL_LITERAL", NULL, NULL); } /* C++ specific */
	| THIS             { makeList(tablePtr, 'k', lineCount); trackToken(tablePtr); $$ = createNode("this", NULL, NULL); } /* C++ specific */
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
    | IDENTIFIER SCOPE_OP IDENTIFIER { 
        // Check if this is a std::cin or std::cout
        if (strcmp(tablePtr, "cin") == 0 || strcmp(tablePtr, "cout") == 0) {
            // Since std:: prefix is used, disable namespace checking
            namespaceCheckEnabled = 0;
            printf("Found 'std::%s' - namespace correctly used\n", tablePtr);
        }
        $$ = createNode("SCOPE_OP", NULL, NULL); 
    } /* C++ specific */
    | postfix_expression LEFT_OP primary_expression { $$ = createNode("<<", $1, $3); } /* C++ iostream */
    /* Common cout mistake - treating cout as a function */
    | IOSTREAM_OUT '(' primary_expression ')' { 
        makeList("(", 'p', lineCount);
        makeList(")", 'p', lineCount);
        addError(lineCount, "Invalid cout usage: cout is not a function, use 'cout << expression' instead of 'cout(expression)'");
        $$ = createNode("ERROR", NULL, NULL); 
    }
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
	| expression ',' assignment_expression { $$ = createNode(",", $1, $3); }
	;

constant_expression
	: conditional_expression { $$ = $1; }
	;

/* Add C++ specific syntax */
class_definition
    : class_head '{' class_body '}' { 
        makeList("{", 'p', lineCount);
        makeList("}", 'p', lineCount);
        inDeclarationContext = 1; // Set context flag
        $$ = createNode("class_definition", $1, $3); 
        inDeclarationContext = 0; // Reset context flag
    }
    | class_head '{' error '}' {
        makeList("{", 'p', lineCount);
        makeList("}", 'p', lineCount);
        inDeclarationContext = 1; // Set context flag
        yyerror("Syntax error in class body");
        $$ = createNode("class_definition_error", $1, NULL);
        inDeclarationContext = 0; // Reset context flag
    }
    | class_head error {
        inDeclarationContext = 1; // Set context flag
        yyerror("Missing opening brace '{' in class definition");
        $$ = createNode("class_definition_error", $1, NULL);
        inDeclarationContext = 0; // Reset context flag
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
        inDeclarationContext = 1; // Set context flag
        $$ = createNode("namespace", $4, NULL); 
        root = $$;
        inDeclarationContext = 0; // Reset context flag
    }
    | USING NAMESPACE IDENTIFIER ';' { 
        makeList("using", 'k', lineCount);
        makeList("namespace", 'k', lineCount);
        makeList(tablePtr, 'v', lineCount);
        makeList(";", 'p', lineCount);
        // Check if it's the std namespace
        if (strcmp(tablePtr, "std") == 0) {
            stdNamespaceUsed = 1; // Mark std namespace as used
            printf("Found 'using namespace std;' - iostream objects can be used directly\n");
        }
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
        // Check if iostream is included
        if (strcmp(tablePtr, "iostream") == 0) {
            // This is important for iostream operations, but doesn't affect namespace usage
            // Still need using namespace std; or std:: prefix
            printf("Found '#include <iostream>' - iostream library included\n");
        }
        $$ = createNode("preprocessor_include", NULL, NULL); 
        root = $$; 
    }
    | NAMESPACE IDENTIFIER error translation_unit '}' {
        inDeclarationContext = 1; // Set context flag
        yyerror("Missing opening brace in namespace definition");
        $$ = createNode("namespace_error", $4, NULL);
        root = $$;
        inDeclarationContext = 0; // Reset context flag
    }
    | NAMESPACE IDENTIFIER '{' translation_unit error {
        inDeclarationContext = 1; // Set context flag
        yyerror("Missing closing brace in namespace definition");
        $$ = createNode("namespace_error", $4, NULL);
        root = $$;
        inDeclarationContext = 0; // Reset context flag
    }
    | USING NAMESPACE IDENTIFIER error {
        yyerror("Missing semicolon after using namespace directive");
        $$ = createNode("using_namespace_error", NULL, NULL);
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
		inDeclarationContext = 1; // Set context flag for function declaration
		$$ = flattenTree("function_definition", $1, flattenTree("function_parts", $2, flattenTree("function_parts", $3, $4)));
		inDeclarationContext = 0; // Reset context flag
	}
	| declaration_specifiers declarator compound_statement {
		inDeclarationContext = 1; // Set context flag for function declaration
		$$ = flattenTree("function_definition", $1, flattenTree("function_parts", $2, $3));
        
        // Function implementation checks
        FunctionDecl* decl = findFunctionDeclaration(currentFunctionName);
        if (decl) {
            // Check existing declaration against current implementation
            // Type checking for parameters could be added here
            if (strcmp(typeBuffer, "char") == 0 && currentParamIndex > 0) {
                // We're processing a char parameter
                // Check if it was declared as a different type
                if (decl->paramCount >= currentParamIndex && 
                    strcmp(decl->paramTypes[currentParamIndex-1], "int") == 0) {
                    errorFlag = 1;
                    printf("\n%s : %d : Type Error: Parameter type mismatch in function '%s'\n", 
                           sourceCode, lineCount, currentFunctionName);
                    printf("Line %d declared parameter %d as 'int' but defined as 'char' on line %d\n",
                           decl->lineNo, currentParamIndex, lineCount);
                }
            }
        }
        inDeclarationContext = 0; // Reset context flag
	}
	| declarator declaration_list compound_statement {
		inDeclarationContext = 1; // Set context flag
		$$ = flattenTree("function_definition", $1, flattenTree("function_parts", $2, $3));
		inDeclarationContext = 0; // Reset context flag
	}
	| declarator compound_statement {
		inDeclarationContext = 1; // Set context flag
		$$ = flattenTree("function_definition", $1, $2);
		inDeclarationContext = 0; // Reset context flag
	}
    | declaration_specifiers declarator error {
        inDeclarationContext = 1; // Set context flag
        yyerror("Invalid function definition - missing body or semicolon");
        $$ = createNode("function_definition_error", NULL, NULL);
        inDeclarationContext = 0; // Reset context flag
    }
	;

declaration
	: declaration_specifiers ';' { 
		makeList(";", 'p', lineCount);
		trackToken(";");
		inDeclarationContext = 1; // Set context flag
		$$ = flattenTree("declaration", $1, NULL); 
		inDeclarationContext = 0; // Reset context flag
	}
	| declaration_specifiers init_declarator_list ';' { 
		makeList(";", 'p', lineCount);
		trackToken(";");
		inDeclarationContext = 1; // Set context flag
		$$ = flattenTree("declaration", $1, $2); 
		inDeclarationContext = 0; // Reset context flag
	}
    | declaration_specifiers error ';' {
        inDeclarationContext = 1; // Set context flag
        yyerror("Syntax error in declaration");
        $$ = createNode("error", NULL, NULL);
        inDeclarationContext = 0; // Reset context flag
    }
	| declaration_specifiers init_declarator_list error {
		inDeclarationContext = 1; // Set context flag
		yyerror("Missing semicolon after declaration");
		$$ = flattenTree("declaration", $1, $2);
		inDeclarationContext = 0; // Reset context flag
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
        trackToken(tablePtr);
        // Check for variable/function declaration
        if (inDeclarationContext) {
            // This is a variable or function declaration
            checkDeclaration(tablePtr, lineCount, scopeCount);
            if (strcmp(typeBuffer, "UNKNOWN") != 0) {
                // If function declaration, track it
                if (strstr(tablePtr, "(") != NULL) {
                    addFunctionDeclaration(tablePtr, lineCount);
                }
            }
        }
        $$ = createNode("identifier", NULL, NULL); 
    }
    | '(' declarator ')' { 
        makeList("(", 'p', lineCount);
        makeList(")", 'p', lineCount);
        trackToken(")");
        $$ = $2; 
    }
    | direct_declarator '[' ']' { 
        makeList("[", 'p', lineCount);
        makeList("]", 'p', lineCount);
        trackToken("]");
        $$ = createNode("array_declarator", $1, NULL); 
    }
    | direct_declarator '[' constant_expression ']' { 
        makeList("[", 'p', lineCount);
        makeList("]", 'p', lineCount);
        trackToken("]");
        $$ = createNode("array_size_declarator", $1, $3); 
    }
    | direct_declarator '(' parameter_type_list ')' { 
        makeList("(", 'p', lineCount);
        makeList(")", 'p', lineCount);
        trackToken(")");
        // Function declaration
        if (inDeclarationContext) {
            addFunctionDeclaration(currentFunctionName, lineCount);
        }
        $$ = createNode("function_declarator", $1, $3); 
    }
    | direct_declarator '(' identifier_list ')' { 
        makeList("(", 'p', lineCount);
        makeList(")", 'p', lineCount);
        trackToken(")");
        // Function declaration
        if (inDeclarationContext) {
            addFunctionDeclaration(currentFunctionName, lineCount);
        }
        $$ = createNode("function_declarator", $1, $3); 
    }
    | direct_declarator '(' ')' { 
        makeList("(", 'p', lineCount);
        makeList(")", 'p', lineCount);
        trackToken(")");
        // Function declaration
        if (inDeclarationContext) {
            addFunctionDeclaration(currentFunctionName, lineCount);
        }
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
    : declaration_specifiers declarator { 
        inDeclarationContext = 1; // Parameters are declarations
        currentParamIndex++;
        // Track parameter type in case we need it for type checking
        if (strcmp(typeBuffer, "char") == 0) {
            strcpy(currentParamType, "char");
            addFunctionParameter("char");
        } else if (strcmp(typeBuffer, "int") == 0) {
            strcpy(currentParamType, "int");
            addFunctionParameter("int");
        } else {
            strcpy(currentParamType, typeBuffer);
            addFunctionParameter(typeBuffer);
        }
        $$ = flattenTree("parameter", $1, $2); 
        inDeclarationContext = 0;
    }
    | declaration_specifiers abstract_declarator { 
        inDeclarationContext = 1;
        currentParamIndex++;
        $$ = flattenTree("abstract_parameter", $1, $2); 
        inDeclarationContext = 0;
    }
    | declaration_specifiers { 
        inDeclarationContext = 1;
        currentParamIndex++;
        $$ = $1; 
        inDeclarationContext = 0;
    }
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
    : '{' '}' { 
        makeList("{", 'p', lineCount); 
        makeList("}", 'p', lineCount); 
        trackToken("}");
        scopeCount++; // New scope
        $$ = createNode("compound", NULL, NULL); 
        scopeCount--; // Exit scope
    }
    | '{' block_item_list '}' { 
        makeList("{", 'p', lineCount); 
        makeList("}", 'p', lineCount); 
        trackToken("}");
        scopeCount++; // New scope
        $$ = createNode("compound", $2, NULL); 
        scopeCount--; // Exit scope
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
    : ';' { makeList(";", 'p', lineCount); $$ = createNode(";", NULL, NULL); }
    | expression ';' { makeList(";", 'p', lineCount); $$ = createNode("expression_stmt", $1, NULL); }
    | stream_expression ';' { makeList(";", 'p', lineCount); $$ = createNode("stream_stmt", $1, NULL); }
    | stream_expression error { 
        addError(lineCount, "Missing semicolon after stream expression");
        $$ = createNode("stream_stmt_error", $1, NULL);
    }
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
    | IF error expression ')' statement {
        yyerror("Missing opening parenthesis in if statement");
        $$ = createNode("if_error", $3, $5);
    }
    | IF '(' expression error statement {
        yyerror("Missing closing parenthesis in if statement");
        $$ = createNode("if_error", $3, $5);
    }
    | SWITCH error expression ')' statement {
        yyerror("Missing opening parenthesis in switch statement");
        $$ = createNode("switch_error", $3, $5);
    }
    | SWITCH '(' expression error statement {
        yyerror("Missing closing parenthesis in switch statement");
        $$ = createNode("switch_error", $3, $5);
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
    | WHILE error expression ')' statement {
        yyerror("Missing opening parenthesis in while statement");
        $$ = createNode("while_error", $3, $5);
    }
    | WHILE '(' expression error statement {
        yyerror("Missing closing parenthesis in while statement");
        $$ = createNode("while_error", $3, $5);
    }
    | DO statement WHILE error expression ')' ';' {
        yyerror("Missing opening parenthesis in do-while statement");
        $$ = createNode("do-while_error", $2, $5);
    }
    | DO statement WHILE '(' expression error ';' {
        yyerror("Missing closing parenthesis in do-while statement");
        $$ = createNode("do-while_error", $2, $5);
    }
    | DO statement WHILE '(' expression ')' error {
        yyerror("Missing semicolon after do-while statement");
        $$ = createNode("do-while_error", $2, $5);
    }
    | FOR error { 
        yyerror("Invalid for loop syntax");
        $$ = createNode("for_error", NULL, NULL);
    }
    | FOR '(' error ')' statement {
        yyerror("Invalid for loop control expressions");
        $$ = createNode("for_error", NULL, $5);
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
    | TRY compound_statement CATCH error parameter_declaration ')' compound_statement {
        yyerror("Missing opening parenthesis in catch statement");
        $$ = createNode("try_catch_error", $2, $7);
    }
    | TRY compound_statement CATCH '(' parameter_declaration error compound_statement {
        yyerror("Missing closing parenthesis in catch statement");
        $$ = createNode("try_catch_error", $2, $7);
    }
    | TRY error {
        yyerror("Invalid try block");
        $$ = createNode("try_error", NULL, NULL);
    }
    ;

/* C++ specific iostream operations */
stream_expression
    : IOSTREAM_OUT LEFT_OP primary_expression { 
        lastStreamOpIsLeft = 1;
        lastStreamObjIsCout = 1;
        mixedStreamOps = 0;
        // Check if std namespace is used
        if (namespaceCheckEnabled && !stdNamespaceUsed) {
            addError(lineCount, "Namespace error: 'cout' used without 'std::' prefix and no 'using namespace std;' found. Use 'std::cout' or add 'using namespace std;'");
        }
        $$ = createNode("cout_op", NULL, $3); 
    }
    | IOSTREAM_IN RIGHT_OP primary_expression { 
        lastStreamOpIsLeft = 0;
        lastStreamObjIsCout = 0;
        mixedStreamOps = 0;
        // Check if std namespace is used
        if (namespaceCheckEnabled && !stdNamespaceUsed) {
            addError(lineCount, "Namespace error: 'cin' used without 'std::' prefix and no 'using namespace std;' found. Use 'std::cin' or add 'using namespace std;'");
        }
        $$ = createNode("cin_op", NULL, $3); 
    }
    | stream_expression LEFT_OP primary_expression { 
        // Check for mixed operators in the same stream
        if (!lastStreamOpIsLeft && lastStreamObjIsCout) {
            mixedStreamOps = 1;
            addError(lineCount, "Mixed stream operators: cannot mix '<<' and '>>' in the same stream operation");
        }
        if (!lastStreamOpIsLeft && !lastStreamObjIsCout) {
            mixedStreamOps = 1;
            addError(lineCount, "Mixed stream operators: cannot mix '>>' and '<<' in the same 'cin' stream operation");
        }
        lastStreamOpIsLeft = 1;
        $$ = createNode("cout_op", $1, $3); 
    }
    | stream_expression RIGHT_OP primary_expression { 
        // Check for mixed operators in the same stream
        if (lastStreamOpIsLeft && lastStreamObjIsCout) {
            mixedStreamOps = 1;
            addError(lineCount, "Mixed stream operators: cannot mix '<<' and '>>' in the same 'cout' stream operation");
        }
        if (lastStreamOpIsLeft && !lastStreamObjIsCout) {
            mixedStreamOps = 1;
            addError(lineCount, "Mixed stream operators: cannot mix '>>' and '<<' in the same stream operation");
        }
        lastStreamOpIsLeft = 0;
        $$ = createNode("cin_op", $1, $3); 
    }
    /* Rules for misspelled iostream objects */
    | IOSTREAM_OUT_MISSPELLED LEFT_OP primary_expression { 
        addError(lineCount, "Misspelled iostream object: did you mean 'cout'?");
        $$ = createNode("ERROR", NULL, NULL);
    }
    | IOSTREAM_IN_MISSPELLED RIGHT_OP primary_expression { 
        addError(lineCount, "Misspelled iostream object: did you mean 'cin'?");
        $$ = createNode("ERROR", NULL, NULL);
    }
    | IOSTREAM_OUT_MISSPELLED RIGHT_OP primary_expression { 
        addError(lineCount, "Misspelled iostream object: did you mean 'cout'? Also, 'cout' uses '<<', not '>>'");
        $$ = createNode("ERROR", NULL, NULL);
    }
    | IOSTREAM_IN_MISSPELLED LEFT_OP primary_expression { 
        addError(lineCount, "Misspelled iostream object: did you mean 'cin'? Also, 'cin' uses '>>', not '<<'");
        $$ = createNode("ERROR", NULL, NULL);
    }
    | IOSTREAM_OUT RIGHT_OP primary_expression { 
        makeList(">>", 'o', lineCount);
        addError(lineCount, "Invalid stream operation: 'cout' uses '<<' (insertion operator), not '>>' (extraction operator)");
        $$ = createNode("ERROR", NULL, NULL);
    }
    /* Comment out this problematic rule that causes reduce/reduce conflicts */
    /*
    | IOSTREAM_IN LEFT_OP primary_expression { 
        makeList("<<", 'o', lineCount);
        addError(lineCount, "Invalid stream operation: 'cin' uses '>>', not '<<' (insertion operator is for 'cout')");
        $$ = createNode("ERROR", NULL, NULL);
    }
    */
    | IOSTREAM_IN error primary_expression { 
        if (strcmp(tablePtr, "<<") == 0) {
            makeList("<<", 'o', lineCount);
            addError(lineCount, "Invalid stream operation: 'cin' uses '>>', not '<<' (insertion operator is for 'cout')");
        } else {
            addError(lineCount, "Invalid stream operation with 'cin'");
        }
        $$ = createNode("ERROR", NULL, NULL);
    }
    | IOSTREAM_IN '<' primary_expression { 
        makeList("<", 'o', lineCount);
        addError(lineCount, "Invalid stream operation: expected '>>' for cin, not '<'");
        $$ = createNode("ERROR", NULL, NULL);
    }
    | stream_expression LEFT_OP error { 
        addError(lineCount, "Invalid or missing expression after '<<'");
        $$ = createNode("ERROR", NULL, NULL);
    }
    | stream_expression RIGHT_OP error { 
        addError(lineCount, "Invalid or missing expression after '>>'");
        $$ = createNode("ERROR", NULL, NULL);
    }
    | stream_expression '>' primary_expression { 
        makeList(">", 'o', lineCount);
        addError(lineCount, "Invalid chained stream operation: expected '<<', not '>'");
        $$ = createNode("ERROR", NULL, NULL);
    }
    | stream_expression '<' primary_expression { 
        makeList("<", 'o', lineCount);
        addError(lineCount, "Invalid chained stream operation: expected '>>', not '<'");
        $$ = createNode("ERROR", NULL, NULL);
    }
    /* Error for using string literal directly with stream operators - common mistake */
    | LEFT_OP STRING_LITERAL { 
        makeList("<<", 'o', lineCount);
        makeList(tablePtr, 's', lineCount);
        addError(lineCount, "Invalid stream syntax: stream operator must be used with iostream object, e.g. 'cout << \"string\"'");
        $$ = createNode("ERROR", NULL, NULL);
    }
    | RIGHT_OP IDENTIFIER { 
        makeList(">>", 'o', lineCount);
        makeList(tablePtr, 'v', lineCount);
        addError(lineCount, "Invalid stream syntax: stream operator must be used with iostream object, e.g. 'cin >> variable'");
        $$ = createNode("ERROR", NULL, NULL);
    }
    ;

%%

void yyerror(const char *s) {
    errorFlag = 1;
	fflush(stdout);
	
	fprintf(yyerrfile, "\nSyntax Errors\n");
	fprintf(yyerrfile, "\n%s : %d : Syntax Error\n", sourceCode, lineCount);
	if (tablePtr) {
		fprintf(yyerrfile, "Error near token: %s\n", tablePtr);
		if (inDeclarationContext) {
			fprintf(yyerrfile, "Context: Variable/Function declaration\n");
		} 
        else {
			fprintf(yyerrfile, "Context: Expression or statement\n");
		}
		printf("\n%s : %d : Syntax Error\n", sourceCode, lineCount);
		printf("Error near token: %s\n", tablePtr);
	}
    else {
		fprintf(yyerrfile, "Error: Unexpected token or end of input\n");
		printf("\n%s : %d : Syntax Error\n", sourceCode, lineCount);
		printf("Error: Unexpected token or end of input\n");
	}
    // Store the error for summary reporting
    char errorMsg[256];
    sprintf(errorMsg, "Syntax Error near %s", tablePtr ? tablePtr : (lastToken[0] != '\0' ? lastToken : "end of input"));
    addError(lineCount, errorMsg);
}

int main(int argc, char *argv[])
{
    // Initialize the table pointers
    symbolPtr = NULL;
    constantPtr = NULL;
    parsedPtr = NULL;
    errorFlag = 0;
    errorCount = 0;
    errorList = NULL;
    
    // Reset error flags and type checking variables
    commentFlag = 0;
    nestedCommentCount = 0;
    
    // Reset function declaration tracking
    functionTable = NULL;
    currentFunctionName[0] = '\0';
    currentParamIndex = 0;
    currentParamType[0] = '\0';
    lastToken[0] = '\0';
    
    // Reset context tracking
    inDeclarationContext = 0;
    scopeCount = 0;
    
    // Reset stream operator tracking
    lastStreamOpIsLeft = 0;
    lastStreamObjIsCout = 0;
    mixedStreamOps = 0;
    
    // Reset namespace tracking
    stdNamespaceUsed = 0;
    namespaceCheckEnabled = 1;
    
    // Set default type
    strcpy(typeBuffer, "UNKNOWN");

    // Open error file
	yyerrfile = fopen("syntaxErrors.txt", "w");
	if (!yyerrfile) {
		printf("Error: Could not open syntaxErrors.txt for writing\n");
		return 1;
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
    
    // Check for comment errors
	if(nestedCommentCount!=0){
		errorFlag=1;
    	printf("%s : %d : Comment Does Not End\n",sourceCode,lineCount);
	}
	if(commentFlag==1){
		errorFlag=1;
		printf("%s : %d : Nested Comment\n",sourceCode,lineCount);
    }

    if(!errorFlag) {
        printf("Successful parsing! %s has no syntax errors.\n",sourceCode);

        // Print parse tree
        FILE *parseTree = fopen("parsetree.txt", "w");
        if(parseTree) {
            printParseTree(root, 0, parseTree);
            fclose(parseTree);
        }
    } else {
        printf("\n%s Parsing Failed\n", sourceCode);
        printf("Found %d syntax errors in %s\n", errorCount, sourceCode);
    }
    
    // Free the error list
    while (errorList) {
        ErrorInfo *temp = errorList;
        errorList = errorList->next;
        free(temp);
    }
    
    // Close the input file
    if (yyin) fclose(yyin);
    if (yyerrfile) fclose(yyerrfile);
    
    return errorFlag; // Return error status
}



