import React, { useEffect } from 'react';
import { CheckCircle, Info, AlertTriangle, X } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

export interface Toast {
  id: string;
  message: string;
  type: 'success' | 'error' | 'info';
}

interface NotificationProps {
  toasts: Toast[];
  setToasts: React.Dispatch<React.SetStateAction<Toast[]>>;
}

export default function Notification({ toasts, setToasts }: NotificationProps) {
  useEffect(() => {
    if (toasts.length > 0) {
      const timer = setTimeout(() => {
        setToasts((prev) => prev.slice(1));
      }, 3500);
      return () => clearTimeout(timer);
    }
  }, [toasts, setToasts]);

  const removeToast = (id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  };

  return (
    <div className="absolute top-12 left-1/2 -translate-x-1/2 w-[90%] max-w-[340px] z-50 flex flex-col gap-2 pointer-events-none">
      <AnimatePresence>
        {toasts.map((toast) => (
          <motion.div
            key={toast.id}
            initial={{ opacity: 0, y: -20, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -10, scale: 0.95 }}
            className={`p-3 rounded-xl shadow-lg border flex items-start gap-2.5 backdrop-blur-md pointer-events-auto ${
              toast.type === 'success'
                ? 'bg-emerald-500/90 border-emerald-400 text-white'
                : toast.type === 'error'
                ? 'bg-rose-500/90 border-rose-400 text-white'
                : 'bg-slate-900/90 border-slate-700 text-slate-100'
            }`}
          >
            <div className="shrink-0 mt-0.5">
              {toast.type === 'success' && <CheckCircle className="w-4 h-4 text-emerald-100" />}
              {toast.type === 'error' && <AlertTriangle className="w-4 h-4 text-rose-100" />}
              {toast.type === 'info' && <Info className="w-4 h-4 text-emerald-400" />}
            </div>
            <p className="text-[12px] font-bold flex-1 leading-normal">
              {toast.message}
            </p>
            <button
              onClick={() => removeToast(toast.id)}
              className="text-white/70 hover:text-white shrink-0"
            >
              <X className="w-3.5 h-3.5" />
            </button>
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}
