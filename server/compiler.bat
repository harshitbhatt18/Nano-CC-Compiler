@echo off
echo Compiling input.cc...

:: Set the lexical directory path
set LEXICAL_DIR=lexical

:: Create lexical directory if it doesn't exist
if not exist %LEXICAL_DIR% mkdir %LEXICAL_DIR%

:: Create placeholder output files if they don't exist yet
:: These will be replaced by the actual scanner output in the future

:: Check if lex is available
where lex >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Running lexical analysis with Lex...
    cd %LEXICAL_DIR%
    lex -o scanner.c scanner.l
    gcc scanner.c -o scanner.exe
    
    if exist scanner.exe (
        scanner.exe input.cc > parseTable.txt
        echo Lexical analysis completed.
        cd ..
    ) else (
        echo Failed to compile the scanner.
       
        cd ..
    )
) else (
    echo Lex not found. 
  
)

::if not exist %LEXICAL_DIR%\symbolTable (
    echo NAME    TYPE    SCOPE    VALUE > %LEXICAL_DIR%\symbolTable
    echo test    int     global   0 >> %LEXICAL_DIR%\symbolTable
    echo value   int     global   0 >> %LEXICAL_DIR%\symbolTable
::)

::if not exist %LEXICAL_DIR%\constantTable (
    echo VALUE    TYPE > %LEXICAL_DIR%\constantTable
    echo 1        INT >> %LEXICAL_DIR%\constantTable
    echo 2        INT >> %LEXICAL_DIR%\constantTable
::)

:: Compile the input.cc file
g++ %LEXICAL_DIR%\input.cc -o output.exe 2>error.txt
set COMPILE_ERROR=%ERRORLEVEL%

:: Check if compilation was successful
if %COMPILE_ERROR% EQU 0 (
    echo Compilation successful!
    echo Program output:
    output.exe
) else (
    echo Compilation failed with errors:
    type error.txt
    del error.txt
) 