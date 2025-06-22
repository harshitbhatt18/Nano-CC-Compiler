#ifndef SEMANTIC_H
#define SEMANTIC_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct tokenList {
    char *token, type[20], line[100];
    char scope[20];
    int scopeValue;
    int funcCount;
    struct tokenList *next;
};
typedef struct tokenList tokenList;

struct funcNode {
    char funcName[30];
    int line;
    char funcReturn[20];
    struct funcNode *next;
};
typedef struct funcNode funcNode;

// Symbol Table Pointers
tokenList *symbolPtr = NULL;
tokenList *constantPtr = NULL;
tokenList *parsedPtr = NULL;

// Globals - declare as extern, define them in syntaxChecker.y
extern int functionCount;
extern int scopeCount;
char typeBuffer = ' ';
char *sourceCode = NULL;
int tempCheckType = 3;
int semanticErr = 0, lineSemanticCount;

// Function declarations
void addSymbol(char *tokenName, int tokenLine, int scopeVal);
void addConstant(char *tokenName, int tokenLine);
void makeList(char *tokenName, char tokenType, int tokenLine);
void makeList(const char *tokenName, char tokenType, int tokenLine);  // For string literals
void checkDeclaration(char *tokenName, int tokenLine, int scopeVal);
void checkType(int value1, int value2, int lineCount);
void checkArray(int val, int lineCount);
int checkScope(char *tempToken, int lineCount);

void addSymbol(char *tokenName, int tokenLine, int scopeVal) {
    char line[39], lineBuffer[19];
    snprintf(lineBuffer, 19, "%d", tokenLine);
    strcpy(line, " ");
    strcat(line, lineBuffer);

    for (tokenList *p = symbolPtr; p != NULL; p = p->next)
        if (strcmp(p->token, tokenName) == 0 && p->scopeValue == scopeCount && p->funcCount == functionCount) {
            strcat(p->line, line);
            return;
        }

    tokenList *temp = (tokenList *)malloc(sizeof(tokenList));
    temp->token = strdup(tokenName);
    switch (typeBuffer) {
        case 'i': strcpy(temp->type, "INT"); break;
        case 'f': strcpy(temp->type, "FLOAT"); break;
        case 'v': strcpy(temp->type, "VOID"); break;
        case 'c': strcpy(temp->type, "CHAR"); break;
    }

    strcpy(temp->scope, scopeCount == 0 ? "GLOBAL" : "NESTING");
    temp->scopeValue = scopeVal;
    temp->funcCount = functionCount;
    strcpy(temp->line, line);
    temp->next = NULL;

    if (symbolPtr == NULL)
        symbolPtr = temp;
    else {
        tokenList *p = symbolPtr;
        while (p->next != NULL) p = p->next;
        p->next = temp;
    }
}

void addConstant(char *tokenName, int tokenLine) {
    char line[39], lineBuffer[19];
    snprintf(lineBuffer, 19, "%d", tokenLine);
    strcpy(line, " ");
    strcat(line, lineBuffer);

    for (tokenList *p = constantPtr; p != NULL; p = p->next)
        if (strcmp(p->token, tokenName) == 0) {
            strcat(p->line, line);
            return;
        }

    tokenList *temp = (tokenList *)malloc(sizeof(tokenList));
    temp->token = strdup(tokenName);
    strcpy(temp->line, line);
    temp->next = NULL;

    if (constantPtr == NULL)
        constantPtr = temp;
    else {
        tokenList *p = constantPtr;
        while (p->next != NULL) p = p->next;
        p->next = temp;
    }
}

void makeList(char *tokenName, char tokenType, int tokenLine) {
    char line[39], lineBuffer[19];
    snprintf(lineBuffer, 19, "%d", tokenLine);
    strcpy(line, " ");
    strcat(line, lineBuffer);

    char type[20];
    switch (tokenType) {
        case 'c': strcpy(type, "Constant"); break;
        case 'v': strcpy(type, "Identifier"); break;
        case 'p': strcpy(type, "Punctuator"); break;
        case 'o': strcpy(type, "Operator"); break;
        case 'k': strcpy(type, "Keyword"); break;
        case 's': strcpy(type, "String Literal"); break;
        case 'd': strcpy(type, "Preprocessor Statement"); break;
    }

    for (tokenList *p = parsedPtr; p != NULL; p = p->next)
        if (strcmp(p->token, tokenName) == 0) {
            strcat(p->line, line);
            return;
        }

    tokenList *temp = (tokenList *)malloc(sizeof(tokenList));
    temp->token = strdup(tokenName);
    strcpy(temp->type, type);
    strcpy(temp->line, line);
    temp->next = NULL;

    if (parsedPtr == NULL)
        parsedPtr = temp;
    else {
        tokenList *p = parsedPtr;
        while (p->next != NULL) p = p->next;
        p->next = temp;
    }
}

// Overloaded makeList for const char* (for string literals)
void makeList(const char *tokenName, char tokenType, int tokenLine) {
    char *nonConstToken = strdup(tokenName);
    makeList(nonConstToken, tokenType, tokenLine);
    free(nonConstToken);
}

int checkScope(char *tempToken, int lineCount) {
    char type[20];
    strcpy(type, "INT"); // Default type
    int flag = 0, tempFlag = 0;

    for (tokenList *p = symbolPtr; p != NULL; p = p->next) {
        if (strcmp(tempToken, "printf") == 0 || strcmp(tempToken, "scanf") == 0) {
            tempFlag = 1;
            break;
        } else if (strcmp(tempToken, p->token) == 0) {
            strcpy(type, p->type);
            flag = 1;
            break;
        }
    }

    if (flag == 0 && tempFlag == 0) {
        printf("\n%s : %d :Undeclared variable\n", sourceCode, lineCount - 1);
        semanticErr = 1;
        return 0;
    } else if (tempFlag == 1) {
        // Built-in functions like printf/scanf
        return 0;
    } else {
        addSymbol(tempToken, lineCount, scopeCount);
        if (strcmp(type, "VOID") == 0) return 1;
        if (strcmp(type, "CHAR") == 0) return 2;
        if (strcmp(type, "INT") == 0) return 3;
        if (strcmp(type, "FLOAT") == 0) return 4;
    }
    return 0;
}

void checkType(int value1, int value2, int lineCount) {
    lineSemanticCount = lineCount;
    if (value2 == 0) value2 = tempCheckType;

    if (value1 != value2) {
        printf("\n%s : %d :Type Mismatch error\n", sourceCode, lineSemanticCount - 1);
        semanticErr = 1;
    }

    tempCheckType = 3;
}

void checkDeclaration(char *tokenName, int tokenLine, int scopeVal) {
    char type[20];
    char line[39], lineBuffer[19];
    snprintf(lineBuffer, 19, "%d", tokenLine);
    strcpy(line, " ");
    strcat(line, lineBuffer);

    switch (typeBuffer) {
        case 'i': strcpy(type, "INT"); break;
        case 'f': strcpy(type, "FLOAT"); break;
        case 'v': strcpy(type, "VOID"); break;
        case 'c': strcpy(type, "CHAR"); break;
    }

    for (tokenList *p = symbolPtr; p != NULL; p = p->next) {
        if (strcmp(p->token, tokenName) == 0 && p->scopeValue == scopeCount && p->funcCount == functionCount) {
            semanticErr = 1;
            if (strcmp(p->type, type) == 0)
                printf("\n%s : %d :Multiple Declaration\n", sourceCode, tokenLine);
            else
                printf("\n%s : %d :Multiple Declaration with Different Type\n", sourceCode, tokenLine);
            return;
        }
    }

    addSymbol(tokenName, tokenLine, scopeVal);
}

void checkArray(int val, int lineCount) {
    if (val < 0) {
        semanticErr = 1;
        printf("\n%s : %d :Array Index error\n", sourceCode, lineCount - 1);
    }
}

#endif // SEMANTIC_H
