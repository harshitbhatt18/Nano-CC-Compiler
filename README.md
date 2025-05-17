# Nano CC Compiler

A simple C compiler built for educational purposes, demonstrating the key phases of compilation: lexical analysis, syntax analysis, and semantic analysis.

## Features

- Web-based interface for writing and compiling C code
- Visual representation of compiler phases
- View lexical tokens, symbol tables, and constant tables
- Interactive terminal for program I/O

## Project Structure

```
nano-cc-compiler/
├── client/             # React frontend
│   ├── src/
│   │   ├── components/ # Reusable UI components
│   │   └── pages/      # Page components
│   └── package.json    # Frontend dependencies
├── server/             # Node.js backend
│   ├── compiler.bat    # Windows batch script for compilation
│   ├── compiler.ps1    # PowerShell script for compilation (alternative)
│   ├── compiler.sh     # Shell script for compilation (Linux/Mac)
│   ├── index.js        # Express server
│   └── package.json    # Backend dependencies
└── package.json        # Root package.json for running both client and server
```

## Getting Started

### Prerequisites

- Node.js (v14 or higher)
- npm (v6 or higher)
- GCC compiler (for actually compiling C code)

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/nano-cc-compiler.git
   cd nano-cc-compiler
   ```

2. Install dependencies:
   ```
   npm run install
   ```

3. Run the development server:
   ```
   npm run dev
   ```
   Or simply double-click the `start.bat` file if you're on Windows.

4. Open your browser and navigate to `http://localhost:3000`

### Windows Compatibility Note

For Windows users:
- The application uses a .bat file for running the compiler process
- If you encounter issues, make sure you have GCC installed and added to your PATH
- You can use MinGW, Cygwin, or the GCC that comes with Windows Subsystem for Linux (WSL)

## How It Works

1. User writes C code in the editor
2. Code is sent to the Node.js backend
3. Backend saves the code to a file and runs the compiler script
4. Compiler script processes the code and generates:
   - Parse table (lexical phase)
   - Symbol table (semantic phase)
   - Constant table (semantic phase)
5. Results are sent back to the frontend and displayed

## Future Plans

- Implement full Lex/Yacc integration
- Add syntax tree visualization
- Support for more C language features
- Better error handling and debugging tools

## License

This project is licensed under the ISC License.

## Acknowledgments

- [React](https://reactjs.org/)
- [Material-UI](https://mui.com/)
- [Monaco Editor](https://microsoft.github.io/monaco-editor/)
- [Express](https://expressjs.com/)
- [GCC](https://gcc.gnu.org/) 