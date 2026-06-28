import React, { useState, useEffect } from 'react';
import { Wifi, Battery, Signal, Moon, Sun, Smartphone, Laptop, Sparkles } from 'lucide-react';

interface PhoneFrameProps {
  children: React.ReactNode;
  darkMode: boolean;
  setDarkMode: (dark: boolean) => void;
  activeScreen: string;
  setActiveScreen: (screen: any) => void;
  onResetDemo: () => void;
}

export default function PhoneFrame({
  children,
  darkMode,
  setDarkMode,
  activeScreen,
  setActiveScreen,
  onResetDemo,
}: PhoneFrameProps) {
  const [time, setTime] = useState('');

  useEffect(() => {
    const updateClock = () => {
      const now = new Date();
      let hours = now.getHours();
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const ampm = hours >= 12 ? 'PM' : 'AM';
      // Format 12 hours or 24 hours depending on preference, let's do 24 hour display or 12 hour
      const formattedHours = String(hours).padStart(2, '0');
      setTime(`${formattedHours}:${minutes}`);
    };
    
    updateClock();
    const interval = setInterval(updateClock, 1000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="min-h-screen bg-slate-100 dark:bg-slate-950 text-slate-800 dark:text-slate-100 flex flex-col lg:flex-row items-center justify-center p-4 lg:p-8 transition-colors duration-300 font-sans">
      {/* Background decoration elements */}
      <div className="absolute top-0 left-0 w-96 h-96 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute bottom-0 right-0 w-96 h-96 bg-teal-500/10 rounded-full blur-3xl pointer-events-none" />

      {/* Main Container */}
      <div className="flex flex-col xl:flex-row items-center gap-8 z-10 w-full max-w-6xl justify-center">
        
        {/* Left Side: App Pitch & Screen Selector (for desktop) */}
        <div className="flex-1 max-w-md text-center xl:text-left space-y-6 hidden lg:block">
          <div className="inline-flex items-center gap-2 bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-400 px-3 py-1.5 rounded-full text-sm font-semibold border border-emerald-100 dark:border-emerald-900/30">
            <Sparkles className="w-4 h-4 animate-pulse" />
            <span>Interactive Courier Prototype</span>
          </div>
          <h1 className="text-4xl font-extrabold tracking-tight text-slate-900 dark:text-white sm:text-5xl">
            SwiftDrop <span className="text-emerald-600 dark:text-emerald-400">Rider</span>
          </h1>
          <p className="text-lg text-slate-600 dark:text-slate-300">
            An ultra-polished, responsive mobile app experience designed specifically for high-efficiency urban delivery. Live navigation, earnings ledger, and real-time order states.
          </p>

          <div className="bg-white dark:bg-slate-900/80 p-5 rounded-2xl border border-slate-200/60 dark:border-slate-800/60 shadow-lg space-y-4">
            <h3 className="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              Screen Navigation Controller
            </h3>
            <div className="grid grid-cols-2 gap-2">
              {[
                { id: 'LOGIN', label: 'Rider Login' },
                { id: 'DASHBOARD', label: 'Dashboard' },
                { id: 'ACTIVE_DELIVERY', label: 'Active Delivery' },
                { id: 'NAVIGATION', label: 'Route Map' },
                { id: 'EARNINGS', label: 'Earnings' },
              ].map((s) => (
                <button
                  key={s.id}
                  onClick={() => setActiveScreen(s.id)}
                  className={`px-3 py-2.5 rounded-xl text-xs font-semibold text-left transition-all duration-200 border flex items-center justify-between ${
                    activeScreen === s.id
                      ? 'bg-emerald-600 border-emerald-600 text-white shadow-md shadow-emerald-600/20'
                      : 'bg-slate-50 dark:bg-slate-800/40 border-slate-200/60 dark:border-slate-800/60 text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800'
                  }`}
                >
                  <span>{s.label}</span>
                  {activeScreen === s.id && <div className="w-2 h-2 bg-white rounded-full" />}
                </button>
              ))}
            </div>

            <div className="pt-2 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between gap-4 text-xs">
              <button
                onClick={onResetDemo}
                className="text-emerald-600 dark:text-emerald-400 font-bold hover:underline"
              >
                Reset Prototype State
              </button>
              <div className="text-slate-400">
                Ver 1.4.0 (Beta)
              </div>
            </div>
          </div>

          <div className="flex items-center gap-4 text-sm text-slate-500 dark:text-slate-400 justify-center xl:justify-start">
            <div className="flex items-center gap-1.5">
              <Smartphone className="w-4 h-4" />
              <span>Full-Screen Mobile UI</span>
            </div>
            <div className="w-1.5 h-1.5 bg-slate-300 dark:bg-slate-700 rounded-full" />
            <div className="flex items-center gap-1.5">
              <Laptop className="w-4 h-4" />
              <span>Responsive Bezel Control</span>
            </div>
          </div>
        </div>

        {/* Center: The Smartphone Wrapper */}
        <div className="relative mx-auto">
          {/* Quick Floating Dark Mode & Info buttons (always visible, outside the screen on desktop) */}
          <div className="absolute -left-16 top-4 flex flex-col gap-3 z-30 lg:flex hidden">
            <button
              onClick={() => setDarkMode(!darkMode)}
              className="w-12 h-12 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl shadow-xl flex items-center justify-center hover:scale-105 active:scale-95 text-slate-700 dark:text-slate-300 transition-all"
              title="Toggle Dark Mode"
            >
              {darkMode ? <Sun className="w-5 h-5 text-amber-500" /> : <Moon className="w-5 h-5 text-indigo-500" />}
            </button>
          </div>

          {/* Device Shell */}
          <div className="w-[380px] h-[820px] sm:w-[390px] sm:h-[844px] bg-slate-950 rounded-[50px] p-[10px] shadow-[0_25px_60px_-15px_rgba(0,108,73,0.15)] ring-12 ring-slate-900 flex flex-col overflow-hidden relative border-4 border-slate-800">
            {/* Speaker & Sensor Notch ("Dynamic Island") */}
            <div className="absolute top-3 left-1/2 -translate-x-1/2 w-28 h-6 bg-slate-950 rounded-full z-50 flex items-center justify-end px-3">
              <div className="w-2.5 h-2.5 bg-slate-900 rounded-full border border-slate-800" />
            </div>

            {/* Simulated Screen Inner */}
            <div className={`flex-1 rounded-[42px] overflow-hidden flex flex-col relative bg-[#f4fbf4] text-[#161d19] ${darkMode ? 'dark bg-[#121814] text-[#ebf3eb]' : ''} transition-colors duration-300`}>
              
              {/* Device Status Bar */}
              <div className="h-11 px-6 pt-3 flex items-center justify-between text-[13px] font-semibold z-50 select-none bg-transparent absolute top-0 left-0 w-full">
                <span className="text-slate-700 dark:text-slate-300 tabular-nums">
                  {time}
                </span>
                
                <div className="flex items-center gap-1.5 text-slate-700 dark:text-slate-300">
                  <Signal className="w-3.5 h-3.5" />
                  <span className="text-[10px]">5G</span>
                  <Wifi className="w-3.5 h-3.5" />
                  <Battery className="w-4 h-4 text-emerald-500 fill-emerald-500 dark:text-emerald-400 dark:fill-emerald-400" />
                </div>
              </div>

              {/* Screen Content */}
              <div className="flex-1 flex flex-col overflow-y-auto no-scrollbar pt-11 relative">
                {children}
              </div>

              {/* Device Bottom Home Indicator Bar */}
              <div className="h-6 flex items-center justify-center bg-transparent z-50 select-none pb-1 shrink-0">
                <div className="w-32 h-1 bg-slate-400 dark:bg-slate-600 rounded-full hover:bg-slate-500" />
              </div>
            </div>
          </div>
          
          {/* Quick theme toggle floating helper on mobile */}
          <div className="absolute right-4 -top-12 flex gap-2 lg:hidden">
            <button
              onClick={() => setDarkMode(!darkMode)}
              className="px-3 py-1.5 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-full shadow-md flex items-center gap-1.5 text-xs font-semibold text-slate-700 dark:text-slate-300"
            >
              {darkMode ? <Sun className="w-3.5 h-3.5 text-amber-500" /> : <Moon className="w-3.5 h-3.5 text-indigo-500" />}
              <span>{darkMode ? 'Light' : 'Dark'}</span>
            </button>
            <button
              onClick={() => {
                const screens = ['LOGIN', 'DASHBOARD', 'ACTIVE_DELIVERY', 'NAVIGATION', 'EARNINGS'];
                const currentIndex = screens.indexOf(activeScreen);
                const nextIndex = (currentIndex + 1) % screens.length;
                setActiveScreen(screens[nextIndex] as any);
              }}
              className="px-3 py-1.5 bg-emerald-600 text-white rounded-full shadow-md flex items-center text-xs font-semibold"
            >
              Next Screen
            </button>
          </div>
        </div>

      </div>
    </div>
  );
}
