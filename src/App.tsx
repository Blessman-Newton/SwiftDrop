import React, { useState } from 'react';
import { AnimatePresence } from 'motion/react';
import { Screen, Toast } from './types';
import PhoneFrame from './components/PhoneFrame';
import LoginScreen from './components/LoginScreen';
import DashboardScreen from './components/DashboardScreen';
import ActiveDeliveryScreen from './components/ActiveDeliveryScreen';
import NavigationScreen from './components/NavigationScreen';
import EarningsScreen from './components/EarningsScreen';
import Notification from './components/Notification';

export default function App() {
  const [activeScreen, setActiveScreen] = useState<Screen>(Screen.LOGIN);
  const [darkMode, setDarkMode] = useState<boolean>(false);
  const [isOnline, setIsOnline] = useState<boolean>(false);
  const [toasts, setToasts] = useState<Toast[]>([]);

  const showToast = (message: string, type: 'success' | 'error' | 'info') => {
    const newToast: Toast = {
      id: Math.random().toString(36).substring(2, 9),
      message,
      type,
    };
    setToasts((prev) => [...prev, newToast]);
  };

  const handleLoginSuccess = () => {
    setActiveScreen(Screen.DASHBOARD);
  };

  const handleResetDemo = () => {
    setActiveScreen(Screen.LOGIN);
    setIsOnline(false);
    setToasts([]);
    showToast('Demo application state fully reset!', 'info');
  };

  return (
    <PhoneFrame
      darkMode={darkMode}
      setDarkMode={setDarkMode}
      activeScreen={activeScreen}
      setActiveScreen={setActiveScreen}
      onResetDemo={handleResetDemo}
    >
      {/* Dynamic ios-style Floating Notifications banner */}
      <Notification toasts={toasts} setToasts={setToasts} />

      {/* Screen Transitions Router */}
      <AnimatePresence mode="wait">
        {activeScreen === Screen.LOGIN && (
          <div key="login" className="contents">
            <LoginScreen
              onLoginSuccess={handleLoginSuccess}
              showToast={showToast}
            />
          </div>
        )}
        
        {activeScreen === Screen.DASHBOARD && (
          <div key="dashboard" className="contents">
            <DashboardScreen
              isOnline={isOnline}
              setIsOnline={setIsOnline}
              setActiveScreen={setActiveScreen}
              showToast={showToast}
            />
          </div>
        )}

        {activeScreen === Screen.ACTIVE_DELIVERY && (
          <div key="active_delivery" className="contents">
            <ActiveDeliveryScreen
              setActiveScreen={setActiveScreen}
              showToast={showToast}
            />
          </div>
        )}

        {activeScreen === Screen.NAVIGATION && (
          <div key="navigation" className="contents">
            <NavigationScreen
              setActiveScreen={setActiveScreen}
              showToast={showToast}
              darkMode={darkMode}
            />
          </div>
        )}

        {activeScreen === Screen.EARNINGS && (
          <div key="earnings" className="contents">
            <EarningsScreen
              setActiveScreen={setActiveScreen}
              showToast={showToast}
            />
          </div>
        )}
      </AnimatePresence>
    </PhoneFrame>
  );
}
