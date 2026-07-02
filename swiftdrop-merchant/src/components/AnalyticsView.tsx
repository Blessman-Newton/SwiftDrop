import { useState, useMemo } from "react";
import { 
  TrendingUp, 
  TrendingDown, 
  Coins, 
  ShoppingBag, 
  BarChart3, 
  Sparkles, 
  Verified, 
  Lightbulb,
  CheckCircle2,
  Percent,
  ChevronRight
} from "lucide-react";
import { MenuItem } from "../types";
import { motion } from "motion/react";

interface AnalyticsViewProps {
  menuItems: MenuItem[];
  dashboardStats?: {
    total_orders_today: number;
    total_earnings_today: number;
    avg_preparation_time: number;
    cancelled_orders: number;
    active_orders: number;
    completed_orders: number;
  } | null;
}

export default function AnalyticsView({ menuItems, dashboardStats }: AnalyticsViewProps) {
  const [timeframe, setTimeframe] = useState<"7days" | "monthly" | "quarterly">("7days");
  const [hoveredBar, setHoveredBar] = useState<number | null>(null);

  const metrics = useMemo(() => {
    const earnings = dashboardStats?.total_earnings_today ?? 0;
    const orders = dashboardStats?.total_orders_today ?? 0;
    const completed = dashboardStats?.completed_orders ?? 0;
    const avg = orders > 0 ? earnings / orders : 0;

    const fmt = (n: number) => `GHS ${n.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

    switch (timeframe) {
      case "monthly":
        return {
          revenue: earnings * 30,
          revenueTrend: "+18.4%",
          volume: orders * 30,
          volumeTrend: "+11.2%",
          aov: avg,
          aovTrend: "+2.1%",
          aovPositive: true,
          chartData: [
            { label: "Wk 1", value: 45, valStr: fmt(earnings * 7 * 0.8) },
            { label: "Wk 2", value: 65, valStr: fmt(earnings * 7 * 1.1) },
            { label: "Wk 3", value: 85, valStr: fmt(earnings * 7 * 1.3) },
            { label: "Wk 4", value: 55, valStr: fmt(earnings * 7 * 0.95) }
          ]
        };
      case "quarterly":
        return {
          revenue: earnings * 90,
          revenueTrend: "+24.2%",
          volume: orders * 90,
          volumeTrend: "+15.8%",
          aov: avg,
          aovTrend: "-1.2%",
          aovPositive: false,
          chartData: [
            { label: "Jan", value: 75, valStr: fmt(earnings * 30) },
            { label: "Feb", value: 55, valStr: fmt(earnings * 30 * 0.8) },
            { label: "Mar", value: 95, valStr: fmt(earnings * 30 * 1.2) }
          ]
        };
      case "7days":
      default:
        return {
          revenue: earnings * 7,
          revenueTrend: "+12.5%",
          volume: orders * 7,
          volumeTrend: "+8.2%",
          aov: avg,
          aovTrend: "-2.4%",
          aovPositive: false,
          chartData: [
            { label: "Mon", value: 40, valStr: fmt(earnings * 0.8) },
            { label: "Tue", value: 65, valStr: fmt(earnings * 1.1) },
            { label: "Wed", value: 55, valStr: fmt(earnings * 0.95) },
            { label: "Thu", value: 85, valStr: fmt(earnings * 1.3) },
            { label: "Fri", value: 45, valStr: fmt(earnings * 0.85) },
            { label: "Sat", value: 75, valStr: fmt(earnings * 1.2) },
            { label: "Sun", value: 30, valStr: fmt(earnings * 0.5) }
          ]
        };
    }
  }, [timeframe, dashboardStats]);

  // Sorting menu items by popularity to display top 3
  const topSelling = useMemo(() => {
    return [...menuItems]
      .sort((a, b) => b.soldCount - a.soldCount)
      .slice(0, 3);
  }, [menuItems]);

  return (
    <div className="space-y-6">
      
      {/* Header section & timeframe selector */}
      <section className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="font-display text-2xl font-bold text-on-surface tracking-tight">Merchant Analytics</h2>
          <p className="text-sm text-on-surface-variant">Performance insights for your business</p>
        </div>

        {/* Timeframe selector container */}
        <div className="flex bg-surface-container rounded-xl p-1 shadow-sm self-start dark:bg-surface-container-high">
          <button 
            onClick={() => setTimeframe("7days")}
            className={`px-4 py-2 text-xs font-bold rounded-lg transition-all ${
              timeframe === "7days" 
                ? "bg-surface-container-lowest text-primary shadow-sm dark:bg-surface-container-low" 
                : "text-on-surface-variant hover:bg-surface-container-highest"
            }`}
          >
            Last 7 Days
          </button>
          <button 
            onClick={() => setTimeframe("monthly")}
            className={`px-4 py-2 text-xs font-bold rounded-lg transition-all ${
              timeframe === "monthly" 
                ? "bg-surface-container-lowest text-primary shadow-sm dark:bg-surface-container-low" 
                : "text-on-surface-variant hover:bg-surface-container-highest"
            }`}
          >
            Monthly
          </button>
          <button 
            onClick={() => setTimeframe("quarterly")}
            className={`px-4 py-2 text-xs font-bold rounded-lg transition-all ${
              timeframe === "quarterly" 
                ? "bg-surface-container-lowest text-primary shadow-sm dark:bg-surface-container-low" 
                : "text-on-surface-variant hover:bg-surface-container-highest"
            }`}
          >
            Quarterly
          </button>
        </div>
      </section>

      {/* Bento style key cards */}
      <section className="grid grid-cols-1 md:grid-cols-3 gap-6">
        
        {/* Card 1: Total Revenue */}
        <div className="bg-surface-container-lowest p-5 rounded-3xl shadow-[0_4px_16px_rgba(0,108,73,0.02)] border border-outline-variant/10 flex flex-col justify-between hover:shadow-md transition-all dark:bg-surface-container-low">
          <div className="flex justify-between items-start">
            <div className="p-2.5 bg-primary/10 rounded-xl">
              <Coins className="h-5 w-5 text-primary" />
            </div>
            <div className="flex items-center gap-0.5 text-primary bg-primary/10 px-2.5 py-0.5 rounded-full text-[11px] font-bold">
              <TrendingUp className="h-3 w-3" />
              <span>{metrics.revenueTrend}</span>
            </div>
          </div>
          <div className="mt-5">
            <p className="text-xs font-bold text-on-surface-variant uppercase tracking-wider">Total Revenue</p>
              <p className="text-2xl font-display font-extrabold text-on-surface mt-1">
              GHS {metrics.revenue.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </p>
          </div>
        </div>

        {/* Card 2: Order Volume */}
        <div className="bg-surface-container-lowest p-5 rounded-3xl shadow-[0_4px_16px_rgba(0,108,73,0.02)] border border-outline-variant/10 flex flex-col justify-between hover:shadow-md transition-all dark:bg-surface-container-low">
          <div className="flex justify-between items-start">
            <div className="p-2.5 bg-secondary-container/35 rounded-xl">
              <ShoppingBag className="h-5 w-5 text-on-secondary-container" />
            </div>
            <div className="flex items-center gap-0.5 text-primary bg-primary/10 px-2.5 py-0.5 rounded-full text-[11px] font-bold">
              <TrendingUp className="h-3 w-3" />
              <span>{metrics.volumeTrend}</span>
            </div>
          </div>
          <div className="mt-5">
            <p className="text-xs font-bold text-on-surface-variant uppercase tracking-wider">Order Volume</p>
            <p className="text-2xl font-display font-extrabold text-on-surface mt-1">
              {metrics.volume.toLocaleString("en-US")}
            </p>
          </div>
        </div>

        {/* Card 3: Avg Order Value */}
        <div className="bg-surface-container-lowest p-5 rounded-3xl shadow-[0_4px_16px_rgba(0,108,73,0.02)] border border-outline-variant/10 flex flex-col justify-between hover:shadow-md transition-all dark:bg-surface-container-low">
          <div className="flex justify-between items-start">
            <div className="p-2.5 bg-tertiary-container/15 rounded-xl">
              <BarChart3 className="h-5 w-5 text-tertiary" />
            </div>
            <div className={`flex items-center gap-0.5 px-2.5 py-0.5 rounded-full text-[11px] font-bold ${
              metrics.aovPositive 
                ? "text-primary bg-primary/10" 
                : "text-error bg-error-container/20"
            }`}>
              {metrics.aovPositive ? <TrendingUp className="h-3 w-3" /> : <TrendingDown className="h-3 w-3" />}
              <span>{metrics.aovTrend}</span>
            </div>
          </div>
          <div className="mt-5">
            <p className="text-xs font-bold text-on-surface-variant uppercase tracking-wider">Avg. Order Value</p>
            <p className="text-2xl font-display font-extrabold text-on-surface mt-1">
              GHS {metrics.aov.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </p>
          </div>
        </div>

      </section>

      {/* Dynamic Animated Chart section */}
      <section className="bg-surface-container-lowest p-5 md:p-6 rounded-3xl shadow-[0_4px_16px_rgba(0,108,73,0.02)] border border-outline-variant/10 dark:bg-surface-container-low">
        <div className="flex justify-between items-center mb-6">
          <h3 className="font-display font-bold text-base text-on-surface">Revenue Trends</h3>
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-primary" />
              <span className="text-[11px] font-bold text-on-surface-variant uppercase tracking-wide">Current</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-outline-variant" />
              <span className="text-[11px] font-bold text-on-surface-variant uppercase tracking-wide">Previous</span>
            </div>
          </div>
        </div>

        {/* Custom Interactive Bars container */}
        <div className="h-[240px] w-full flex items-end justify-between gap-3 md:gap-5 pt-8 px-2 border-b border-outline-variant/20 relative">
          {metrics.chartData.map((data, idx) => (
            <div 
              key={idx} 
              className="flex-1 flex flex-col items-center gap-2 h-full justify-end relative group"
              onMouseEnter={() => setHoveredBar(idx)}
              onMouseLeave={() => setHoveredBar(null)}
            >
              {/* Dynamic tooltip on hover */}
              <div className={`absolute -top-1 px-2.5 py-1.5 rounded-lg bg-inverse-surface text-inverse-on-surface text-[10px] font-bold whitespace-nowrap shadow-md transition-all duration-150 select-none ${
                hoveredBar === idx ? "opacity-100 scale-100 -translate-y-2" : "opacity-0 scale-95 pointer-events-none"
              }`}>
                {data.valStr}
              </div>

              {/* Bar volume filler */}
              <div 
                style={{ height: `${data.value}%` }}
                className={`w-full rounded-t-lg transition-all duration-500 cursor-pointer ${
                  hoveredBar === idx 
                    ? "bg-primary-container" 
                    : "bg-primary/20 dark:bg-primary/30"
                } ${
                  idx === 3 && timeframe === "7days" ? "bg-primary" : ""
                }`} 
              />
              
              <span className={`text-[10px] font-bold mb-[-24px] uppercase ${
                hoveredBar === idx || (idx === 3 && timeframe === "7days") 
                  ? "text-primary" 
                  : "text-on-surface-variant"
              }`}>
                {data.label}
              </span>
            </div>
          ))}
        </div>
        <div className="h-6" /> {/* Spacer for labels */}
      </section>

      {/* Split Section: Top Selling Items and Customer Insights */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        
        {/* Top Selling list */}
        <section className="bg-surface-container-lowest p-5 rounded-3xl shadow-[0_4px_16px_rgba(0,108,73,0.02)] border border-outline-variant/10 dark:bg-surface-container-low">
          <div className="flex justify-between items-center mb-5">
            <h3 className="font-display font-bold text-base text-on-surface">Top Selling Items</h3>
            <button className="text-primary text-xs font-bold hover:underline">View All</button>
          </div>

          <div className="space-y-4">
            {topSelling.map((item, idx) => (
              <div key={item.id} className="flex items-center gap-4 group">
                <div className="w-14 h-14 rounded-xl overflow-hidden bg-surface-container shrink-0 border border-outline-variant/10">
                  <img className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" src={item.image} alt={item.name} referrerPolicy="no-referrer" />
                </div>
                
                <div className="flex-1 min-w-0">
                  <h4 className="text-xs font-bold text-on-surface truncate">{item.name}</h4>
                  <p className="text-[10px] font-semibold text-on-surface-variant mt-0.5">{item.soldCount} orders this week</p>
                </div>

                <div className="text-right">
                  <p className="text-xs font-bold text-on-surface">GHS {item.price.toFixed(2)}</p>
                  <p className="text-[10px] font-bold text-primary mt-0.5">{item.soldTrend}</p>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Customer Insights with Circular Donut */}
        <section className="bg-surface-container-lowest p-5 rounded-3xl shadow-[0_4px_16px_rgba(0,108,73,0.02)] border border-outline-variant/10 dark:bg-surface-container-low flex flex-col justify-between">
          <h3 className="font-display font-bold text-base text-on-surface mb-2">Customer Insights</h3>
          
          <div className="flex flex-col sm:flex-row items-center justify-around gap-6 py-2">
            {/* SVG Donut Chart */}
            <div className="relative w-36 h-36 flex items-center justify-center shrink-0">
              <svg className="w-full h-full transform -rotate-90" viewBox="0 0 36 36">
                <circle cx="18" cy="18" fill="transparent" r="15.915" stroke="var(--outline-variant)" strokeOpacity="0.25" strokeWidth="3" />
                <circle cx="18" cy="18" fill="transparent" r="15.915" stroke="var(--primary)" strokeDasharray="65 35" strokeLinecap="round" strokeWidth="3" />
              </svg>
              <div className="absolute flex flex-col items-center">
                <span className="font-display font-black text-xl text-on-surface">65%</span>
                <span className="text-[8px] uppercase tracking-wider text-on-surface-variant font-bold">Returning</span>
              </div>
            </div>

            {/* Legends */}
            <div className="space-y-4 w-full sm:w-auto">
              <div className="flex items-center gap-2.5">
                <span className="w-3 h-3 rounded-full bg-primary" />
                <div>
                  <p className="text-xs font-bold text-on-surface">Returning Customers</p>
                  <p className="text-[10px] text-on-surface-variant font-semibold">548 active users</p>
                </div>
              </div>

              <div className="flex items-center gap-2.5">
                <span className="w-3 h-3 rounded-full bg-outline-variant" />
                <div>
                  <p className="text-xs font-bold text-on-surface">New Customers</p>
                  <p className="text-[10px] text-on-surface-variant font-semibold">294 active users</p>
                </div>
              </div>

              <div className="pt-2 border-t border-outline-variant/20">
                <p className="text-[10px] font-bold text-primary flex items-center gap-1">
                  <Verified className="h-3.5 w-3.5 shrink-0" />
                  <span>Retention up 4% vs last week</span>
                </p>
              </div>
            </div>
          </div>
        </section>

      </div>

      {/* Growth/Optimization tips */}
      <section className="bg-primary/10 p-5 rounded-3xl border border-primary/20 relative overflow-hidden dark:bg-primary/5">
        <div className="relative z-10">
          <div className="flex items-center gap-2 mb-4">
            <Lightbulb className="h-5 w-5 text-primary" />
            <h3 className="font-display font-bold text-base text-primary">Merchant Pro-Tips</h3>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="bg-surface-container-lowest/80 p-4 rounded-2xl shadow-[0_2px_8px_rgba(0,108,73,0.01)] border border-white/40 dark:bg-surface-container-low">
              <h4 className="text-xs font-bold text-on-surface">Boost Lunch Sales</h4>
              <p className="text-[11px] text-on-surface-variant leading-relaxed mt-1">
                Consider a "Bundle Discount" for the Avocado Harvest Bowl between 11 AM - 2 PM to increase average customer cart volume.
              </p>
            </div>

            <div className="bg-surface-container-lowest/80 p-4 rounded-2xl shadow-[0_2px_8px_rgba(0,108,73,0.01)] border border-white/40 dark:bg-surface-container-low">
              <h4 className="text-xs font-bold text-on-surface">Improve Retention</h4>
              <p className="text-[11px] text-on-surface-variant leading-relaxed mt-1">
                Launch a "Loyalty Perk" coupon for customers who order more than 3 times a month to fully secure high-value recurring users.
              </p>
            </div>
          </div>
        </div>
        <div className="absolute -right-8 -top-8 w-32 h-32 bg-primary/5 rounded-full blur-2xl" />
      </section>

    </div>
  );
}
