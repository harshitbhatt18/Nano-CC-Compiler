const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Route to handle code compilation
app.post('/api/compile', (req, res) => {
  const { code } = req.body;
  if (!code) {
    return res.status(400).json({ error: 'No code provided' });
  }

  // Write the code to input.c in the lexical directory
  const lexicalDir = path.join(__dirname, 'lexical');
  const inputFilePath = path.join(lexicalDir, 'input.c');
  
  // Ensure the lexical directory exists
  if (!fs.existsSync(lexicalDir)) {
    fs.mkdirSync(lexicalDir, { recursive: true });
  }
  
  fs.writeFileSync(inputFilePath, code);

  // Determine the platform-specific command
  const isWindows = process.platform === 'win32';
  const compileCommand = isWindows ? '.\\compiler.bat' : 'sh compiler.sh';

  // Execute the compiler script
  exec(compileCommand, { cwd: __dirname }, (error, stdout, stderr) => {
    let output = stdout;
    let errorOutput = stderr;
    
    // Try to read the output files from the lexical directory
    let parseTable = '';
    let symbolTable = '';
    let constantTable = '';
    
    try {
      parseTable = fs.readFileSync(path.join(lexicalDir, 'parseTable'), 'utf8');
    } catch (err) {
      console.error('Error reading parseTable:', err);
    }
    
    try {
      symbolTable = fs.readFileSync(path.join(lexicalDir, 'symbolTable'), 'utf8');
    } catch (err) {
      console.error('Error reading symbolTable:', err);
    }
    
    try {
      constantTable = fs.readFileSync(path.join(lexicalDir, 'constantTable'), 'utf8');
    } catch (err) {
      console.error('Error reading constantTable:', err);
    }
    
    res.json({
      output,
      error: errorOutput,
      parseTable,
      symbolTable,
      constantTable,
    });
  });
});

// Route to receive terminal input (for scanf functionality)
app.post('/api/input', (req, res) => {
  const { input } = req.body;
  // This is a placeholder for handling input to the running process
  // Will need to be expanded based on how you implement the actual process communication
  res.json({ success: true });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
}); 