import React from 'react';
import { 
  LayoutDashboard, 
  Map, 
  Wallet, 
  LineChart, 
  ShieldAlert, 
  Sparkles,
  Info
} from 'lucide-react';
import { Screen } from '../types';

interface NavigationProps {
  activeScreen: Screen;
  setActiveScreen: (screen: Screen) => void;
  isDarkMode: boolean;
}

export default function Navigation({ activeScreen, setActiveScreen, isDarkMode }: NavigationProps) {
  // Navigation Menu Options
  const navItems = [
    { id: 'fleet' as Screen, label: 'Fleet Map', icon: Map, desc: 'Real-time telemetry & hubs' },
    { id: 'dashboard' as Screen, label: 'Dashboard', icon: LayoutDashboard, desc: 'Overview & system KPIs' },
    { id: 'cosmetics' as Screen, label: 'Cosmetics', icon: Sparkles, desc: 'Manage cosmetics inventory' },
    { id: 'wallet' as Screen, label: 'Financials', icon: Wallet, desc: 'Revenue, payouts & audits' },
    { id: 'reports' as Screen, label: 'Analytics', icon: LineChart, desc: 'SLA, retention & performance' },
    { id: 'security' as Screen, label: 'Audit Logs', icon: ShieldAlert, desc: 'Security, changes & entries' },
  ];

  return (
    <>
      {/* Desktop Navigation Drawer (Shared Sidebar Shell) */}
      <aside className="hidden md:flex flex-col h-screen fixed left-0 top-0 py-6 px-4 bg-surface-container-low border-r border-outline-variant/30 w-64 z-30 transition-all duration-300">
        {/* Brand Header */}
        <div className="mb-8 px-2">
          <div className="flex items-center gap-2">
            <span className="font-extrabold text-2xl text-primary tracking-tight">SwiftDrop</span>
            <span className="text-[9px] bg-primary/10 text-primary px-1.5 py-0.5 rounded-full font-bold uppercase tracking-wider">
              Lead
            </span>
          </div>
          <p className="text-on-surface-variant text-[11px] font-semibold tracking-wider uppercase mt-1 opacity-70">
            Logistics v1.0.2
          </p>
        </div>

        {/* Sidebar Nav Items */}
        <nav className="flex-1 space-y-1.5">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeScreen === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveScreen(item.id)}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl text-left cursor-pointer transition-all duration-200 group relative ${
                  isActive 
                    ? 'bg-primary text-on-primary font-bold shadow-md shadow-primary/10' 
                    : 'text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface'
                }`}
              >
                <Icon className={`w-5 h-5 shrink-0 transition-transform duration-300 group-hover:scale-110 ${
                  isActive ? 'text-on-primary' : 'text-outline group-hover:text-primary'
                }`} />
                <div>
                  <div className="text-sm leading-none">{item.label}</div>
                  <div className={`text-[10px] mt-0.5 font-normal transition-opacity duration-200 ${
                    isActive ? 'text-on-primary/80' : 'text-on-surface-variant/60 group-hover:text-on-surface-variant/80'
                  }`}>
                    {item.desc}
                  </div>
                </div>
                {/* Active Bar indicator */}
                {isActive && (
                  <span className="absolute right-3 top-1/2 -translate-y-1/2 w-1.5 h-1.5 bg-on-primary rounded-full"></span>
                )}
              </button>
            );
          })}
        </nav>

        {/* Footer Admin Card */}
        <div className="mt-auto p-4 bg-surface-container rounded-2xl border border-outline-variant/20 flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-primary/10 border-2 border-primary overflow-hidden shrink-0">
            <img 
              className="w-full h-full object-cover" 
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuDqfkis-kCnLF84fno594JJdVwbsa-C83tko7CzbtqjS8xMfhyELgb_H59rze3WgN7De0l8-g5OmahJ97AygcLKJsVU5dvMNT9kBPYP2XbSfwQGV6bxe98WSrcJPOWyqfcM8EcfC9lBB7weTt5oULlt427Kgz03toHVB93dQJBa9f2gGyxocssHfa0EvIdI2uO80oBed4AxVlMO2es8QO4Qyh6nJ5QDysD_BDexGiJsgsjwapDkC71jqrurHDGXQwIZE8OO-ODRmhw" 
              alt="Admin Profile" 
              referrerPolicy="no-referrer"
            />
          </div>
          <div className="min-w-0">
            <p className="font-bold text-xs text-on-surface truncate">Admin Lead</p>
            <p className="text-[10px] text-on-surface-variant/70 truncate flex items-center gap-1 uppercase tracking-wider">
              <span className="w-1.5 h-1.5 bg-primary rounded-full"></span> Active Ops
            </p>
          </div>
        </div>
      </aside>

      {/* Bottom Navigation Bar (Mobile Only Shared Component) */}
      <nav className="md:hidden fixed bottom-0 left-0 w-full z-50 flex justify-around items-center px-2 pb-5 pt-2 bg-surface-container-lowest/90 backdrop-blur-md shadow-[0_-4px_16px_rgba(0,0,0,0.06)] border-t border-outline-variant/30 rounded-t-2xl">
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeScreen === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setActiveScreen(item.id)}
              className={`flex flex-col items-center justify-center py-1.5 px-3 rounded-full cursor-pointer transition-all duration-300 relative ${
                isActive 
                  ? 'text-primary scale-110 font-bold' 
                  : 'text-on-surface-variant/80 hover:text-on-surface'
              }`}
            >
              <Icon className={`w-5 h-5 shrink-0 ${isActive ? 'text-primary fill-primary/10' : 'text-outline'}`} />
              <span className="text-[10px] tracking-tight mt-1">{item.label.split(' ')[0]}</span>
              
              {isActive && (
                <span className="absolute -bottom-1 w-1 h-1 bg-primary rounded-full"></span>
              )}
            </button>
          );
        })}
      </nav>
    </>
  );
}
