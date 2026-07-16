import React, { useState } from 'react';
import { 
  Sun, 
  Moon, 
  Bell, 
  Search, 
  MapPin, 
  ShieldCheck, 
  Laptop, 
  User,
  Settings,
  LogOut,
  Sparkles
} from 'lucide-react';
import { Screen } from '../types';

interface HeaderProps {
  activeScreen: Screen;
  isDarkMode: boolean;
  toggleDarkMode: () => void;
  userEmail?: string;
}

export default function Header({ activeScreen, isDarkMode, toggleDarkMode, userEmail = "blessmannewton0@gmail.com" }: HeaderProps) {
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const [showNotifications, setShowNotifications] = useState(false);

  // Get display title based on active screen
  const getScreenTitle = () => {
    switch (activeScreen) {
      case 'fleet': return 'Fleet Monitoring';
      case 'dashboard': return 'SwiftDrop Dashboard';
      case 'cosmetics': return 'Cosmetics Inventory';
      case 'wallet': return 'Financial Reports';
      case 'reports': return 'System Analytics';
      case 'security': return 'Audit & Security';
      default: return 'SwiftDrop';
    }
  };

  const notificationItems = [
    { id: 1, text: "Region Delay: Central Hub causing 15m delay", type: "critical" },
    { id: 2, text: "Server Load High: Scaling active (CPU 85%)", type: "warning" },
    { id: 3, text: "Daily payout totals successfully processed", type: "info" }
  ];

  return (
    <header className="sticky top-0 z-40 flex items-center justify-between w-full px-4 py-3 bg-surface-container-lowest/80 backdrop-blur-md border-b border-outline-variant/30 transition-all duration-300">
      {/* Left Title & Indicator */}
      <div className="flex items-center gap-3">
        <div className="p-2 bg-primary/10 rounded-full text-primary">
          <MapPin className="w-5 h-5" />
        </div>
        <div>
          <h2 className="text-lg md:text-xl font-bold text-on-surface tracking-tight transition-all">
            {getScreenTitle()}
          </h2>
          <div className="hidden sm:flex items-center gap-1.5 mt-0.5 text-xs text-on-surface-variant">
            <span className="w-1.5 h-1.5 bg-primary rounded-full animate-pulse"></span>
            <span>Live Telemetry Connected</span>
          </div>
        </div>
      </div>

      {/* Right Controls */}
      <div className="flex items-center gap-2">
        {/* Search input - Hidden on small screens */}
        <div className="hidden md:flex items-center gap-2 px-3 py-1.5 bg-surface-container-low border border-outline-variant/30 rounded-full focus-within:border-primary transition-all duration-200">
          <Search className="w-4 h-4 text-outline" />
          <input 
            type="text" 
            placeholder="Search riders, hubs or logs..." 
            className="w-44 bg-transparent border-none text-sm focus:outline-none focus:ring-0 text-on-surface placeholder-outline/60"
          />
        </div>

        {/* Theme Toggle Button */}
        <button 
          onClick={toggleDarkMode}
          title={isDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode"}
          className="p-2.5 text-on-surface-variant hover:text-primary hover:bg-surface-container-high rounded-full transition-all active:scale-95 duration-200 cursor-pointer"
        >
          {isDarkMode ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
        </button>

        {/* Notifications Icon with Badge */}
        <div className="relative">
          <button 
            onClick={() => {
              setShowNotifications(!showNotifications);
              setShowProfileMenu(false);
            }}
            className="p-2.5 text-on-surface-variant hover:text-primary hover:bg-surface-container-high rounded-full transition-all active:scale-95 duration-200 cursor-pointer"
          >
            <Bell className="w-5 h-5" />
            <span className="absolute top-2.5 right-2.5 w-2 h-2 bg-error rounded-full ring-2 ring-surface-container-lowest"></span>
          </button>

          {/* Notifications Dropdown */}
          {showNotifications && (
            <div className="absolute right-0 mt-2 w-80 bg-surface-container-lowest border border-outline-variant/50 rounded-xl shadow-xl py-2 z-50 animate-in fade-in slide-in-from-top-3 duration-200">
              <div className="px-4 py-2 border-b border-outline-variant/30 flex justify-between items-center">
                <span className="font-semibold text-sm text-on-surface">System Alerts</span>
                <span className="text-[10px] text-error font-bold uppercase bg-error/10 px-1.5 py-0.5 rounded">
                  2 Active
                </span>
              </div>
              <div className="max-h-60 overflow-y-auto">
                {notificationItems.map(item => (
                  <div key={item.id} className="px-4 py-3 hover:bg-surface-container-low transition-colors border-b border-outline-variant/10 last:border-0">
                    <p className="text-xs text-on-surface-variant leading-normal">
                      {item.text}
                    </p>
                    <span className={`text-[9px] font-bold uppercase mt-1 inline-block ${
                      item.type === 'critical' ? 'text-error' : item.type === 'warning' ? 'text-tertiary' : 'text-primary'
                    }`}>
                      {item.type}
                    </span>
                  </div>
                ))}
              </div>
              <div className="px-4 py-1.5 text-center border-t border-outline-variant/30">
                <button 
                  onClick={() => setShowNotifications(false)}
                  className="text-xs text-primary font-medium hover:underline cursor-pointer"
                >
                  Clear All Notifications
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Profile Avatar Trigger */}
        <div className="relative ml-1">
          <button 
            onClick={() => {
              setShowProfileMenu(!showProfileMenu);
              setShowNotifications(false);
            }}
            className="flex items-center focus:outline-none cursor-pointer"
          >
            <div className="w-8 h-8 rounded-full border-2 border-primary/40 overflow-hidden hover:border-primary transition-all duration-300">
              <img 
                src="https://lh3.googleusercontent.com/aida-public/AB6AXuDuw5F0hIultYeIx6TzWHIdaWXsYLKjwB5iydqMHoZNfrpJgPeLB9bXegP63ArbfsT62SefGG7usi4KXNYViIio1bZ9G5A8cPTnkfceOhqdATwxQZoEXW3yxyVelVj0T6s-o8nnEHW89biKw3yKuauOiarK3qnW-g9Ss4Sb-un6GlyWuj6qm4mRs_f0X69aMoUgCR3Jrl-JbHl6SBdNUcgar91L9Qsqp6vDuOZLV3_b8Q0QXYCA35BoVEtjlG73bpWzwVRcHM4Y_HM" 
                alt="Profile Avatar" 
                className="w-full h-full object-cover"
                referrerPolicy="no-referrer"
              />
            </div>
          </button>

          {/* Profile Dropdown Menu */}
          {showProfileMenu && (
            <div className="absolute right-0 mt-2 w-72 bg-surface-container-lowest border border-outline-variant/50 rounded-xl shadow-xl py-3 z-50 animate-in fade-in slide-in-from-top-3 duration-200">
              {/* Profile Header */}
              <div className="px-4 pb-3 border-b border-outline-variant/30">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full overflow-hidden bg-primary/10 border border-primary/20">
                    <img 
                      src="https://lh3.googleusercontent.com/aida-public/AB6AXuDuw5F0hIultYeIx6TzWHIdaWXsYLKjwB5iydqMHoZNfrpJgPeLB9bXegP63ArbfsT62SefGG7usi4KXNYViIio1bZ9G5A8cPTnkfceOhqdATwxQZoEXW3yxyVelVj0T6s-o8nnEHW89biKw3yKuauOiarK3qnW-g9Ss4Sb-un6GlyWuj6qm4mRs_f0X69aMoUgCR3Jrl-JbHl6SBdNUcgar91L9Qsqp6vDuOZLV3_b8Q0QXYCA35BoVEtjlG73bpWzwVRcHM4Y_HM" 
                      alt="Profile Avatar" 
                      className="w-full h-full object-cover"
                      referrerPolicy="no-referrer"
                    />
                  </div>
                  <div>
                    <h4 className="font-bold text-sm text-on-surface truncate">Admin Lead</h4>
                    <p className="text-xs text-on-surface-variant truncate">{userEmail}</p>
                  </div>
                </div>
                <div className="mt-2.5 flex items-center gap-1 bg-primary/10 rounded-lg p-1.5 text-[10px] font-bold text-primary">
                  <Sparkles className="w-3.5 h-3.5" />
                  <span>SwiftDrop Enterprise Admin v1.0.2</span>
                </div>
              </div>

              {/* Menu Items */}
              <div className="py-1 px-2 space-y-0.5">
                <button className="w-full flex items-center gap-3 px-3 py-2 text-sm text-on-surface hover:bg-surface-container-low rounded-lg transition-colors cursor-pointer text-left">
                  <User className="w-4 h-4 text-outline" />
                  <span>My Profile</span>
                </button>
                <button className="w-full flex items-center gap-3 px-3 py-2 text-sm text-on-surface hover:bg-surface-container-low rounded-lg transition-colors cursor-pointer text-left">
                  <Settings className="w-4 h-4 text-outline" />
                  <span>Account Settings</span>
                </button>
                <button className="w-full flex items-center gap-3 px-3 py-2 text-sm text-on-surface hover:bg-surface-container-low rounded-lg transition-colors cursor-pointer text-left">
                  <ShieldCheck className="w-4 h-4 text-outline" />
                  <span>Security Dashboard</span>
                </button>
              </div>

              {/* Logout */}
              <div className="pt-2 px-2 border-t border-outline-variant/30">
                <button className="w-full flex items-center gap-3 px-3 py-2 text-sm text-error hover:bg-error/5 rounded-lg transition-colors cursor-pointer text-left">
                  <LogOut className="w-4 h-4" />
                  <span>Logout Account</span>
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
