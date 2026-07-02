import { useState } from "react";
import { 
  Store, 
  TrendingUp, 
  Coins, 
  Clock, 
  ClipboardList, 
  XCircle, 
  ChevronRight, 
  Phone, 
  Plus, 
  Utensils, 
  Check, 
  Calendar, 
  Star, 
  HelpCircle,
  Sparkles,
  AlertCircle
} from "lucide-react";
import { Order } from "../types";
import { motion, AnimatePresence } from "motion/react";

interface DashboardViewProps {
  isOnline: boolean;
  onToggleOnline: () => void;
  orders: Order[];
  onUpdateOrderStatus: (orderId: string, newStatus: any) => void;
  onNavigate: (view: "dashboard" | "orders" | "menu" | "analytics" | "settings") => void;
  dashboardStats?: {total_orders_today: number; total_earnings_today: number; avg_preparation_time: number; cancelled_orders: number; active_orders: number; completed_orders: number} | null;
  merchantInfo?: {restaurant_name: string; merchant_name: string} | null;
}

export default function DashboardView({
  isOnline,
  onToggleOnline,
  orders,
  onUpdateOrderStatus,
  onNavigate,
  dashboardStats,
  merchantInfo,
}: DashboardViewProps) {
  const [courierCallState, setCourierCallState] = useState<string | null>(null);

  // Filter active dashboard orders
  const dashboardOrders = orders.filter(
    (o) => o.status === "new" || o.status === "preparing" || o.status === "awaiting_pickup"
  ).slice(0, 3); // Top 3 active orders

  const handleCallCourier = (orderNo: string) => {
    setCourierCallState(orderNo);
    setTimeout(() => {
      setCourierCallState(null);
      alert(`Connecting call to courier assigned to ${orderNo}...`);
    }, 1500);
  };

  // Use API stats when available, fallback to computed values
  const totalOrdersCount = dashboardStats?.total_orders_today ?? orders.length;
  const totalEarningsToday = dashboardStats?.total_earnings_today ?? orders
    .filter(o => o.status !== "declined")
    .reduce((sum, o) => sum + o.total, 0);
  const avgPrepTime = dashboardStats?.avg_preparation_time ?? 0;
  const cancelledOrders = dashboardStats?.cancelled_orders ?? 0;
  const activeOrdersCount = dashboardStats?.active_orders ?? dashboardOrders.length;

  return (
    <div className="space-y-6">
      {/* Top Banner Alert (AI Suggestion) */}
      <div className="rounded-xl border border-primary/20 bg-primary/10 p-4 dark:bg-primary/5">
        <div className="flex gap-3">
          <Sparkles className="h-5 w-5 text-primary-container shrink-0 mt-0.5 animate-bounce" />
          <div>
            <h4 className="text-sm font-semibold text-primary dark:text-primary">
              AI Recommendation: Peak Hour Imminent!
            </h4>
            <p className="text-xs text-on-surface-variant leading-relaxed mt-0.5">
              Based on historical trends, pizza and burger orders usually spike by 25% in the next hour. Keep ingredients prepped for fast execution.
            </p>
          </div>
        </div>
      </div>

      {/* Main Stats and Status Container */}
      <section className="grid grid-cols-1 gap-6 md:grid-cols-2">
        {/* Store Status Card */}
        <div className="relative overflow-hidden rounded-2xl border border-outline-variant/30 bg-surface-container-lowest p-6 shadow-[0_4px_12px_rgba(0,0,0,0.03)] transition-all duration-300 dark:bg-surface-container-low">
          <div className="relative z-10 flex h-full flex-col justify-between">
            <div className="flex items-start justify-between">
              <div>
                <p className="text-xs font-semibold text-on-surface-variant uppercase tracking-wider">Store Status</p>
                <h3 className="mt-1 flex items-center gap-2 font-display text-2xl font-bold text-on-surface">
                  <span className={`h-3 w-3 rounded-full ${isOnline ? 'bg-primary-container animate-pulse' : 'bg-error'}`} />
                  {isOnline ? "Online" : "Offline"}
                </h3>
              </div>

              {/* IOS-style toggle slider */}
              <button
                onClick={onToggleOnline}
                className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                  isOnline ? "bg-primary" : "bg-outline-variant"
                }`}
              >
                <span
                  className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                    isOnline ? "translate-x-5" : "translate-x-0"
                  }`}
                />
              </button>
            </div>

            <p className="mt-6 text-sm text-on-surface-variant leading-relaxed">
              {isOnline ? (
                <span>Accepting orders for <strong className="text-primary font-bold">{merchantInfo?.restaurant_name || 'Restaurant'}</strong></span>
              ) : (
                <span className="text-error font-medium">Auto-reject enabled. Store is currently closed.</span>
              )}
            </p>
          </div>

          {/* Background decorative watermark */}
          <div className="absolute right-[-10px] bottom-[-10px] opacity-5 pointer-events-none select-none text-on-surface">
            <Store className="h-32 w-32" />
          </div>
        </div>

        {/* Total Earnings Card */}
        <div className="relative overflow-hidden rounded-2xl bg-primary p-6 text-on-primary shadow-[0_10px_25px_rgba(0,108,73,0.15)]">
          <div className="flex h-full flex-col justify-between">
            <div>
              <p className="text-xs font-semibold uppercase tracking-wider opacity-85">Total Earnings (Today)</p>
              <h2 className="mt-1 font-display text-4xl font-extrabold tracking-tight">
                GHS {totalEarningsToday.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
              </h2>
            </div>

            <div className="mt-6 flex items-center gap-1 text-xs font-bold bg-white/15 w-fit px-2.5 py-1 rounded-full border border-white/10">
              <TrendingUp className="h-3.5 w-3.5" />
              <span>{totalOrdersCount} orders today</span>
            </div>
          </div>
          {/* Subtle light ripple decor */}
          <div className="absolute top-0 right-0 h-full w-32 bg-gradient-to-l from-white/5 to-transparent pointer-events-none" />
        </div>
      </section>

      {/* Active Orders List */}
      <section className="space-y-3">
        <div className="flex items-end justify-between px-1">
          <h3 className="font-display text-lg font-bold text-on-surface tracking-tight">Active Orders ({dashboardOrders.length})</h3>
          <button 
            onClick={() => onNavigate("orders")}
            className="flex items-center text-xs font-bold text-primary hover:underline"
          >
            View all history <ChevronRight className="h-3.5 w-3.5 ml-0.5" />
          </button>
        </div>

        <div className="grid grid-cols-1 gap-4">
          <AnimatePresence mode="popLayout">
            {dashboardOrders.length === 0 ? (
              <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-outline-variant/40 p-8 text-center bg-surface-container-lowest dark:bg-surface-container-low">
                <ClipboardList className="h-10 w-10 text-on-surface-variant/50 mb-2" />
                <p className="text-sm font-medium text-on-surface-variant">No active orders right now</p>
                <p className="text-xs text-on-surface-variant/70 mt-0.5">Toggle store status or wait for new customer pings</p>
              </div>
            ) : (
              dashboardOrders.map((order) => (
                <motion.div
                  key={order.id}
                  layout
                  initial={{ opacity: 0, y: 15 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.95 }}
                  transition={{ duration: 0.2 }}
                  className={`rounded-2xl border border-outline-variant/30 bg-surface-container-lowest p-5 shadow-[0_4px_12px_rgba(0,0,0,0.02)] flex flex-col md:flex-row md:items-center justify-between gap-4 hover:-translate-y-0.5 transition-transform duration-300 dark:bg-surface-container-low ${
                    order.status === "new" ? "ring-2 ring-primary-container bg-primary-container/5 dark:ring-primary/60" : ""
                  }`}
                >
                  <div className="flex items-center gap-4">
                    <div className={`h-12 w-12 rounded-xl flex items-center justify-center shrink-0 ${
                      order.status === "new" 
                        ? "bg-primary-container text-on-primary-container" 
                        : "bg-surface-container text-primary"
                    }`}>
                      {order.status === "new" ? <AlertCircle className="h-6 w-6" /> : <ClipboardList className="h-6 w-6" />}
                    </div>

                    <div>
                      <div className="flex flex-wrap items-center gap-2">
                        <span className="font-display font-bold text-on-surface text-sm">#{order.orderNo}</span>
                        {order.status === "new" && (
                          <span className="rounded-full bg-primary text-on-primary px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide">New Order</span>
                        )}
                        {order.status === "preparing" && (
                          <span className="rounded-full bg-tertiary-container/20 text-tertiary-container px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide">Preparing</span>
                        )}
                        {order.status === "awaiting_pickup" && (
                          <span className="rounded-full bg-secondary-container/20 text-on-secondary-container px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide">Awaiting Pickup</span>
                        )}
                      </div>
                      <p className="text-xs text-on-surface-variant mt-1">
                        {order.items.map(item => `${item.name} x${item.quantity}`).join(", ")} • <strong>GHS {order.total.toFixed(2)}</strong> • Customer: {order.customerName}
                      </p>
                      {order.driverName && (
                        <p className="text-[11px] text-primary font-medium mt-1">
                          Driver: {order.driverName} ({order.driverStatus})
                        </p>
                      )}
                    </div>
                  </div>

                  {/* Actions buttons */}
                  <div className="flex items-center gap-2">
                    {order.status === "new" && (
                      <>
                        <button
                          onClick={() => onUpdateOrderStatus(order.id, "declined")}
                          className="px-4 py-2 rounded-xl border border-outline text-xs font-bold text-on-surface hover:bg-surface-container transition-colors active:scale-95 duration-150"
                        >
                          Decline
                        </button>
                        <button
                          onClick={() => onUpdateOrderStatus(order.id, "preparing")}
                          className="px-4 py-2 rounded-xl bg-primary text-on-primary text-xs font-bold hover:brightness-110 shadow-sm active:scale-95 transition-all"
                        >
                          Accept Order
                        </button>
                      </>
                    )}

                    {order.status === "preparing" && (
                      <>
                        <button
                          onClick={() => onNavigate("orders")}
                          className="px-4 py-2 rounded-xl border border-outline text-xs font-bold text-on-surface hover:bg-surface-container transition-colors active:scale-95 duration-150"
                        >
                          Detail
                        </button>
                        <button
                          onClick={() => onUpdateOrderStatus(order.id, "awaiting_pickup")}
                          className="px-4 py-2 rounded-xl bg-primary text-on-primary text-xs font-bold hover:brightness-110 shadow-sm active:scale-95 transition-all"
                        >
                          Ready
                        </button>
                      </>
                    )}

                    {order.status === "awaiting_pickup" && (
                      <button
                        onClick={() => handleCallCourier(order.orderNo)}
                        disabled={courierCallState === order.orderNo}
                        className="px-4 py-2 rounded-xl border border-outline-variant bg-surface-container text-on-surface text-xs font-bold hover:bg-surface-container-highest transition-colors flex items-center gap-1"
                      >
                        <Phone className="h-3 w-3" />
                        {courierCallState === order.orderNo ? "Calling..." : "Call Courier"}
                      </button>
                    )}
                  </div>
                </motion.div>
              ))
            )}
          </AnimatePresence>
        </div>
      </section>

      {/* Bento-style metrics & actions */}
      <section className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Quick Metrics */}
        <div className="lg:col-span-5 rounded-2xl border border-outline-variant/30 bg-surface-container-lowest p-5 shadow-[0_4px_12px_rgba(0,0,0,0.02)] dark:bg-surface-container-low">
          <h4 className="text-xs font-bold uppercase tracking-wider text-on-surface-variant mb-4">Quick Metrics</h4>
          
          <div className="space-y-3">
            <div className="flex justify-between items-center p-3 rounded-xl bg-surface-container-low/50 dark:bg-surface-container-high/40">
              <span className="text-sm font-medium text-on-surface-variant">Total Orders</span>
              <span className="text-lg font-bold text-on-surface">{totalOrdersCount}</span>
            </div>
            
            <div className="flex justify-between items-center p-3 rounded-xl bg-surface-container-low/50 dark:bg-surface-container-high/40">
              <span className="text-sm font-medium text-on-surface-variant">Avg. Prep Time</span>
              <span className="text-lg font-bold text-on-surface">{avgPrepTime > 0 ? `${Math.round(avgPrepTime)}m` : '-'}</span>
            </div>
            
            <div className="flex justify-between items-center p-3 rounded-xl bg-surface-container-low/50 dark:bg-surface-container-high/40">
              <span className="text-sm font-medium text-on-surface-variant">Cancelled Orders</span>
              <span className="text-lg font-bold text-error">{cancelledOrders}</span>
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="lg:col-span-7 space-y-3">
          <h4 className="text-xs font-bold uppercase tracking-wider text-on-surface-variant mb-1 px-1">Quick Actions</h4>
          <div className="grid grid-cols-2 gap-4">
            <button
              onClick={() => onNavigate("menu")}
              className="flex flex-col items-center justify-center p-4 bg-surface-container-lowest border border-outline-variant/30 rounded-2xl shadow-[0_4px_12px_rgba(0,0,0,0.02)] hover:bg-primary/5 transition-all group active:scale-95 dark:bg-surface-container-low"
            >
              <Utensils className="h-6 w-6 text-primary mb-2 group-hover:scale-110 transition-transform" />
              <span className="text-xs font-bold text-on-surface text-center">Manage Menu</span>
            </button>

            <button
              onClick={() => {
                alert("Opening configuration for standard operation hours...");
              }}
              className="flex flex-col items-center justify-center p-4 bg-surface-container-lowest border border-outline-variant/30 rounded-2xl shadow-[0_4px_12px_rgba(0,0,0,0.02)] hover:bg-primary/5 transition-all group active:scale-95 dark:bg-surface-container-low"
            >
              <Clock className="h-6 w-6 text-primary mb-2 group-hover:scale-110 transition-transform" />
              <span className="text-xs font-bold text-on-surface text-center">Update Hours</span>
            </button>

            <button
              onClick={() => {
                alert("Redirecting to reviews manager...");
              }}
              className="flex flex-col items-center justify-center p-4 bg-surface-container-lowest border border-outline-variant/30 rounded-2xl shadow-[0_4px_12px_rgba(0,0,0,0.02)] hover:bg-primary/5 transition-all group active:scale-95 dark:bg-surface-container-low"
            >
              <Star className="h-6 w-6 text-primary mb-2 group-hover:scale-110 transition-transform" />
              <span className="text-xs font-bold text-on-surface text-center">View Reviews</span>
            </button>

            <button
              onClick={() => {
                alert("Launching customer support widget...");
              }}
              className="flex flex-col items-center justify-center p-4 bg-surface-container-lowest border border-outline-variant/30 rounded-2xl shadow-[0_4px_12px_rgba(0,0,0,0.02)] hover:bg-primary/5 transition-all group active:scale-95 dark:bg-surface-container-low"
            >
              <HelpCircle className="h-6 w-6 text-primary mb-2 group-hover:scale-110 transition-transform" />
              <span className="text-xs font-bold text-on-surface text-center">Support Portal</span>
            </button>
          </div>
        </div>
      </section>

      {/* Support Banner Card */}
      <div className="relative rounded-2xl overflow-hidden shadow-md h-40 flex items-end">
        <img 
          className="absolute inset-0 w-full h-full object-cover select-none" 
          src="https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400" 
          alt="Kitchen Tools"
          referrerPolicy="no-referrer"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/40 to-transparent" />
        <div className="relative z-10 p-5 w-full">
          <p className="text-white/80 text-xs font-semibold uppercase tracking-wider">Merchant Growth Program</p>
          <h4 className="text-white text-lg font-extrabold tracking-tight mt-1">Optimize your delivery speed</h4>
          <p className="text-white/75 text-[11px] mt-0.5">Learn how to slash preparation times by up to 20% using bulk batching.</p>
        </div>
      </div>
    </div>
  );
}
