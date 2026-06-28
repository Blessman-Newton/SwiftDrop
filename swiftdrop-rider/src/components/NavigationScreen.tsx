import React, { useState, useEffect } from 'react';
import { 
  ArrowUp, CornerUpRight, Plus, Minus, Navigation, 
  X, HelpCircle, PhoneCall, Check, UserCheck, Layers
} from 'lucide-react';
import { motion } from 'motion/react';
import { Screen } from '../types';

interface NavigationScreenProps {
  setActiveScreen: (screen: Screen) => void;
  showToast: (message: string, type: 'success' | 'error' | 'info') => void;
  darkMode: boolean;
}

export default function NavigationScreen({
  setActiveScreen,
  showToast,
  darkMode,
}: NavigationScreenProps) {
  const [distance, setDistance] = useState(200);
  const [zoomLevel, setZoomLevel] = useState(16);
  const [showExitModal, setShowExitModal] = useState(false);
  const [mapStyle, setMapStyle] = useState<'light' | 'dark'>(darkMode ? 'dark' : 'light');

  useEffect(() => {
    setMapStyle(darkMode ? 'dark' : 'light');
  }, [darkMode]);

  const toggleMapStyle = () => {
    const nextStyle = mapStyle === 'light' ? 'dark' : 'light';
    setMapStyle(nextStyle);
    showToast(`Switched map style to ${nextStyle === 'dark' ? 'Night/Dark' : 'Day/Light'}`, 'success');
  };

  useEffect(() => {
    const interval = setInterval(() => {
      setDistance((prev) => {
        if (prev > 15) {
          return prev - 4;
        } else {
          showToast('Turn right onto Main St now!', 'info');
          return 400; // Reset loop for simulation
        }
      });
    }, 1500);

    return () => clearInterval(interval);
  }, [showToast]);

  const handleZoom = (type: 'in' | 'out') => {
    if (type === 'in' && zoomLevel < 20) {
      setZoomLevel(zoomLevel + 1);
      showToast(`Zoomed Map In (Level ${zoomLevel + 1})`, 'info');
    } else if (type === 'out' && zoomLevel > 12) {
      setZoomLevel(zoomLevel - 1);
      showToast(`Zoomed Map Out (Level ${zoomLevel - 1})`, 'info');
    }
  };

  const handleSupport = () => {
    showToast('Connecting with SwiftDrop Dispatch support hotline...', 'success');
  };

  const handleExit = () => {
    showToast('Navigation terminated. Returning to task hub.', 'info');
    setActiveScreen(Screen.ACTIVE_DELIVERY);
  };

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.98 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.3 }}
      className="absolute inset-0 bg-[#f4fbf4] dark:bg-[#121814] z-50 flex flex-col justify-between overflow-hidden"
    >
      {/* FULL SCREEN MAP (Simulated via image) */}
      <div className="absolute inset-0 z-0">
        <img 
          className={`w-full h-full object-cover select-none pointer-events-none transition-all duration-500 origin-center grayscale-[5%] ${
            mapStyle === 'dark' ? 'brightness-[0.55] contrast-[1.1]' : 'brightness-100 contrast-100'
          }`}
          style={{ transform: `scale(${1 + (zoomLevel - 16) * 0.08})` }}
          alt="Chicago driver view isometric route map" 
          src="https://lh3.googleusercontent.com/aida-public/AB6AXuC2vWqt1jpjRGFrAbW_RYos-wzC36OUiHXFYplMGMohrhl0WeS_FUEsL4jc7tmkPpRvNWFS2YjuhQgz03A02nWfYoYHv86EkDNNeoYACwNmulCc8D17KAJ2mPhkZuEbNXizyIc7pqEoFwnFupOZ1rvcBm5dUOs66yswri8C5SFvBy_F16o9ipOUZCPcNS2lG5zr61vd6IN-m0SrUoFLkVVowkE9OoA_c-E1w6SCHwCMMPMoPWMai7K_P8r30VE1eX7E8a89-wIC6Is"
        />
        {/* Soft dark overlays to keep text readable */}
        <div className="absolute inset-0 bg-gradient-to-b from-slate-950/40 via-transparent to-slate-950/40 pointer-events-none" />
      </div>

      {/* NAVIGATION HEADER: Next Instruction */}
      <header className="absolute top-10 left-0 w-full px-5 pt-3 z-30 select-none">
        <div className="bg-emerald-800 dark:bg-emerald-950 text-white rounded-2xl shadow-xl p-4 flex items-center gap-4 border border-emerald-700/50">
          
          {/* Turn direction icon */}
          <div className="bg-white/10 dark:bg-white/5 rounded-xl p-2.5 flex items-center justify-center shrink-0">
            <CornerUpRight className="w-8 h-8 text-white animate-pulse" />
          </div>
          
          <div className="flex-1 min-w-0">
            <h1 className="text-sm font-extrabold tracking-tight text-white leading-snug truncate">
              Turn Right onto Main St
            </h1>
            <p className="text-[11px] font-bold text-emerald-200 mt-0.5 tabular-nums">
              In {distance}m
            </p>
          </div>
          
          <div className="text-right border-l border-white/15 pl-4 shrink-0 flex flex-col items-center justify-center">
            <p className="text-[9px] font-extrabold text-emerald-300 uppercase tracking-wider leading-none">
              Next
            </p>
            <ArrowUp className="w-5 h-5 text-white mt-1" />
          </div>
        </div>
      </header>

      {/* MAP INTERACTIVE ELEMENTS */}
      <div className="absolute inset-0 flex items-center justify-center pointer-events-none z-20">
        {/* Rider Position Pulsing Marker */}
        <div className="relative">
          <div className="bg-emerald-600 w-11 h-11 rounded-full border-4 border-white dark:border-slate-900 shadow-2xl flex items-center justify-center pulse-emerald relative z-10">
            <Navigation className="w-5 h-5 text-white fill-white rotate-45 -translate-y-[1px] translate-x-[1px]" />
          </div>
          {/* Pulsing ring */}
          <div className="absolute top-0 left-0 w-11 h-11 bg-emerald-500 rounded-full animate-ping scale-150 opacity-40" />
        </div>
      </div>

      {/* MAP ZOOM & CONTROLS */}
      <div className="absolute right-5 bottom-44 flex flex-col gap-3.5 z-30">
        <button 
          onClick={() => handleZoom('in')}
          className="w-11 h-11 bg-white dark:bg-slate-900 border border-slate-100 dark:border-slate-800 shadow-lg rounded-full flex items-center justify-center text-slate-700 dark:text-slate-200 hover:scale-105 active:scale-95 transition-all"
          title="Zoom In"
        >
          <Plus className="w-5 h-5" />
        </button>
        <button 
          onClick={() => handleZoom('out')}
          className="w-11 h-11 bg-white dark:bg-slate-900 border border-slate-100 dark:border-slate-800 shadow-lg rounded-full flex items-center justify-center text-slate-700 dark:text-slate-200 hover:scale-105 active:scale-95 transition-all"
          title="Zoom Out"
        >
          <Minus className="w-5 h-5" />
        </button>
        <button 
          onClick={toggleMapStyle}
          className="w-11 h-11 bg-white dark:bg-slate-900 border border-slate-100 dark:border-slate-800 shadow-lg rounded-full flex items-center justify-center text-slate-700 dark:text-slate-200 hover:scale-105 active:scale-95 transition-all"
          title="Toggle Map Style"
        >
          <Layers className={`w-5 h-5 ${mapStyle === 'dark' ? 'text-emerald-500' : 'text-slate-500 dark:text-slate-400'}`} />
        </button>
        <button 
          onClick={() => showToast('Re-centering map direction to GPS heading', 'success')}
          className="w-11 h-11 bg-emerald-600 shadow-xl rounded-full flex items-center justify-center text-white hover:scale-105 active:scale-95 transition-all"
          title="Recenter Map"
        >
          <Navigation className="w-5 h-5 fill-white rotate-45" />
        </button>
      </div>

      {/* NAVIGATION FOOTER CARD */}
      <footer className="absolute bottom-0 left-0 w-full z-30 bg-white/95 dark:bg-slate-900/95 backdrop-blur-md rounded-t-[32px] shadow-[0_-8px_30px_rgba(0,0,0,0.12)] border-t border-slate-100 dark:border-slate-800/35 px-5 pb-5 pt-3 select-none flex flex-col">
        {/* Swipe Handle Indicator */}
        <div className="w-12 h-1.5 bg-slate-200 dark:bg-slate-800 rounded-full mx-auto mb-4" />

        {/* Primary Stats */}
        <div className="flex justify-between items-end mb-5">
          <div>
            <div className="flex items-baseline gap-1">
              <span className="text-2xl font-black text-emerald-600 dark:text-emerald-400">12</span>
              <span className="text-[10px] font-bold text-slate-400 dark:text-slate-500 tracking-wider">MIN</span>
            </div>
            <p className="text-xs text-slate-500 dark:text-slate-400 font-semibold mt-0.5">
              Arrival: 14:42
            </p>
          </div>
          
          <div className="text-right">
            <div className="flex items-baseline justify-end gap-1">
              <span className="text-2xl font-black text-slate-800 dark:text-white">3.4</span>
              <span className="text-[10px] font-bold text-slate-400 dark:text-slate-500 tracking-wider">KM</span>
            </div>
            <p className="text-xs text-slate-500 dark:text-slate-400 font-semibold mt-0.5 truncate max-w-[160px]">
              Destination: 242 Market St
            </p>
          </div>
        </div>

        {/* Quick Actions Grid */}
        <div className="grid grid-cols-2 gap-3">
          <button 
            onClick={handleSupport}
            className="flex items-center justify-center gap-1.5 py-3 rounded-xl border border-slate-200 dark:border-slate-850 hover:bg-slate-50 dark:hover:bg-slate-800/50 text-slate-600 dark:text-slate-300 font-bold text-xs transition-colors"
          >
            <HelpCircle className="w-4 h-4 text-emerald-600" />
            <span>Support Help</span>
          </button>
          
          <button 
            onClick={handleExit}
            className="flex items-center justify-center gap-1.5 py-3 rounded-xl bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs shadow-sm active:scale-95 transition-transform"
          >
            <X className="w-4 h-4" />
            <span>Exit Route</span>
          </button>
        </div>
      </footer>
    </motion.div>
  );
}
