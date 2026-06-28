import { useState, useMemo } from "react";
import { 
  Search, 
  SlidersHorizontal, 
  Clock, 
  Truck, 
  User, 
  Check, 
  X, 
  AlertTriangle,
  ChevronRight,
  Sparkles,
  ClipboardList
} from "lucide-react";
import { Order, OrderStatus } from "../types";
import { motion, AnimatePresence } from "motion/react";

interface OrdersViewProps {
  orders: Order[];
  onUpdateOrderStatus: (orderId: string, newStatus: OrderStatus) => void;
  onNavigate: (view: "dashboard" | "orders" | "menu" | "analytics") => void;
}

export default function OrdersView({ orders, onUpdateOrderStatus, onNavigate }: OrdersViewProps) {
  const [activeTab, setActiveTab] = useState<"active" | "scheduled" | "completed">("active");
  const [searchQuery, setSearchQuery] = useState("");

  // Helper to format elapsed seconds to mm:ss
  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
  };

  // Filter orders based on Tab and Query
  const filteredOrders = useMemo(() => {
    return orders.filter((o) => {
      // Filter by Search Query (Order # or Customer Name)
      const matchesSearch = 
        o.orderNo.toLowerCase().includes(searchQuery.toLowerCase()) ||
        o.customerName.toLowerCase().includes(searchQuery.toLowerCase());
      
      if (!matchesSearch) return false;

      // Filter by Tab Status
      if (activeTab === "active") {
        return o.status === "new" || o.status === "preparing" || o.status === "awaiting_pickup" || o.status === "ready";
      } else if (activeTab === "scheduled") {
        return false; // Simulate scheduled tab
      } else {
        return o.status === "completed" || o.status === "declined";
      }
    });
  }, [orders, activeTab, searchQuery]);

  return (
    <div className="space-y-6">
      {/* Header with Search and filter */}
      <section className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="font-display text-2xl font-bold text-on-surface tracking-tight">Orders Management</h2>
          <p className="text-sm text-on-surface-variant">Manage your real-time delivery performance.</p>
        </div>

        {/* Search Input Box */}
        <div className="flex items-center gap-3 w-full md:w-auto">
          <div className="relative flex-grow md:w-64">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant h-4 w-4" />
            <input 
              type="text" 
              placeholder="Search Order # or Customer..." 
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-surface-container-lowest border-none focus:ring-2 focus:ring-primary text-sm font-medium shadow-sm outline-none dark:bg-surface-container-low"
            />
          </div>
          <button 
            onClick={() => alert("Detailed filters layout: Search by driver, payment method, or item.")}
            className="p-2.5 bg-surface-container-lowest border border-outline-variant/20 rounded-xl hover:bg-surface-container-highest transition-colors flex items-center justify-center dark:bg-surface-container-low"
            title="Filter options"
          >
            <SlidersHorizontal className="h-4 w-4 text-primary" />
          </button>
        </div>
      </section>

      {/* Tabs */}
      <nav className="flex border-b border-outline-variant/30 overflow-x-auto no-scrollbar">
        <button 
          onClick={() => setActiveTab("active")}
          className={`px-6 py-3.5 text-sm font-bold border-b-2 transition-colors whitespace-nowrap ${
            activeTab === "active" 
              ? "border-primary text-primary" 
              : "border-transparent text-on-surface-variant hover:text-on-surface"
          }`}
        >
          Active ({orders.filter(o => o.status !== "completed" && o.status !== "declined").length})
        </button>
        <button 
          onClick={() => setActiveTab("scheduled")}
          className={`px-6 py-3.5 text-sm font-bold border-b-2 transition-colors whitespace-nowrap ${
            activeTab === "scheduled" 
              ? "border-primary text-primary" 
              : "border-transparent text-on-surface-variant hover:text-on-surface"
          }`}
        >
          Scheduled (5)
        </button>
        <button 
          onClick={() => setActiveTab("completed")}
          className={`px-6 py-3.5 text-sm font-bold border-b-2 transition-colors whitespace-nowrap ${
            activeTab === "completed" 
              ? "border-primary text-primary" 
              : "border-transparent text-on-surface-variant hover:text-on-surface"
          }`}
        >
          Completed ({orders.filter(o => o.status === "completed" || o.status === "declined").length})
        </button>
      </nav>

      {/* Orders Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <AnimatePresence mode="popLayout">
          {filteredOrders.length === 0 ? (
            <div className="col-span-full flex flex-col items-center justify-center rounded-2xl border border-dashed border-outline-variant/40 p-12 text-center bg-surface-container-lowest dark:bg-surface-container-low">
              <ClipboardList className="h-12 w-12 text-on-surface-variant/40 mb-2" />
              <p className="text-sm font-medium text-on-surface-variant">No orders match your criteria</p>
              <p className="text-xs text-on-surface-variant/60 mt-0.5">Try clearing the search or adding simulated test orders</p>
            </div>
          ) : (
            filteredOrders.map((order) => {
              // Styling helper based on status and delay
              const isDelayed = order.elapsedSeconds > 600 && order.status === "preparing"; // > 10 mins

              return (
                <motion.div
                  key={order.id}
                  layout
                  initial={{ opacity: 0, scale: 0.95 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0, scale: 0.9 }}
                  transition={{ duration: 0.2 }}
                  className={`bg-surface-container-lowest rounded-3xl p-6 shadow-[0_4px_16px_rgba(0,0,0,0.02)] border border-outline-variant/20 flex flex-col justify-between hover:shadow-md transition-all dark:bg-surface-container-low ${
                    isDelayed ? "border-l-4 border-l-error" : ""
                  }`}
                >
                  <div>
                    {/* Header bar */}
                    <div className="flex justify-between items-start mb-4">
                      <div>
                        {order.status === "new" && (
                          <span className="text-[10px] font-bold text-on-primary-container bg-primary-container px-2.5 py-0.5 rounded-full mb-2 inline-block uppercase tracking-wider">New Request</span>
                        )}
                        {isDelayed && (
                          <span className="text-[10px] font-bold text-error bg-error-container px-2.5 py-0.5 rounded-full mb-2 inline-block uppercase tracking-wider flex items-center gap-1">
                            <AlertTriangle className="h-3 w-3" /> Delayed
                          </span>
                        )}
                        {!isDelayed && order.status === "preparing" && (
                          <span className="text-[10px] font-bold text-on-secondary-container bg-secondary-container px-2.5 py-0.5 rounded-full mb-2 inline-block uppercase tracking-wider">Preparing</span>
                        )}
                        {order.status === "awaiting_pickup" && (
                          <span className="text-[10px] font-bold text-on-primary-container bg-primary-container px-2.5 py-0.5 rounded-full mb-2 inline-block uppercase tracking-wider">Awaiting Pickup</span>
                        )}
                        {order.status === "ready" && (
                          <span className="text-[10px] font-bold text-primary bg-primary/10 px-2.5 py-0.5 rounded-full mb-2 inline-block uppercase tracking-wide">Ready for Pickup</span>
                        )}
                        {order.status === "completed" && (
                          <span className="text-[10px] font-bold text-primary bg-primary-container/20 px-2.5 py-0.5 rounded-full mb-2 inline-block uppercase tracking-wide">Completed</span>
                        )}
                        {order.status === "declined" && (
                          <span className="text-[10px] font-bold text-error bg-error-container/20 px-2.5 py-0.5 rounded-full mb-2 inline-block uppercase tracking-wide">Declined</span>
                        )}
                        
                        <h3 className="text-lg font-display font-bold text-on-surface">Order #{order.orderNo}</h3>
                        <p className="text-xs text-on-surface-variant font-medium">Customer: {order.customerName}</p>
                      </div>

                      <div className="text-right">
                        <p className="text-[10px] uppercase font-bold text-on-surface-variant tracking-wider">
                          {order.status === "completed" || order.status === "declined" ? "Total Price" : "Elapsed"}
                        </p>
                        <p className={`text-sm font-bold ${isDelayed ? "text-error" : "text-on-surface"}`}>
                          {order.status === "completed" || order.status === "declined" 
                            ? `$${order.total.toFixed(2)}` 
                            : formatTime(order.elapsedSeconds)}
                        </p>
                      </div>
                    </div>

                    {/* Items detail list */}
                    <div className="mb-6 space-y-2 border-t border-b border-outline-variant/20 py-3">
                      {order.items.map((item, idx) => (
                        <div key={idx} className="flex items-center gap-2.5">
                          <span className="w-1.5 h-1.5 rounded-full bg-primary shrink-0" />
                          <p className="text-xs font-semibold text-on-surface">
                            {item.name} <span className="text-on-surface-variant font-medium">x{item.quantity}</span>
                          </p>
                        </div>
                      ))}
                    </div>

                    {/* Driver Assign Status block */}
                    {order.status !== "completed" && order.status !== "declined" && (
                      <div className="flex items-center gap-3 p-3 bg-surface-container rounded-xl mb-6">
                        <div className="w-8 h-8 rounded-full bg-secondary-container flex items-center justify-center shrink-0">
                          <Truck className="h-4 w-4 text-primary" />
                        </div>
                        <div className="min-w-0">
                          <p className="text-xs font-bold text-on-surface truncate">
                            {order.driverName || "Searching Driver..."}
                          </p>
                          <p className="text-[10px] text-on-surface-variant font-semibold">
                            {order.driverStatus || "Assigning soon"}
                          </p>
                        </div>
                      </div>
                    )}
                  </div>

                  {/* Actions based on dynamic statuses */}
                  <div>
                    {order.status === "new" && (
                      <div className="grid grid-cols-2 gap-3">
                        <button 
                          onClick={() => onUpdateOrderStatus(order.id, "declined")}
                          className="py-3.5 border border-outline-variant text-on-surface rounded-xl text-xs font-bold hover:bg-surface-container active:scale-95 transition-all"
                        >
                          Decline
                        </button>
                        <button 
                          onClick={() => onUpdateOrderStatus(order.id, "preparing")}
                          className="py-3.5 bg-primary text-on-primary rounded-xl text-xs font-bold hover:brightness-110 active:scale-95 transition-all shadow-sm"
                        >
                          Accept Order
                        </button>
                      </div>
                    )}

                    {order.status === "preparing" && (
                      <button 
                        onClick={() => onUpdateOrderStatus(order.id, "awaiting_pickup")}
                        className="w-full py-3.5 bg-primary text-on-primary rounded-xl text-xs font-bold hover:brightness-110 active:scale-95 transition-all shadow-sm"
                      >
                        Ready for Pickup
                      </button>
                    )}

                    {order.status === "awaiting_pickup" && (
                      <button 
                        onClick={() => onUpdateOrderStatus(order.id, "completed")}
                        className="w-full py-3.5 bg-primary text-on-primary rounded-xl text-xs font-bold hover:brightness-110 active:scale-95 transition-all shadow-sm"
                      >
                        Hand Over to Courier
                      </button>
                    )}

                    {order.status === "ready" && (
                      <button 
                        onClick={() => onUpdateOrderStatus(order.id, "completed")}
                        className="w-full py-3.5 bg-primary-container text-on-primary-container rounded-xl text-xs font-bold hover:brightness-110 active:scale-95 transition-all shadow-sm"
                      >
                        Mark Completed
                      </button>
                    )}

                    {(order.status === "completed" || order.status === "declined") && (
                      <div className="text-center py-2 border border-outline-variant/30 rounded-xl bg-surface-container-low">
                        <p className="text-[11px] font-bold text-on-surface-variant uppercase tracking-wider">
                          {order.status === "completed" ? "Successfully Delivered" : "Rejected"}
                        </p>
                      </div>
                    )}
                  </div>
                </motion.div>
              );
            })
          )}
        </AnimatePresence>
      </div>

      {/* Morning Rush Banner Grid */}
      {activeTab === "active" && (
        <div className="bg-primary-container text-on-primary-container rounded-3xl p-6 shadow-md flex flex-col md:flex-row justify-between items-center gap-4 relative overflow-hidden group">
          <div className="relative z-10">
            <h3 className="font-display font-bold text-xl mb-1 flex items-center gap-2">
              <Sparkles className="h-5 w-5 text-white shrink-0" /> Morning Rush
            </h3>
            <p className="text-xs text-white/90 max-w-xl leading-relaxed">
              12 orders currently being prepared. Your kitchen dispatch performance is 8% higher than yesterday, matching high-quality metrics.
            </p>
          </div>
          <button 
            onClick={() => onNavigate("analytics")}
            className="relative z-10 bg-on-primary-container text-primary-container px-5 py-2.5 rounded-xl text-xs font-bold hover:bg-white hover:text-primary transition-all shrink-0 shadow-sm active:scale-95"
          >
            View Analytics
          </button>
          <div className="absolute -right-8 -bottom-8 w-32 h-32 bg-white/10 rounded-full blur-2xl group-hover:scale-120 transition-transform duration-700" />
        </div>
      )}
    </div>
  );
}
