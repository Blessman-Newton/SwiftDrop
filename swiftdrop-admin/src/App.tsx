import React, { useState, useEffect } from 'react';
import { AnimatePresence, motion } from 'motion/react';
import Header from './components/Header';
import Navigation from './components/Navigation';
import FleetMonitoringView from './components/FleetMonitoringView';
import DashboardView from './components/DashboardView';
import FinancialReportsView from './components/FinancialReportsView';
import SystemAnalyticsView from './components/SystemAnalyticsView';
import AuditSecurityView from './components/AuditSecurityView';
import { Screen } from './types';

export default function App() {
  // Screen views manager state
  const [activeScreen, setActiveScreen] = useState<Screen>('fleet');
  
  // Theme state
  const [isDarkMode, setIsDarkMode] = useState<boolean>(() => {
    const saved = localStorage.getItem('swiftDropTheme');
    return saved === 'dark';
  });

  // Apply dark class to document on change
  useEffect(() => {
    if (isDarkMode) {
      document.documentElement.classList.add('dark');
      localStorage.setItem('swiftDropTheme', 'dark');
    } else {
      document.documentElement.classList.remove('dark');
      localStorage.setItem('swiftDropTheme', 'light');
    }
  }, [isDarkMode]);

  const toggleDarkMode = () => {
    setIsDarkMode(prev => !prev);
  };

  // Render active dashboard screen
  const renderScreen = () => {
    switch (activeScreen) {
      case 'fleet':
        return <FleetMonitoringView />;
      case 'dashboard':
        return <DashboardView setActiveScreen={setActiveScreen} />;
      case 'wallet':
        return <FinancialReportsView />;
      case 'reports':
        return <SystemAnalyticsView />;
      case 'security':
        return <AuditSecurityView />;
      default:
        return <FleetMonitoringView />;
    }
  };

  return (
    <div className="min-h-screen bg-background text-on-surface flex flex-col md:flex-row transition-all duration-300">
      
      {/* 1. Responsive Sidebar / Bottom navigation */}
      <Navigation 
        activeScreen={activeScreen} 
        setActiveScreen={setActiveScreen} 
        isDarkMode={isDarkMode}
      />

      {/* 2. Main content area wrapper */}
      <div className="flex-1 md:ml-64 flex flex-col min-h-screen transition-all">
        
        {/* Persistent top app bar header */}
        <Header 
          activeScreen={activeScreen} 
          isDarkMode={isDarkMode} 
          toggleDarkMode={toggleDarkMode}
        />

        {/* Scaled viewport container with responsive bottom margins for mobile navbar */}
        <main className="flex-1 p-4 md:p-6 pb-24 md:pb-8 transition-all overflow-y-auto">
          <AnimatePresence mode="wait">
            <motion.div
              key={activeScreen}
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -15 }}
              transition={{ duration: 0.3, ease: [0.4, 0, 0.2, 1] }}
              className="h-full"
            >
              {renderScreen()}
            </motion.div>
          </AnimatePresence>
        </main>

      </div>
    </div>
  );
}
