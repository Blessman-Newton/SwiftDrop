import React, { useState } from 'react';
import { Mail, Lock, Eye, EyeOff, ShieldAlert, CheckCircle, Fingerprint, LogIn, ExternalLink } from 'lucide-react';
import { motion } from 'motion/react';

interface LoginScreenProps {
  onLoginSuccess: () => void;
  showToast: (message: string, type: 'success' | 'error' | 'info') => void;
}

export default function LoginScreen({ onLoginSuccess, showToast }: LoginScreenProps) {
  const [email, setEmail] = useState('rider@swiftdrop.com');
  const [password, setPassword] = useState('••••••••');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) {
      showToast('Please enter your email or phone number', 'error');
      return;
    }
    
    setIsLoading(true);
    showToast('Authenticating security keys...', 'info');

    setTimeout(() => {
      setIsLoading(false);
      showToast('Welcome back, Alex!', 'success');
      onLoginSuccess();
    }, 1500);
  };

  const handleBiometric = (type: 'Face ID' | 'Touch ID') => {
    setIsLoading(true);
    showToast(`Scanning for ${type}...`, 'info');
    
    setTimeout(() => {
      setIsLoading(false);
      showToast(`Biometric match! Welcome back, Alex`, 'success');
      onLoginSuccess();
    }, 1200);
  };

  return (
    <motion.div 
      initial={{ opacity: 0, y: 15 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -15 }}
      transition={{ duration: 0.3 }}
      className="flex flex-col min-h-full justify-between px-6 pb-6 pt-2 overflow-y-auto no-scrollbar"
    >
      {/* Brand Header */}
      <div className="flex flex-col items-center text-center mt-4">
        <div className="flex items-center gap-2 mb-1 mt-2">
          <div className="w-10 h-10 rounded-xl bg-emerald-600 dark:bg-emerald-500 flex items-center justify-center text-white shadow-md shadow-emerald-600/20">
            <LogIn className="w-5 h-5" />
          </div>
          <span className="text-2xl font-extrabold tracking-tight text-emerald-600 dark:text-emerald-400">
            SwiftDrop
          </span>
        </div>
        <span className="text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-400 px-2.5 py-1 rounded-full border border-emerald-100 dark:border-emerald-900/20">
          SECURE RIDER HUB
        </span>
      </div>

      {/* Main Login Card */}
      <div className="mt-6 bg-white/90 dark:bg-slate-900/95 backdrop-blur-md p-6 rounded-3xl shadow-xl border border-slate-100 dark:border-slate-800 flex-1 flex flex-col justify-center">
        <div className="mb-6">
          <h2 className="text-2xl font-bold tracking-tight text-slate-800 dark:text-white mb-1">
            Rider Login
          </h2>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Secure access to your delivery dashboard
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1.5">
            <label className="text-[13px] font-bold text-slate-500 dark:text-slate-400 block ml-1">
              Email or Phone Number
            </label>
            <div className="relative group">
              <span className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-emerald-600 dark:group-focus-within:text-emerald-400 transition-colors">
                <Mail className="w-4.5 h-4.5" />
              </span>
              <input
                type="text"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="rider@swiftdrop.com"
                className="w-full pl-11 pr-4 py-3 bg-slate-50 dark:bg-slate-800/80 border-none rounded-2xl text-[15px] focus:outline-none focus:ring-2 focus:ring-emerald-500 dark:focus:ring-emerald-400 text-slate-800 dark:text-slate-100 font-medium transition-all"
                disabled={isLoading}
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <div className="flex justify-between items-center ml-1">
              <label className="text-[13px] font-bold text-slate-500 dark:text-slate-400">
                Password
              </label>
              <button
                type="button"
                onClick={() => showToast('Password reset link sent to registered phone/email', 'success')}
                className="text-[12px] font-semibold text-emerald-600 dark:text-emerald-400 hover:underline"
              >
                Forgot Password?
              </button>
            </div>
            <div className="relative group">
              <span className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-emerald-600 dark:group-focus-within:text-emerald-400 transition-colors">
                <Lock className="w-4.5 h-4.5" />
              </span>
              <input
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full pl-11 pr-11 py-3 bg-slate-50 dark:bg-slate-800/80 border-none rounded-2xl text-[15px] focus:outline-none focus:ring-2 focus:ring-emerald-500 dark:focus:ring-emerald-400 text-slate-800 dark:text-slate-100 transition-all tracking-wider font-semibold"
                disabled={isLoading}
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition-colors"
              >
                {showPassword ? <EyeOff className="w-4.5 h-4.5" /> : <Eye className="w-4.5 h-4.5" />}
              </button>
            </div>
          </div>

          <div className="pt-2">
            <button
              type="submit"
              disabled={isLoading}
              className="w-full py-3.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-2xl flex items-center justify-center gap-2 shadow-lg shadow-emerald-600/15 active:scale-95 transition-all text-[15px]"
            >
              {isLoading ? (
                <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : (
                <>
                  <span>Sign In</span>
                  <ExternalLink className="w-4.5 h-4.5" />
                </>
              )}
            </button>
          </div>
        </form>

        <div className="mt-6">
          <div className="relative flex items-center mb-4">
            <div className="flex-grow border-t border-slate-100 dark:border-slate-800" />
            <span className="flex-shrink mx-4 text-[11px] font-bold text-slate-400 dark:text-slate-500 tracking-wider uppercase">
              OR SECURE LOGIN WITH
            </span>
            <div className="flex-grow border-t border-slate-100 dark:border-slate-800" />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <button
              onClick={() => handleBiometric('Face ID')}
              disabled={isLoading}
              className="flex items-center justify-center gap-2 py-3 bg-slate-50 dark:bg-slate-800 hover:bg-slate-100 dark:hover:bg-slate-700/80 rounded-2xl text-[13px] font-bold text-slate-600 dark:text-slate-300 transition-colors"
            >
              <Fingerprint className="w-4.5 h-4.5 text-emerald-600 dark:text-emerald-400" />
              <span>Face ID</span>
            </button>
            <button
              onClick={() => handleBiometric('Touch ID')}
              disabled={isLoading}
              className="flex items-center justify-center gap-2 py-3 bg-slate-50 dark:bg-slate-800 hover:bg-slate-100 dark:hover:bg-slate-700/80 rounded-2xl text-[13px] font-bold text-slate-600 dark:text-slate-300 transition-colors"
            >
              <Fingerprint className="w-4.5 h-4.5 text-emerald-600 dark:text-emerald-400" />
              <span>Touch ID</span>
            </button>
          </div>
        </div>
      </div>

      {/* Want to earn CTA */}
      <div className="mt-6 text-center bg-white/40 dark:bg-slate-900/40 backdrop-blur-sm p-4 rounded-2xl border border-slate-200/40 dark:border-slate-800/40 shadow-sm flex flex-col items-center">
        <p className="text-[13px] font-medium text-slate-500 dark:text-slate-400">
          Want to earn with us?
        </p>
        <button
          onClick={() => showToast('Fleet application portal is open! Details sent to email.', 'success')}
          className="inline-flex items-center gap-1 text-[13px] text-emerald-600 dark:text-emerald-400 font-bold hover:underline mt-0.5"
        >
          <span>Join the Fleet</span>
          <ExternalLink className="w-3.5 h-3.5" />
        </button>
      </div>

      {/* Security Footer */}
      <footer className="mt-6 flex justify-center gap-6 text-[11px] font-semibold text-slate-400 dark:text-slate-500 tracking-wide select-none">
        <div className="flex items-center gap-1">
          <ShieldAlert className="w-3.5 h-3.5" />
          <span>256-bit Encrypted</span>
        </div>
        <div className="flex items-center gap-1">
          <CheckCircle className="w-3.5 h-3.5" />
          <span>Secure Identity</span>
        </div>
      </footer>
    </motion.div>
  );
}
