import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import LandingPage from './pages/LandingPage';
import CompilerPage from './pages/CompilerPage';

const theme = createTheme({
  palette: {
    mode: 'dark',
    primary: {
      main: '#7c3aed', // Rich purple
      light: '#a855f7',
      dark: '#5b21b6',
      contrastText: '#ffffff',
    },
    secondary: {
      main: '#06b6d4', // Cyan
      light: '#67e8f9',
      dark: '#0891b2',
      contrastText: '#ffffff',
    },
    background: {
      default: '#0f0f23', // Deep dark background
      paper: '#1a1a2e', // Slightly lighter for cards/papers
    },
    surface: {
      main: '#16213e', // Custom surface color
      light: '#1e293b',
      dark: '#0f172a',
    },
    text: {
      primary: '#f1f5f9', // Light text
      secondary: '#94a3b8', // Muted text
    },
    error: {
      main: '#ef4444',
      light: '#f87171',
      dark: '#dc2626',
    },
    warning: {
      main: '#f59e0b',
      light: '#fbbf24',
      dark: '#d97706',
    },
    success: {
      main: '#10b981',
      light: '#34d399',
      dark: '#059669',
    },
    info: {
      main: '#3b82f6',
      light: '#60a5fa',
      dark: '#2563eb',
    },
  },
  typography: {
    fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
    h1: {
      fontWeight: 700,
      letterSpacing: '-0.025em',
    },
    h2: {
      fontWeight: 700,
      letterSpacing: '-0.025em',
    },
    h3: {
      fontWeight: 600,
      letterSpacing: '-0.025em',
    },
    h4: {
      fontWeight: 600,
      letterSpacing: '-0.025em',
    },
    h5: {
      fontWeight: 600,
      letterSpacing: '-0.025em',
    },
    h6: {
      fontWeight: 600,
      letterSpacing: '-0.025em',
    },
    body1: {
      lineHeight: 1.7,
    },
    body2: {
      lineHeight: 1.6,
    },
  },
  shape: {
    borderRadius: 12,
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none',
          fontWeight: 600,
          borderRadius: 10,
          padding: '10px 24px',
          boxShadow: '0 4px 14px 0 rgba(124, 58, 237, 0.25)',
          transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
          '&:hover': {
            transform: 'translateY(-2px)',
            boxShadow: '0 8px 25px 0 rgba(124, 58, 237, 0.35)',
          },
        },
        containedPrimary: {
          background: 'linear-gradient(135deg, #7c3aed 0%, #a855f7 100%)',
          '&:hover': {
            background: 'linear-gradient(135deg, #6d28d9 0%, #9333ea 100%)',
          },
        },
        containedSecondary: {
          background: 'linear-gradient(135deg, #06b6d4 0%, #67e8f9 100%)',
          '&:hover': {
            background: 'linear-gradient(135deg, #0891b2 0%, #22d3ee 100%)',
          },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          backgroundColor: '#1a1a2e',
          backgroundImage: 'linear-gradient(135deg, rgba(124, 58, 237, 0.05) 0%, rgba(6, 182, 212, 0.05) 100%)',
          border: '1px solid rgba(124, 58, 237, 0.1)',
          backdropFilter: 'blur(10px)',
          boxShadow: '0 8px 32px 0 rgba(31, 38, 135, 0.37)',
        },
      },
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          backgroundColor: 'transparent',
          backgroundImage: 'linear-gradient(135deg, #0f0f23 0%, #1a1a2e 100%)',
          backdropFilter: 'blur(20px)',
          borderBottom: '1px solid rgba(124, 58, 237, 0.2)',
        },
      },
    },
    MuiTab: {
      styleOverrides: {
        root: {
          textTransform: 'none',
          fontWeight: 600,
          fontSize: '0.95rem',
          color: '#94a3b8',
          '&.Mui-selected': {
            color: '#7c3aed',
          },
        },
      },
    },
    MuiTabs: {
      styleOverrides: {
        indicator: {
          background: 'linear-gradient(135deg, #7c3aed 0%, #a855f7 100%)',
          height: 3,
          borderRadius: '3px 3px 0 0',
        },
      },
    },
  },
});

// Add custom colors to theme
declare module '@mui/material/styles' {
  interface Palette {
    surface: Palette['primary'];
  }
  interface PaletteOptions {
    surface?: PaletteOptions['primary'];
  }
}

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <Routes>
          <Route path="/" element={<LandingPage />} />
          <Route path="/compiler" element={<CompilerPage />} />
        </Routes>
      </Router>
    </ThemeProvider>
  );
}

export default App;
