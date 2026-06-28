import React, { useState } from 'react';
import { 
  Menu, Navigation, MapPin, Phone, HelpCircle, CheckCircle, Clock, 
  ChevronRight, ArrowLeft, LayoutDashboard, Truck, Wallet, User, MessageSquare
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { Screen } from '../types';

interface ActiveDeliveryScreenProps {
  setActiveScreen: (screen: Screen) => void;
  showToast: (message: string, type: 'success' | 'error' | 'info') => void;
}

export default function ActiveDeliveryScreen({
  setActiveScreen,
  showToast,
}: ActiveDeliveryScreenProps) {
  const [deliveryState, setDeliveryState] = useState<'EN_ROUTE' | 'ARRIVED' | 'COLLECTED'>('EN_ROUTE');
  const [isCalling, setIsCalling] = useState(false);
  const [isSupporting, setIsSupporting] = useState(false);

  const handlePrimaryCTA = () => {
    if (deliveryState === 'EN_ROUTE') {
      setDeliveryState('ARRIVED');
      showToast('Status updated: Arrived at The Burger Loft. Please verify order items.', 'success');
    } else if (deliveryState === 'ARRIVED') {
      setDeliveryState('COLLECTED');
      showToast('Items collected! Route configured for 123 Oak St.', 'success');
    } else if (deliveryState === 'COLLECTED') {
      // Transition directly to active navigation
      showToast('Launching GPS Navigation Guide...', 'success');
      setActiveScreen(Screen.NAVIGATION);
    }
  };

  const handleReset = () => {
    setDeliveryState('EN_ROUTE');
    showToast('Reset delivery task to initial state', 'info');
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.2 }}
      className="flex flex-col min-h-full pb-20 select-none bg-[#f4fbf4] dark:bg-[#121814] overflow-x-hidden"
    >
      {/* Top App Bar */}
      <header className="fixed top-11 left-0 w-full z-45 bg-white/95 dark:bg-[#121814]/95 backdrop-blur-md border-b border-slate-100 dark:border-slate-800/40 px-5 h-14 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button 
            onClick={() => setActiveScreen(Screen.DASHBOARD)}
            className="text-slate-700 dark:text-slate-300 active:scale-95 transition-transform"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <h1 className="text-lg font-extrabold tracking-tight text-emerald-600 dark:text-emerald-400">
            SwiftDrop
          </h1>
        </div>
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full border border-slate-200 dark:border-slate-800 overflow-hidden shadow-sm">
            <img 
              className="w-full h-full object-cover" 
              alt="Rider Avatar" 
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuAZ7kgXczq54u-gJEtkyigagJpw1rmbXXDNzdeDJhkYk-I4gQldvVmYQouqEKMu19xmK3qHT5nyoldETP-wVFFhz-C4bl_O5beAMxx64vsgfu3Nl-t-3WFBuyR5hG4QH6KkAwhk8DSCIHQjntCL8XTcgSxW6K2IBKxSI2vwMkCbEIQBTd1qxYiII6Lif3d8QySCN8hdiOjLQhBq_YS4hoAp1y2_XcceTZv_p3_NxlTff_quoeDhemxVOZdfG15Udn0XL-Q94RsOQdY"
            />
          </div>
        </div>
      </header>

      {/* Interactive Map Section */}
      <section className="relative h-64 w-full overflow-hidden mt-14 bg-slate-200 dark:bg-slate-950 shrink-0">
        <img 
          className="w-full h-full object-cover dark:brightness-[0.6] opacity-90 grayscale-[10%]" 
          alt="Chicago city route navigation map" 
          src="https://lh3.googleusercontent.com/aida-public/AB6AXuAQDzmaPQ961YYdO_5yCEW2HnYTDs4STfQHPBuLSRd5u13WSflB95_cC1H1L_CyoK0qFgK0YTP3wfq2_TJ0RVZvnJ3pkT7dT8H75w8lH2hh-RiY3cijMRgJ46DT-BBryZ0ifRtSTGOQIZV4GNP2KLBPoJ83pSYreCnMcJm_EHB1PJxElisUb0Sj9Ilsi_gSZo89TdLQME0xnB884K1KlxYOf9zeW_TKhvCXtsWusE1v1CeuMMvrXoy5vHXZrgJ3h_lF2egkkiPgFiQ"
        />
        
        {/* Floating elements inside map */}
        <div className="absolute inset-0 bg-gradient-to-t from-slate-900/10 to-transparent pointer-events-none" />
        
        {/* Floating ETA Card on left */}
        <div className="absolute bottom-4 left-4 bg-white/95 dark:bg-slate-900/95 p-3 rounded-2xl shadow-lg border border-slate-100 dark:border-slate-800/80 flex items-center gap-3 max-w-[170px] z-10 animate-fade-in">
          <div className="bg-emerald-500 text-white p-2 rounded-xl shrink-0">
            <Navigation className="w-4 h-4 fill-white" />
          </div>
          <div>
            <p className="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-widest leading-none">
              {deliveryState === 'COLLECTED' ? 'To Dropoff' : 'To Pickup'}
            </p>
            <p className="text-sm font-extrabold text-emerald-600 dark:text-emerald-400 mt-0.5">
              {deliveryState === 'COLLECTED' ? '6 mins' : '8 mins'}
            </p>
          </div>
        </div>

        {/* Floating location zoom action */}
        <button 
          onClick={() => showToast('Re-centering map onto your current position...', 'info')}
          className="absolute bottom-4 right-4 w-11 h-11 bg-white/95 dark:bg-slate-900/95 border border-slate-100 dark:border-slate-800 rounded-full shadow-lg flex items-center justify-center text-emerald-600 dark:text-emerald-400 active:scale-90 transition-transform z-10"
        >
          <Navigation className="w-4.5 h-4.5 rotate-45" />
        </button>

        {/* Route Pulsing Pointer Marker on the Map (Simulated) */}
        <div className="absolute top-[38%] left-[45%] -translate-x-1/2 -translate-y-1/2 z-0 pointer-events-none">
          <div className="relative">
            <div className="w-6 h-6 bg-emerald-500/30 border border-emerald-500 rounded-full animate-ping absolute top-0 left-0" />
            <div className="w-4 h-4 bg-emerald-600 rounded-full border-2 border-white shadow-md" />
          </div>
        </div>
      </section>

      {/* Delivery Details Bottom Sheet Style Container */}
      <section className="flex-1 bg-white dark:bg-slate-900 px-5 rounded-t-[32px] -mt-5 relative z-20 shadow-[0_-10px_30px_rgba(0,0,0,0.06)] border-t border-slate-100 dark:border-slate-800/20">
        
        {/* Grip Handle bar decoration */}
        <div className="w-12 h-1.5 bg-slate-200 dark:bg-slate-800 rounded-full mx-auto mt-3 mb-5" />

        {/* Task Title & Count Header */}
        <div className="flex items-center justify-between mb-5">
          <div>
            <h2 className="text-xl font-bold text-slate-800 dark:text-white leading-tight">
              Current Task
            </h2>
            <div className="flex items-center gap-1.5 mt-0.5">
              <span className="text-xs font-semibold text-slate-400 dark:text-slate-500">
                Order #SW-9982
              </span>
              <div className="w-1 h-1 bg-slate-300 dark:bg-slate-700 rounded-full" />
              <button 
                onClick={handleReset}
                className="text-[10px] text-emerald-600 dark:text-emerald-400 font-bold hover:underline uppercase tracking-wide"
              >
                Reset Order state
              </button>
            </div>
          </div>
          <div className="bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-400 px-3 py-1.5 rounded-full text-xs font-extrabold border border-emerald-100 dark:border-emerald-900/10">
            3 Items
          </div>
        </div>

        {/* Locations Bento Stack */}
        <div className="space-y-3.5 mb-6">
          
          {/* Pickup Address Card */}
          <div className={`p-4 rounded-2xl border transition-all ${
            deliveryState === 'EN_ROUTE' 
              ? 'bg-emerald-500/5 border-emerald-500/30 dark:bg-emerald-500/5 dark:border-emerald-500/20' 
              : 'bg-slate-50/80 border-slate-100 dark:bg-slate-800/40 dark:border-slate-800/30 opacity-70'
          }`}>
            <div className="flex items-start gap-3.5">
              <div className="bg-emerald-100 dark:bg-emerald-950 text-emerald-600 dark:text-emerald-400 p-2.5 rounded-xl shrink-0">
                <Truck className="w-5 h-5" />
              </div>
              <div className="flex-1 min-w-0">
                <span className="text-[10px] font-extrabold text-emerald-600 dark:text-emerald-400 uppercase tracking-widest block mb-0.5">
                  Pickup
                </span>
                <h3 className="text-sm font-extrabold text-slate-800 dark:text-slate-200">
                  The Burger Loft
                </h3>
                <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5 font-medium">
                  455 West Grand Ave
                </p>
                <div className="mt-2.5 flex items-center gap-1.5">
                  <span className="bg-emerald-100 dark:bg-emerald-950/60 text-emerald-800 dark:text-emerald-400 px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wide">
                    Ready in 2m
                  </span>
                  {deliveryState !== 'EN_ROUTE' && (
                    <span className="bg-slate-200 dark:bg-slate-800 text-slate-600 dark:text-slate-400 px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wide">
                      Items Collected
                    </span>
                  )}
                </div>
              </div>
              <button 
                onClick={() => setActiveScreen(Screen.NAVIGATION)}
                className="w-9 h-9 bg-white dark:bg-slate-800 rounded-full flex items-center justify-center text-emerald-600 dark:text-emerald-400 border border-slate-100 dark:border-slate-700 shadow-sm shrink-0 active:scale-95 transition-transform"
                title="Launch GPS Map Guide"
              >
                <Navigation className="w-4 h-4 fill-emerald-600/10" />
              </button>
            </div>
          </div>

          {/* Dropoff Address Card */}
          <div className={`p-4 rounded-2xl border transition-all ${
            deliveryState === 'COLLECTED'
              ? 'bg-emerald-500/5 border-emerald-500/30 dark:bg-emerald-500/5 dark:border-emerald-500/20' 
              : 'bg-slate-50/80 border-slate-100 dark:bg-slate-800/40 dark:border-slate-800/30'
          }`}>
            <div className="flex items-start gap-3.5">
              <div className="bg-slate-100 dark:bg-slate-800 text-slate-500 dark:text-slate-400 p-2.5 rounded-xl shrink-0">
                <MapPin className="w-5 h-5" />
              </div>
              <div className="flex-1 min-w-0">
                <span className="text-[10px] font-extrabold text-slate-400 dark:text-slate-500 uppercase tracking-widest block mb-0.5">
                  Dropoff
                </span>
                <h3 className="text-sm font-extrabold text-slate-800 dark:text-slate-200">
                  123 Oak St
                </h3>
                <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5 font-medium">
                  Unit 4B (Gate code: 1234)
                </p>
              </div>
            </div>
          </div>

        </div>

        {/* Quick Contacts Actions Row */}
        <div className="grid grid-cols-2 gap-3 mb-6">
          <button 
            onClick={() => {
              setIsCalling(true);
              showToast('Connecting line to customer...', 'info');
              setTimeout(() => setIsCalling(false), 3000);
            }}
            className="flex items-center justify-center gap-2 py-3.5 rounded-2xl bg-slate-50 dark:bg-slate-800 hover:bg-slate-100 dark:hover:bg-slate-700/80 font-bold text-xs text-slate-700 dark:text-slate-300 transition-colors border border-slate-200/40 dark:border-slate-800/30"
          >
            <Phone className="w-4 h-4 text-emerald-600 dark:text-emerald-400 animate-pulse" />
            <span>Call Customer</span>
          </button>
          <button 
            onClick={() => {
              setIsSupporting(true);
              showToast('Opening support chat thread...', 'info');
              setTimeout(() => setIsSupporting(false), 3000);
            }}
            className="flex items-center justify-center gap-2 py-3.5 rounded-2xl bg-slate-50 dark:bg-slate-800 hover:bg-slate-100 dark:hover:bg-slate-700/80 font-bold text-xs text-slate-700 dark:text-slate-300 transition-colors border border-slate-200/40 dark:border-slate-800/30"
          >
            <HelpCircle className="w-4 h-4 text-rose-500" />
            <span>Support Chat</span>
          </button>
        </div>

        {/* Primary CTA (Changes with steps!) */}
        <button 
          onClick={handlePrimaryCTA}
          className="w-full py-4.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-2xl shadow-xl shadow-emerald-600/15 active:scale-[0.98] transition-all flex items-center justify-center gap-2 text-sm"
        >
          <CheckCircle className="w-4.5 h-4.5" />
          <span>
            {deliveryState === 'EN_ROUTE' && 'Arrived at Pickup'}
            {deliveryState === 'ARRIVED' && 'Confirm Collection (3 Items)'}
            {deliveryState === 'COLLECTED' && 'Start Navigation to Dropoff'}
          </span>
        </button>

      </section>

      {/* Simulated Active Phone overlays */}
      <AnimatePresence>
        {isCalling && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="absolute inset-0 bg-slate-950/90 z-50 flex flex-col items-center justify-center text-white"
          >
            <Phone className="w-12 h-12 text-emerald-500 animate-bounce mb-4" />
            <p className="text-sm font-bold">Simulating Secure Phone Call...</p>
            <p className="text-xs text-slate-400 mt-1">Calling: customer via masked line</p>
            <button 
              onClick={() => setIsCalling(false)}
              className="mt-8 px-6 py-2 bg-rose-600 hover:bg-rose-700 font-bold text-xs rounded-full"
            >
              End Call
            </button>
          </motion.div>
        )}

        {isSupporting && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="absolute inset-0 bg-slate-950/90 z-50 flex flex-col items-center justify-center text-white"
          >
            <MessageSquare className="w-12 h-12 text-rose-500 animate-pulse mb-4" />
            <p className="text-sm font-bold">Connecting SwiftDrop Dispatch...</p>
            <p className="text-xs text-slate-400 mt-1">Live agent secure session</p>
            <button 
              onClick={() => setIsSupporting(false)}
              className="mt-8 px-6 py-2 bg-slate-700 font-bold text-xs rounded-full"
            >
              Close Thread
            </button>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Navigation tabs overlay */}
      <nav className="absolute bottom-0 left-0 w-full bg-white/95 dark:bg-slate-900/95 backdrop-blur-md border-t border-slate-100 dark:border-slate-800/40 h-16 flex justify-around items-center px-2 z-40 select-none shrink-0">
        <button 
          onClick={() => setActiveScreen(Screen.DASHBOARD)}
          className="flex flex-col items-center justify-center text-slate-400 dark:text-slate-500 hover:text-slate-600 dark:hover:text-slate-300 w-16 h-12 transition-transform active:scale-95"
        >
          <LayoutDashboard className="w-5 h-5" />
          <span className="text-[10px] font-bold mt-0.5">Dashboard</span>
        </button>

        <button 
          onClick={() => setActiveScreen(Screen.ACTIVE_DELIVERY)}
          className="flex flex-col items-center justify-center text-emerald-600 dark:text-emerald-400 w-16 h-12 transition-transform active:scale-95"
        >
          <Truck className="w-5 h-5 fill-emerald-500/10" />
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
            showToast('Alex is a Level 4 Platinum Courier with 98% Rating', 'success');
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
