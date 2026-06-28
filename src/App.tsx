import { useState, useEffect } from "react";
import Navbar from "./components/Navbar";
import DashboardView from "./components/DashboardView";
import OrdersView from "./components/OrdersView";
import MenuView from "./components/MenuView";
import AnalyticsView from "./components/AnalyticsView";

import { MenuItem, Order, OrderStatus } from "./types";
import { INITIAL_MENU_ITEMS, INITIAL_ORDERS } from "./data";
import { motion, AnimatePresence } from "motion/react";
import { 
  LayoutDashboard, 
  ClipboardList, 
  Utensils, 
  TrendingUp,
  Smartphone,
  Laptop,
  Sparkles,
  Wifi,
  Battery,
  Volume2,
  Moon,
  Sun,
  AlertCircle
} from "lucide-react";

export default function App() {
  const [activeView, setActiveView] = useState<"dashboard" | "orders" | "menu" | "analytics">("dashboard");
  const [darkMode, setDarkMode] = useState<boolean>(() => {
    const saved = localStorage.getItem("swift_drop_dark_mode");
    return saved === "true";
  });
  
  // Store status
  const [isOnline, setIsOnline] = useState(true);

  // Core Data States
  const [menuItems, setMenuItems] = useState<MenuItem[]>(INITIAL_MENU_ITEMS);
  const [orders, setOrders] = useState<Order[]>(INITIAL_ORDERS);

  // Preview container frame mode
  // "split" (Desktop Admin on left, interactive smartphone on right), "mobile" (Smartphone only), "web" (Standard fluid page)
  const [previewMode, setPreviewMode] = useState<"split" | "mobile" | "web">("split");

  // Synchronize Dark Mode HTML class
  useEffect(() => {
    const root = window.document.documentElement;
    if (darkMode) {
      root.classList.add("dark");
    } else {
      root.classList.remove("dark");
    }
    localStorage.setItem("swift_drop_dark_mode", String(darkMode));
  }, [darkMode]);

  // Real-time ticking effect for active orders elapsed timers
  useEffect(() => {
    const interval = setInterval(() => {
      setOrders((prevOrders) =>
        prevOrders.map((order) => {
          if (
            order.status === "new" ||
            order.status === "preparing" ||
            order.status === "awaiting_pickup"
          ) {
            return { ...order, elapsedSeconds: order.elapsedSeconds + 1 };
          }
          return order;
        })
      );
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  // Handlers
  const handleToggleOnline = () => {
    setIsOnline(!isOnline);
  };

  const handleToggleStock = (itemId: string) => {
    setMenuItems((prev) =>
      prev.map((item) =>
        item.id === itemId ? { ...item, inStock: !item.inStock } : item
      )
    );
  };

  const handleAddItem = (newItem: Omit<MenuItem, "id" | "soldCount" | "soldTrend">) => {
    const item: MenuItem = {
      ...newItem,
      id: `m-${Date.now()}`,
      soldCount: 0,
      soldTrend: "0%"
    };
    setMenuItems((prev) => [item, ...prev]);
  };

  const handleUpdateItem = (itemId: string, updatedFields: Partial<MenuItem>) => {
    setMenuItems((prev) =>
      prev.map((item) =>
        item.id === itemId ? { ...item, ...updatedFields } : item
      )
    );
  };

  const handleDeleteItem = (itemId: string) => {
    setMenuItems((prev) => prev.filter((item) => item.id !== itemId));
  };

  const handleUpdateOrderStatus = (orderId: string, newStatus: OrderStatus) => {
    setOrders((prev) =>
      prev.map((order) => {
        if (order.id === orderId) {
          let extra: Partial<Order> = {};
          if (newStatus === "preparing" && !order.driverName) {
            extra = {
              driverName: "Searching Driver...",
              driverStatus: "Assigning soon"
            };
          } else if (newStatus === "awaiting_pickup") {
            extra = {
              driverName: "Marcus Chen",
              driverStatus: "Arriving in 2m"
            };
          } else if (newStatus === "completed") {
            extra = {
              driverStatus: "Completed"
            };
          }
          return { ...order, status: newStatus, ...extra };
        }
        return order;
      })
    );
  };

  // Render correct inner page based on dynamic view
  const renderViewContent = () => {
    switch (activeView) {
      case "orders":
        return (
          <OrdersView 
            orders={orders} 
            onUpdateOrderStatus={handleUpdateOrderStatus}
            onNavigate={setActiveView}
          />
        );
      case "menu":
        return (
          <MenuView 
            menuItems={menuItems} 
            onToggleStock={handleToggleStock}
            onAddItem={handleAddItem}
            onUpdateItem={handleUpdateItem}
            onDeleteItem={handleDeleteItem}
          />
        );
      case "analytics":
        return <AnalyticsView menuItems={menuItems} />;
      case "dashboard":
      default:
        return (
          <DashboardView 
            isOnline={isOnline}
            onToggleOnline={handleToggleOnline}
            orders={orders}
            onUpdateOrderStatus={handleUpdateOrderStatus}
            onNavigate={setActiveView}
          />
        );
    }
  };

  // Bottom navigation elements list
  const navItems = [
    { id: "dashboard", label: "Dashboard", icon: LayoutDashboard },
    { id: "orders", label: "Orders", icon: ClipboardList },
    { id: "menu", label: "Menu", icon: Utensils },
    { id: "analytics", label: "Analytics", icon: TrendingUp },
  ];

  return (
    <div className="min-h-screen bg-background text-on-background flex flex-col transition-colors duration-300">
      
      {/* Top Level Preview Control Bar - Promotes Premium Layout Presentation */}
      <div className="bg-surface-container-high border-b border-outline-variant/30 px-5 py-2.5 flex flex-wrap justify-between items-center gap-3 text-xs font-bold dark:bg-surface-container-highest">
        <div className="flex items-center gap-2 text-primary">
          <Sparkles className="h-4 w-4 shrink-0" />
          <span>Interactive SwiftDrop Merchant Portal (React 19)</span>
        </div>

        {/* Presentation modes buttons */}
        <div className="flex items-center bg-surface-container rounded-lg p-0.5 border border-outline-variant/20 dark:bg-surface-container-low">
          <button
            onClick={() => setPreviewMode("split")}
            className={`px-3 py-1.5 rounded-md flex items-center gap-1.5 transition-all ${
              previewMode === "split" 
                ? "bg-surface-container-lowest text-primary shadow-sm dark:bg-surface-container-high" 
                : "text-on-surface-variant hover:text-on-surface"
            }`}
          >
            <Laptop className="h-3.5 w-3.5" />
            <span className="hidden sm:inline">Split Presentation</span>
          </button>
          <button
            onClick={() => setPreviewMode("mobile")}
            className={`px-3 py-1.5 rounded-md flex items-center gap-1.5 transition-all ${
              previewMode === "mobile" 
                ? "bg-surface-container-lowest text-primary shadow-sm dark:bg-surface-container-high" 
                : "text-on-surface-variant hover:text-on-surface"
            }`}
          >
            <Smartphone className="h-3.5 w-3.5" />
            <span className="hidden sm:inline">Mobile Mockup</span>
          </button>
          <button
            onClick={() => setPreviewMode("web")}
            className={`px-3 py-1.5 rounded-md flex items-center gap-1.5 transition-all ${
              previewMode === "web" 
                ? "bg-surface-container-lowest text-primary shadow-sm dark:bg-surface-container-high" 
                : "text-on-surface-variant hover:text-on-surface"
            }`}
          >
            <Laptop className="h-3.5 w-3.5" />
            <span className="hidden sm:inline">Responsive Web Only</span>
          </button>
        </div>
      </div>

      {/* Render based on layout preview modes */}
      <div className="flex-1 flex flex-col md:flex-row max-w-[1536px] w-full mx-auto">
        
        {/* LEFT COMPONENT: Responsive Desktop / Main Application layout */}
        {previewMode !== "mobile" && (
          <div className={`flex-1 flex flex-col ${previewMode === "split" ? "lg:max-w-[65%]" : "w-full"}`}>
            <Navbar 
              darkMode={darkMode} 
              onToggleDarkMode={() => setDarkMode(!darkMode)} 
              onNavigate={setActiveView}
              activeView={activeView}
            />

            {/* Desktop Side Bar / Header Info Panel */}
            <div className="flex-1 flex">
              {/* Desktop Sidebar menu */}
              <aside className="hidden md:flex flex-col border-r border-outline-variant/20 bg-surface-container-low w-24 py-8 items-center gap-6 shrink-0">
                {navItems.map((item) => {
                  const Icon = item.icon;
                  const isActive = activeView === item.id;
                  return (
                    <button
                      key={item.id}
                      onClick={() => setActiveView(item.id as any)}
                      className="flex flex-col items-center gap-1 group w-20 py-2.5 rounded-2xl hover:bg-surface-container transition-all active:scale-95 text-center relative"
                    >
                      <div className={`p-3 rounded-2xl transition-all ${
                        isActive 
                          ? "bg-primary-container text-on-primary-container font-extrabold" 
                          : "text-on-surface-variant group-hover:text-primary"
                      }`}>
                        <Icon className="h-5 w-5" />
                      </div>
                      <span className={`text-[10px] font-bold ${
                        isActive ? "text-primary" : "text-on-surface-variant"
                      }`}>
                        {item.label}
                      </span>
                      {isActive && (
                        <span className="absolute left-1.5 top-1/2 -translate-y-1/2 w-1 h-8 rounded-r-full bg-primary" />
                      )}
                    </button>
                  );
                })}
              </aside>

              {/* Core Content Container view */}
              <main className="flex-1 px-5 py-6 overflow-y-auto max-w-[1280px]">
                <AnimatePresence mode="wait">
                  <motion.div
                    key={activeView}
                    initial={{ opacity: 0, y: 15 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -15 }}
                    transition={{ duration: 0.2 }}
                    className="h-full"
                  >
                    {renderViewContent()}
                  </motion.div>
                </AnimatePresence>
              </main>
            </div>

            {/* Mobile Bottom Navigation Bar (Visible only on mobile screen widths) */}
            <nav className="md:hidden sticky bottom-0 left-0 w-full h-20 bg-surface border-t border-outline-variant/20 flex justify-around items-center px-4 pb-safe z-40 transition-colors">
              {navItems.map((item) => {
                const Icon = item.icon;
                const isActive = activeView === item.id;
                return (
                  <button
                    key={item.id}
                    onClick={() => setActiveView(item.id as any)}
                    className={`flex flex-col items-center justify-center px-4 py-1.5 transition-all duration-150 active:scale-90 ${
                      isActive 
                        ? "bg-primary-container text-on-primary-container rounded-2xl font-black px-5 py-2 scale-105 shadow-sm" 
                        : "text-on-surface-variant hover:text-primary"
                    }`}
                  >
                    <Icon className="h-5 w-5" />
                    <span className="text-[10px] font-bold mt-1 leading-none">{item.label}</span>
                  </button>
                );
              })}
            </nav>
          </div>
        )}

        {/* RIGHT COMPONENT: 3D-styled interactive Smartphone Mockup Frame */}
        {previewMode !== "web" && (
          <div className={`flex-1 flex items-center justify-center p-6 bg-surface-container-low border-l border-outline-variant/10 dark:bg-surface-container-lowest ${
            previewMode === "mobile" ? "w-full" : "hidden lg:flex"
          }`}>
            <div className="relative mx-auto w-[370px] h-[780px] rounded-[52px] bg-neutral-900 p-3.5 shadow-2xl border-4 border-neutral-800 flex flex-col overflow-hidden ring-1 ring-white/10">
              
              {/* Speaker Bezel & Dynamic Island Notch */}
              <div className="absolute top-0 left-1/2 -translate-x-1/2 h-8 w-44 bg-neutral-900 rounded-b-2xl z-50 flex items-center justify-center">
                <div className="w-16 h-3 bg-neutral-950 rounded-full" />
                <div className="w-3.5 h-3.5 bg-neutral-950 rounded-full ml-3" />
              </div>

              {/* Smartphone Display Content Screen */}
              <div className="flex-1 rounded-[38px] bg-background text-on-background overflow-hidden relative flex flex-col border border-neutral-950/20 select-none">
                
                {/* Simulated Smartphone Status Bar */}
                <div className="h-10 bg-surface px-6 flex items-center justify-between text-[11px] font-bold text-on-surface-variant z-40 border-b border-outline-variant/10 transition-colors">
                  <span>12:55 PM</span>
                  <div className="flex items-center gap-1.5">
                    <Wifi className="h-3 w-3" />
                    <span>5G</span>
                    <Battery className="h-3.5 w-3.5 text-primary-container" />
                  </div>
                </div>

                {/* Smartphone Custom Inner Top Navbar */}
                <div className="h-14 bg-surface flex items-center justify-between px-5 z-40 border-b border-outline-variant/10">
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 rounded-full border border-outline-variant/30 overflow-hidden">
                      <img className="h-full w-full object-cover" src={INITIAL_MENU_ITEMS[0].image} alt="Chef" />
                    </div>
                    <span className="font-display font-extrabold text-sm text-primary">SwiftDrop</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <button 
                      onClick={() => setDarkMode(!darkMode)}
                      className="p-1.5 text-on-surface-variant hover:bg-surface-container rounded-full"
                    >
                      {darkMode ? <Sun className="h-3.5 w-3.5 text-amber-400" /> : <Moon className="h-3.5 w-3.5 text-primary" />}
                    </button>
                    <span className="h-2 w-2 rounded-full bg-primary-container animate-pulse" />
                  </div>
                </div>

                {/* Smartphone Main View Scrollbox */}
                <div className="flex-1 overflow-y-auto px-4 py-4 pb-20 no-scrollbar">
                  <AnimatePresence mode="wait">
                    <motion.div
                      key={activeView}
                      initial={{ opacity: 0, y: 15 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -15 }}
                      transition={{ duration: 0.15 }}
                    >
                      {renderViewContent()}
                    </motion.div>
                  </AnimatePresence>
                </div>

                {/* Smartphone Simulated Bottom Navigation Bar */}
                <nav className="absolute bottom-0 left-0 w-full h-18 bg-surface/90 backdrop-blur-md border-t border-outline-variant/20 flex justify-around items-center px-2 pb-safe z-45 shadow-[0_-4px_10px_rgba(0,0,0,0.03)]">
                  {navItems.map((item) => {
                    const Icon = item.icon;
                    const isActive = activeView === item.id;
                    return (
                      <button
                        key={item.id}
                        onClick={() => setActiveView(item.id as any)}
                        className={`flex flex-col items-center justify-center px-3 py-1 transition-all duration-150 active:scale-90 ${
                          isActive 
                            ? "bg-primary-container text-on-primary-container rounded-xl font-bold px-4 py-1.5 scale-105" 
                            : "text-on-surface-variant"
                        }`}
                      >
                        <Icon className="h-4 w-4" />
                        <span className="text-[9px] font-bold mt-0.5 leading-none">{item.label}</span>
                      </button>
                    );
                  })}
                </nav>

              </div>
            </div>
          </div>
        )}

      </div>
    </div>
  );
}
