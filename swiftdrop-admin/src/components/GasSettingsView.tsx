import React, { useState, useEffect } from 'react';
import { Flame, DollarSign, Save, Loader2, Sparkles, HelpCircle } from 'lucide-react';
import { api } from '../api';

export default function GasSettingsView() {
  const [prices, setPrices] = useState<Record<string, number>>({
    '6 kg': 75.0,
    '12.5 kg': 150.0,
    '14 kg': 180.0,
    '22 kg': 280.0,
    '50 kg': 600.0,
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [successMessage, setSuccessMessage] = useState('');
  const [errorMessage, setErrorMessage] = useState('');

  useEffect(() => {
    const fetchPrices = async () => {
      setLoading(true);
      try {
        const data = await api.getGasPrices();
        if (data && Object.keys(data).length > 0) {
          setPrices(data);
        }
      } catch (err) {
        console.error('Failed to load gas prices', err);
      } finally {
        setLoading(false);
      }
    };
    fetchPrices();
  }, []);

  const handlePriceChange = (size: string, val: string) => {
    const num = parseFloat(val);
    setPrices((prev) => ({
      ...prev,
      [size]: isNaN(num) ? 0 : num,
    }));
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setSuccessMessage('');
    setErrorMessage('');
    try {
      await api.updateGasPrices(prices);
      setSuccessMessage('Gas refill prices updated successfully on the platform!');
      setTimeout(() => setSuccessMessage(''), 4000);
    } catch (err: any) {
      setErrorMessage(err.message || 'Failed to update gas prices.');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <Loader2 className="w-10 h-10 animate-spin text-primary-600" />
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Header card */}
      <div className="bg-gradient-to-r from-orange-500 to-amber-600 rounded-2xl p-6 text-white shadow-md relative overflow-hidden">
        <div className="relative z-10">
          <div className="flex items-center gap-3">
            <div className="p-3 bg-white/10 rounded-xl backdrop-blur-sm">
              <Flame className="w-8 h-8 text-white" />
            </div>
            <div>
              <h2 className="text-2xl font-bold">LPG Gas Refill Pricing</h2>
              <p className="text-orange-100 text-sm mt-1">
                Configure rates for standard LPG cylinder refill delivery sizes.
              </p>
            </div>
          </div>
        </div>
        <div className="absolute right-0 top-0 translate-x-1/4 -translate-y-1/4 opacity-10 pointer-events-none">
          <Flame className="w-80 h-80 text-white" />
        </div>
      </div>

      <form onSubmit={handleSave} className="space-y-6">
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
            <Sparkles className="w-5 h-5 text-amber-500" />
            Cylinder Size Price Sheet
          </h3>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {Object.keys(prices).map((size) => (
              <div
                key={size}
                className="flex items-center justify-between p-4 bg-gray-50 rounded-xl border border-gray-100 transition hover:shadow-sm"
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-orange-100 text-orange-600 rounded-lg flex items-center justify-center font-bold text-sm">
                    {size.split(' ')[0]}
                  </div>
                  <div>
                    <h4 className="font-semibold text-gray-800">{size} Cylinder</h4>
                    <p className="text-xs text-gray-500">Refill Delivery Service</p>
                  </div>
                </div>

                <div className="relative w-36">
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 font-semibold text-sm">
                    GHS
                  </span>
                  <input
                    type="number"
                    step="0.01"
                    min="1"
                    required
                    value={prices[size] || ''}
                    onChange={(e) => handlePriceChange(size, e.target.value)}
                    className="w-full pl-12 pr-4 py-2 border border-gray-200 rounded-lg font-bold text-gray-800 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
                  />
                </div>
              </div>
            ))}
          </div>

          <div className="mt-8 border-t border-gray-100 pt-6 flex items-center justify-between flex-wrap gap-4">
            <div className="flex items-start gap-2 max-w-lg">
              <HelpCircle className="w-5 h-5 text-gray-400 shrink-0 mt-0.5" />
              <p className="text-xs text-gray-500">
                Updating these values will immediately affect all new scheduled LPG refill bookings generated by customers on the SwiftDrop mobile app. Make sure to check local LPG rates before saving.
              </p>
            </div>

            <button
              type="submit"
              disabled={saving}
              className="flex items-center gap-2 px-6 py-2.5 bg-orange-600 hover:bg-orange-700 disabled:bg-gray-300 text-white font-bold rounded-xl shadow-sm hover:shadow transition"
            >
              {saving ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" />
                  Saving...
                </>
              ) : (
                <>
                  <Save className="w-5 h-5" />
                  Save Prices
                </>
              )}
            </button>
          </div>
        </div>
      </form>

      {/* Notifications */}
      {successMessage && (
        <div className="bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded-xl font-medium text-sm flex items-center gap-2 shadow-sm animate-pulse">
          <span>✓</span> {successMessage}
        </div>
      )}
      {errorMessage && (
        <div className="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-xl font-medium text-sm flex items-center gap-2 shadow-sm">
          <span>✗</span> {errorMessage}
        </div>
      )}
    </div>
  );
}
