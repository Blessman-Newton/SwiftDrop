import React, { useState } from 'react';
import { 
  TrendingUp, 
  Clock, 
  MapPin, 
  AlertTriangle, 
  Utensils, 
  Package, 
  MoreHorizontal,
  ChevronRight,
  Plus,
  RefreshCw,
  Search,
  CheckCircle,
  Activity
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { Hub } from '../types';

export default function FleetMonitoringView() {
  const [activeTab, setActiveTab] = useState<'fleet' | 'hubs'>('fleet');
  const [serviceFilter, setServiceFilter] = useState({ food: true, parcel: true });
  const [selectedHub, setSelectedHub] = useState<string | null>(null);
  const [showNotification, setShowNotification] = useState(false);
  const [notificationMsg, setNotificationMsg] = useState('');

  // Initial list of Regional Hubs
  const [hubs, setHubs] = useState<Hub[]>([
    { id: 'hub-01', name: 'North Greenwich (HUB-01)', status: 'peak', statusText: 'Peak Performance', rating: 9.8, capacity: 88, pendingOrders: 142 },
    { id: 'hub-04', name: 'Westminster (HUB-04)', status: 'congested', statusText: 'Congested Area', rating: 8.2, capacity: 92, pendingOrders: 298 },
    { id: 'hub-07', name: 'Shoreditch (HUB-07)', status: 'normal', statusText: 'Normal Ops', rating: 9.4, capacity: 45, pendingOrders: 34 },
    { id: 'hub-12', name: 'Chelsea Harbor (HUB-12)', status: 'low', statusText: 'Underutilized', rating: 9.1, capacity: 24, pendingOrders: 12 },
  ]);

  // Handle mock order dispatching
  const handleDispatchOrder = (hubId: string) => {
    setHubs(prevHubs => 
      prevHubs.map(hub => {
        if (hub.id === hubId) {
          const newOrders = Math.max(0, hub.pendingOrders - 1);
          const newCapacity = Math.max(10, Math.floor(hub.capacity - 1.5));
          triggerNotification(`Dispatched order successfully from ${hub.name}! Remaining pending: ${newOrders}`);
          return { ...hub, pendingOrders: newOrders, capacity: newCapacity };
        }
        return hub;
      })
    );
  };

  const triggerNotification = (msg: string) => {
    setNotificationMsg(msg);
    setShowNotification(true);
    setTimeout(() => setShowNotification(false), 3500);
  };

  // Status statistics inside filters
  const [statusActive, setStatusActive] = useState(1204);

  return (
    <div className="relative w-full h-[calc(100vh-140px)] md:h-[calc(100vh-70px)] overflow-hidden rounded-2xl border border-outline-variant/30 shadow-lg">
      
      {/* Toast Notification for Interactivity */}
      <AnimatePresence>
        {showNotification && (
          <motion.div 
            initial={{ opacity: 0, y: -20, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -20, scale: 0.95 }}
            className="absolute top-4 left-1/2 -translate-x-1/2 z-50 bg-primary text-on-primary px-4 py-2.5 rounded-xl shadow-xl flex items-center gap-2 font-semibold text-xs border border-primary-container"
          >
            <CheckCircle className="w-4 h-4 shrink-0" />
            <span>{notificationMsg}</span>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Simulated Map Background with Satellite-style layer */}
      <div className="absolute inset-0 z-0 bg-surface-container select-none">
        <div 
          className="w-full h-full bg-cover bg-center grayscale dark:invert dark:contrast-125 contrast-75 brightness-110 opacity-90 transition-all duration-500"
          style={{ backgroundImage: `url('https://lh3.googleusercontent.com/aida-public/AB6AXuCMyyv3eXK93x12pGZcbdKX_q6IWH8TWJlWVujhmjbSA2WEXH5KgsqcdP2agjlAn5t1xr555UMDdztoLnynsULne4OeMixGBSi1Q0MnEPJe9wNs8Glt-Xl9ayliI4ORkQitUIKh2dHsiZ3bcnxHt-xc0j6uNyFLKcGQU64lcZ60o_ikn-GjLrzwyr8mSWTCh0UuNU_7EF1h3T940OTLXTyYsu-jXSGMcwaFRadWlXa1RoG0Gb0ZwlwBp6AI4UL3xh2dYD4w4zheT1Q')` }}
        />

        {/* Dynamic Pins reflecting filter states */}
        {serviceFilter.food && (
          <div className="absolute top-[28%] left-[34%] z-10 transition-all duration-300">
            <div className="w-12 h-12 bg-primary/25 rounded-full flex items-center justify-center map-pulse">
              <div className="w-7 h-7 bg-primary text-on-primary rounded-full flex items-center justify-center text-[10px] font-bold shadow-lg border-2 border-surface-container-lowest">
                42
              </div>
            </div>
            <span className="absolute -bottom-5 left-1/2 -translate-x-1/2 bg-surface-container-lowest dark:bg-surface-container-low text-[9px] font-bold px-1.5 py-0.5 rounded shadow text-on-surface whitespace-nowrap">
              Food Clusters
            </span>
          </div>
        )}

        {serviceFilter.parcel && (
          <div className="absolute bottom-[35%] right-[28%] z-10 transition-all duration-300">
            <div className="w-16 h-16 bg-primary/15 rounded-full flex items-center justify-center map-pulse" style={{ animationDelay: '0.6s' }}>
              <div className="w-8 h-8 bg-primary text-on-primary rounded-full flex items-center justify-center text-xs font-bold shadow-lg border-2 border-surface-container-lowest">
                128
              </div>
            </div>
            <span className="absolute -bottom-5 left-1/2 -translate-x-1/2 bg-surface-container-lowest dark:bg-surface-container-low text-[9px] font-bold px-1.5 py-0.5 rounded shadow text-on-surface whitespace-nowrap">
              Express Hubs
            </span>
          </div>
        )}

        {/* Active Incident Pin */}
        <div className="absolute top-[52%] left-[48%] z-10">
          <div className="w-10 h-10 bg-error/20 rounded-full flex items-center justify-center map-pulse" style={{ animationDelay: '1.2s' }}>
            <div className="w-6 h-6 bg-error text-on-error rounded-full flex items-center justify-center shadow-lg border-2 border-surface-container-lowest">
              <AlertTriangle className="w-3.5 h-3.5" />
            </div>
          </div>
          <span className="absolute -bottom-5 left-1/2 -translate-x-1/2 bg-error text-on-error text-[8px] font-extrabold px-1.5 py-0.5 rounded shadow whitespace-nowrap uppercase tracking-wider">
            Traffic Incident
          </span>
        </div>

        {/* Mock interactive focal ring */}
        {selectedHub && (
          <div className={`absolute transition-all duration-700 ${
            selectedHub === 'hub-01' ? 'top-[28%] left-[34%]' :
            selectedHub === 'hub-04' ? 'top-[52%] left-[48%]' :
            selectedHub === 'hub-07' ? 'bottom-[35%] right-[28%]' : 'top-[40%] left-[50%]'
          } z-20`}>
            <div className="w-24 h-24 border-2 border-dashed border-primary rounded-full flex items-center justify-center animate-spin" style={{ animationDuration: '8s' }}></div>
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-primary/20 text-primary p-1 rounded-full">
              <Activity className="w-4 h-4 animate-bounce" />
            </div>
          </div>
        )}
      </div>

      {/* OVERLAY PANELS */}

      {/* Filters & Controls (Top Left) */}
      <div className="absolute top-4 left-4 z-20 flex flex-col gap-3 max-w-xs pointer-events-none">
        {/* Toggle Pills */}
        <div className="glass-panel p-1 rounded-full shadow-lg flex items-center pointer-events-auto border border-outline-variant/30 self-start bg-surface-container-lowest/70 backdrop-blur-md">
          <button 
            onClick={() => setActiveTab('fleet')}
            className={`px-4 py-1.5 rounded-full text-xs font-semibold transition-all cursor-pointer ${
              activeTab === 'fleet' ? 'bg-primary text-on-primary shadow-sm' : 'text-on-surface-variant hover:bg-surface-container-high'
            }`}
          >
            Fleet
          </button>
          <button 
            onClick={() => setActiveTab('hubs')}
            className={`px-4 py-1.5 rounded-full text-xs font-semibold transition-all cursor-pointer ${
              activeTab === 'hubs' ? 'bg-primary text-on-primary shadow-sm' : 'text-on-surface-variant hover:bg-surface-container-high'
            }`}
          >
            Hubs
          </button>
        </div>

        {/* Filter View panel */}
        <div className="glass-panel p-4 rounded-2xl shadow-lg w-64 pointer-events-auto border border-outline-variant/30 bg-surface-container-lowest/80 backdrop-blur-md">
          <p className="text-[10px] font-bold text-outline uppercase tracking-wider mb-2">
            Filter Options
          </p>
          <div className="space-y-3.5">
            <div>
              <label className="text-xs font-bold text-on-surface mb-1.5 block">Service Type</label>
              <div className="grid grid-cols-2 gap-2">
                <label className="cursor-pointer border border-outline-variant/40 rounded-xl p-2 flex items-center gap-1.5 hover:border-primary transition-colors bg-surface-container-lowest dark:bg-surface-container-low">
                  <input 
                    type="checkbox" 
                    checked={serviceFilter.food} 
                    onChange={() => setServiceFilter(prev => ({ ...prev, food: !prev.food }))}
                    className="accent-primary rounded"
                  />
                  <Utensils className="w-3.5 h-3.5 text-outline shrink-0" />
                  <span className="text-[10px] font-semibold text-on-surface">Food</span>
                </label>
                <label className="cursor-pointer border border-outline-variant/40 rounded-xl p-2 flex items-center gap-1.5 hover:border-primary transition-colors bg-surface-container-lowest dark:bg-surface-container-low">
                  <input 
                    type="checkbox" 
                    checked={serviceFilter.parcel} 
                    onChange={() => setServiceFilter(prev => ({ ...prev, parcel: !prev.parcel }))}
                    className="accent-primary rounded"
                  />
                  <Package className="w-3.5 h-3.5 text-outline shrink-0" />
                  <span className="text-[10px] font-semibold text-on-surface">Parcel</span>
                </label>
              </div>
            </div>

            <div>
              <label className="text-xs font-bold text-on-surface mb-1.5 block">Live Telemetry</label>
              <div className="flex flex-col gap-1.5">
                <div className="flex items-center justify-between text-[11px] text-on-surface-variant bg-surface-container-low p-1.5 rounded-lg border border-outline-variant/20">
                  <span className="flex items-center gap-1.5">
                    <span className="w-1.5 h-1.5 bg-primary rounded-full animate-pulse"></span>
                    Active Riders
                  </span>
                  <span className="font-bold text-on-surface">{statusActive}</span>
                </div>
                <div className="flex items-center justify-between text-[11px] text-on-surface-variant bg-surface-container-low p-1.5 rounded-lg border border-outline-variant/20">
                  <span className="flex items-center gap-1.5">
                    <span className="w-1.5 h-1.5 bg-tertiary rounded-full"></span>
                    SLA Delay Alerts
                  </span>
                  <span className="font-bold text-tertiary">3</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Live Fleet Status (Top Right - Bento Stats Panel) */}
      <div className="absolute top-4 right-4 z-20 flex flex-col gap-3 max-w-sm pointer-events-none md:max-w-xs lg:max-w-sm">
        {/* Availability / Delivery Stats */}
        <div className="grid grid-cols-2 gap-3 pointer-events-auto">
          <div className="glass-panel p-3 rounded-2xl shadow-lg border border-outline-variant/30 bg-surface-container-lowest/80 backdrop-blur-md">
            <div className="flex items-center gap-1.5 text-primary mb-1">
              <TrendingUp className="w-4 h-4" />
              <span className="text-[10px] font-bold uppercase tracking-wider">Availability</span>
            </div>
            <h4 className="text-xl font-extrabold text-on-surface">94.2%</h4>
            <p className="text-[9px] text-primary mt-0.5 font-bold">+2.4% last hour</p>
          </div>

          <div className="glass-panel p-3 rounded-2xl shadow-lg border border-outline-variant/30 bg-surface-container-lowest/80 backdrop-blur-md">
            <div className="flex items-center gap-1.5 text-tertiary mb-1">
              <Clock className="w-4 h-4" />
              <span className="text-[10px] font-bold uppercase tracking-wider">Avg. Delivery</span>
            </div>
            <h4 className="text-xl font-extrabold text-on-surface">22.4m</h4>
            <p className="text-[9px] text-on-surface-variant mt-0.5">-30s below target</p>
          </div>
        </div>

        {/* Fleet Distribution card */}
        <div className="glass-panel p-4 rounded-2xl shadow-lg border border-outline-variant/30 bg-surface-container-lowest/80 backdrop-blur-md pointer-events-auto">
          <div className="flex justify-between items-center mb-2.5">
            <h4 className="text-xs font-bold uppercase tracking-wider text-on-surface">
              Fleet Distribution
            </h4>
            <MoreHorizontal className="w-4 h-4 text-outline" />
          </div>
          <div className="space-y-3">
            <div className="space-y-1">
              <div className="flex justify-between text-xs">
                <span className="text-on-surface-variant">City Center</span>
                <span className="font-extrabold text-on-surface">642 units</span>
              </div>
              <div className="w-full bg-surface-container-high dark:bg-surface-container-low h-1.5 rounded-full overflow-hidden">
                <div className="bg-primary h-full w-[65%] rounded-full transition-all duration-500"></div>
              </div>
            </div>

            <div className="space-y-1">
              <div className="flex justify-between text-xs">
                <span className="text-on-surface-variant">Suburban Hubs</span>
                <span className="font-extrabold text-on-surface">410 units</span>
              </div>
              <div className="w-full bg-surface-container-high dark:bg-surface-container-low h-1.5 rounded-full overflow-hidden">
                <div className="bg-primary-container h-full w-[40%] rounded-full transition-all duration-500"></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Regional Hubs List (Bottom Right Panel) */}
      <div className="absolute right-4 bottom-12 md:bottom-4 z-20 w-80 max-h-[42%] md:max-h-[48%] pointer-events-auto">
        <div className="glass-panel rounded-2xl shadow-xl flex flex-col h-full overflow-hidden border border-outline-variant/30 bg-surface-container-lowest/90 backdrop-blur-md">
          {/* Panel Header */}
          <div className="p-3 border-b border-outline-variant/30 bg-surface-container-low/50">
            <h3 className="font-extrabold text-sm text-on-surface mb-0.5">Regional Hubs</h3>
            <p className="text-[11px] text-on-surface-variant">Live capacity & dispatcher center</p>
          </div>

          {/* Hubs Scrollable List */}
          <div className="flex-1 overflow-y-auto p-2.5 space-y-2 bg-surface-container/20">
            {hubs.map((hub) => (
              <div 
                key={hub.id}
                onClick={() => setSelectedHub(hub.id === selectedHub ? null : hub.id)}
                className={`p-2.5 rounded-xl shadow-sm border transition-all cursor-pointer group relative ${
                  selectedHub === hub.id 
                    ? 'bg-primary/5 dark:bg-primary/10 border-primary ring-1 ring-primary/20' 
                    : 'bg-surface-container-lowest dark:bg-surface-container-low border-outline-variant/20 hover:border-primary/50'
                }`}
              >
                <div className="flex justify-between items-start mb-1.5">
                  <div>
                    <h5 className="text-xs font-bold text-on-surface group-hover:text-primary transition-colors">
                      {hub.name}
                    </h5>
                    <p className="text-[10px] text-on-surface-variant flex items-center gap-1 mt-0.5">
                      <span className={`w-1.5 h-1.5 rounded-full ${
                        hub.status === 'peak' ? 'bg-red-500' :
                        hub.status === 'congested' ? 'bg-amber-500' :
                        hub.status === 'normal' ? 'bg-emerald-500' : 'bg-blue-500'
                      }`}></span>
                      {hub.statusText}
                    </p>
                  </div>
                  <span className={`text-[10px] font-black px-1.5 py-0.5 rounded ${
                    hub.rating >= 9.5 ? 'text-primary bg-primary-container/15' : 'text-secondary bg-secondary-container/15'
                  }`}>
                    {hub.rating}
                  </span>
                </div>

                <div className="grid grid-cols-2 gap-2 mt-2">
                  <div className="bg-surface-container-low dark:bg-surface-container/40 p-1.5 rounded-lg text-[10px]">
                    <span className="block text-outline text-[9px] uppercase tracking-wider">Capacity</span>
                    <span className={`font-bold ${hub.capacity >= 85 ? 'text-error' : 'text-on-surface'}`}>
                      {hub.capacity}% {hub.capacity >= 85 ? '(High)' : '(Stable)'}
                    </span>
                  </div>
                  <div className="bg-surface-container-low dark:bg-surface-container/40 p-1.5 rounded-lg text-[10px] flex justify-between items-center">
                    <div>
                      <span className="block text-outline text-[9px] uppercase tracking-wider">Pending</span>
                      <span className="font-bold text-on-surface">{hub.pendingOrders} Orders</span>
                    </div>
                    {/* Quick Interactive Dispatch Button */}
                    {hub.pendingOrders > 0 && (
                      <button 
                        onClick={(e) => {
                          e.stopPropagation();
                          handleDispatchOrder(hub.id);
                        }}
                        className="bg-primary text-on-primary p-1 rounded hover:bg-primary-hover active:scale-95 transition-all cursor-pointer"
                        title="Dispatch Order"
                      >
                        <RefreshCw className="w-3.5 h-3.5" />
                      </button>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Panel Footer */}
          <div className="p-2 border-t border-outline-variant/30 bg-surface-container-low/30 flex justify-center">
            <button className="text-primary hover:text-primary-hover font-bold text-xs flex items-center gap-1 py-1 px-3 hover:underline cursor-pointer">
              View All 24 Hubs <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Floating Plus button on mobile */}
      <button 
        onClick={() => {
          setStatusActive(prev => prev + 1);
          triggerNotification("Dispatched new roaming drone squad to central grid!");
        }}
        className="md:hidden fixed bottom-24 right-4 w-12 h-12 bg-primary text-on-primary rounded-full shadow-2xl flex items-center justify-center z-20 active:scale-90 transition-all cursor-pointer"
      >
        <Plus className="w-6 h-6" />
      </button>
    </div>
  );
}
