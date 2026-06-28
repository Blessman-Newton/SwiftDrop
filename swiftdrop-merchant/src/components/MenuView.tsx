import React, { useState, useMemo } from "react";
import { 
  Plus, 
  Edit, 
  Trash2, 
  Check, 
  X, 
  DollarSign, 
  Camera, 
  Sparkles,
  ClipboardList,
  AlertCircle
} from "lucide-react";
import { MenuItem } from "../types";
import { motion, AnimatePresence } from "motion/react";

interface MenuViewProps {
  menuItems: MenuItem[];
  onToggleStock: (itemId: string) => void;
  onAddItem: (newItem: Omit<MenuItem, "id" | "soldCount" | "soldTrend">) => void;
  onUpdateItem: (itemId: string, updatedItem: Partial<MenuItem>) => void;
  onDeleteItem: (itemId: string) => void;
}

const CATEGORIES = ["Popular", "Burgers", "Sides", "Beverages", "Desserts", "Combos"];

// Suggested culinary images for quick creation
const SUGGESTED_IMAGES = [
  {
    name: "Gourmet Burger",
    url: "https://lh3.googleusercontent.com/aida-public/AB6AXuBtPZPf8uj943aflmRsqlgyQLnOCvi_AWEz6GRRLKM4utZXgAHR7peXrB1fpf-hJAEgj8Wh9xe8VDyL_fpN9YTWo4cjA6D9db82hBAbhJgOS0l5dJ4n59qvkBoqfWKkW5BdGn2hla0oxcLMzyfa7hn7vsxXA0d5UQpWg8MEaMrjleojIfUEHCa9dTR6AKWt5AnNgluIjDBLWUIup7gKHl5_rmpf5nEbIf2L4Z-kTI7oHEU6r4G6Che8Tu2XtKSl9VDLqT0bdILMzX4"
  },
  {
    name: "Golden Truffle Fries",
    url: "https://lh3.googleusercontent.com/aida-public/AB6AXuAV0xrtFVaGwuyfVGJIwdwQTb5JBbIORuPl9uHqjAZ8qqSrzfSoxGXnDies3Zeg_tmc6YHcdl41Lut6cb47tYmtSKJ2xzqkb9uhDBKkyNyAPkvVFyF8NEUhsk9Z_1GIOjAnsbdUr8sz8efwyLcC3Jaf18eQXggDNGV-Kp_kEeGCzb6qlfuhALCRRl7rNpITH5EHr9XxLy58-_Js7S4SrAnTGTBW859W7UNJcOqnIUG-yhDOWCgDi8lYyHqAuAvFxWFT7n9P0tlVS0Q"
  },
  {
    name: "Mediterranean Healthy Bowl",
    url: "https://lh3.googleusercontent.com/aida-public/AB6AXuBRBAm0Z9NUsZIH57rrgyZrxQ2GrptnQwJ9RNBh_mswOww0fKXTKEbIqvgQT9YGEPSVuQkKjqmhmvmSPL1jj5OanQxnKoDdS0QGrxj3y9lkio8az1QZE9MsAGE_0LRLuB3e6X6hluqjJAj5T_jGrhT5B7r8yIS6hTatuPdgSkUflzJIxM4CoZn4qI0o7UBmfA_i3gXoeGKw2igtjLqOsRBN43r-0wMYLD8aerOBkq_3_aZhrvvpzXvJr8vZGNDLKkZxbmJDuG7EwBI"
  },
  {
    name: "Smasher Stack Cheese",
    url: "https://lh3.googleusercontent.com/aida-public/AB6AXuCd0Iagz8NQC0-Sy5X5Bc4_q24cjiISVfiY9boMGv_Uqs4sscVPfEE3kSabOVRg4H0belE3a9j86tX2BIRE2vm1wsKhRUo3D_b7o1gsTWjSgJEljgvVrxZ3cghQv8RPL87A2MzZmwyJgdPy7yZKukf1bGj2qCWD44GVzsu6fCImNZpro_K1k2vynm33AtQJNZEkFbW7RjyZrFG0dtEOQgX16fEG0REsTNRnpVn5Cpal_yFwBuJU4dzAzRUxdVu94NIVlR-Ao61jFDo"
  },
  {
    name: "Avocado Sourdough Toast",
    url: "https://lh3.googleusercontent.com/aida-public/AB6AXuBpLSrmR5cilFOcHwcnTMwNPIyF_4Ksk9-k2O-Uf6W2ksQTqe2qq1BAfKpFs1HB-NQSEYiBy_e1w3obduYekACnyGx_vStkV2fExecUxjK-W6ZrAwtpu-EkPbjCkIvJOZEuUHbeSfsszuRDJWELbEO0BjODIee9_eWK0gvNdfYL6wUC38n3DcVXpmu1WZ3weCWFhuTOj81BlBl4n9Ri8nE_tSyU_k-Ot4MPeahSj7Mzk7S2NZSRbdF5fAXJ4oOnar6vIPF9apR4E-g"
  },
  {
    name: "Crafted Cold Brew Bottle",
    url: "https://lh3.googleusercontent.com/aida-public/AB6AXuC8uPRbZVlOTY6Ezxe2rKUKVWpEKfaazecofsQrundILPrcDeCTK_PJD4K7EDy8La_MKzaYFppG4pJrKVYLEPsZU6OpcxJhcC5JVVY7OoqjqH-bj9_cy2nrYJyx6Hgqt8rXPQQgue2cWnTtPWbE13xDv33o0JXNfajRLwGh74rc9eKNoGfk_TP2vWhEh33JDgC4n5VuQVPLPYMblER955prUVgeNuJk805e0pwd_5eub7h7xY2rYLH_FqfFOY8la-CtGRGzMyR8cdY"
  }
];

export default function MenuView({
  menuItems,
  onToggleStock,
  onAddItem,
  onUpdateItem,
  onDeleteItem,
}: MenuViewProps) {
  const [selectedCategory, setSelectedCategory] = useState("Popular");
  
  // Modals state
  const [showAddModal, setShowAddModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState<MenuItem | null>(null);

  // Form states for Add Item
  const [addName, setAddName] = useState("");
  const [addDescription, setAddDescription] = useState("");
  const [addPrice, setAddPrice] = useState("");
  const [addCategory, setAddCategory] = useState("Burgers");
  const [addImageUrl, setAddImageUrl] = useState(SUGGESTED_IMAGES[0].url);
  const [addInStock, setAddInStock] = useState(true);

  // Filter items by category
  const filteredItems = useMemo(() => {
    return menuItems.filter((item) => {
      if (selectedCategory === "Popular") {
        return item.category === "Popular" || item.soldCount > 180;
      }
      return item.category === selectedCategory;
    });
  }, [menuItems, selectedCategory]);

  const handleCreateItem = (e: React.FormEvent) => {
    e.preventDefault();
    if (!addName.trim() || !addPrice.trim()) {
      alert("Name and Price are required.");
      return;
    }

    onAddItem({
      name: addName,
      description: addDescription,
      price: parseFloat(addPrice) || 0,
      category: addCategory,
      image: addImageUrl,
      inStock: addInStock
    });

    // Reset fields
    setAddName("");
    setAddDescription("");
    setAddPrice("");
    setAddCategory("Burgers");
    setAddImageUrl(SUGGESTED_IMAGES[0].url);
    setAddInStock(true);
    setShowAddModal(false);
  };

  const handleOpenEdit = (item: MenuItem, e: React.MouseEvent) => {
    e.stopPropagation();
    setShowEditModal(item);
  };

  const handleSaveEdit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!showEditModal) return;
    if (!showEditModal.name.trim() || !showEditModal.price) {
      alert("Name and Price are required.");
      return;
    }

    onUpdateItem(showEditModal.id, showEditModal);
    setShowEditModal(null);
  };

  const handleDelete = (itemId: string) => {
    if (window.confirm("Are you sure you want to delete this menu item?")) {
      onDeleteItem(itemId);
      setShowEditModal(null);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header section */}
      <section className="flex flex-col gap-2 mb-2">
        <h1 className="font-display text-2xl font-bold text-on-surface tracking-tight">Menu Management</h1>
        <p className="text-sm text-on-surface-variant">Manage your catalog, stock availability, and prices in real-time.</p>
      </section>

      {/* Category Pills Slider */}
      <div className="flex gap-2.5 overflow-x-auto no-scrollbar pb-1">
        {CATEGORIES.map((cat) => (
          <button
            key={cat}
            onClick={() => setSelectedCategory(cat)}
            className={`whitespace-nowrap px-5 py-2 rounded-full text-xs font-bold transition-all ${
              selectedCategory === cat
                ? "bg-primary text-on-primary shadow-md"
                : "bg-surface-container-high text-on-surface-variant hover:bg-surface-container-highest"
            }`}
          >
            {cat}
          </button>
        ))}
      </div>

      {/* Menu Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <AnimatePresence mode="popLayout">
          {filteredItems.map((item) => (
            <motion.div
              key={item.id}
              layout
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              transition={{ duration: 0.2 }}
              className={`bg-surface-container-lowest rounded-3xl shadow-[0_4px_16px_rgba(0,108,73,0.02)] overflow-hidden border border-outline-variant/10 group hover:shadow-[0_12px_24px_rgba(0,108,73,0.05)] transition-all duration-300 dark:bg-surface-container-low ${
                !item.inStock ? "opacity-75 grayscale-[0.3]" : ""
              }`}
            >
              {/* Product Image Section */}
              <div className="relative h-48 overflow-hidden bg-surface-container-low">
                <img 
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" 
                  src={item.image} 
                  alt={item.name}
                  referrerPolicy="no-referrer"
                />
                
                {/* Out of stock overlay */}
                {!item.inStock && (
                  <div className="absolute inset-0 bg-black/30 backdrop-blur-[1px] flex items-center justify-center">
                    <span className="bg-error text-on-error px-4 py-1.5 rounded-full text-[10px] font-bold uppercase tracking-wider shadow-sm">
                      Out of Stock
                    </span>
                  </div>
                )}

                {/* Edit Button overlay top right */}
                <button 
                  onClick={(e) => handleOpenEdit(item, e)}
                  className="absolute top-3 right-3 w-9 h-9 bg-white/90 backdrop-blur-md rounded-full flex items-center justify-center text-primary shadow-sm hover:bg-primary hover:text-on-primary active:scale-95 transition-all duration-200"
                  title="Edit item"
                >
                  <Edit className="h-4 w-4" />
                </button>
              </div>

              {/* Card Details Block */}
              <div className="p-5">
                <div className="flex justify-between items-start mb-2">
                  <h3 className="font-display font-bold text-on-surface text-base tracking-tight truncate max-w-[70%]">
                    {item.name}
                  </h3>
                  <span className="font-extrabold text-primary text-sm shrink-0">
                    ${item.price.toFixed(2)}
                  </span>
                </div>
                
                <p className="text-xs text-on-surface-variant mb-5 line-clamp-2 leading-relaxed min-h-[32px]">
                  {item.description || "Freshly made standard kitchen item with fine premium ingredients."}
                </p>

                {/* Stock Switch Switcher */}
                <div className="flex items-center justify-between pt-3 border-t border-outline-variant/20">
                  <span className={`text-[11px] font-bold uppercase tracking-wider ${item.inStock ? "text-primary" : "text-error"}`}>
                    {item.inStock ? "In Stock" : "Out of Stock"}
                  </span>
                  
                  {/* IOS Toggled Button */}
                  <button
                    onClick={() => onToggleStock(item.id)}
                    className={`relative inline-flex h-5.5 w-10 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                      item.inStock ? "bg-primary" : "bg-outline-variant"
                    }`}
                  >
                    <span
                      className={`pointer-events-none inline-block h-4.5 w-4.5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                        item.inStock ? "translate-x-4.5" : "translate-x-0"
                      }`}
                    />
                  </button>
                </div>
              </div>
            </motion.div>
          ))}

          {/* Add New Item Button Card */}
          <button 
            onClick={() => setShowAddModal(true)}
            className="border-2 border-dashed border-outline-variant/40 rounded-3xl p-8 flex flex-col items-center justify-center gap-3 bg-surface-container-low/20 hover:border-primary hover:bg-primary/5 transition-all group duration-300 min-h-[320px]"
          >
            <div className="w-12 h-12 rounded-full bg-surface-container flex items-center justify-center text-primary group-hover:scale-110 transition-transform">
              <Plus className="h-6 w-6" />
            </div>
            <span className="font-display font-bold text-on-surface text-sm group-hover:text-primary">Add New Menu Item</span>
            <span className="text-[11px] text-on-surface-variant text-center max-w-[200px]">Upload photos, set custom pricing, and configure real-time stock.</span>
          </button>
        </AnimatePresence>
      </div>

      {/* Floating Action Button for Adding items */}
      <button 
        onClick={() => setShowAddModal(true)}
        className="fixed bottom-24 right-6 w-14 h-14 bg-primary text-on-primary rounded-2xl shadow-xl flex items-center justify-center hover:bg-primary-container hover:brightness-105 active:scale-90 transition-all z-40 sm:bottom-6"
        title="Add Menu Item"
      >
        <Plus className="h-7 w-7" />
      </button>

      {/* --------------------- MODALS SECTION --------------------- */}
      
      {/* ADD ITEM MODAL */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-[2px]">
          <motion.div 
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            className="bg-surface-container-lowest max-w-md w-full rounded-3xl p-6 shadow-xl max-h-[90vh] overflow-y-auto no-scrollbar border border-outline-variant/20 dark:bg-surface-container-low"
          >
            <div className="flex justify-between items-center mb-4">
              <h2 className="font-display font-bold text-lg text-on-surface flex items-center gap-2">
                <Sparkles className="h-5 w-5 text-primary" /> Create Menu Item
              </h2>
              <button onClick={() => setShowAddModal(false)} className="p-1 text-on-surface-variant hover:bg-surface-container rounded-full transition-colors">
                <X className="h-5 w-5" />
              </button>
            </div>

            <form onSubmit={handleCreateItem} className="space-y-4 text-left">
              <div>
                <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">Item Name *</label>
                <input 
                  type="text" 
                  required 
                  placeholder="e.g. Signature Truffle Burger"
                  value={addName}
                  onChange={(e) => setAddName(e.target.value)}
                  className="w-full px-3.5 py-2.5 rounded-xl border border-outline-variant/40 bg-surface focus:ring-2 focus:ring-primary text-sm font-semibold outline-none dark:bg-surface-container-high"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">Price ($) *</label>
                  <div className="relative">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant text-xs font-extrabold">$</span>
                    <input 
                      type="number" 
                      step="0.01" 
                      required 
                      placeholder="18.50"
                      value={addPrice}
                      onChange={(e) => setAddPrice(e.target.value)}
                      className="w-full pl-7 pr-3.5 py-2.5 rounded-xl border border-outline-variant/40 bg-surface focus:ring-2 focus:ring-primary text-sm font-semibold outline-none dark:bg-surface-container-high"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">Category</label>
                  <select 
                    value={addCategory}
                    onChange={(e) => setAddCategory(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl border border-outline-variant/40 bg-surface focus:ring-2 focus:ring-primary text-sm font-semibold outline-none dark:bg-surface-container-high"
                  >
                    {CATEGORIES.map(cat => (
                      <option key={cat} value={cat}>{cat}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">Description</label>
                <textarea 
                  rows={2}
                  placeholder="Short, appetizing culinary ingredients list..."
                  value={addDescription}
                  onChange={(e) => setAddDescription(e.target.value)}
                  className="w-full px-3.5 py-2.5 rounded-xl border border-outline-variant/40 bg-surface focus:ring-2 focus:ring-primary text-sm font-semibold outline-none dark:bg-surface-container-high resize-none"
                />
              </div>

              {/* Preset Image Suggestion Slider */}
              <div>
                <label className="block text-xs font-bold text-on-surface-variant uppercase mb-2">Predefined Food Asset</label>
                <div className="grid grid-cols-6 gap-2 bg-surface-container p-2.5 rounded-xl dark:bg-surface-container-high">
                  {SUGGESTED_IMAGES.map((img, idx) => (
                    <button
                      key={idx}
                      type="button"
                      onClick={() => setAddImageUrl(img.url)}
                      className={`relative h-10 w-10 rounded-lg overflow-hidden border-2 transition-all shrink-0 ${
                        addImageUrl === img.url ? "border-primary scale-105" : "border-transparent opacity-70 hover:opacity-100"
                      }`}
                      title={img.name}
                    >
                      <img className="h-full w-full object-cover" src={img.url} alt={img.name} referrerPolicy="no-referrer" />
                    </button>
                  ))}
                </div>
                <div className="mt-2">
                  <span className="text-[10px] text-on-surface-variant">Selected asset matches standard delivery platform guidelines.</span>
                </div>
              </div>

              <div className="flex items-center justify-between pt-2">
                <span className="text-xs font-bold text-on-surface-variant uppercase">Initial Availability</span>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input 
                    type="checkbox" 
                    checked={addInStock}
                    onChange={(e) => setAddInStock(e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-surface-container-highest peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                </label>
              </div>

              <div className="flex gap-3 pt-4 border-t border-outline-variant/20">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="flex-1 py-3 border border-outline text-on-surface rounded-xl text-xs font-bold hover:bg-surface-container active:scale-95 transition-all"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 py-3 bg-primary text-on-primary rounded-xl text-xs font-bold hover:brightness-110 active:scale-95 transition-all shadow-md"
                >
                  Add Item
                </button>
              </div>
            </form>
          </motion.div>
        </div>
      )}

      {/* EDIT ITEM MODAL */}
      {showEditModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-[2px]">
          <motion.div 
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            className="bg-surface-container-lowest max-w-md w-full rounded-3xl p-6 shadow-xl max-h-[90vh] overflow-y-auto no-scrollbar border border-outline-variant/20 dark:bg-surface-container-low"
          >
            <div className="flex justify-between items-center mb-4">
              <h2 className="font-display font-bold text-lg text-on-surface flex items-center gap-2">
                <Edit className="h-5 w-5 text-primary" /> Modify Catalog Item
              </h2>
              <button onClick={() => setShowEditModal(null)} className="p-1 text-on-surface-variant hover:bg-surface-container rounded-full transition-colors">
                <X className="h-5 w-5" />
              </button>
            </div>

            <form onSubmit={handleSaveEdit} className="space-y-4 text-left">
              <div>
                <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">Item Name *</label>
                <input 
                  type="text" 
                  required 
                  value={showEditModal.name}
                  onChange={(e) => setShowEditModal({ ...showEditModal, name: e.target.value })}
                  className="w-full px-3.5 py-2.5 rounded-xl border border-outline-variant/40 bg-surface focus:ring-2 focus:ring-primary text-sm font-semibold outline-none dark:bg-surface-container-high"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">Price ($) *</label>
                  <div className="relative">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant text-xs font-extrabold">$</span>
                    <input 
                      type="number" 
                      step="0.01" 
                      required 
                      value={showEditModal.price}
                      onChange={(e) => setShowEditModal({ ...showEditModal, price: parseFloat(e.target.value) || 0 })}
                      className="w-full pl-7 pr-3.5 py-2.5 rounded-xl border border-outline-variant/40 bg-surface focus:ring-2 focus:ring-primary text-sm font-semibold outline-none dark:bg-surface-container-high"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">Category</label>
                  <select 
                    value={showEditModal.category}
                    onChange={(e) => setShowEditModal({ ...showEditModal, category: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl border border-outline-variant/40 bg-surface focus:ring-2 focus:ring-primary text-sm font-semibold outline-none dark:bg-surface-container-high"
                  >
                    {CATEGORIES.map(cat => (
                      <option key={cat} value={cat}>{cat}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">Description</label>
                <textarea 
                  rows={2}
                  value={showEditModal.description}
                  onChange={(e) => setShowEditModal({ ...showEditModal, description: e.target.value })}
                  className="w-full px-3.5 py-2.5 rounded-xl border border-outline-variant/40 bg-surface focus:ring-2 focus:ring-primary text-sm font-semibold outline-none dark:bg-surface-container-high resize-none"
                />
              </div>

              {/* Predefined image selector slider */}
              <div>
                <label className="block text-xs font-bold text-on-surface-variant uppercase mb-2">Selected Culinary Asset</label>
                <div className="grid grid-cols-6 gap-2 bg-surface-container p-2.5 rounded-xl dark:bg-surface-container-high">
                  {SUGGESTED_IMAGES.map((img, idx) => (
                    <button
                      key={idx}
                      type="button"
                      onClick={() => setShowEditModal({ ...showEditModal, image: img.url })}
                      className={`relative h-10 w-10 rounded-lg overflow-hidden border-2 transition-all shrink-0 ${
                        showEditModal.image === img.url ? "border-primary scale-105" : "border-transparent opacity-70 hover:opacity-100"
                      }`}
                      title={img.name}
                    >
                      <img className="h-full w-full object-cover" src={img.url} alt={img.name} referrerPolicy="no-referrer" />
                    </button>
                  ))}
                </div>
              </div>

              <div className="flex gap-3 pt-4 border-t border-outline-variant/20">
                <button
                  type="button"
                  onClick={() => handleDelete(showEditModal.id)}
                  className="px-4 py-3 border border-error/40 text-error hover:bg-error/5 rounded-xl text-xs font-bold active:scale-95 transition-all flex items-center justify-center gap-1"
                  title="Delete item"
                >
                  <Trash2 className="h-4 w-4" /> Delete
                </button>
                <button
                  type="button"
                  onClick={() => setShowEditModal(null)}
                  className="flex-1 py-3 border border-outline text-on-surface rounded-xl text-xs font-bold hover:bg-surface-container active:scale-95 transition-all"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 py-3 bg-primary text-on-primary rounded-xl text-xs font-bold hover:brightness-110 active:scale-95 transition-all shadow-md"
                >
                  Save Changes
                </button>
              </div>
            </form>
          </motion.div>
        </div>
      )}

    </div>
  );
}
