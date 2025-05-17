#!/usr/bin/env pwsh

# This is a placeholder script for the compiler process
# It will be replaced with the actual implementation using Lex/Yacc

Write-Output "Compiling input.c..."

# Set the lexical directory path
$LEXICAL_DIR = "lexical"

# Create lexical directory if it doesn't exist
if (-not (Test-Path $LEXICAL_DIR)) {
    New-Item -ItemType Directory -Path $LEXICAL_DIR -Force | Out-Null
}

# Try to use Lex if available
try {
    # Check if lex is available
    $lexPath = Get-Command lex -ErrorAction SilentlyContinue
    
    if ($lexPath) {
        Write-Output "Running lexical analysis with Lex..."
        
        # Change to lexical directory
        Push-Location $LEXICAL_DIR


        lex -o scanner.c scanner.l
        gcc scanner.c -o scanner.exe

       
        if (Test-Path scanner) {
            ./scanner.exe input.c > parseTable
            Write-Output "Lexical analysis completed."
        } else {
            Write-Output "Failed to compile the Lexical analysis"
        }
        
        # Return to original directory
        Pop-Location
    } else {
        Write-Output "Lex not found.."
    }
} catch {
    Write-Output "Error checking for Lex: $_"
   
}

# Create other tables if they don't exist
if (-not (Test-Path "$LEXICAL_DIR\symbolTable")) {
    "NAME    TYPE    SCOPE    VALUE" | Out-File -FilePath "$LEXICAL_DIR\symbolTable" -Encoding utf8
    "test    int     global   0" | Out-File -FilePath "$LEXICAL_DIR\symbolTable" -Append -Encoding utf8
    "value   int     global   0" | Out-File -FilePath "$LEXICAL_DIR\symbolTable" -Append -Encoding utf8
}

if (-not (Test-Path "$LEXICAL_DIR\constantTable")) {
    "VALUE    TYPE" | Out-File -FilePath "$LEXICAL_DIR\constantTable" -Encoding utf8
    "1        INT" | Out-File -FilePath "$LEXICAL_DIR\constantTable" -Append -Encoding utf8
    "2        INT" | Out-File -FilePath "$LEXICAL_DIR\constantTable" -Append -Encoding utf8
}

# Try to compile the input.c file
try {
    # Call gcc to compile
    $compileOutput = gcc "$LEXICAL_DIR\input.c" -o output.exe 2>&1
    
    # Check if compilation was successful
    if (Test-Path output.exe) {
        Write-Output "Compilation successful!"
        Write-Output "Program output:"
        # Run the compiled program
        ./output.exe
    } else {
        Write-Output "Compilation failed."
        Write-Output $compileOutput
    }
} catch {
    Write-Output "Error during compilation:"
    Write-Output $_
}


