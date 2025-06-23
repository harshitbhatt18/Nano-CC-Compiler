const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const { v4: uuidv4 } = require('uuid');

// Check if running on Windows
if (process.platform !== 'win32') {
  console.error('❌ This application is designed to run only on Windows.');
  process.exit(1);
}

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(bodyParser.json());

const activeProcesses = {};
const processTimeouts = {};
const terminationReasons = {}; 

// === Compile Endpoint ===
app.post('/api/compile', (req, res) => {
  const { code } = req.body;
  if (!code) return res.status(400).json({ error: 'No code provided' });

  const compilationId = uuidv4();
  const lexicalDir = path.join(__dirname, 'lexical');
  const semanticDir = path.join(__dirname, 'semantic');
  const inputFilePath = path.join(lexicalDir, 'input.cc');

  if (!fs.existsSync(lexicalDir)) {
    fs.mkdirSync(lexicalDir, { recursive: true });
  }

  fs.writeFileSync(inputFilePath, code);

  // Windows-only compilation
  const command = 'compiler.bat';

  const compileProcess = spawn(
    'cmd.exe',
    ['/c', command],
    { cwd: __dirname, shell: true }
  );

  activeProcesses[compilationId] = compileProcess;

  let output = '';
  let errorOutput = '';
  let responded = false;

  compileProcess.stdout.on('data', data => {
    output += data.toString();
  });

  compileProcess.stderr.on('data', data => {
    errorOutput += data.toString();
  });

  // === Auto-Terminate after 10 seconds ===
  const timeout = setTimeout(() => {
    if (!compileProcess.killed) {
      compileProcess.kill('SIGKILL');
      terminationReasons[compilationId] = 'timeout';
      console.log(`⏱️ Auto-killed compilation ${compilationId} after timeout.`);
    }
  }, 10000);
  processTimeouts[compilationId] = timeout;

  // === On Successful Compilation ===
  compileProcess.on('exit', () => {
    if (responded) return;

    responded = true;
    clearTimeout(timeout);
    delete activeProcesses[compilationId];
    delete processTimeouts[compilationId];

    const reason = terminationReasons[compilationId];
    if (reason === 'timeout') {
      output += `\n\n⏱️ Time Limit Exceeded!`;
    }
    delete terminationReasons[compilationId];

    const safeRead = filePath => {
      try {
        return fs.readFileSync(filePath, 'utf8');
      } catch {
        return '';
      }
    };

    const parseTable = safeRead(path.join(lexicalDir, 'parseTable'));
    const symbolTable = safeRead(path.join(semanticDir, 'symbolTable'));
    const constantTable = safeRead(path.join(semanticDir, 'constantTable'));
    const parseTreePath = path.join(__dirname, 'syntax', 'parsetree.txt');
    const parseTree = fs.existsSync(parseTreePath)
      ? safeRead(parseTreePath).replace(/\r\n/g, '\n')
      : '';

    res.json({
      compilationId,
      output,
      error: errorOutput,
      parseTable,
      symbolTable,
      constantTable,
      parseTree
    });
  });

  compileProcess.on('error', err => {
    if (responded) return;

    responded = true;
    clearTimeout(timeout);
    delete activeProcesses[compilationId];
    delete processTimeouts[compilationId];

    console.error(`Compilation process error [${compilationId}]:`, err);
    res.status(500).json({
      compilationId,
      error: 'Failed to start compilation process.'
    });
  });
});

// === Input Route  ===
app.post('/api/input', (req, res) => {
  res.json({ success: true });
});

// === Static parse tree image serving ===
const syntaxAnalyzerDir = path.join(__dirname, 'syntax');
app.use('/api/parsetree-image', express.static(syntaxAnalyzerDir));

// === Start server ===
app.listen(PORT, () => {
  console.log(`🚀 Nano CC Compiler server running on port ${PORT}`);
});
