import React, { useState, useEffect } from 'react';
import { Sparkles, Plus, Search, Eye, EyeOff, Loader2, Image as ImageIcon, DollarSign } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { api } from '../api';

interface CosmeticProduct {
  id: string;
  name: string;
  description: string | null;
  price: number;
  image_url: string | null;
  is_available: boolean;
  created_at: string;
}

export default function CosmeticsView() {
  const [products, setProducts] = useState<CosmeticProduct[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [showAddModal, setShowAddModal] = useState(false);
  
  // New cosmetic product form state
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [price, setPrice] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  const loadCosmetics = async () => {
    setLoading(true);
    try {
      // Fetch from backend admin route
      const res = await api.getAdminCosmetics();
      setProducts(res);
    } catch (e: any) {
      console.error('Failed to load cosmetics', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadCosmetics();
  }, []);

  const handleToggleAvailability = async (id: string) => {
    try {
      const res = await api.toggleAdminCosmetic(id);
      setProducts(prev => prev.map(p => p.id === id ? { ...p, is_available: res.is_available } : p));
    } catch (e) {
      console.error('Failed to toggle cosmetic availability', e);
    }
  };

  const handleAddCosmetic = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !price) {
      setError('Name and Price are required.');
      return;
    }
    
    setSubmitting(true);
    setError('');

    try {
      await api.createAdminCosmetic({
        name,
        description: description || undefined,
        price: parseFloat(price),
        image_url: imageUrl || undefined
      });

      // Reset form & reload
      setName('');
      setDescription('');
      setPrice('');
      setImageUrl('');
      setShowAddModal(false);
      await loadCosmetics();
    } catch (e: any) {
      setError(e.message || 'Failed to add cosmetic product');
    } finally {
      setSubmitting(false);
    }
  };

  const filteredProducts = products.filter(p =>
    p.name.toLowerCase().includes(search.toLowerCase()) ||
    (p.description && p.description.toLowerCase().includes(search.toLowerCase()))
  );

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-12">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-black text-on-surface flex items-center gap-2">
            <span className="p-2 bg-pink-500/10 rounded-xl text-pink-500">
              <Sparkles className="w-6 h-6" />
            </span>
            Cosmetics Inventory
          </h2>
          <p className="text-xs text-on-surface-variant mt-1">Manage global cosmetics store catalog & delivery availability</p>
        </div>

        <button
          onClick={() => { setShowAddModal(true); setError(''); }}
          className="flex items-center gap-2 px-4 py-2.5 bg-pink-600 hover:bg-pink-700 text-white font-bold text-xs rounded-xl transition cursor-pointer shadow-md shadow-pink-600/10 self-start sm:self-auto"
        >
          <Plus className="w-4 h-4" />
          Add Cosmetic Item
        </button>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-surface-container-lowest dark:bg-surface-container-low p-4 rounded-2xl border border-outline-variant/30 shadow-sm flex flex-col md:flex-row gap-4 items-center justify-between">
        <div className="relative w-full md:w-96">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-outline" />
          <input
            type="text"
            placeholder="Search cosmetics..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 bg-surface-container-low border border-outline-variant/30 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-pink-500 text-on-surface"
          />
        </div>
        <span className="text-xs text-on-surface-variant font-bold">
          Showing {filteredProducts.length} of {products.length} Items
        </span>
      </div>

      {/* Grid of items */}
      {loading ? (
        <div className="flex flex-col items-center justify-center py-20 gap-3">
          <Loader2 className="w-8 h-8 text-pink-500 animate-spin" />
          <p className="text-xs text-on-surface-variant font-medium">Loading cosmetics list...</p>
        </div>
      ) : filteredProducts.length === 0 ? (
        <div className="bg-surface-container-lowest dark:bg-surface-container-low py-16 rounded-2xl border border-outline-variant/30 text-center">
          <ImageIcon className="w-12 h-12 text-outline mx-auto mb-3" />
          <h4 className="font-bold text-on-surface text-base">No Cosmetics Found</h4>
          <p className="text-xs text-on-surface-variant mt-1">Try updating your search query or add a new item.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
          {filteredProducts.map((p) => (
            <motion.div
              layout
              key={p.id}
              className={`bg-surface-container-lowest dark:bg-surface-container-low rounded-2xl border transition-all duration-300 shadow-sm overflow-hidden flex flex-col relative group ${
                p.is_available ? 'border-outline-variant/30' : 'border-outline-variant/20 opacity-75'
              }`}
            >
              {/* Product Image */}
              <div className="h-44 bg-surface-container-low relative overflow-hidden">
                {p.image_url ? (
                  <img
                    src={p.image_url}
                    alt={p.name}
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                    referrerPolicy="no-referrer"
                  />
                ) : (
                  <div className="w-full h-full flex flex-col items-center justify-center text-outline">
                    <ImageIcon className="w-8 h-8 opacity-40" />
                    <span className="text-[10px] mt-1">No Image</span>
                  </div>
                )}
                
                {/* Availability Badge */}
                <span className={`absolute top-3 right-3 text-[10px] font-extrabold px-2 py-0.5 rounded-full ${
                  p.is_available ? 'bg-green-500/10 text-green-500' : 'bg-red-500/10 text-red-500'
                }`}>
                  {p.is_available ? 'Available' : 'Out of Stock'}
                </span>
              </div>

              {/* Product Body */}
              <div className="p-4 flex-1 flex flex-col justify-between">
                <div>
                  <h4 className="font-bold text-on-surface text-sm truncate">{p.name}</h4>
                  <p className="text-on-surface-variant text-[11px] mt-1 line-clamp-2 min-h-[32px] leading-relaxed">
                    {p.description || 'No description provided.'}
                  </p>
                </div>

                <div className="mt-4 pt-3 border-t border-outline-variant/10 flex items-center justify-between">
                  <span className="text-base font-extrabold text-on-surface">₵{p.price.toFixed(2)}</span>
                  
                  <button
                    onClick={() => handleToggleAvailability(p.id)}
                    className={`p-2 rounded-xl border cursor-pointer transition ${
                      p.is_available
                        ? 'border-green-500/20 text-green-500 bg-green-500/5 hover:bg-green-500/10'
                        : 'border-red-500/20 text-red-500 bg-red-500/5 hover:bg-red-500/10'
                    }`}
                    title={p.is_available ? 'Mark Out of Stock' : 'Mark Available'}
                  >
                    {p.is_available ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
                  </button>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      )}

      {/* Add Cosmetic Item Modal */}
      <AnimatePresence>
        {showAddModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="bg-surface-container-lowest dark:bg-surface-container-low w-full max-w-lg rounded-2xl shadow-xl border border-outline-variant/30 overflow-hidden"
            >
              <div className="p-6 border-b border-outline-variant/20 flex justify-between items-center bg-pink-500/5">
                <h3 className="font-extrabold text-base text-on-surface flex items-center gap-2">
                  <Sparkles className="w-5 h-5 text-pink-500" />
                  Add New Cosmetic Product
                </h3>
                <button
                  onClick={() => setShowAddModal(false)}
                  className="text-outline hover:text-on-surface font-bold text-lg cursor-pointer"
                >
                  &times;
                </button>
              </div>

              <form onSubmit={handleAddCosmetic} className="p-6 space-y-4">
                {error && (
                  <p className="p-3 bg-red-500/10 border-l-4 border-red-500 text-xs text-red-500 rounded-lg">
                    {error}
                  </p>
                )}

                <div>
                  <label className="block text-xs font-bold text-on-surface-variant uppercase tracking-wider mb-1">
                    Product Name *
                  </label>
                  <input
                    type="text"
                    required
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="e.g. Shea Moisture Hair Oil"
                    className="w-full px-3 py-2 border border-outline-variant/30 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-pink-500 bg-surface-container-low text-on-surface"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-on-surface-variant uppercase tracking-wider mb-1">
                    Description
                  </label>
                  <textarea
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    placeholder="e.g. 100% natural organic shea butter extract..."
                    rows={3}
                    className="w-full px-3 py-2 border border-outline-variant/30 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-pink-500 bg-surface-container-low text-on-surface resize-none"
                  />
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-bold text-on-surface-variant uppercase tracking-wider mb-1">
                      Price (₵ GHS) *
                    </label>
                    <div className="relative">
                      <span className="absolute left-3 top-1/2 -translate-y-1/2 text-outline text-sm">₵</span>
                      <input
                        type="number"
                        step="0.01"
                        required
                        value={price}
                        onChange={(e) => setPrice(e.target.value)}
                        placeholder="0.00"
                        className="w-full pl-7 pr-3 py-2 border border-outline-variant/30 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-pink-500 bg-surface-container-low text-on-surface"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-on-surface-variant uppercase tracking-wider mb-1">
                      Image URL
                    </label>
                    <input
                      type="url"
                      value={imageUrl}
                      onChange={(e) => setImageUrl(e.target.value)}
                      placeholder="https://images.unsplash.com/..."
                      className="w-full px-3 py-2 border border-outline-variant/30 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-pink-500 bg-surface-container-low text-on-surface"
                    />
                  </div>
                </div>

                <div className="pt-4 border-t border-outline-variant/10 flex justify-end gap-3">
                  <button
                    type="button"
                    onClick={() => setShowAddModal(false)}
                    className="px-4 py-2 border border-outline-variant/30 hover:bg-surface-container-high rounded-xl text-xs font-bold text-on-surface cursor-pointer"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={submitting}
                    className="flex items-center gap-1.5 px-4 py-2 bg-pink-600 hover:bg-pink-700 disabled:opacity-50 text-white font-bold text-xs rounded-xl cursor-pointer"
                  >
                    {submitting && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                    Save Product
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
