@echo off
echo Compiling input.cc...
echo -----------------------------------------------------------------------------------------

:: Set the lexical directory path
set LEXICAL_DIR=lexical

:: Create lexical directory if it doesn't exist
if not exist %LEXICAL_DIR% mkdir %LEXICAL_DIR%

:: Clean up previous lexical analysis files
cd %LEXICAL_DIR%
del /f /q parseTable symbolTable constantTable >nul 2>&1
cd ..

:: Check if lex is available
where lex >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Running lexical analysis with Lex...
    cd %LEXICAL_DIR%
    lex -o scanner.c scanner.l
    g++ scanner.c -o scanner.exe
    
    if exist scanner.exe (
        scanner.exe input.cc 
        echo Lexical analysis completed.
        cd ..
        
        :: Ensure output files exist 
        if not exist %LEXICAL_DIR%\parseTable (
            echo No tokens found > %LEXICAL_DIR%\parseTable
        )
       
    ) else (
        echo Failed to compile the scanner.
        cd ..
        
        :: Create empty output files when scanner fails
        echo No tokens found > %LEXICAL_DIR%\parseTable
    )

    echo -----------------------------------------------------------------------------------------
    echo Running Syntax Analyzer with Bison...
    "C:\Program Files\Git\bin\sh.exe" "syntax/compile.sh"
    ::echo -----------------------------------------------------------------------------------------
    echo Running Semantic Analyzer...
    "C:\Program Files\Git\bin\sh.exe" "semantic/compile.sh"
    echo -----------------------------------------------------------------------------------------
    
) else (
    echo Lex and Bison not found.
)

:: -----------------------------------------------------------------------------------------
:: Force kill and delete previous output.exe 
taskkill /f /im output.exe >nul 2>&1
del /f /q output.exe >nul 2>&1

:: Compile the input.cc file
g++ %LEXICAL_DIR%\input.cc -o output.exe 2>error.txt
set COMPILE_ERROR=%ERRORLEVEL%

:: Check if compilation was successful
if %COMPILE_ERROR% EQU 0 (
    echo Compilation successful!
    echo -----------------------------------------------------------------------------------------
    echo Program output:
    output.exe
) else (
    echo Compilation failed!
    :: type error.txt
    del error.txt
)
