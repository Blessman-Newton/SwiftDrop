import React from 'react';
import { 
  Menu, Power, CheckCircle, TrendingUp, Award, Clock, ArrowRight, MapPin, 
  Lightbulb, ShieldAlert, LayoutDashboard, Truck, Wallet, User, Eye, Sparkles
} from 'lucide-react';
import { motion } from 'motion/react';
import { Screen } from '../types';

interface DashboardScreenProps {
  isOnline: boolean;
  setIsOnline: (online: boolean) => void;
  setActiveScreen: (screen: Screen) => void;
  showToast: (message: string, type: 'success' | 'error' | 'info') => void;
}

export default function DashboardScreen({
  isOnline,
  setIsOnline,
  setActiveScreen,
  showToast,
}: DashboardScreenProps) {
  
  const handleOnlineToggle = () => {
    const nextState = !isOnline;
    setIsOnline(nextState);
    if (nextState) {
      showToast('You are now ONLINE. Searching for nearby orders...', 'success');
    } else {
      showToast('You are now OFFLINE. No new delivery offers will be sent.', 'info');
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.2 }}
      className="flex flex-col min-h-full pb-20 select-none bg-[#f4fbf4] dark:bg-[#121814]"
    >
      {/* Top App Bar (Sticky layout style) */}
      <header className="fixed top-11 left-0 w-full z-40 bg-white/95 dark:bg-[#121814]/95 backdrop-blur-md border-b border-slate-100 dark:border-slate-800/40 px-5 h-14 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button 
            onClick={() => showToast('Sidebar menu coming soon in v1.5!', 'info')}
            className="text-slate-700 dark:text-slate-300 active:scale-95 transition-transform"
          >
            <Menu className="w-5 h-5" />
          </button>
          <h1 className="text-lg font-extrabold tracking-tight text-emerald-600 dark:text-emerald-400">
            SwiftDrop
          </h1>
        </div>
        <div className="flex items-center gap-3">
          <button 
            onClick={() => setActiveScreen(Screen.LOGIN)} 
            className="w-8 h-8 rounded-full border border-slate-200 dark:border-slate-800 overflow-hidden shadow-sm active:scale-90 transition-transform"
            title="Log Out / Switch Account"
          >
            <img 
              className="w-full h-full object-cover" 
              alt="Rider Profile Avatar" 
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuAZ7kgXczq54u-gJEtkyigagJpw1rmbXXDNzdeDJhkYk-I4gQldvVmYQouqEKMu19xmK3qHT5nyoldETP-wVFFhz-C4bl_O5beAMxx64vsgfu3Nl-t-3WFBuyR5hG4QH6KkAwhk8DSCIHQjntCL8XTcgSxW6K2IBKxSI2vwMkCbEIQBTd1qxYiII6Lif3d8QySCN8hdiOjLQhBq_YS4hoAp1y2_XcceTZv_p3_NxlTff_quoeDhemxVOZdfG15Udn0XL-Q94RsOQdY"
            />
          </button>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="pt-16 px-5 space-y-5">
        
        {/* Welcome Text & Online Toggle */}
        <section className="space-y-3 pt-2">
          <div>
            <h2 className="text-xl font-bold text-slate-800 dark:text-white leading-tight">
              Good Morning, Alex
            </h2>
            <p className="text-xs font-semibold text-slate-500 dark:text-slate-400">
              Ready for some high-demand shifts?
            </p>
          </div>

          {/* Slider Switch Button */}
          <button 
            onClick={handleOnlineToggle}
            className="w-full h-14 rounded-2xl bg-slate-100 dark:bg-slate-900/80 p-1 border border-slate-200/50 dark:border-slate-800/40 relative overflow-hidden transition-all duration-300"
          >
            {/* Animated Slider Track Cover */}
            <div 
              className={`absolute inset-0 transition-all duration-500 ease-out ${
                isOnline ? 'bg-emerald-600' : 'bg-slate-100 dark:bg-slate-900/80'
              }`} 
            />

            {/* Slider Circle Head */}
            <div 
              className={`absolute top-1 bottom-1 w-[48%] rounded-xl bg-white dark:bg-slate-800 shadow-md flex items-center justify-center transition-all duration-500 ease-out z-10 ${
                isOnline ? 'left-[50%]' : 'left-1'
              }`}
            >
              {isOnline ? (
                <CheckCircle className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
              ) : (
                <Power className="w-5 h-5 text-slate-400" />
              )}
            </div>

            {/* Behind Text Labels */}
            <div className="absolute inset-0 flex items-center justify-between px-6 font-bold text-xs pointer-events-none z-0">
              <span className={`transition-opacity duration-300 ${isOnline ? 'opacity-0 text-white' : 'opacity-100 text-slate-400'}`}>
                OFFLINE
              </span>
              <span className={`transition-opacity duration-300 ${isOnline ? 'opacity-100 text-white' : 'opacity-0 text-slate-500'}`}>
                GO OFFLINE
              </span>
              <span className={`transition-opacity duration-300 ${isOnline ? 'opacity-0 text-slate-500' : 'opacity-100 text-slate-800 dark:text-white'}`}>
                GO ONLINE
              </span>
            </div>
          </button>
        </section>

        {/* Pending Order Notice Banner (When online, prompt user to do active delivery!) */}
        {isOnline && (
          <motion.div 
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-800/50 p-4 rounded-2xl flex items-center justify-between gap-3 shadow-sm cursor-pointer hover:bg-emerald-100/50 dark:hover:bg-emerald-950/40 transition-colors"
            onClick={() => {
              showToast('Active delivery offer received!', 'success');
              setActiveScreen(Screen.ACTIVE_DELIVERY);
            }}
          >
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-emerald-500 text-white flex items-center justify-center animate-bounce">
                <Truck className="w-5 h-5" />
              </div>
              <div>
                <p className="text-xs font-extrabold text-emerald-800 dark:text-emerald-400">
                  NEW ORDER OFFER AVAILABLE
                </p>
                <p className="text-[11px] text-emerald-600 dark:text-emerald-500 font-medium mt-0.5">
                  Order #SW-9982 • Est: 8 mins • Pay: $15.50
                </p>
              </div>
            </div>
            <ArrowRight className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
          </motion.div>
        )}

        {/* Earnings Bento Grid */}
        <section className="grid grid-cols-1 gap-4">
          
          {/* Today's Earnings Card */}
          <div className="bg-white dark:bg-slate-900 p-5 rounded-2xl border border-slate-100 dark:border-slate-800/80 shadow-sm relative overflow-hidden group">
            <div className="flex justify-between items-start">
              <div>
                <p className="text-[11px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-widest">
                  Today's Earnings
                </p>
                <h3 className="text-3xl font-extrabold text-emerald-600 dark:text-emerald-400 mt-1">
                  $142.50
                </h3>
              </div>
              <div className="bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 px-2.5 py-1 rounded-full text-[11px] font-bold flex items-center gap-1 border border-emerald-500/15">
                <TrendingUp className="w-3.5 h-3.5" />
                <span>+12% vs yesterday</span>
              </div>
            </div>

            <div className="mt-5 grid grid-cols-3 gap-2 pt-4 border-t border-slate-50 dark:border-slate-800/40 text-center">
              <div>
                <p className="text-[10px] font-semibold text-slate-400 dark:text-slate-500 uppercase tracking-wider">
                  Trips
                </p>
                <p className="text-sm font-bold text-slate-700 dark:text-slate-200">12</p>
              </div>
              <div>
                <p className="text-[10px] font-semibold text-slate-400 dark:text-slate-500 uppercase tracking-wider">
                  Distance
                </p>
                <p className="text-sm font-bold text-slate-700 dark:text-slate-200">34.2 km</p>
              </div>
              <div>
                <p className="text-[10px] font-semibold text-slate-400 dark:text-slate-500 uppercase tracking-wider">
                  Active
                </p>
                <p className="text-sm font-bold text-slate-700 dark:text-slate-200">5h 20m</p>
              </div>
            </div>
          </div>

          {/* Goal Progress Card */}
          <div className="bg-emerald-700 dark:bg-emerald-800 p-5 rounded-2xl shadow-md text-white flex flex-col justify-between space-y-4">
            <div>
              <div className="flex items-center gap-1.5 opacity-95">
                <Award className="w-4 h-4 text-emerald-300" />
                <p className="text-[11px] font-bold uppercase tracking-wider text-emerald-100">
                  Daily Goal Progress
                </p>
              </div>
              <h4 className="text-lg font-bold text-white mt-1">$200.00 Goal</h4>
            </div>

            <div className="space-y-1.5">
              <div className="flex justify-between text-[11px] font-bold text-emerald-100">
                <span>71% Reached</span>
                <span>$57.50 left</span>
              </div>
              <div className="w-full h-2 bg-emerald-950/40 dark:bg-emerald-950/60 rounded-full overflow-hidden">
                <div className="h-full bg-white rounded-full shadow-sm" style={{ width: '71%' }} />
              </div>
              <p className="text-[10px] text-emerald-100/90 font-medium leading-snug">
                Complete 3 more orders to hit your daily bonus!
              </p>
            </div>
          </div>
        </section>

        {/* Recent Activity List */}
        <section className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-100 dark:border-slate-800/80 shadow-sm overflow-hidden">
          <div className="p-4 border-b border-slate-50 dark:border-slate-800/40 flex justify-between items-center">
            <h3 className="text-[14px] font-bold text-slate-800 dark:text-slate-200">
              Recent Activity
            </h3>
            <button 
              onClick={() => setActiveScreen(Screen.EARNINGS)}
              className="text-xs text-emerald-600 dark:text-emerald-400 font-bold hover:underline"
            >
              View All
            </button>
          </div>

          <div className="p-2 divide-y divide-slate-50 dark:divide-slate-800/30">
            {[
              { id: '1', name: 'The Green Bistro', dist: '2.4km', time: '18 mins ago', pay: 12.40 },
              { id: '2', name: 'Central Pharma', dist: '1.1km', time: '45 mins ago', pay: 8.15 },
              { id: '3', name: 'Modern Market', dist: '4.8km', time: '1h 10m ago', pay: 15.90 }
            ].map((act) => (
              <div 
                key={act.id} 
                onClick={() => showToast(`Activity details for ${act.name}: $${act.pay.toFixed(2)} completed`, 'info')}
                className="p-3 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-800/40 rounded-xl transition-colors cursor-pointer"
              >
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 flex items-center justify-center text-emerald-600 dark:text-emerald-400 shrink-0">
                    <Truck className="w-4.5 h-4.5" />
                  </div>
                  <div>
                    <p className="text-xs font-bold text-slate-800 dark:text-slate-200">
                      {act.name}
                    </p>
                    <p className="text-[10px] font-semibold text-slate-400 dark:text-slate-500 mt-0.5">
                      {act.dist} • {act.time}
                    </p>
                  </div>
                </div>
                <p className="text-xs font-extrabold text-emerald-600 dark:text-emerald-400">
                  +${act.pay.toFixed(2)}
                </p>
              </div>
            ))}
          </div>
        </section>

        {/* Nearby Hotzones Map Container */}
        <section className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-100 dark:border-slate-800/80 shadow-sm overflow-hidden">
          <div className="p-4 border-b border-slate-50 dark:border-slate-800/40 flex justify-between items-center">
            <div className="flex items-center gap-1.5 text-rose-500">
              <Sparkles className="w-4.5 h-4.5 animate-pulse" />
              <h3 className="text-[14px] font-bold text-slate-800 dark:text-slate-200">
                Nearby Hotzones
              </h3>
            </div>
            <span className="bg-rose-500/10 text-rose-600 dark:text-rose-400 text-[10px] font-bold px-2 py-0.5 rounded-full flex items-center gap-1 animate-pulse border border-rose-500/10">
              <span className="w-1.5 h-1.5 bg-rose-500 rounded-full" />
              <span>1.5x Boost</span>
            </span>
          </div>

          {/* Map Image Section */}
          <div className="relative h-44 bg-slate-200 dark:bg-slate-950 overflow-hidden">
            <img 
              className="w-full h-full object-cover dark:brightness-[0.7] opacity-90 transition-all" 
              alt="City logistics hotspot map" 
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuDc63z-aJca1DIvHBjjILESsmPUmp0UrAG_dqvgpI7rvnmcOeUzaH3FYdZf8wixJxpbryEQzbBS9qjiU3nEe5tPpPkn6s4t0Due5wuA3uidQUrr7yaHS4T13ioZXHM-wtwKkFt3Ax6tI6ho7gsplw_5MArOPnl7ZqsIy_Z6ThEEsa5amDsNy-oCbDtEXrON83JrdCZd1K2GYKEbeeSF08ieV-7rdsX0qE92xMdUZMN3e8H84UUyEZ-m4EYmPwDyz-vEgHsItA_bjZo"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/25 via-transparent to-transparent pointer-events-none" />

            {/* Glowing Hotzone 1: Downtown */}
            <div className="absolute top-[28%] left-[25%] flex flex-col items-center">
              <div className="relative flex items-center justify-center">
                <div className="absolute w-14 h-14 bg-rose-500/20 border border-rose-500/40 rounded-full animate-ping" />
                <div className="absolute w-8 h-8 bg-rose-500/35 border-2 border-rose-500/50 rounded-full animate-pulse" />
                <span className="bg-rose-600 text-white text-[9px] font-extrabold px-1.5 py-0.5 rounded shadow-md z-10 select-none">
                  Downtown
                </span>
              </div>
            </div>

            {/* Glowing Hotzone 2: East Wharf */}
            <div className="absolute bottom-[24%] right-[22%] flex flex-col items-center">
              <div className="relative flex items-center justify-center">
                <div className="absolute w-16 h-16 bg-rose-500/10 border border-rose-500/30 rounded-full animate-ping [animation-delay:1s]" />
                <div className="absolute w-10 h-10 bg-rose-500/25 border-2 border-rose-500/40 rounded-full animate-pulse [animation-delay:0.8s]" />
                <span className="bg-rose-600 text-white text-[9px] font-extrabold px-1.5 py-0.5 rounded shadow-md z-10 select-none">
                  East Wharf
                </span>
              </div>
            </div>

            {/* Rider Position Blue Glow */}
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 flex items-center justify-center">
              <div className="relative">
                <div className="absolute inset-0 w-5 h-5 bg-emerald-500/50 rounded-full animate-ping" />
                <div className="w-5 h-5 bg-emerald-600 rounded-full border-3 border-white dark:border-slate-900 shadow-md z-20 relative" />
              </div>
            </div>
          </div>
        </section>

        {/* Insights / Tips Grid */}
        <section className="space-y-3">
          <div className="bg-teal-500/5 dark:bg-teal-500/10 p-4 rounded-2xl border border-teal-500/15 dark:border-teal-500/20 flex gap-3 items-start">
            <div className="bg-teal-100 dark:bg-teal-950 text-teal-700 dark:text-teal-400 p-2 rounded-xl shrink-0">
              <Lightbulb className="w-4.5 h-4.5" />
            </div>
            <div>
              <h4 className="text-xs font-bold text-slate-800 dark:text-slate-200">
                Pro-Tip for Today
              </h4>
              <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-0.5 leading-relaxed">
                Lunch demand is peaking early in Downtown. Head there by 11:30 AM to maximize back-to-back orders.
              </p>
            </div>
          </div>

          <div className="bg-amber-500/5 dark:bg-amber-500/10 p-4 rounded-2xl border border-amber-500/15 dark:border-amber-500/20 flex gap-3 items-start">
            <div className="bg-amber-100 dark:bg-amber-950 text-amber-700 dark:text-amber-400 p-2 rounded-xl shrink-0">
              <ShieldAlert className="w-4.5 h-4.5" />
            </div>
            <div>
              <h4 className="text-xs font-bold text-slate-800 dark:text-slate-200">
                Safety Reminder
              </h4>
              <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-0.5 leading-relaxed">
                Rain is expected in 45 minutes. Ensure your high-visibility gear is ready and take extra care on slick turns.
              </p>
            </div>
          </div>
        </section>

      </main>

      {/* Persistent Bottom Tab Navigation (Fixed positioning inside Phone frame context) */}
      <nav className="absolute bottom-0 left-0 w-full bg-white/95 dark:bg-slate-900/95 backdrop-blur-md border-t border-slate-100 dark:border-slate-800/40 h-16 flex justify-around items-center px-2 z-40 select-none shrink-0">
        <button 
          onClick={() => setActiveScreen(Screen.DASHBOARD)}
          className="flex flex-col items-center justify-center text-emerald-600 dark:text-emerald-400 w-16 h-12 transition-transform active:scale-95"
        >
          <LayoutDashboard className="w-5 h-5 fill-emerald-500/10" />
          <span className="text-[10px] font-bold mt-0.5">Dashboard</span>
        </button>

        <button 
          onClick={() => {
            if (!isOnline) {
              showToast('Please GO ONLINE to view available delivery tasks', 'error');
            } else {
              setActiveScreen(Screen.ACTIVE_DELIVERY);
            }
          }}
          className="flex flex-col items-center justify-center text-slate-400 dark:text-slate-500 hover:text-slate-600 dark:hover:text-slate-300 w-16 h-12 transition-transform active:scale-95"
        >
          <Truck className="w-5 h-5" />
          <span className="text-[10px] font-bold mt-0.5">Orders</span>
        </button>

        <button 
          onClick={() => setActiveScreen(Screen.EARNINGS)}
          className="flex flex-col items-center justify-center text-slate-400 dark:text-slate-500 hover:text-slate-600 dark:hover:text-slate-300 w-16 h-12 transition-transform active:scale-95"
        >
          <Wallet className="w-5 h-5" />
          <span className="text-[10px] font-bold mt-0.5">Earnings</span>
        </button>

        <button 
          onClick={() => {
            showToast(' Alex is a Level 4 Platinum Courier with 98% Rating', 'success');
          }}
          className="flex flex-col items-center justify-center text-slate-400 dark:text-slate-500 hover:text-slate-600 dark:hover:text-slate-300 w-16 h-12 transition-transform active:scale-95"
        >
          <User className="w-5 h-5" />
          <span className="text-[10px] font-bold mt-0.5">Profile</span>
        </button>
      </nav>
    </motion.div>
  );
}
