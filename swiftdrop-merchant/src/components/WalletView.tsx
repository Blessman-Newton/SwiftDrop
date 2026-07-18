import { useState } from "react";
import { Wallet, ArrowUpRight, Clock, CheckCircle2, XCircle, Loader2, Building2, Phone } from "lucide-react";
import { motion } from "motion/react";

export default function WalletView() {
  const [amount, setAmount] = useState("");
  const [provider, setProvider] = useState("MTN");
  const [number, setNumber] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const balance = 1250.50;
  const pending = 350.00;
  const totalEarned = 15800.00;

  const transactions = [
    { id: "TX1234", date: "2026-07-18T10:30:00", desc: "Payout to MTN MoMo", amount: -500, status: "pending" },
    { id: "TX1233", date: "2026-07-17T14:20:00", desc: "Order Earnings (#ORD-089)", amount: 150.50, status: "completed" },
    { id: "TX1232", date: "2026-07-16T09:15:00", desc: "Order Earnings (#ORD-088)", amount: 80.00, status: "completed" },
    { id: "TX1231", date: "2026-07-15T18:45:00", desc: "Payout to Telecel Cash", amount: -1000, status: "completed" },
    { id: "TX1230", date: "2026-07-14T12:00:00", desc: "Order Earnings (#ORD-087)", amount: 200.00, status: "failed" },
  ];

  const handleRequestPayout = (e: React.FormEvent) => {
    e.preventDefault();
    if (!amount || parseFloat(amount) <= 0 || parseFloat(amount) > balance) return;
    if (!number) return;
    
    setIsSubmitting(true);
    setTimeout(() => {
      setIsSubmitting(false);
      setToastMessage(`Successfully requested payout of GHS ${amount} to ${provider}`);
      setAmount("");
      setNumber("");
      setTimeout(() => setToastMessage(null), 3000);
    }, 1500);
  };

  return (
    <div className="space-y-6 relative">
      {toastMessage && (
        <motion.div 
          initial={{ opacity: 0, y: -20 }} 
          animate={{ opacity: 1, y: 0 }} 
          exit={{ opacity: 0, y: -20 }}
          className="absolute top-0 right-0 bg-primary text-on-primary px-4 py-3 rounded-xl shadow-lg z-50 flex items-center gap-2"
        >
          <CheckCircle2 className="h-5 w-5" />
          <span className="text-sm font-bold">{toastMessage}</span>
        </motion.div>
      )}

      <div>
        <h2 className="font-display text-2xl font-bold text-on-surface tracking-tight">Wallet & Payouts</h2>
        <p className="text-sm text-on-surface-variant">Manage your earnings and request withdrawals.</p>
      </div>

      {/* Balance Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="md:col-span-1 rounded-3xl bg-gradient-to-br from-[#006C49] to-[#004d34] p-6 text-white shadow-xl relative overflow-hidden">
          <div className="absolute top-0 right-0 -mr-8 -mt-8 w-32 h-32 rounded-full bg-white/10 blur-2xl" />
          <div className="absolute bottom-0 left-0 -ml-8 -mb-8 w-24 h-24 rounded-full bg-black/10 blur-xl" />
          
          <div className="relative z-10 flex flex-col h-full justify-between">
            <div>
              <p className="text-xs font-medium uppercase tracking-wider text-white/80 flex items-center gap-2">
                <Wallet className="h-4 w-4" /> Available Balance
              </p>
              <h3 className="text-4xl font-display font-extrabold mt-2 tracking-tight">
                <span className="text-xl mr-1">GHS</span>
                {balance.toFixed(2)}
              </h3>
            </div>
          </div>
        </div>

        <div className="md:col-span-2 grid grid-cols-2 gap-4">
          <div className="rounded-2xl border border-outline-variant/30 bg-surface-container-lowest p-5 flex flex-col justify-center dark:bg-surface-container-low">
            <p className="text-xs font-semibold text-on-surface-variant flex items-center gap-1.5 uppercase tracking-wider">
              <Clock className="h-4 w-4 text-secondary" /> Pending Payouts
            </p>
            <h4 className="text-2xl font-bold text-on-surface mt-2">GHS {pending.toFixed(2)}</h4>
          </div>
          <div className="rounded-2xl border border-outline-variant/30 bg-surface-container-lowest p-5 flex flex-col justify-center dark:bg-surface-container-low">
            <p className="text-xs font-semibold text-on-surface-variant flex items-center gap-1.5 uppercase tracking-wider">
              <ArrowUpRight className="h-4 w-4 text-primary" /> Total Earned
            </p>
            <h4 className="text-2xl font-bold text-on-surface mt-2">GHS {totalEarned.toFixed(2)}</h4>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Request Payout Form */}
        <div className="lg:col-span-1 bg-surface-container-lowest rounded-3xl p-6 border border-outline-variant/30 shadow-sm dark:bg-surface-container-low h-fit">
          <h3 className="font-display font-bold text-lg mb-4">Request Payout</h3>
          <form onSubmit={handleRequestPayout} className="space-y-4">
            <div>
              <label className="text-xs font-bold text-on-surface-variant mb-1.5 block">Amount (GHS)</label>
              <div className="relative">
                <span className="absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant font-bold text-sm">GHS</span>
                <input 
                  type="number" 
                  step="0.01"
                  max={balance}
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  placeholder="0.00"
                  className="w-full pl-12 pr-4 py-3 bg-surface-container rounded-xl border border-outline-variant/30 text-sm focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all font-medium"
                  required
                />
              </div>
              <p className="text-[10px] text-on-surface-variant mt-1.5">Max available: GHS {balance.toFixed(2)}</p>
            </div>

            <div>
              <label className="text-xs font-bold text-on-surface-variant mb-1.5 block">Provider</label>
              <div className="relative">
                <Building2 className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-on-surface-variant" />
                <select 
                  value={provider}
                  onChange={(e) => setProvider(e.target.value)}
                  className="w-full pl-10 pr-4 py-3 bg-surface-container rounded-xl border border-outline-variant/30 text-sm focus:outline-none focus:border-primary appearance-none font-medium"
                >
                  <option value="MTN">MTN Mobile Money</option>
                  <option value="Telecel">Telecel Cash</option>
                  <option value="AirtelTigo">AirtelTigo Money</option>
                </select>
              </div>
            </div>

            <div>
              <label className="text-xs font-bold text-on-surface-variant mb-1.5 block">Mobile Number</label>
              <div className="relative">
                <Phone className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-on-surface-variant" />
                <input 
                  type="tel" 
                  value={number}
                  onChange={(e) => setNumber(e.target.value)}
                  placeholder="e.g. 024XXXXXXX"
                  className="w-full pl-10 pr-4 py-3 bg-surface-container rounded-xl border border-outline-variant/30 text-sm focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all font-medium"
                  required
                />
              </div>
            </div>

            <button 
              type="submit" 
              disabled={isSubmitting || !amount || parseFloat(amount) <= 0 || parseFloat(amount) > balance || !number}
              className="w-full py-3.5 bg-primary text-on-primary rounded-xl text-sm font-bold shadow-sm hover:brightness-110 active:scale-95 transition-all disabled:opacity-50 disabled:active:scale-100 flex items-center justify-center mt-2"
            >
              {isSubmitting ? <Loader2 className="h-5 w-5 animate-spin" /> : "Submit Request"}
            </button>
          </form>
        </div>

        {/* Transaction History */}
        <div className="lg:col-span-2 bg-surface-container-lowest rounded-3xl p-6 border border-outline-variant/30 shadow-sm dark:bg-surface-container-low overflow-hidden flex flex-col">
          <div className="flex justify-between items-center mb-6">
            <h3 className="font-display font-bold text-lg">Transaction History</h3>
          </div>
          
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-outline-variant/20 text-xs text-on-surface-variant uppercase tracking-wider">
                  <th className="pb-3 font-semibold pl-1">Date</th>
                  <th className="pb-3 font-semibold">Description</th>
                  <th className="pb-3 font-semibold text-right">Amount</th>
                  <th className="pb-3 font-semibold text-right pr-1">Status</th>
                </tr>
              </thead>
              <tbody className="text-sm">
                {transactions.map((tx) => (
                  <tr key={tx.id} className="border-b border-outline-variant/10 hover:bg-surface-container-low/30 transition-colors">
                    <td className="py-4 pl-1 text-on-surface-variant">
                      {new Date(tx.date).toLocaleDateString()}
                      <span className="block text-[10px]">{new Date(tx.date).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                    </td>
                    <td className="py-4">
                      <p className="font-medium text-on-surface">{tx.desc}</p>
                      <p className="text-[10px] text-on-surface-variant uppercase">{tx.id}</p>
                    </td>
                    <td className={`py-4 text-right font-bold ${tx.amount > 0 ? "text-primary" : "text-on-surface"}`}>
                      {tx.amount > 0 ? "+" : ""}GHS {Math.abs(tx.amount).toFixed(2)}
                    </td>
                    <td className="py-4 text-right pr-1">
                      {tx.status === "completed" && (
                        <span className="inline-flex items-center gap-1 text-[10px] font-bold text-primary bg-primary/10 px-2 py-1 rounded-md uppercase">
                          <CheckCircle2 className="h-3 w-3" /> Completed
                        </span>
                      )}
                      {tx.status === "pending" && (
                        <span className="inline-flex items-center gap-1 text-[10px] font-bold text-secondary bg-secondary/10 px-2 py-1 rounded-md uppercase">
                          <Clock className="h-3 w-3" /> Pending
                        </span>
                      )}
                      {tx.status === "failed" && (
                        <span className="inline-flex items-center gap-1 text-[10px] font-bold text-error bg-error/10 px-2 py-1 rounded-md uppercase">
                          <XCircle className="h-3 w-3" /> Failed
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
