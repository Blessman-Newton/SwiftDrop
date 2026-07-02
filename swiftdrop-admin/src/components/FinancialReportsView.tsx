import React, { useState } from 'react';
import { 
  TrendingUp, 
  ArrowUpRight, 
  Wallet, 
  Download, 
  FileText,
  Clock,
  ArrowRight,
  TrendingDown,
  Info,
  Building,
  User,
  Plus
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { Payout } from '../types';

export default function FinancialReportsView() {
  const [billingCycle, setBillingCycle] = useState<'daily' | 'weekly'>('daily');
  const [hoveredPoint, setHoveredPoint] = useState<number | null>(null);
  const [showPayoutModal, setShowPayoutModal] = useState(false);
  const [newRecipient, setNewRecipient] = useState('');
  const [newAmount, setNewAmount] = useState('');
  const [newType, setNewType] = useState('Standard');

  // Initial recent payouts state
  const [payouts, setPayouts] = useState<Payout[]>([
    { id: '1', recipient: 'Gourmet Republic', recipientId: 'Merchant ID: 8821', avatarText: 'GR', type: 'Standard', status: 'completed', amount: 12450.00 },
    { id: '2', recipient: 'James Smith', recipientId: 'Rider ID: 4402', avatarText: 'JS', type: 'Instant', status: 'completed', amount: 842.15 },
    { id: '3', recipient: 'Burger Factory', recipientId: 'Merchant ID: 9012', avatarText: 'BF', type: 'Standard', status: 'processing', amount: 3120.00 },
    { id: '4', recipient: 'Luna Logistics', recipientId: 'Partner ID: 1120', avatarText: 'LL', type: 'Weekly Batch', status: 'completed', amount: 28900.50 }
  ]);

  // Handle new simulated payout request
  const handleCreatePayout = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newRecipient || !newAmount) return;

    const amt = parseFloat(newAmount);
    if (isNaN(amt)) return;

    const payout: Payout = {
      id: Date.now().toString(),
      recipient: newRecipient,
      recipientId: `Rider/Merchant: #${Math.floor(Math.random() * 9000 + 1000)}`,
      avatarText: newRecipient.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2),
      type: newType,
      status: 'processing',
      amount: amt
    };

    setPayouts([payout, ...payouts]);
    setNewRecipient('');
    setNewAmount('');
    setShowPayoutModal(false);
  };

  // Line points for Revenue Growth Trend line SVG
  // Based on SVG dimensions 1000 x 200
  const points = [
    { x: 0, y: 180, label: 'Oct 01', val: 'GHS 84,200' },
    { x: 100, y: 160, label: 'Oct 04', val: 'GHS 96,500' },
    { x: 200, y: 140, label: 'Oct 08', val: 'GHS 110,400' },
    { x: 300, y: 150, label: 'Oct 11', val: 'GHS 104,900' },
    { x: 400, y: 110, label: 'Oct 15', val: 'GHS 132,800' },
    { x: 500, y: 120, label: 'Oct 18', val: 'GHS 128,100' },
    { x: 600, y: 80, label: 'Oct 22', val: 'GHS 156,000' },
    { x: 700, y: 90, label: 'Oct 25', val: 'GHS 149,900' },
    { x: 800, y: 60, label: 'Oct 29', val: 'GHS 178,400' },
    { x: 1000, y: 40, label: 'Today', val: 'GHS 198,900' }
  ];

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-12">
      
      {/* 1. Header Toolbar Actions */}
      <div className="flex justify-between items-center bg-surface-container-low/40 p-4 rounded-2xl border border-outline-variant/20">
        <div>
          <span className="text-xs text-outline font-semibold">Financial Ledger Dashboard</span>
          <p className="text-sm font-bold text-on-surface mt-0.5">Real-time ledger entries</p>
        </div>
        <div className="flex gap-2">
          <button 
            onClick={() => setShowPayoutModal(true)}
            className="flex items-center gap-1.5 bg-primary text-on-primary px-4 py-2 rounded-full font-bold text-xs hover:bg-primary-hover transition-all active:scale-95 cursor-pointer shadow-sm"
          >
            <Plus className="w-3.5 h-3.5" />
            <span>Initiate Payout</span>
          </button>
          <button className="hidden sm:flex items-center gap-1.5 bg-surface-container-high dark:bg-surface-container text-on-surface px-4 py-2 rounded-full font-bold text-xs hover:bg-surface-container-highest transition-all active:scale-95 cursor-pointer border border-outline-variant/30">
            <Download className="w-3.5 h-3.5" />
            <span>Export CSV</span>
          </button>
        </div>
      </div>

      {/* 2. Snapshot Bento Grid */}
      <section className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* Gross Volume */}
        <div className="bg-surface-container-lowest dark:bg-surface-container-low p-5 rounded-2xl border border-outline-variant/20 shadow-sm flex flex-col justify-between">
          <div className="flex justify-between items-start mb-4">
            <div className="p-2.5 bg-primary/10 rounded-xl text-primary">
              <Wallet className="w-5 h-5" />
            </div>
            <span className="text-primary text-xs font-bold bg-primary/10 px-2.5 py-0.5 rounded-full flex items-center gap-0.5">
              <TrendingUp className="w-3.5 h-3.5" />
              +12.5%
            </span>
          </div>
          <p className="text-outline text-xs font-bold uppercase tracking-wider mb-1">Gross Volume</p>
          <h3 className="text-2xl md:text-3xl font-extrabold text-on-surface">GHS 2,842,900</h3>
          <p className="text-outline text-xs mt-1.5 font-semibold">v.s. GHS 2,527,022 last month</p>
        </div>

        {/* Net Platform Fees */}
        <div className="bg-surface-container-lowest dark:bg-surface-container-low p-5 rounded-2xl border border-outline-variant/20 shadow-sm flex flex-col justify-between">
          <div className="flex justify-between items-start mb-4">
            <div className="p-2.5 bg-secondary-container/20 rounded-xl text-secondary">
              <Building className="w-5 h-5" />
            </div>
            <span className="text-secondary text-xs font-bold bg-secondary-container/20 px-2.5 py-0.5 rounded-full">
              +8.2%
            </span>
          </div>
          <p className="text-outline text-xs font-bold uppercase tracking-wider mb-1">Net Platform Fees</p>
          <h3 className="text-2xl md:text-3xl font-extrabold text-on-surface">GHS 426,180</h3>
          <p className="text-outline text-xs mt-1.5 font-semibold">15% average commission</p>
        </div>

        {/* Payout Totals */}
        <div className="bg-surface-container-lowest dark:bg-surface-container-low p-5 rounded-2xl border border-outline-variant/20 shadow-sm flex flex-col justify-between">
          <div className="flex justify-between items-start mb-4">
            <div className="p-2.5 bg-tertiary-container/15 rounded-xl text-tertiary">
              <FileText className="w-5 h-5" />
            </div>
            <span className="text-tertiary text-xs font-bold bg-tertiary-container/10 px-2.5 py-0.5 rounded-full font-mono">
              99.8% Success
            </span>
          </div>
          <p className="text-outline text-xs font-bold uppercase tracking-wider mb-1">Payout Totals</p>
          <h3 className="text-2xl md:text-3xl font-extrabold text-on-surface">GHS 2,416,720</h3>
          <p className="text-outline text-xs mt-1.5 font-semibold">To 1,240 partners this month</p>
        </div>
      </section>

      {/* 3. Revenue Growth Trend Line */}
      <section className="bg-surface-container-lowest dark:bg-surface-container-low p-5 rounded-2xl border border-outline-variant/20 shadow-sm">
        <div className="flex justify-between items-center mb-6">
          <div>
            <h2 className="text-lg font-bold text-on-surface">Revenue Growth</h2>
            <p className="text-xs text-on-surface-variant">Daily volume trends for current cycle</p>
          </div>
          <div className="flex gap-1.5">
            <button 
              onClick={() => setBillingCycle('daily')}
              className={`px-3 py-1 rounded-full text-xs font-bold transition-all cursor-pointer ${
                billingCycle === 'daily' ? 'bg-primary text-on-primary' : 'bg-surface-container-high dark:bg-surface-container text-on-surface-variant hover:text-on-surface'
              }`}
            >
              Daily
            </button>
            <button 
              onClick={() => setBillingCycle('weekly')}
              className={`px-3 py-1 rounded-full text-xs font-bold transition-all cursor-pointer ${
                billingCycle === 'weekly' ? 'bg-primary text-on-primary' : 'bg-surface-container-high dark:bg-surface-container text-on-surface-variant hover:text-on-surface'
              }`}
            >
              Weekly
            </button>
          </div>
        </div>

        {/* Custom Curved SVG Line Chart with Gradient and interactive nodes */}
        <div className="relative h-64 w-full bg-surface-container/30 rounded-xl border border-outline-variant/10 overflow-hidden group">
          <svg className="w-full h-full" preserveAspectRatio="none" viewBox="0 0 1000 200">
            <defs>
              <linearGradient id="chart-area-grad" x1="0%" x2="0%" y1="0%" y2="100%">
                <stop offset="0%" stopColor="var(--primary)" stopOpacity="0.25"></stop>
                <stop offset="100%" stopColor="var(--primary)" stopOpacity="0"></stop>
              </linearGradient>
            </defs>

            {/* Filled Area path */}
            <path 
              d="M0,180 Q100,160 200,140 T400,110 T600,80 T800,60 T1000,40 L1000,200 L0,200 Z" 
              fill="url(#chart-area-grad)"
              className="transition-all duration-500"
            />

            {/* Beautiful stroke path */}
            <path 
              d="M0,180 Q100,160 200,140 T400,110 T600,80 T800,60 T1000,40" 
              fill="none" 
              stroke="var(--primary)" 
              strokeWidth="4" 
              strokeLinecap="round"
              className="transition-all duration-500"
            />

            {/* Interactive Circles / nodes */}
            {points.map((pt, idx) => (
              <circle
                key={idx}
                cx={pt.x}
                cy={pt.y}
                r={hoveredPoint === idx ? "7" : "4"}
                fill="var(--primary)"
                stroke="var(--surface-container-lowest)"
                strokeWidth={hoveredPoint === idx ? "3" : "1.5"}
                className="cursor-pointer transition-all duration-200"
                onMouseEnter={() => setHoveredPoint(idx)}
                onMouseLeave={() => setHoveredPoint(null)}
              />
            ))}
          </svg>

          {/* Floating Tooltip Simulation */}
          <AnimatePresence>
            {hoveredPoint !== null && (
              <motion.div 
                initial={{ opacity: 0, y: 10, scale: 0.95 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: 10 }}
                className="absolute top-4 right-4 bg-on-surface text-surface-container-lowest text-xs font-bold px-3 py-1.5 rounded-xl shadow-lg border border-outline-variant/25 z-20 flex flex-col"
              >
                <span className="text-[10px] text-outline font-semibold uppercase">{points[hoveredPoint].label}</span>
                <span className="text-primary-container font-extrabold text-sm">{points[hoveredPoint].val}</span>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {/* X-Axis labels */}
        <div className="flex justify-between mt-4 px-2 text-outline text-xs font-bold">
          <span>Oct 01</span>
          <span>Oct 08</span>
          <span>Oct 15</span>
          <span>Oct 22</span>
          <span>Oct 29</span>
        </div>
      </section>

      {/* 4. Bottom Row: Recent Payouts & Service Breakdown */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Recent Payouts Table */}
        <section className="lg:col-span-2 bg-surface-container-lowest dark:bg-surface-container-low rounded-2xl border border-outline-variant/20 shadow-sm overflow-hidden flex flex-col justify-between">
          <div>
            <div className="p-4 border-b border-outline-variant/30 flex justify-between items-center bg-surface-container-low/30">
              <h2 className="font-extrabold text-base text-on-surface">Recent Payouts</h2>
              <span className="text-primary font-bold text-xs cursor-pointer hover:underline">View All</span>
            </div>
            
            <div className="overflow-x-auto">
              <table className="w-full text-left">
                <thead className="bg-surface-container-low/40 text-xs font-bold text-outline uppercase tracking-wider border-b border-outline-variant/20">
                  <tr>
                    <th className="px-5 py-3.5">Recipient</th>
                    <th className="px-5 py-3.5">Type</th>
                    <th className="px-5 py-3.5">Status</th>
                    <th className="px-5 py-3.5 text-right">Amount</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-outline-variant/15">
                  {payouts.map((payout) => (
                    <tr 
                      key={payout.id} 
                      className="hover:bg-primary/5 transition-colors cursor-pointer group"
                    >
                      <td className="px-5 py-3.5">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-secondary-container flex items-center justify-center text-on-secondary-container font-extrabold text-xs">
                            {payout.avatarText}
                          </div>
                          <div>
                            <p className="font-bold text-xs text-on-surface group-hover:text-primary transition-colors">
                              {payout.recipient}
                            </p>
                            <p className="text-[10px] text-outline font-semibold">{payout.recipientId}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-5 py-3.5 text-xs text-on-surface-variant font-medium">
                        {payout.type}
                      </td>
                      <td className="px-5 py-3.5">
                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                          payout.status === 'completed' 
                            ? 'bg-primary-container/15 text-on-primary-container' 
                            : 'bg-secondary-container text-on-secondary-container'
                        }`}>
                          {payout.status}
                        </span>
                      </td>
                      <td className="px-5 py-3.5 text-right font-extrabold text-xs text-on-surface">
                        ${payout.amount.toLocaleString(undefined, { minimumFractionDigits: 2 })}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </section>

        {/* Service Line Breakdown Progress Bars */}
        <section className="bg-surface-container-lowest dark:bg-surface-container-low p-5 rounded-2xl border border-outline-variant/20 shadow-sm flex flex-col justify-between">
          <div>
            <h2 className="font-extrabold text-base text-on-surface mb-6">Service Revenue Breakdown</h2>
            
            <div className="space-y-5">
              {/* Food Delivery */}
              <div className="space-y-1">
                <div className="flex justify-between items-center text-xs">
                  <div className="flex items-center gap-2">
                    <span className="w-2.5 h-2.5 rounded-full bg-primary"></span>
                    <span className="font-bold text-on-surface">Food Delivery</span>
                  </div>
                  <span className="font-extrabold text-on-surface">72%</span>
                </div>
                <div className="h-2 w-full bg-surface-container-high dark:bg-surface-container rounded-full overflow-hidden">
                  <div className="h-full bg-primary w-[72%] rounded-full"></div>
                </div>
                <p className="text-right text-[10px] font-bold text-outline">GHS 2,046,888</p>
              </div>

              {/* Parcel Express */}
              <div className="space-y-1">
                <div className="flex justify-between items-center text-xs">
                  <div className="flex items-center gap-2">
                    <span className="w-2.5 h-2.5 rounded-full bg-tertiary"></span>
                    <span className="font-bold text-on-surface">Parcel Express</span>
                  </div>
                  <span className="font-extrabold text-on-surface">24%</span>
                </div>
                <div className="h-2 w-full bg-surface-container-high dark:bg-surface-container rounded-full overflow-hidden">
                  <div className="h-full bg-tertiary w-[24%] rounded-full"></div>
                </div>
                <p className="text-right text-[10px] font-bold text-outline">GHS 682,296</p>
              </div>

              {/* Marketplace Services */}
              <div className="space-y-1">
                <div className="flex justify-between items-center text-xs">
                  <div className="flex items-center gap-2">
                    <span className="w-2.5 h-2.5 rounded-full bg-secondary"></span>
                    <span className="font-bold text-on-surface">Marketplace</span>
                  </div>
                  <span className="font-extrabold text-on-surface">4%</span>
                </div>
                <div className="h-2 w-full bg-surface-container-high dark:bg-surface-container rounded-full overflow-hidden">
                  <div className="h-full bg-secondary w-[4%] rounded-full"></div>
                </div>
                <p className="text-right text-[10px] font-bold text-outline">GHS 113,716</p>
              </div>
            </div>
          </div>

          <div className="mt-6 p-4 bg-surface-container-low dark:bg-surface-container/30 rounded-xl border border-outline-variant/10 flex flex-col gap-1.5">
            <p className="font-bold text-xs text-on-surface-variant flex items-center gap-1.5">
              <Info className="w-4 h-4 text-primary shrink-0" />
              <span>Growth Forecast</span>
            </p>
            <p className="text-[10px] text-outline leading-normal font-semibold">
              Based on current predictive models, parcel express delivery is forecasted to spike by 5.2% in the next fiscal quarter.
            </p>
          </div>
        </section>

      </div>

      {/* simulated payout creation modal */}
      <AnimatePresence>
        {showPayoutModal && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
            <motion.div 
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              className="bg-surface-container-lowest dark:bg-surface-container p-6 rounded-2xl border border-outline-variant/30 max-w-sm w-full shadow-2xl"
            >
              <h3 className="font-extrabold text-lg text-on-surface mb-3 flex items-center gap-2">
                <Wallet className="text-primary w-5 h-5" />
                <span>Initiate Partner Payout</span>
              </h3>
              <p className="text-xs text-on-surface-variant mb-4 leading-normal">
                Disburse system funds to courier riders or logistics merchants securely.
              </p>

              <form onSubmit={handleCreatePayout} className="space-y-4">
                <div>
                  <label className="text-xs font-bold text-on-surface block mb-1">Recipient Name</label>
                  <input 
                    type="text" 
                    required
                    placeholder="e.g. Green Garden Deli"
                    value={newRecipient}
                    onChange={(e) => setNewRecipient(e.target.value)}
                    className="w-full bg-surface-container-low dark:bg-surface-container-low border border-outline-variant/30 rounded-xl px-3 py-2 text-sm text-on-surface focus:border-primary focus:ring-0 focus:outline-none"
                  />
                </div>

                <div>
                  <label className="text-xs font-bold text-on-surface block mb-1">Amount (USD)</label>
                  <input 
                    type="number" 
                    required
                    step="0.01"
                    placeholder="e.g. 1500.00"
                    value={newAmount}
                    onChange={(e) => setNewAmount(e.target.value)}
                    className="w-full bg-surface-container-low dark:bg-surface-container-low border border-outline-variant/30 rounded-xl px-3 py-2 text-sm text-on-surface focus:border-primary focus:ring-0 focus:outline-none"
                  />
                </div>

                <div>
                  <label className="text-xs font-bold text-on-surface block mb-1">Disbursement Route</label>
                  <select 
                    value={newType}
                    onChange={(e) => setNewType(e.target.value)}
                    className="w-full bg-surface-container-low dark:bg-surface-container-low border border-outline-variant/30 rounded-xl px-3 py-2 text-sm text-on-surface focus:border-primary focus:ring-0 focus:outline-none"
                  >
                    <option value="Standard">Standard ACH (1-2 Days)</option>
                    <option value="Instant">Instant Debit Transfer</option>
                    <option value="Weekly Batch">Weekly Settlement Batch</option>
                  </select>
                </div>

                <div className="flex gap-2 pt-2">
                  <button 
                    type="button" 
                    onClick={() => setShowPayoutModal(false)}
                    className="flex-1 py-2 rounded-full border border-outline-variant/50 text-xs font-bold text-on-surface hover:bg-surface-container-low cursor-pointer"
                  >
                    Cancel
                  </button>
                  <button 
                    type="submit"
                    className="flex-1 py-2 rounded-full bg-primary text-on-primary text-xs font-bold hover:bg-primary-hover shadow-md cursor-pointer"
                  >
                    Disburse Funds
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

    </div>
  );
}
