import { useState, useEffect } from "react";
import Navbar from "./components/Navbar";
import DashboardView from "./components/DashboardView";
import OrdersView from "./components/OrdersView";
import MenuView from "./components/MenuView";
import AnalyticsView from "./components/AnalyticsView";
import OnboardingView from "./components/OnboardingView";
import SettingsView from "./components/SettingsView";
import type { OnboardingData } from "./components/OnboardingView";

import { MenuItem, Order, OrderStatus, Category, Restaurant } from "./types";
import { motion, AnimatePresence } from "motion/react";
import { 
  LayoutDashboard, 
  ClipboardList, 
  Utensils, 
  TrendingUp,
  Settings,
  Smartphone,
  Laptop,
  Sparkles,
  Wifi,
  Battery,
  Moon,
  Sun,
  AlertCircle,
  Phone,
  KeyRound
} from "lucide-react";
import * as api from "./api";

export default function App() {
  const [activeView, setActiveView] = useState<"dashboard" | "orders" | "menu" | "analytics" | "settings">("dashboard");
  const [darkMode, setDarkMode] = useState<boolean>(() => {
    const saved = localStorage.getItem("swift_drop_dark_mode");
    return saved === "true";
  });
  
  const [isOnline, setIsOnline] = useState(true);

  const [isLoggedIn, setIsLoggedIn] = useState(() => api.isAuthenticated());
  const [authMode, setAuthMode] = useState<'login' | 'signup'>('login');
  const [usePhoneLogin, setUsePhoneLogin] = useState(false);
  const [authEmail, setAuthEmail] = useState("");
  const [authPassword, setAuthPassword] = useState("");
  const [authPhone, setAuthPhone] = useState("");
  const [authName, setAuthName] = useState("");
  const [authCode, setAuthCode] = useState("");
  const [authStep, setAuthStep] = useState<"form" | "otp">("form");
  const [authLoading, setAuthLoading] = useState(false);
  const [authError, setAuthError] = useState("");
  const [devCode, setDevCode] = useState("");

  const [menuItems, setMenuItems] = useState<MenuItem[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [restaurant, setRestaurant] = useState<Restaurant | null>(null);
  const [needsOnboarding, setNeedsOnboarding] = useState(false);
  const [onboardingLoading, setOnboardingLoading] = useState(false);
  const [settingsLoading, setSettingsLoading] = useState(false);
  const [merchantInfo, setMerchantInfo] = useState<{restaurant_name: string; merchant_name: string; avatar_url: string} | null>(null);
  const [dashboardStats, setDashboardStats] = useState<{total_orders_today: number; total_earnings_today: number; avg_preparation_time: number; cancelled_orders: number; active_orders: number; completed_orders: number} | null>(null);

  const [previewMode, setPreviewMode] = useState<"split" | "mobile" | "web">("split");

  useEffect(() => {
    const root = window.document.documentElement;
    if (darkMode) {
      root.classList.add("dark");
    } else {
      root.classList.remove("dark");
    }
    localStorage.setItem("swift_drop_dark_mode", String(darkMode));
  }, [darkMode]);

  useEffect(() => {
    if (!isLoggedIn) return;

    async function loadData() {
      try {
        // Fetch categories first (always available, no auth dependency on restaurant)
        try {
          const catData = await api.getCategories();
          setCategories(catData);
        } catch (e) {
          console.error("Failed to load categories:", e);
        }

        // Check onboarding status from localStorage
        const onboardingData = localStorage.getItem('swiftdrop_merchant_onboarding');
        let onboardingCompleted = false;
        if (onboardingData) {
          try {
            const parsed = JSON.parse(onboardingData);
            onboardingCompleted = parsed.completed === true;
          } catch (e) {
            console.error("Failed to parse onboarding data:", e);
          }
        }

        // Fetch merchant-specific data (may 404 if no restaurant exists yet)
        let restaurantData: Restaurant | null = null;
        try {
          restaurantData = await api.getRestaurant();
          setRestaurant(restaurantData);
          // Only show onboarding if not completed AND restaurant has default values
          if (!onboardingCompleted) {
            const isDefaultName = /^Restaurant \d{4}$/.test(restaurantData.name);
            const isDefaultAddress = restaurantData.address === "Accra, Ghana";
            setNeedsOnboarding(isDefaultName || isDefaultAddress);
          } else {
            setNeedsOnboarding(false);
          }
        } catch (e) {
          console.error("No restaurant found, needs onboarding:", e);
          // If no restaurant and onboarding not completed, show onboarding
          setNeedsOnboarding(!onboardingCompleted);
        }

        // Fetch menu items
        try {
          const menuData = await api.getMenuItems();
          setMenuItems(menuData.map((item: any) => ({
            id: item.id,
            name: item.name,
            description: item.description || "",
            price: item.price,
            category: item.category_name || "Uncategorized",
            category_id: item.category_id || null,
            category_name: item.category_name || null,
            image: item.image_url || "",
            inStock: item.is_available,
            is_vegetarian: item.is_vegetarian || false,
            is_spicy: item.is_spicy || false,
            tags: item.tags || [],
            soldCount: 0,
            soldTrend: "0%",
          })));
        } catch (e) {
          console.error("Failed to load menu items:", e);
        }

        // Fetch orders
        try {
          const ordersData = await api.getOrders();
          setOrders(ordersData.map((order: any) => ({
            id: order.id,
            orderNo: order.order_no,
            status: order.status,
            customerName: order.customer_name,
            items: order.items,
            total: order.total,
            elapsedSeconds: order.elapsed_seconds,
            createdAtStr: new Date(order.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
            driverName: order.rider_name || null,
            driverStatus: order.rider_name ? (order.status === 'awaiting_pickup' ? 'Arriving' : 'Assigned') : null,
            driverPhone: order.rider_phone || null,
            driverAvatar: order.rider_avatar || null,
          })));
        } catch (e) {
          console.error("Failed to load orders:", e);
        }

        // Fetch merchant info
        try {
          const merchantData = await api.getMerchantInfo();
          setMerchantInfo(merchantData);
        } catch (e) {
          console.error("Failed to load merchant info:", e);
        }

        // Fetch dashboard stats
        try {
          const dashData = await api.getDashboardStats();
          setDashboardStats(dashData);
        } catch (e) {
          console.error("Failed to load dashboard stats:", e);
        }
      } catch (err) {
        console.error("Failed to load data:", err);
      }
    }
    loadData();
  }, [isLoggedIn]);

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

  // Poll for order updates every 15 seconds
  useEffect(() => {
    if (!isLoggedIn) return;
    const pollInterval = setInterval(async () => {
      try {
        const ordersData = await api.getOrders();
        setOrders(ordersData.map((order: any) => ({
          id: order.id,
          orderNo: order.order_no,
          status: order.status,
          customerName: order.customer_name,
          items: order.items,
          total: order.total,
          elapsedSeconds: order.elapsed_seconds,
          createdAtStr: new Date(order.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          driverName: order.rider_name || null,
          driverStatus: order.rider_name ? (order.status === 'awaiting_pickup' ? 'Arriving' : 'Assigned') : null,
          driverPhone: order.rider_phone || null,
          driverAvatar: order.rider_avatar || null,
        })));
      } catch (e) {
        console.error("Failed to poll orders:", e);
      }
    }, 15000);
    return () => clearInterval(pollInterval);
  }, [isLoggedIn]);

  const handleToggleOnline = () => {
    setIsOnline(!isOnline);
  };

  const handleToggleStock = async (itemId: string) => {
    try {
      const result = await api.toggleStock(itemId);
      setMenuItems((prev) =>
        prev.map((item) =>
          item.id === itemId ? { ...item, inStock: result.is_available } : item
        )
      );
    } catch (err) {
      console.error("Failed to toggle stock:", err);
    }
  };

  const handleAddItem = async (newItem: Omit<MenuItem, "id" | "soldCount" | "soldTrend">) => {
    try {
      const created = await api.createMenuItem({
        name: newItem.name,
        description: newItem.description,
        price: newItem.price,
        category_id: newItem.category_id || undefined,
        image_url: newItem.image,
        is_available: newItem.inStock,
        is_vegetarian: newItem.is_vegetarian,
        is_spicy: newItem.is_spicy,
        tags: newItem.tags,
      });
      const item: MenuItem = {
        id: created.id,
        name: created.name,
        description: created.description || "",
        price: created.price,
        category: created.category_name || "Uncategorized",
        category_id: created.category_id || null,
        category_name: created.category_name || null,
        image: created.image_url || "",
        inStock: created.is_available,
        is_vegetarian: created.is_vegetarian,
        is_spicy: created.is_spicy,
        tags: created.tags || [],
        soldCount: 0,
        soldTrend: "0%"
      };
      setMenuItems((prev) => [item, ...prev]);
    } catch (err) {
      console.error("Failed to add item:", err);
    }
  };

  const handleUpdateItem = async (itemId: string, updatedFields: Partial<MenuItem>) => {
    try {
      const updates: Record<string, unknown> = {};
      if (updatedFields.name !== undefined) updates.name = updatedFields.name;
      if (updatedFields.description !== undefined) updates.description = updatedFields.description;
      if (updatedFields.price !== undefined) updates.price = updatedFields.price;
      if (updatedFields.category_id !== undefined) updates.category_id = updatedFields.category_id;
      if (updatedFields.image !== undefined) updates.image_url = updatedFields.image;
      if (updatedFields.inStock !== undefined) updates.is_available = updatedFields.inStock;
      if (updatedFields.is_vegetarian !== undefined) updates.is_vegetarian = updatedFields.is_vegetarian;
      if (updatedFields.is_spicy !== undefined) updates.is_spicy = updatedFields.is_spicy;
      if (updatedFields.tags !== undefined) updates.tags = updatedFields.tags;

      const result = await api.updateMenuItem(itemId, updates);
      setMenuItems((prev) =>
        prev.map((item) => {
          if (item.id === itemId) {
            const updated = { ...item, ...updatedFields };
            if (result.category_name !== undefined) updated.category_name = result.category_name;
            if (result.category_name) updated.category = result.category_name;
            return updated;
          }
          return item;
        })
      );
    } catch (err) {
      console.error("Failed to update item:", err);
    }
  };

  const handleDeleteItem = async (itemId: string) => {
    try {
      await api.deleteMenuItem(itemId);
      setMenuItems((prev) => prev.filter((item) => item.id !== itemId));
    } catch (err) {
      console.error("Failed to delete item:", err);
    }
  };

  const handleUpdateOrderStatus = async (orderId: string, newStatus: OrderStatus) => {
    try {
      const response = await api.updateOrderStatus(orderId, newStatus);
      setOrders((prev) =>
        prev.map((order) => {
          if (order.id === orderId) {
            return {
              ...order,
              status: newStatus,
              driverName: response?.rider_name || order.driverName,
              driverStatus: response?.rider_name
                ? (newStatus === 'awaiting_pickup' ? 'Arriving' : 'Assigned')
                : order.driverStatus,
              driverPhone: response?.rider_phone || order.driverPhone,
              driverAvatar: response?.rider_avatar || order.driverAvatar,
            };
          }
          return order;
        })
      );
    } catch (err) {
      console.error("Failed to update order status:", err);
    }
  };

  const handleEmailLogin = async () => {
    if (!authEmail || !authPassword) {
      setAuthError("Please enter email and password");
      return;
    }
    setAuthLoading(true);
    setAuthError("");
    try {
      const res = await api.loginWithEmail(authEmail, authPassword);
      localStorage.setItem('swiftdrop_merchant_onboarding', JSON.stringify({
        completed: res.user.onboarding_completed
      }));
      setIsLoggedIn(true);
    } catch (err: any) {
      setAuthError(err.message || "Invalid credentials");
    } finally {
      setAuthLoading(false);
    }
  };

  const handleSignup = async () => {
    if (!authEmail || !authPassword || !authPhone) {
      setAuthError("Please fill in all required fields");
      return;
    }
    if (authPassword.length < 8) {
      setAuthError("Password must be at least 8 characters");
      return;
    }
    setAuthLoading(true);
    setAuthError("");
    try {
      const res = await api.signUp(authEmail, authPassword, authPhone, authName || undefined);
      localStorage.setItem('swiftdrop_merchant_onboarding', JSON.stringify({
        completed: res.user.onboarding_completed
      }));
      setIsLoggedIn(true);
    } catch (err: any) {
      setAuthError(err.message || "Signup failed");
    } finally {
      setAuthLoading(false);
    }
  };

  const handleSendOtp = async () => {
    if (!authPhone) return;
    setAuthLoading(true);
    setAuthError("");
    try {
      const res = await api.sendOtp(authPhone);
      setDevCode(res.dev_code || "");
      setAuthStep("otp");
    } catch (err: any) {
      setAuthError(err.message || "Failed to send OTP");
    } finally {
      setAuthLoading(false);
    }
  };

  const handleVerifyOtp = async () => {
    if (!authCode) return;
    setAuthLoading(true);
    setAuthError("");
    try {
      const res = await api.verifyOtp(authPhone, authCode);
      localStorage.setItem('swiftdrop_merchant_onboarding', JSON.stringify({
        completed: res.user.onboarding_completed
      }));
      setIsLoggedIn(true);
    } catch (err: any) {
      setAuthError(err.message || "Invalid code");
    } finally {
      setAuthLoading(false);
    }
  };

  const handleAuthSubmit = () => {
    if (authMode === 'signup') {
      handleSignup();
    } else if (usePhoneLogin) {
      handleSendOtp();
    } else {
      handleEmailLogin();
    }
  };

  const handleLogout = () => {
    api.logout();
    localStorage.removeItem('swiftdrop_merchant_onboarding');
    setIsLoggedIn(false);
    setAuthEmail("");
    setAuthPassword("");
    setAuthPhone("");
    setAuthName("");
    setAuthCode("");
    setAuthStep("form");
    setAuthMode("login");
    setUsePhoneLogin(false);
    setNeedsOnboarding(false);
    setRestaurant(null);
  };

  const handleOnboardingComplete = async (data: OnboardingData) => {
    setOnboardingLoading(true);
    try {
      let updated: Restaurant;
      if (restaurant) {
        // Restaurant exists, update it
        updated = await api.updateRestaurant({
          name: data.name,
          description: data.description || undefined,
          restaurant_type: data.restaurant_type,
          address: data.address,
          phone: data.phone || undefined,
          email: data.email || undefined,
          logo_url: data.logo_url || undefined,
          opening_hours: data.opening_hours,
        });
      } else {
        // No restaurant exists, create one
        updated = await api.createRestaurant({
          name: data.name,
          description: data.description || undefined,
          restaurant_type: data.restaurant_type,
          address: data.address,
          phone: data.phone || undefined,
          email: data.email || undefined,
          logo_url: data.logo_url || undefined,
          opening_hours: data.opening_hours,
        });
      }
      setRestaurant(updated);
      setMerchantInfo((prev) => prev ? { ...prev, restaurant_name: updated.name } : prev);
      
      // Mark onboarding as complete on backend
      await api.completeOnboarding();
      
      // Update localStorage
      localStorage.setItem('swiftdrop_merchant_onboarding', JSON.stringify({
        completed: true
      }));
      
      setNeedsOnboarding(false);
    } catch (err) {
      console.error("Failed to save restaurant:", err);
    } finally {
      setOnboardingLoading(false);
    }
  };

  const handleSaveSettings = async (data: Partial<Restaurant>) => {
    setSettingsLoading(true);
    try {
      const updated = await api.updateRestaurant(data);
      setRestaurant(updated);
      setMerchantInfo((prev) => prev ? { ...prev, restaurant_name: updated.name } : prev);
    } catch (err) {
      console.error("Failed to save settings:", err);
    } finally {
      setSettingsLoading(false);
    }
  };

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
            categories={categories}
            onToggleStock={handleToggleStock}
            onAddItem={handleAddItem}
            onUpdateItem={handleUpdateItem}
            onDeleteItem={handleDeleteItem}
          />
        );
      case "analytics":
        return <AnalyticsView menuItems={menuItems} dashboardStats={dashboardStats} />;
      case "settings":
        return restaurant ? (
          <SettingsView
            restaurant={restaurant}
            onSave={handleSaveSettings}
            loading={settingsLoading}
          />
        ) : null;
      case "dashboard":
      default:
        return (
          <DashboardView 
            isOnline={isOnline}
            onToggleOnline={handleToggleOnline}
            orders={orders}
            onUpdateOrderStatus={handleUpdateOrderStatus}
            onNavigate={setActiveView}
            dashboardStats={dashboardStats}
            merchantInfo={merchantInfo}
          />
        );
    }
  };

  const navItems = [
    { id: "dashboard", label: "Dashboard", icon: LayoutDashboard },
    { id: "orders", label: "Orders", icon: ClipboardList },
    { id: "menu", label: "Menu", icon: Utensils },
    { id: "analytics", label: "Analytics", icon: TrendingUp },
    { id: "settings", label: "Settings", icon: Settings },
  ];

  // AUTH SCREEN - early return
  if (!isLoggedIn) {
    return (
      <div className="min-h-screen bg-background text-on-background flex items-center justify-center p-4">
        <div className="w-full max-w-sm bg-surface rounded-3xl p-8 shadow-xl border border-outline-variant/20">
          <div className="flex items-center gap-3 mb-8">
            <div className="w-12 h-12 bg-primary rounded-2xl flex items-center justify-center">
              <Utensils className="h-6 w-6 text-on-primary" />
            </div>
            <div>
              <h1 className="font-display font-extrabold text-lg text-primary">SwiftDrop</h1>
              <p className="text-xs text-on-surface-variant">Merchant Portal</p>
            </div>
          </div>

          {authStep === "form" ? (
            <div className="space-y-4">
              {authMode === 'signup' && (
                <div>
                  <label className="text-xs font-bold text-on-surface-variant mb-1 block">Full Name</label>
                  <div className="relative">
                    <input
                      type="text"
                      value={authName}
                      onChange={(e) => setAuthName(e.target.value)}
                      placeholder="John Doe"
                      className="w-full px-4 py-3 bg-surface-container rounded-xl border border-outline-variant/30 text-sm focus:outline-none focus:border-primary"
                    />
                  </div>
                </div>
              )}

              <div>
                <label className="text-xs font-bold text-on-surface-variant mb-1 block">Email</label>
                <div className="relative">
                  <input
                    type="email"
                    value={authEmail}
                    onChange={(e) => setAuthEmail(e.target.value)}
                    placeholder="merchant@example.com"
                    className="w-full px-4 py-3 bg-surface-container rounded-xl border border-outline-variant/30 text-sm focus:outline-none focus:border-primary"
                  />
                </div>
              </div>

              <div>
                <label className="text-xs font-bold text-on-surface-variant mb-1 block">Password</label>
                <div className="relative">
                  <input
                    type="password"
                    value={authPassword}
                    onChange={(e) => setAuthPassword(e.target.value)}
                    placeholder="••••••••"
                    className="w-full px-4 py-3 bg-surface-container rounded-xl border border-outline-variant/30 text-sm focus:outline-none focus:border-primary"
                  />
                </div>
              </div>

              {(authMode === 'signup' || usePhoneLogin) && (
                <div>
                  <label className="text-xs font-bold text-on-surface-variant mb-1 block">Phone Number</label>
                  <div className="relative">
                    <Phone className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-on-surface-variant" />
                    <input
                      type="tel"
                      value={authPhone}
                      onChange={(e) => setAuthPhone(e.target.value)}
                      placeholder="+233..."
                      className="w-full pl-10 pr-4 py-3 bg-surface-container rounded-xl border border-outline-variant/30 text-sm focus:outline-none focus:border-primary"
                    />
                  </div>
                </div>
              )}

              {authError && (
                <p className="text-xs text-error flex items-center gap-1">
                  <AlertCircle className="h-3 w-3" /> {authError}
                </p>
              )}

              <button
                onClick={handleAuthSubmit}
                disabled={authLoading}
                className="w-full py-3 bg-primary text-on-primary rounded-xl font-bold text-sm disabled:opacity-50 hover:brightness-110 transition-all"
              >
                {authLoading ? "Please wait..." : authMode === 'signup' ? 'Create Account' : 'Login'}
              </button>

              {authMode === 'login' && (
                <button
                  onClick={() => setUsePhoneLogin(!usePhoneLogin)}
                  className="w-full py-2 text-primary text-xs font-bold hover:underline"
                >
                  {usePhoneLogin ? 'Use email & password instead' : 'Use phone number instead'}
                </button>
              )}

              <div className="text-center text-xs text-on-surface-variant">
                {authMode === 'login' ? "Don't have an account? " : 'Already have an account? '}
                <button
                  onClick={() => { setAuthMode(authMode === 'login' ? 'signup' : 'login'); setAuthError(''); }}
                  className="text-primary font-bold hover:underline"
                >
                  {authMode === 'login' ? 'Sign Up' : 'Sign In'}
                </button>
              </div>
            </div>
          ) : (
            <div className="space-y-4">
              <p className="text-xs text-on-surface-variant">Code sent to {authPhone}</p>
              {devCode && (
                <p className="text-xs font-mono font-bold text-primary bg-primary/10 px-3 py-2 rounded-lg text-center">
                  Dev OTP: {devCode}
                </p>
              )}
              <div>
                <label className="text-xs font-bold text-on-surface-variant mb-1 block">OTP Code</label>
                <div className="relative">
                  <KeyRound className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-on-surface-variant" />
                  <input
                    type="text"
                    value={authCode}
                    onChange={(e) => setAuthCode(e.target.value)}
                    placeholder="123456"
                    maxLength={6}
                    className="w-full pl-10 pr-4 py-3 bg-surface-container rounded-xl border border-outline-variant/30 text-sm focus:outline-none focus:border-primary tracking-widest text-center"
                    onKeyDown={(e) => e.key === "Enter" && handleVerifyOtp()}
                  />
                </div>
              </div>
              {authError && (
                <p className="text-xs text-error flex items-center gap-1">
                  <AlertCircle className="h-3 w-3" /> {authError}
                </p>
              )}
              <button
                onClick={handleVerifyOtp}
                disabled={authLoading || !authCode}
                className="w-full py-3 bg-primary text-on-primary rounded-xl font-bold text-sm disabled:opacity-50 hover:brightness-110 transition-all"
              >
                {authLoading ? "Verifying..." : "Verify & Login"}
              </button>
              <button
                onClick={() => { setAuthStep("form"); setAuthCode(""); setAuthError(""); }}
                className="w-full py-2 text-on-surface-variant text-xs hover:text-on-surface transition-all"
              >
                Back to login
              </button>
            </div>
          )}
        </div>
      </div>
    );
  }

  // ONBOARDING SCREEN - show when restaurant needs setup
  if (isLoggedIn && needsOnboarding) {
    return <OnboardingView onComplete={handleOnboardingComplete} loading={onboardingLoading} />;
  }

  // MAIN APP - logged in
  return (
    <div className="min-h-screen bg-background text-on-background flex flex-col transition-colors duration-300">
      
      {/* Top Preview Control Bar */}
      <div className="bg-surface-container-high border-b border-outline-variant/30 px-5 py-2.5 flex flex-wrap justify-between items-center gap-3 text-xs font-bold dark:bg-surface-container-highest">
        <div className="flex items-center gap-2 text-primary">
          <Sparkles className="h-4 w-4 shrink-0" />
          <span>Interactive SwiftDrop Merchant Portal (React 19)</span>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={handleLogout}
            className="px-3 py-1.5 rounded-md text-error hover:bg-error/10 transition-all"
          >
            Logout
          </button>
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
              <span className="hidden sm:inline">Split</span>
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
              <span className="hidden sm:inline">Mobile</span>
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
              <span className="hidden sm:inline">Web</span>
            </button>
          </div>
        </div>
      </div>

      <div className="flex-1 flex flex-col md:flex-row max-w-[1536px] w-full mx-auto">
        
        {/* Desktop / Split view */}
        {previewMode !== "mobile" && (
          <div className={`flex-1 flex flex-col ${previewMode === "split" ? "lg:max-w-[65%]" : "w-full"}`}>
            <Navbar 
              darkMode={darkMode} 
              onToggleDarkMode={() => setDarkMode(!darkMode)} 
              onNavigate={setActiveView}
              activeView={activeView}
              merchantInfo={merchantInfo}
            />

            <div className="flex-1 flex">
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

            {/* Mobile Bottom Nav */}
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

        {/* Mobile Mockup Frame */}
        {previewMode !== "web" && (
          <div className={`flex-1 flex items-center justify-center p-6 bg-surface-container-low border-l border-outline-variant/10 dark:bg-surface-container-lowest ${
            previewMode === "mobile" ? "w-full" : "hidden lg:flex"
          }`}>
            <div className="relative mx-auto w-[370px] h-[780px] rounded-[52px] bg-neutral-900 p-3.5 shadow-2xl border-4 border-neutral-800 flex flex-col overflow-hidden ring-1 ring-white/10">
              
              <div className="absolute top-0 left-1/2 -translate-x-1/2 h-8 w-44 bg-neutral-900 rounded-b-2xl z-50 flex items-center justify-center">
                <div className="w-16 h-3 bg-neutral-950 rounded-full" />
                <div className="w-3.5 h-3.5 bg-neutral-950 rounded-full ml-3" />
              </div>

              <div className="flex-1 rounded-[38px] bg-background text-on-background overflow-hidden relative flex flex-col border border-neutral-950/20 select-none">
                
                <div className="h-10 bg-surface px-6 flex items-center justify-between text-[11px] font-bold text-on-surface-variant z-40 border-b border-outline-variant/10 transition-colors">
                  <span>12:55 PM</span>
                  <div className="flex items-center gap-1.5">
                    <Wifi className="h-3 w-3" />
                    <span>5G</span>
                    <Battery className="h-3.5 h-3.5 text-primary-container" />
                  </div>
                </div>

                <div className="h-14 bg-surface flex items-center justify-between px-5 z-40 border-b border-outline-variant/10">
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 rounded-full border border-outline-variant/30 overflow-hidden bg-primary/20 flex items-center justify-center">
                      {merchantInfo?.merchant_name ? (
                        <span className="text-xs font-bold text-primary">{merchantInfo.merchant_name[0]}</span>
                      ) : (
                        <span className="text-xs font-bold text-primary">M</span>
                      )}
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
