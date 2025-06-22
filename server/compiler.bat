@echo off
echo Compiling input.cc...
echo -----------------------------------------------------------------------------------------

:: Set the lexical directory path
set LEXICAL_DIR=lexical

:: Create lexical directory if it doesn't exist
if not exist %LEXICAL_DIR% mkdir %LEXICAL_DIR%

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
    ) else (
        echo Failed to compile the scanner.
        cd ..
    )

    echo -----------------------------------------------------------------------------------------
    echo Running Syntax Analyzer with Bison...
    copy /Y lexical\input.cc "Syntax Analyzer\input.cc" >nul
    "C:\Program Files\Git\bin\sh.exe" "Syntax Analyzer/compile.sh"
    echo -----------------------------------------------------------------------------------------
) else (
    echo Lex and Bison not found.
)

:: -----------------------------------------------------------------------------------------
:: PRE-COMPILATION: Force kill and delete previous output.exe if it exists or is locked
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
    @REM type error.txt
    @REM del error.txt
)
