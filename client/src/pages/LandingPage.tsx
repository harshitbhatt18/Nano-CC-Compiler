import React from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Box, 
  Button, 
  Container, 
  Typography, 
  Card,
} from '@mui/material';
import Navbar from '../components/Navbar';
import Footer from '../components/Footer';

const LandingPage: React.FC = () => {
  const navigate = useNavigate();

  return (
    <Box sx={{ 
      display: 'flex', 
      flexDirection: 'column', 
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%)',
    }}>
      <Navbar />

      {/* Hero Section */}
      <Box 
        sx={{
          textAlign: 'center',
          pt: { xs: 6, sm: 8 },
          pb: { xs: 8, sm: 10 },
          background: 'linear-gradient(135deg, rgba(124, 58, 237, 0.1) 0%, rgba(6, 182, 212, 0.1) 100%)',
          borderRadius: '20px',
          position: 'relative',
          overflow: 'hidden',
          mb: { xs: 6, sm: 8 },
          mx: { xs: 2, sm: 4 },
          mt: { xs: 2, sm: 4 },
          border: '1px solid rgba(124, 58, 237, 0.2)',
          backdropFilter: 'blur(20px)',
          boxShadow: '0 20px 60px rgba(0, 0, 0, 0.4)',
        }}
      >
        {/* Animated background elements */}
        <Box 
          sx={{ 
            position: 'absolute', 
            width: '300px', 
            height: '300px', 
            borderRadius: '50%', 
            background: 'radial-gradient(circle, rgba(124, 58, 237, 0.3) 0%, rgba(124, 58, 237, 0) 70%)',
            top: '-50px',
            right: '10%',
            zIndex: 0,
            display: { xs: 'none', sm: 'block' },
            animation: 'pulse 4s infinite ease-in-out',
          }} 
        />

        <Box 
          sx={{ 
            position: 'absolute', 
            width: '400px', 
            height: '400px', 
            borderRadius: '50%', 
            background: 'radial-gradient(circle, rgba(6, 182, 212, 0.2) 0%, rgba(6, 182, 212, 0) 70%)',
            bottom: '-150px',
            left: '5%',
            zIndex: 0,
            display: { xs: 'none', sm: 'block' },
            animation: 'pulse 6s infinite ease-in-out',
          }} 
        />
        
        <Container maxWidth="md" sx={{ position: 'relative', zIndex: 1 }}>
          <Typography 
            variant="h2" 
            component="h1" 
            className="animate-fade-in-up"
            sx={{ 
              mb: 3, 
              background: 'linear-gradient(135deg, #f1f5f9 0%, #94a3b8 100%)',
              backgroundClip: 'text',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              fontWeight: 800,
              fontSize: { xs: '2.5rem', sm: '3.5rem', md: '4rem' },
              textShadow: '0 4px 20px rgba(124, 58, 237, 0.3)',
            }}
          >
            Nano CC Compiler
          </Typography>
          <Typography 
            variant="h6" 
            className="animate-fade-in-up"
            sx={{ 
              mb: 5, 
              color: '#94a3b8',
              maxWidth: '700px',
              mx: 'auto',
              fontSize: { xs: '1.1rem', sm: '1.3rem', md: '1.5rem' },
              lineHeight: 1.6,
              fontWeight: 500,
            }}
          >
            Explore and understand the three phases of compilation
            <br />with interactive visualizations and detailed analysis
          </Typography>
          <Button 
            variant="contained" 
            size="large"
            onClick={() => navigate('/compiler')}
            className="animate-fade-in-up"
            sx={{
              background: 'linear-gradient(135deg, #7c3aed 0%, #a855f7 100%)',
              py: { xs: 1.5, sm: 2 },
              px: { xs: 4, sm: 6 },
              fontSize: { xs: '1rem', sm: '1.2rem' },
              fontWeight: 600,
              borderRadius: '12px',
              boxShadow: '0 8px 30px rgba(124, 58, 237, 0.4)',
              border: '1px solid rgba(168, 85, 247, 0.5)',
              transition: 'all 0.3s ease',
              '&:hover': {
                background: 'linear-gradient(135deg, #6d28d9 0%, #9333ea 100%)',
                transform: 'translateY(-3px)',
                boxShadow: '0 12px 40px rgba(124, 58, 237, 0.6)',
              }
            }}
          >
            Start Compiling
          </Button>
        </Container>
      </Box>

      {/* Features Section */}
      <Container maxWidth="lg" sx={{ mb: 8 }}>
        <Typography 
          variant="h4" 
          component="h3" 
          className="animate-fade-in-up"
          sx={{ 
            mb: 6, 
            textAlign: 'center', 
            fontWeight: 700,
            background: 'linear-gradient(135deg, #f1f5f9 0%, #94a3b8 100%)',
            backgroundClip: 'text',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            fontSize: { xs: '1.8rem', sm: '2.2rem', md: '2.5rem' }
          }}
        >
          Compiler Phases
        </Typography>
        <Box sx={{ 
          display: 'flex', 
          flexWrap: 'wrap', 
          gap: { xs: 3, sm: 4 }, 
          justifyContent: 'center'
        }}>
          {[
            {
              phase: '1',
              title: 'Lexical Analysis',
              gradient: 'linear-gradient(135deg, #7c3aed 0%, #a855f7 100%)',
              description: 'View the tokenization process in real-time. See how your code is broken down into lexemes, with detailed token information and line numbers.',
              shadow: 'rgba(124, 58, 237, 0.4)'
            },
            {
              phase: '2',
              title: 'Syntax Analysis',
              gradient: 'linear-gradient(135deg, #06b6d4 0%, #67e8f9 100%)',
              description: 'Understand the parsing process and syntax validation. Visualize how your code conforms to C language grammar rules.',
              shadow: 'rgba(6, 182, 212, 0.4)'
            },
            {
              phase: '3',
              title: 'Semantic Analysis',
              gradient: 'linear-gradient(135deg, #8b5cf6 0%, #c084fc 100%)',
              description: 'Explore symbol tables and constant tables. Track variable declarations, scope, and type checking in your code.',
              shadow: 'rgba(139, 92, 246, 0.4)'
            }
          ].map((item, index) => (
            <Card key={item.phase} className="animate-fade-in-up" sx={{ 
              flex: '1 1 320px',
              maxWidth: '380px',
              p: 4,
              borderRadius: '16px',
              background: 'linear-gradient(135deg, rgba(26, 26, 46, 0.8) 0%, rgba(22, 33, 62, 0.8) 100%)',
              backdropFilter: 'blur(20px)',
              border: '1px solid rgba(124, 58, 237, 0.2)',
              transition: 'all 0.4s cubic-bezier(0.4, 0, 0.2, 1)',
              position: 'relative',
              overflow: 'hidden',
              '&:hover': {
                transform: 'translateY(-8px) scale(1.02)',
                boxShadow: `0 20px 40px ${item.shadow}`,
                borderColor: 'rgba(124, 58, 237, 0.4)',
              },
              '&::before': {
                content: '""',
                position: 'absolute',
                top: 0,
                left: 0,
                right: 0,
                height: '4px',
                background: item.gradient,
                borderRadius: '16px 16px 0 0',
              },
              animationDelay: `${index * 0.2}s`,
            }}>
              <Box 
                sx={{ 
                  width: { xs: '48px', sm: '56px' },
                  height: { xs: '48px', sm: '56px' },
                  borderRadius: '14px',
                  background: item.gradient,
                  mb: 3,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: 'white',
                  fontWeight: 'bold',
                  fontSize: { xs: '1.4rem', sm: '1.6rem' },
                  boxShadow: `0 8px 20px ${item.shadow}`,
                  transition: 'all 0.3s ease',
                  '&:hover': {
                    transform: 'scale(1.1) rotate(5deg)',
                  }
                }}
              >
                {item.phase}
              </Box>
              <Typography variant="h6" sx={{ 
                fontWeight: 600,
                color: '#f1f5f9',
                mb: 2,
                fontSize: { xs: '1.1rem', sm: '1.3rem' }
              }}>
                {item.title}
              </Typography>
              <Typography variant="body1" sx={{ 
                color: '#94a3b8',
                fontSize: { xs: '0.9rem', sm: '1rem' },
                lineHeight: 1.7,
              }}>
                {item.description}
              </Typography>
            </Card>
          ))}
        </Box>
      </Container>

      <Footer />
    </Box>
  );
};

export default LandingPage; 