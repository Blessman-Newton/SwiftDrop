import { Bell, Sun, Moon, Sparkles } from "lucide-react";
import { MERCHANT_INFO } from "../data";

interface NavbarProps {
  darkMode: boolean;
  onToggleDarkMode: () => void;
  onNavigate: (view: "dashboard" | "orders" | "menu" | "analytics") => void;
  activeView: string;
}

export default function Navbar({ darkMode, onToggleDarkMode, onNavigate, activeView }: NavbarProps) {
  return (
    <header className="sticky top-0 z-40 w-full border-b border-outline-variant/20 bg-surface/95 backdrop-blur-md transition-colors duration-300">
      <div className="mx-auto flex h-16 max-w-[1280px] items-center justify-between px-5">
        
        {/* Brand & Chef Avatar */}
        <div className="flex items-center gap-3">
          <button 
            onClick={() => onNavigate("dashboard")}
            className="group relative h-10 w-10 overflow-hidden rounded-full border border-outline-variant/40 bg-surface-container-highest transition-transform active:scale-95 duration-200"
            title="Go to Dashboard"
          >
            <img 
              className="h-full w-full object-cover transition-transform group-hover:scale-105 duration-300" 
              src={MERCHANT_INFO.chefAvatar} 
              alt="Alex Avatar"
              referrerPolicy="no-referrer"
            />
          </button>
          <div className="flex flex-col">
            <button 
              onClick={() => onNavigate("dashboard")}
              className="text-left font-display text-lg font-bold tracking-tight text-primary transition-opacity hover:opacity-90 dark:text-primary"
            >
              SwiftDrop <span className="text-xs font-semibold px-1.5 py-0.5 rounded-full bg-primary-container/20 text-primary-container dark:text-primary/90 ml-1">Merchant</span>
            </button>
            <span className="text-[10px] text-on-surface-variant font-medium">Alex • {MERCHANT_INFO.name}</span>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center gap-2">
          {/* Quick AI Assist Tip */}
          <div className="hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-primary/10 text-primary border border-primary/20 text-xs font-semibold animate-pulse">
            <Sparkles className="h-3 w-3" />
            <span>AI Powered Speed: +12%</span>
          </div>

          {/* Dark Mode Toggle */}
          <button
            onClick={onToggleDarkMode}
            className="flex h-10 w-10 items-center justify-center rounded-full text-on-surface-variant hover:bg-surface-container-highest active:scale-95 transition-all duration-200"
            title={darkMode ? "Switch to Light Mode" : "Switch to Dark Mode"}
          >
            {darkMode ? (
              <Sun className="h-5 w-5 text-amber-500 animate-spin-slow" />
            ) : (
              <Moon className="h-5 w-5 text-primary" />
            )}
          </button>

          {/* Notification Button */}
          <div className="relative">
            <button
              className="flex h-10 w-10 items-center justify-center rounded-full text-on-surface-variant hover:bg-surface-container-highest active:scale-95 transition-all duration-200"
              title="Notifications"
            >
              <Bell className="h-5 w-5 text-primary" />
              <span className="absolute top-2 right-2 flex h-2.5 w-2.5">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary-container opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-primary-container"></span>
              </span>
            </button>
          </div>
        </div>

      </div>
    </header>
  );
}
