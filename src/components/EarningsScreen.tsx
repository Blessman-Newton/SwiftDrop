import React, { useState, useEffect } from 'react';
import { 
  Menu, Wallet, TrendingUp, Calendar, CreditCard, Star, 
  CheckCircle, ShieldAlert, Award, ArrowUpRight, ArrowDownRight, 
  ChevronRight, Gift, Percent, Receipt, RefreshCw, X, Check,
  LayoutDashboard, Truck, User
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { Screen } from '../types';

interface EarningsScreenProps {
  setActiveScreen: (screen: Screen) => void;
  showToast: (message: string, type: 'success' | 'error' | 'info') => void;
}

export default function EarningsScreen({
  setActiveScreen,
  showToast,
}: EarningsScreenProps) {
  const [balance, setBalance] = useState(1482.50);
  const [showWithdrawModal, setShowWithdrawModal] = useState(false);
  const [withdrawAmount, setWithdrawAmount] = useState('500');
  const [isWithdrawing, setIsWithdrawing] = useState(false);
  const [withdrawSuccess, setWithdrawSuccess] = useState(false);
  const [animateChart, setAnimateChart] = useState(false);

  // Trigger chart bar animation heights on mount
  useEffect(() => {
    const timer = setTimeout(() => setAnimateChart(true), 200);
    return () => clearTimeout(timer);
  }, []);

  const handleWithdrawSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const amountNum = parseFloat(withdrawAmount);
    if (isNaN(amountNum) || amountNum <= 0) {
      showToast('Please enter a valid withdrawal amount', 'error');
      return;
    }
    if (amountNum > balance) {
      showToast('Insufficient funds for this withdrawal amount', 'error');
      return;
    }

    setIsWithdrawing(true);
    showToast('Authorizing instant transfer keys with bank...', 'info');

    setTimeout(() => {
      setIsWithdrawing(false);
      setWithdrawSuccess(true);
      setBalance((prev) => prev - amountNum);
      showToast(`Transfer of $${amountNum.toFixed(2)} completed successfully!`, 'success');
    }, 2000);
  };

  const closeWithdrawalFlow = () => {
    setShowWithdrawModal(false);
    setWithdrawSuccess(false);
    setWithdrawAmount('500');
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.2 }}
      className="flex flex-col min-h-full pb-20 select-none bg-[#f4fbf4] dark:bg-[#121814]"
    >
      {/* Top App Bar */}
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
          <div className="w-8 h-8 rounded-full border border-slate-200 dark:border-slate-800 overflow-hidden shadow-sm">
            <img 
              className="w-full h-full object-cover" 
              alt="Rider Avatar" 
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuAZ7kgXczq54u-gJEtkyigagJpw1rmbXXDNzdeDJhkYk-I4gQldvVmYQouqEKMu19xmK3qHT5nyoldETP-wVFFhz-C4bl_O5beAMxx64vsgfu3Nl-t-3WFBuyR5hG4QH6KkAwhk8DSCIHQjntCL8XTcgSxW6K2IBKxSI2vwMkCbEIQBTd1qxYiII6Lif3d8QySCN8hdiOjLQhBq_YS4hoAp1y2_XcceTZv_p3_NxlTff_quoeDhemxVOZdfG15Udn0XL-Q94RsOQdY"
            />
          </div>
        </div>
      </header>

      {/* Main Container Scrollable */}
      <main className="pt-16 px-5 space-y-5">
        
        {/* Available Balance Card */}
        <section className="bg-gradient-to-br from-emerald-800 to-teal-600 dark:from-emerald-950 dark:to-teal-850 rounded-2xl p-5 text-white shadow-md relative overflow-hidden mt-2">
          {/* Subtle background coin/wallet icon watermark */}
          <div className="absolute top-[-10px] right-[-10px] opacity-10 select-none">
            <Wallet className="w-32 h-32 text-white" />
          </div>

          <div className="relative z-10 space-y-4">
            <div>
              <p className="text-[11px] font-bold uppercase tracking-wider text-emerald-100">
                Available Balance
              </p>
              <div className="flex items-end justify-between mt-1">
                <h2 className="text-3xl font-extrabold tracking-tight text-white tabular-nums">
                  ${balance.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                </h2>
                <span className="text-[10px] font-bold bg-white/20 text-emerald-100 px-2.5 py-0.5 rounded-full border border-white/10 shrink-0">
                  +12% this week
                </span>
              </div>
            </div>

            <button 
              onClick={() => setShowWithdrawModal(true)}
              className="w-full bg-white dark:bg-slate-900 text-emerald-700 dark:text-emerald-400 font-extrabold text-xs py-3 rounded-xl shadow-md active:scale-[0.98] transition-transform flex items-center justify-center gap-2 border border-slate-100 dark:border-slate-800"
            >
              <CreditCard className="w-4 h-4" />
              <span>Withdraw Funds</span>
            </button>
          </div>
        </section>

        {/* Weekly Revenue Chart Section */}
        <section className="bg-white dark:bg-slate-900 rounded-2xl p-5 border border-slate-100 dark:border-slate-800/80 shadow-sm space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-[14px] font-bold text-slate-850 dark:text-slate-200">
              Weekly Revenue
            </h3>
            <div className="flex items-center gap-1.5 text-slate-400 dark:text-slate-500">
              <span className="text-[11px] font-bold">May 14 - May 20</span>
              <Calendar className="w-3.5 h-3.5" />
            </div>
          </div>

          {/* Bar Chart Graphics */}
          <div className="h-40 flex items-end justify-between gap-2 px-1 border-b border-slate-100 dark:border-slate-800/40 pb-2">
            {[
              { day: 'Mon', pct: 40, amt: 85 },
              { day: 'Tue', pct: 65, amt: 130 },
              { day: 'Wed', pct: 55, amt: 110 },
              { day: 'Thu', pct: 85, amt: 180 },
              { day: 'Fri', pct: 95, amt: 211, active: true },
              { day: 'Sat', pct: 30, amt: 60 },
              { day: 'Sun', pct: 20, amt: 40 }
            ].map((bar) => (
              <div key={bar.day} className="flex-1 flex flex-col items-center group cursor-pointer">
                {/* Visual tooltip on hover */}
                <span className="absolute -translate-y-12 bg-slate-900 text-white text-[9px] font-bold px-1.5 py-0.5 rounded shadow-md opacity-0 group-hover:opacity-100 transition-opacity z-10 tabular-nums pointer-events-none">
                  ${bar.amt}
                </span>
                
                {/* Animated bar track filled with state-driven height */}
                <div 
                  className={`w-full rounded-t-lg transition-all duration-1000 ease-out ${
                    bar.active 
                      ? 'bg-emerald-600 dark:bg-emerald-500 shadow-md' 
                      : 'bg-emerald-500/15 dark:bg-emerald-500/10 group-hover:bg-emerald-500/35'
                  }`}
                  style={{ height: animateChart ? `${bar.pct}%` : '0%' }}
                />
                
                <span className={`text-[10px] font-bold mt-2 ${
                  bar.active 
                    ? 'text-emerald-600 dark:text-emerald-400 font-extrabold' 
                    : 'text-slate-400 dark:text-slate-500'
                }`}>
                  {bar.day}
                </span>
              </div>
            ))}
          </div>

          {/* Under chart stats */}
          <div className="grid grid-cols-2 divide-x divide-slate-100 dark:divide-slate-800/40 text-center pt-1.5">
            <div>
              <p className="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-wider">
                Avg. Daily
              </p>
              <p className="text-base font-extrabold text-emerald-600 dark:text-emerald-400 mt-0.5">
                $211.70
              </p>
            </div>
            <div>
              <p className="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-wider">
                Total Trips
              </p>
              <p className="text-base font-extrabold text-emerald-600 dark:text-emerald-400 mt-0.5">
                124
              </p>
            </div>
          </div>
        </section>

        {/* Detailed Breakdown */}
        <section className="bg-white dark:bg-slate-900 rounded-2xl p-5 border border-slate-100 dark:border-slate-800/80 shadow-sm space-y-4">
          <h3 className="text-[14px] font-bold text-slate-800 dark:text-slate-200">
            Detailed Breakdown
          </h3>

          <div className="space-y-3.5">
            {[
              { id: '1', title: 'Base Fare', val: 940.00, icon: RefreshCw, isAdd: true },
              { id: '2', title: 'Tips', val: 325.50, icon: Award, isAdd: true, isGreen: true },
              { id: '3', title: 'Bonuses', val: 280.00, icon: Gift, isAdd: true, isGreen: true },
              { id: '4', title: 'Fees & Platform', val: -63.00, icon: Receipt, isAdd: false, isRed: true }
            ].map((item) => (
              <div key={item.id} className="flex items-center justify-between text-xs font-semibold">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-xl bg-slate-50 dark:bg-slate-800 flex items-center justify-center text-slate-500 dark:text-slate-400 shrink-0">
                    <item.icon className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
                  </div>
                  <span className="text-slate-700 dark:text-slate-300">{item.title}</span>
                </div>
                <span className={`font-bold tabular-nums ${
                  item.isRed ? 'text-rose-500' : item.isGreen ? 'text-emerald-600 dark:text-emerald-400' : 'text-slate-850 dark:text-slate-200'
                }`}>
                  {item.isAdd ? '+' : ''}${Math.abs(item.val).toFixed(2)}
                </span>
              </div>
            ))}
          </div>
        </section>

        {/* Performance Metrics Block */}
        <section className="grid grid-cols-3 gap-3">
          <div className="bg-white dark:bg-slate-900 p-3 rounded-2xl border border-slate-100 dark:border-slate-800/80 shadow-sm flex flex-col items-center text-center">
            <Star className="w-5 h-5 text-amber-500 fill-amber-500 mb-1" />
            <p className="text-[10px] font-bold text-slate-400 dark:text-slate-500">Rating</p>
            <p className="text-sm font-extrabold text-slate-800 dark:text-slate-200 mt-0.5">4.92</p>
          </div>
          <div className="bg-white dark:bg-slate-900 p-3 rounded-2xl border border-slate-100 dark:border-slate-800/80 shadow-sm flex flex-col items-center text-center">
            <CheckCircle className="w-5 h-5 text-emerald-600 mb-1" />
            <p className="text-[10px] font-bold text-slate-400 dark:text-slate-500">Acceptance</p>
            <p className="text-sm font-extrabold text-slate-800 dark:text-slate-200 mt-0.5">98%</p>
          </div>
          <div className="bg-white dark:bg-slate-900 p-3 rounded-2xl border border-slate-100 dark:border-slate-800/80 shadow-sm flex flex-col items-center text-center">
            <ShieldAlert className="w-5 h-5 text-rose-500 mb-1" />
            <p className="text-[10px] font-bold text-slate-400 dark:text-slate-500">Canceled</p>
            <p className="text-sm font-extrabold text-slate-800 dark:text-slate-200 mt-0.5">0.8%</p>
          </div>
        </section>

        {/* Recent Transactions List Block */}
        <section className="space-y-3.5 pb-2">
          <div className="flex items-center justify-between">
            <h3 className="text-[14px] font-bold text-slate-800 dark:text-slate-200">
              Recent Transactions
            </h3>
            <button 
              onClick={() => showToast('Full history requires secure CSV download', 'info')}
              className="text-xs text-emerald-600 dark:text-emerald-400 font-bold hover:underline"
            >
              View All
            </button>
          </div>

          <div className="space-y-2.5">
            {[
              { id: '1', title: 'Order #SD-8291', time: 'Today, 2:45 PM', pay: 18.40, type: 'order' },
              { id: '2', title: 'Bonus: Peak Hour', time: 'Today, 1:00 PM', pay: 5.00, type: 'bonus' }
            ].map((tx) => (
              <div key={tx.id} className="flex items-center justify-between bg-slate-50 dark:bg-slate-800/40 p-4 rounded-xl border border-slate-100/50 dark:border-slate-800/20">
                <div>
                  <p className="text-xs font-bold text-slate-800 dark:text-slate-200">
                    {tx.title}
                  </p>
                  <p className="text-[10px] font-semibold text-slate-400 dark:text-slate-500 mt-0.5">
                    {tx.time}
                  </p>
                </div>
                <p className="text-xs font-extrabold text-emerald-600 dark:text-emerald-400">
                  +${tx.pay.toFixed(2)}
                </p>
              </div>
            ))}
          </div>
        </section>

      </main>

      {/* Interactive Withdrawal Sheet / Modal Overlay */}
      <AnimatePresence>
        {showWithdrawModal && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="absolute inset-0 bg-slate-950/80 z-50 flex items-end justify-center select-none"
          >
            {/* Modal Card sheet content */}
            <motion.div 
              initial={{ y: 200 }}
              animate={{ y: 0 }}
              exit={{ y: 200 }}
              transition={{ type: 'spring', damping: 25 }}
              className="bg-white dark:bg-slate-900 w-full rounded-t-[32px] p-6 max-h-[85%] flex flex-col justify-between border-t border-slate-100 dark:border-slate-800"
            >
              <div>
                <div className="flex justify-between items-start mb-6">
                  <div>
                    <h3 className="text-lg font-bold text-slate-850 dark:text-white">
                      Withdraw Funds
                    </h3>
                    <p className="text-xs text-slate-400 mt-0.5">
                      Available: ${balance.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                    </p>
                  </div>
                  <button 
                    onClick={closeWithdrawalFlow}
                    className="w-8 h-8 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-400 hover:text-slate-600 dark:hover:text-slate-200"
                  >
                    <X className="w-4 h-4" />
                  </button>
                </div>

                {!withdrawSuccess ? (
                  <form onSubmit={handleWithdrawSubmit} className="space-y-4">
                    <div className="space-y-1.5">
                      <label className="text-[11px] font-bold text-slate-500 dark:text-slate-400 ml-1">
                        Enter Withdrawal Amount ($)
                      </label>
                      <div className="relative group">
                        <span className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 font-extrabold text-sm">
                          $
                        </span>
                        <input 
                          type="number"
                          value={withdrawAmount}
                          onChange={(e) => setWithdrawAmount(e.target.value)}
                          max={balance}
                          className="w-full pl-10 pr-4 py-3 bg-slate-50 dark:bg-slate-800 border-none rounded-xl text-sm font-bold focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:ring-offset-2 focus:ring-offset-white dark:focus:ring-offset-slate-900 text-slate-850 dark:text-slate-100"
                          disabled={isWithdrawing}
                        />
                      </div>
                    </div>

                    <div className="bg-slate-50 dark:bg-slate-800 p-4 rounded-xl border border-slate-100 dark:border-slate-850 flex gap-3 items-start">
                      <CreditCard className="w-5 h-5 text-emerald-600 shrink-0" />
                      <div>
                        <p className="text-[11px] font-bold text-slate-800 dark:text-slate-200 leading-none">
                          Chase Bank Business (•••• 9812)
                        </p>
                        <p className="text-[10px] text-slate-400 mt-1 leading-normal">
                          Instant transfer (under 2 minutes) • Fees: $0.00
                        </p>
                      </div>
                    </div>

                    <button 
                      type="submit"
                      disabled={isWithdrawing}
                      className="w-full py-3.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl text-xs shadow-md shadow-emerald-600/15 flex items-center justify-center gap-2 mt-4"
                    >
                      {isWithdrawing ? (
                        <div className="w-4 h-4 border-2 border-white/35 border-t-white rounded-full animate-spin" />
                      ) : (
                        'Confirm Withdrawal'
                      )}
                    </button>
                  </form>
                ) : (
                  <motion.div 
                    initial={{ scale: 0.95, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    className="flex flex-col items-center text-center py-6 space-y-4"
                  >
                    <div className="w-14 h-14 bg-emerald-100 dark:bg-emerald-950 text-emerald-600 dark:text-emerald-400 rounded-full flex items-center justify-center animate-bounce">
                      <Check className="w-6 h-6 stroke-[3px]" />
                    </div>
                    <div>
                      <h4 className="text-base font-bold text-slate-850 dark:text-white">
                        Withdrawal Successful!
                      </h4>
                      <p className="text-xs text-slate-400 mt-1 leading-relaxed px-4">
                        We have triggered an instant transfer of ${parseFloat(withdrawAmount).toFixed(2)} to your Chase Bank Business account. It should settle instantly!
                      </p>
                    </div>
                    <button 
                      onClick={closeWithdrawalFlow}
                      className="px-6 py-2 bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 rounded-full text-xs font-bold"
                    >
                      Done
                    </button>
                  </motion.div>
                )}
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Navigation bottom bar */}
      <nav className="absolute bottom-0 left-0 w-full bg-white/95 dark:bg-slate-900/95 backdrop-blur-md border-t border-slate-100 dark:border-slate-800/40 h-16 flex justify-around items-center px-2 z-40 select-none shrink-0">
        <button 
          onClick={() => setActiveScreen(Screen.DASHBOARD)}
          className="flex flex-col items-center justify-center text-slate-400 dark:text-slate-500 hover:text-slate-600 dark:hover:text-slate-300 w-16 h-12 transition-transform active:scale-95"
        >
          <LayoutDashboard className="w-5 h-5" />
          <span className="text-[10px] font-bold mt-0.5">Dashboard</span>
        </button>

        <button 
          onClick={() => {
            setActiveScreen(Screen.ACTIVE_DELIVERY);
          }}
          className="flex flex-col items-center justify-center text-slate-400 dark:text-slate-500 hover:text-slate-600 dark:hover:text-slate-300 w-16 h-12 transition-transform active:scale-95"
        >
          <Truck className="w-5 h-5" />
          <span className="text-[10px] font-bold mt-0.5">Orders</span>
        </button>

        <button 
          onClick={() => setActiveScreen(Screen.EARNINGS)}
          className="flex flex-col items-center justify-center text-emerald-600 dark:text-emerald-400 w-16 h-12 transition-transform active:scale-95"
        >
          <Wallet className="w-5 h-5 fill-emerald-500/10" />
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
