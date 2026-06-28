import React, { useState } from 'react';
import { 
  ShoppingCart, 
  Bike, 
  DollarSign, 
  AlertTriangle,
  Server,
  Database,
  CheckCircle2,
  TrendingUp,
  MoreVertical,
  Activity,
  ArrowRight
} from 'lucide-react';
import { motion } from 'motion/react';
import { Screen } from '../types';

interface DashboardViewProps {
  setActiveScreen: (screen: Screen) => void;
}

export default function DashboardView({ setActiveScreen }: DashboardViewProps) {
  const [timeframe, setTimeframe] = useState<'hourly' | 'daily'>('daily');
  const [hoveredBar, setHoveredBar] = useState<number | null>(null);

  // Growth data simulation
  const chartData = timeframe === 'daily' 
    ? [240, 380, 310, 520, 480, 690, 850, 1284]
    : [42, 68, 55, 98, 124, 184, 142, 210, 190, 240, 280, 320];

  const maxVal = Math.max(...chartData);

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-12">
      
      {/* 1. KPIs Section (Bento Grid) */}
      <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Active Orders */}
        <motion.div 
          whileHover={{ y: -4 }}
          onClick={() => setActiveScreen('fleet')}
          className="bg-surface-container-lowest dark:bg-surface-container-low p-5 rounded-2xl border border-outline-variant/30 shadow-sm flex flex-col justify-between cursor-pointer group"
        >
          <div className="flex justify-between items-start">
            <div className="p-2 bg-primary/10 rounded-xl text-primary">
              <ShoppingCart className="w-5 h-5" />
            </div>
            <span className="text-primary text-xs font-bold bg-primary/10 px-2 py-0.5 rounded-full">+12%</span>
          </div>
          <div className="mt-4">
            <p className="text-on-surface-variant text-xs font-semibold uppercase tracking-wider">Active Orders</p>
            <h3 className="text-2xl md:text-3xl font-extrabold text-on-surface mt-1 group-hover:text-primary transition-colors">1,284</h3>
          </div>
        </motion.div>

        {/* Online Riders */}
        <motion.div 
          whileHover={{ y: -4 }}
          onClick={() => setActiveScreen('fleet')}
          className="bg-surface-container-lowest dark:bg-surface-container-low p-5 rounded-2xl border border-outline-variant/30 shadow-sm flex flex-col justify-between cursor-pointer group"
        >
          <div className="flex justify-between items-start">
            <div className="p-2 bg-tertiary-container/10 rounded-xl text-tertiary">
              <Bike className="w-5 h-5" />
            </div>
            <span className="text-primary text-xs font-bold bg-primary/10 px-2 py-0.5 rounded-full">+5%</span>
          </div>
          <div className="mt-4">
            <p className="text-on-surface-variant text-xs font-semibold uppercase tracking-wider">Online Riders</p>
            <h3 className="text-2xl md:text-3xl font-extrabold text-on-surface mt-1 group-hover:text-tertiary transition-colors">452</h3>
          </div>
        </motion.div>

        {/* Daily Revenue */}
        <motion.div 
          whileHover={{ y: -4 }}
          onClick={() => setActiveScreen('wallet')}
          className="bg-surface-container-lowest dark:bg-surface-container-low p-5 rounded-2xl border border-outline-variant/30 shadow-sm flex flex-col justify-between cursor-pointer group"
        >
          <div className="flex justify-between items-start">
            <div className="p-2 bg-primary-container/15 rounded-xl text-on-primary-container">
              <DollarSign className="w-5 h-5" />
            </div>
            <span className="text-primary text-xs font-bold bg-primary/10 px-2 py-0.5 rounded-full">+18%</span>
          </div>
          <div className="mt-4">
            <p className="text-on-surface-variant text-xs font-semibold uppercase tracking-wider">Daily Revenue</p>
            <h3 className="text-2xl md:text-3xl font-extrabold text-on-surface mt-1 group-hover:text-primary-container transition-colors">$42,910</h3>
          </div>
        </motion.div>

        {/* System Alerts KPI */}
        <motion.div 
          whileHover={{ y: -4 }}
          onClick={() => setActiveScreen('security')}
          className="bg-error-container p-5 rounded-2xl border border-error/20 shadow-sm flex flex-col justify-between cursor-pointer group"
        >
          <div className="flex justify-between items-start">
            <div className="p-2 bg-error/10 rounded-xl text-error">
              <AlertTriangle className="w-5 h-5" />
            </div>
            <span className="bg-error text-on-error text-[9px] px-2 py-0.5 rounded-full font-black uppercase tracking-wider">CRITICAL</span>
          </div>
          <div className="mt-4">
            <p className="text-on-error-container text-xs font-semibold uppercase tracking-wider">System Alerts</p>
            <h3 className="text-2xl md:text-3xl font-extrabold text-on-error-container mt-1">02</h3>
          </div>
        </motion.div>
      </section>

      {/* 2. Growth & Alerts Row */}
      <section className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Platform Growth Chart Panel */}
        <div className="lg:col-span-2 bg-surface-container-lowest dark:bg-surface-container-low p-6 rounded-2xl border border-outline-variant/20 shadow-sm">
          <div className="flex justify-between items-center mb-6">
            <div>
              <h4 className="text-lg font-bold text-on-surface">Platform Growth</h4>
              <p className="text-xs text-on-surface-variant mt-0.5">Deliveries over the billing cycle</p>
            </div>
            <div className="flex gap-1 bg-surface-container-low dark:bg-surface-container p-1 rounded-xl border border-outline-variant/20">
              <button 
                onClick={() => setTimeframe('hourly')}
                className={`px-3 py-1 text-xs font-bold rounded-lg transition-all cursor-pointer ${
                  timeframe === 'hourly' ? 'bg-primary text-on-primary shadow-sm' : 'text-on-surface-variant hover:text-on-surface'
                }`}
              >
                Hourly
              </button>
              <button 
                onClick={() => setTimeframe('daily')}
                className={`px-3 py-1 text-xs font-bold rounded-lg transition-all cursor-pointer ${
                  timeframe === 'daily' ? 'bg-primary text-on-primary shadow-sm' : 'text-on-surface-variant hover:text-on-surface'
                }`}
              >
                Daily
              </button>
            </div>
          </div>

          {/* Interactive Custom SVG/HTML Bar Chart */}
          <div className="relative h-64 w-full bg-surface-container/30 rounded-xl border border-outline-variant/10 p-4 flex items-end justify-between overflow-hidden group">
            {chartData.map((val, idx) => {
              const heightPct = `${Math.max(15, (val / maxVal) * 85)}%`;
              return (
                <div 
                  key={idx} 
                  className="flex flex-col items-center flex-1 mx-1.5 h-full justify-end relative cursor-pointer"
                  onMouseEnter={() => setHoveredBar(idx)}
                  onMouseLeave={() => setHoveredBar(null)}
                >
                  {/* Floating tooltip on hover */}
                  {hoveredBar === idx && (
                    <motion.div 
                      initial={{ opacity: 0, y: 10, scale: 0.95 }}
                      animate={{ opacity: 1, y: 0, scale: 1 }}
                      className="absolute -top-10 bg-on-surface text-surface-container-lowest text-[10px] font-bold px-2 py-1 rounded-lg whitespace-nowrap shadow-lg z-20"
                    >
                      {timeframe === 'daily' ? `Day ${idx + 1}` : `${idx * 2}:00`}: <span className="text-primary-container">{val.toLocaleString()}</span>
                    </motion.div>
                  )}

                  {/* Active growth Bar */}
                  <div 
                    className={`w-full rounded-t-lg transition-all duration-300 relative ${
                      hoveredBar === idx 
                        ? 'bg-primary shadow-lg shadow-primary/20 scale-x-105' 
                        : 'bg-primary/50 group-hover:bg-primary/30'
                    }`}
                    style={{ height: heightPct }}
                  >
                    {/* Pulsing indicator on last bar */}
                    {idx === chartData.length - 1 && (
                      <span className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1 w-2.5 h-2.5 bg-primary-container rounded-full border-2 border-surface-container-lowest animate-ping"></span>
                    )}
                  </div>
                  <span className="text-[9px] text-outline mt-2 font-bold select-none">
                    {timeframe === 'daily' ? `Oct 0${idx + 1}` : `${idx * 2}h`}
                  </span>
                </div>
              );
            })}
          </div>
        </div>

        {/* System Notifications Panel */}
        <div className="bg-surface-container-lowest dark:bg-surface-container-low p-6 rounded-2xl border border-outline-variant/20 shadow-sm flex flex-col justify-between">
          <div>
            <h4 className="text-lg font-bold text-on-surface mb-4">System Alerts</h4>
            
            <div className="space-y-3.5">
              {/* Alert Item 1 */}
              <div className="p-3 bg-error/5 border-l-4 border-error rounded-xl flex gap-3 items-start">
                <Server className="w-4 h-4 text-error shrink-0 mt-0.5" />
                <div>
                  <p className="font-bold text-xs text-on-error-container">Region Delay: Central</p>
                  <p className="text-[11px] text-on-surface-variant leading-relaxed mt-0.5">
                    High traffic in central hub causing 15m delay in logistics processing.
                  </p>
                </div>
              </div>

              {/* Alert Item 2 */}
              <div className="p-3 bg-tertiary-container/10 border-l-4 border-tertiary rounded-xl flex gap-3 items-start">
                <Activity className="w-4 h-4 text-tertiary shrink-0 mt-0.5" />
                <div>
                  <p className="font-bold text-xs text-on-tertiary-container">Server Load High</p>
                  <p className="text-[11px] text-on-surface-variant leading-relaxed mt-0.5">
                    System CPU at 85%. Automated server scaling is currently active.
                  </p>
                </div>
              </div>

              {/* Alert Item 3 */}
              <div className="p-3 bg-primary/5 border-l-4 border-primary rounded-xl flex gap-3 items-start">
                <Database className="w-4 h-4 text-primary shrink-0 mt-0.5" />
                <div>
                  <p className="font-bold text-xs text-on-primary-container">Backup Completed</p>
                  <p className="text-[11px] text-on-surface-variant leading-relaxed mt-0.5">
                    Full system backup mirrored securely to Dublin Node 4.
                  </p>
                </div>
              </div>
            </div>
          </div>

          <button 
            onClick={() => setActiveScreen('security')}
            className="mt-5 w-full py-2.5 bg-surface-container dark:bg-surface-container-high hover:bg-surface-container-highest text-on-surface font-bold text-xs rounded-xl border border-outline-variant/20 transition-colors flex items-center justify-center gap-1.5 cursor-pointer"
          >
            <span>View Security Logs</span>
            <ArrowRight className="w-3.5 h-3.5" />
          </button>
        </div>
      </section>

      {/* 3. Core Modules Grid */}
      <section className="space-y-3">
        <h4 className="text-lg font-bold text-on-surface">Core Modules</h4>
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          
          {/* Module: Fleet */}
          <div 
            onClick={() => setActiveScreen('fleet')}
            className="group relative h-48 rounded-2xl overflow-hidden shadow-md border border-white/10 cursor-pointer"
          >
            <img 
              className="absolute inset-0 w-full h-full object-cover transition-transform duration-500 group-hover:scale-110" 
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuCBYEUK8fa3NHqXE9NC-76kwp9PEyKf4CQrHP0v4wS_Mf-w2vQiFUJIqIFuc14bD7RgTswxLhM4oIMhRPTY4I18mn-DuowqvR_iLclpw4JJU6nNOn7Su40xYEw95BCpjJeIYz28JnPz9uYPMCk5G-UgmzSBBi6nhOZ8_JDJKzF3aUcUDrzijbDwE6HdBeu-hisDF6_RujI92PlPGZXnjYBchlXcyEhzLGuax83NEvR8S-z7OmWOHLbglKLWvdiOarsj-FxlpRt-ahU" 
              alt="Fleet Module" 
              referrerPolicy="no-referrer"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/30 to-transparent p-4 flex flex-col justify-end">
              <h5 className="text-white font-bold text-base leading-tight">Fleet Map</h5>
              <p className="text-white/70 text-[11px] mt-0.5">Manage Riders & Routes</p>
            </div>
          </div>

          {/* Module: Finance */}
          <div 
            onClick={() => setActiveScreen('wallet')}
            className="group relative h-48 rounded-2xl overflow-hidden shadow-md border border-white/10 cursor-pointer"
          >
            <img 
              className="absolute inset-0 w-full h-full object-cover transition-transform duration-500 group-hover:scale-110" 
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuARzULvl9QTkHgHEiyuWtuLGzgxedyqCFca6ESuN6OCpPd2DrubhaivS6GpK2q5NgqOiSzFUtjBN6c173GUlshVmOXFL9viJquQheZaWI0AbnC48aYmut3V7KIy0q1yikgBlJDb664RljaFDqHfWiTDUG75s3fztlGIKPJ8X5Qi8xtDeSCeHeg3Yxd4PbB7go2db1lRXD0tLoIf60u0l0_8cZdVj562X39KM4hqsN-MmGrF3Zt6E3OYpfYrEt65VaYttpUGi1eacbA" 
              alt="Finance Module" 
              referrerPolicy="no-referrer"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/30 to-transparent p-4 flex flex-col justify-end">
              <h5 className="text-white font-bold text-base leading-tight">Finance</h5>
              <p className="text-white/70 text-[11px] mt-0.5">Payouts & Revenue</p>
            </div>
          </div>

          {/* Module: Users */}
          <div 
            onClick={() => setActiveScreen('reports')}
            className="group relative h-48 rounded-2xl overflow-hidden shadow-md border border-white/10 cursor-pointer"
          >
            <img 
              className="absolute inset-0 w-full h-full object-cover transition-transform duration-500 group-hover:scale-110" 
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuARZPk83BgXSDTgPHL2zgbgfpyc-rJjOVPJF3PM_kwJNwQ_MAJw43YoqX7Gb-Ehw6Nr0A77R0AD8CpF-uA4okMsKW5f6bUeG8NGxfV12jmxZ8sIL6uuPmHRnaKHqR9QIkbo_G8QgBOIE7qZyS9C1wzAVkuiiM7Oba66x7UViHg38iUVHeO6h2BEKGltnocb4luJc0i0uQZMgiU1ZJLRxNERYnO-MHuaB8Ke25KNHzRK04so5p2VLtryZpg74mP8yDRU5GAwioFyTqY" 
              alt="Users Module" 
              referrerPolicy="no-referrer"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/30 to-transparent p-4 flex flex-col justify-end">
              <h5 className="text-white font-bold text-base leading-tight">Analytics</h5>
              <p className="text-white/70 text-[11px] mt-0.5">Roles & SLA metrics</p>
            </div>
          </div>

          {/* Module: Settings */}
          <div 
            onClick={() => setActiveScreen('security')}
            className="group relative h-48 rounded-2xl overflow-hidden shadow-md border border-white/10 cursor-pointer"
          >
            <img 
              className="absolute inset-0 w-full h-full object-cover transition-transform duration-500 group-hover:scale-110" 
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuAmB6vEykyRi3SErzzoc3CWRVUnT6yEvrhT0owdzlxnCwCrRJoWiGA-rhindvEHPtExTT6kgSyRyrAd8lv0LkhQjNgEWrDnWXij2-lSrIEdVemUr265-w5PzGugU8h1uX4kKnGo9yjsoP5keA0F4lIb1COSFsIdgqMnDaskTHCNvT8qm9uMuu47o-rRa7QTBXXpylJ1zMTfSKOjuUkTvMMLgKhfKEvHIhlaEBjEQU9f5Uw-dHfMv0HcfZ1iAQaQKCheX_OriFGotkA" 
              alt="Settings Module" 
              referrerPolicy="no-referrer"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/30 to-transparent p-4 flex flex-col justify-end">
              <h5 className="text-white font-bold text-base leading-tight">Settings</h5>
              <p className="text-white/70 text-[11px] mt-0.5">System Configuration</p>
            </div>
          </div>

        </div>
      </section>

    </div>
  );
}
