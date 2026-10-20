import React, { useState, useEffect } from "react";
import * as api from "../api";

interface Banner {
  id: string;
  title: string;
  subtitle: string | null;
  tag: string | null;
  button_text: string | null;
  route: string | null;
  image_url: string | null;
  colors: string[];
  created_by: string;
  creator_name: string;
  is_approved: boolean;
  created_at: string;
}

export default function MerchantBannersView() {
  const [banners, setBanners] = useState<Banner[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  
  // Form State
  const [title, setTitle] = useState("");
  const [subtitle, setSubtitle] = useState("");
  const [tag, setTag] = useState("");
  const [buttonText, setButtonText] = useState("Claim Offer");
  const [imageUrl, setImageUrl] = useState("");
  const [startColor, setStartColor] = useState("#064E3B");
  const [endColor, setEndColor] = useState("#0f766e");
  const [submitting, setSubmitting] = useState(false);

  const fetchBanners = async () => {
    setLoading(true);
    try {
      const data = await api.getMerchantBanners();
      setBanners(data);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBanners();
  }, []);

  const handleDelete = async (id: string) => {
    if (!confirm("Are you sure you want to delete this promo banner?")) return;
    try {
      await api.deleteMerchantBanner(id);
      setBanners((prev) => prev.filter((b) => b.id !== id));
    } catch (e: any) {
      alert(`Error deleting: ${e.message}`);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) {
      alert("Title is required");
      return;
    }
    setSubmitting(true);
    try {
      const newBanner = await api.createMerchantBanner({
        title,
        subtitle: subtitle || null,
        tag: tag || null,
        button_text: buttonText || "Claim Offer",
        route: "/food-delivery", // Merchant banners always route to food-delivery
        image_url: imageUrl || null,
        colors: [startColor, endColor],
      });
      setBanners((prev) => [newBanner, ...prev]);
      // Reset form
      setTitle("");
      setSubtitle("");
      setTag("");
      setButtonText("Claim Offer");
      setImageUrl("");
      setStartColor("#064E3B");
      setEndColor("#0f766e");
      alert("Promo banner submitted successfully! It will display on the app after Admin approval.");
    } catch (e: any) {
      alert(`Error submitting banner: ${e.message}`);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-display font-extrabold text-on-surface">Promo Banners</h2>
          <p className="text-xs text-on-surface-variant mt-0.5">Advertise your menu specials to customers</p>
        </div>
        <span className="text-xs font-bold bg-surface-container px-2.5 py-1 rounded-full text-on-surface-variant">
          {banners.length} total
        </span>
      </div>

      {error && (
        <div className="p-3.5 bg-error/10 text-error rounded-2xl border border-error/20 text-xs font-medium">
          {error}
        </div>
      )}

      {/* Creation form */}
      <div className="bg-surface rounded-3xl p-5 border border-outline-variant/20 space-y-4">
        <h3 className="font-extrabold text-sm text-on-surface flex items-center gap-1.5">
          <span>📢</span> Submit New Promotion
        </h3>
        
        <form onSubmit={handleSubmit} className="space-y-3.5">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-3">
              <div>
                <label className="block text-[11px] font-bold text-on-surface-variant uppercase">Promo Tag / Label</label>
                <input
                  type="text"
                  placeholder="e.g. WEEKEND SPECIAL, BOGO"
                  value={tag}
                  onChange={(e) => setTag(e.target.value)}
                  className="w-full mt-1.5 px-3.5 py-2 bg-surface-container border border-outline-variant/30 rounded-2xl text-xs focus:bg-surface focus:border-primary focus:outline-none transition"
                />
              </div>

              <div>
                <label className="block text-[11px] font-bold text-on-surface-variant uppercase">Promotion Title *</label>
                <input
                  type="text"
                  placeholder="e.g. Buy 1 Get 1 FreeWaakye!"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  className="w-full mt-1.5 px-3.5 py-2 bg-surface-container border border-outline-variant/30 rounded-2xl text-xs focus:bg-surface focus:border-primary focus:outline-none transition"
                  required
                />
              </div>

              <div>
                <label className="block text-[11px] font-bold text-on-surface-variant uppercase">Subtitle / Code Info</label>
                <input
                  type="text"
                  placeholder="e.g. Discount applied at checkout"
                  value={subtitle}
                  onChange={(e) => setSubtitle(e.target.value)}
                  className="w-full mt-1.5 px-3.5 py-2 bg-surface-container border border-outline-variant/30 rounded-2xl text-xs focus:bg-surface focus:border-primary focus:outline-none transition"
                />
              </div>
            </div>

            <div className="space-y-3">
              <div>
                <label className="block text-[11px] font-bold text-on-surface-variant uppercase">Dish Image URL (Optional)</label>
                <input
                  type="text"
                  placeholder="https://images.unsplash.com/photo-..."
                  value={imageUrl}
                  onChange={(e) => setImageUrl(e.target.value)}
                  className="w-full mt-1.5 px-3.5 py-2 bg-surface-container border border-outline-variant/30 rounded-2xl text-xs focus:bg-surface focus:border-primary focus:outline-none transition"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-[11px] font-bold text-on-surface-variant uppercase">Start Color</label>
                  <div className="flex gap-2 mt-1.5">
                    <input
                      type="color"
                      value={startColor}
                      onChange={(e) => setStartColor(e.target.value)}
                      className="w-8 h-8 rounded border border-outline-variant/30 cursor-pointer"
                    />
                    <input
                      type="text"
                      value={startColor}
                      onChange={(e) => setStartColor(e.target.value)}
                      className="w-full px-2 py-1 bg-surface-container border border-outline-variant/30 rounded-lg text-[10px] font-mono"
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-[11px] font-bold text-on-surface-variant uppercase">End Color</label>
                  <div className="flex gap-2 mt-1.5">
                    <input
                      type="color"
                      value={endColor}
                      onChange={(e) => setEndColor(e.target.value)}
                      className="w-8 h-8 rounded border border-outline-variant/30 cursor-pointer"
                    />
                    <input
                      type="text"
                      value={endColor}
                      onChange={(e) => setEndColor(e.target.value)}
                      className="w-full px-2 py-1 bg-surface-container border border-outline-variant/30 rounded-lg text-[10px] font-mono"
                    />
                  </div>
                </div>
              </div>

              <div>
                <label className="block text-[11px] font-bold text-on-surface-variant uppercase">Button Text</label>
                <input
                  type="text"
                  placeholder="Claim Offer"
                  value={buttonText}
                  onChange={(e) => setButtonText(e.target.value)}
                  className="w-full mt-1.5 px-3.5 py-2 bg-surface-container border border-outline-variant/30 rounded-2xl text-xs focus:bg-surface focus:border-primary focus:outline-none transition"
                />
              </div>
            </div>
          </div>

          {/* Banner Live Preview */}
          <div className="border border-dashed border-outline-variant/30 rounded-2xl p-3 bg-surface-container-low mt-2">
            <span className="text-[9px] font-extrabold text-on-surface-variant/50 uppercase">Live Mobile Banner Preview</span>
            <div 
              className="w-full rounded-2xl p-4 mt-1.5 text-white relative overflow-hidden flex flex-col justify-between"
              style={{ 
                background: `linear-gradient(135deg, ${startColor}, ${endColor})`,
                minHeight: "105px"
              }}
            >
              {imageUrl && (
                <div 
                  className="absolute inset-0 bg-cover bg-center opacity-25 mix-blend-overlay"
                  style={{ backgroundImage: `url(${imageUrl})` }}
                />
              )}
              <div className="relative z-10">
                <span className="text-[8px] bg-white/20 text-white px-2 py-0.5 rounded-full font-bold uppercase tracking-wider">
                  {tag || "PROMOTION"}
                </span>
                <h4 className="font-extrabold text-xs mt-1 leading-tight">{title || "Your Promo Title"}</h4>
                <p className="text-[9px] text-white/80 mt-0.5">{subtitle || "Your Promo description details"}</p>
              </div>
              <div className="relative z-10 flex items-center justify-between mt-2">
                <span className="text-[8px] bg-white text-gray-900 px-2 py-0.5 rounded-full font-bold">
                  {buttonText || "Claim Offer"}
                </span>
              </div>
            </div>
          </div>

          <button
            type="submit"
            disabled={submitting}
            className="w-full py-2.5 bg-primary text-on-primary rounded-2xl text-xs font-bold hover:shadow-md disabled:opacity-50 transition cursor-pointer"
          >
            {submitting ? "Submitting..." : "Submit for Admin Approval"}
          </button>
        </form>
      </div>

      {/* Existing banners list */}
      <div className="space-y-3">
        <h3 className="font-extrabold text-sm text-on-surface">Your Submitted Banners</h3>
        {loading ? (
          <p className="text-center text-on-surface-variant/70 text-xs py-6">Loading banners...</p>
        ) : banners.length === 0 ? (
          <p className="text-center text-on-surface-variant/70 text-xs py-6 bg-surface rounded-3xl border border-dashed border-outline-variant/30">
            No banners submitted yet
          </p>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {banners.map((b) => (
              <div key={b.id} className="bg-surface rounded-3xl p-4 border border-outline-variant/20 flex flex-col justify-between gap-4">
                <div 
                  className="w-full rounded-2xl p-4 text-white relative overflow-hidden flex flex-col justify-between"
                  style={{ 
                    background: `linear-gradient(135deg, ${b.colors[0] || "#064E3B"}, ${b.colors[1] || "#0f766e"})`,
                    minHeight: "105px"
                  }}
                >
                  {b.image_url && (
                    <div 
                      className="absolute inset-0 bg-cover bg-center opacity-25 mix-blend-overlay"
                      style={{ backgroundImage: `url(${b.image_url})` }}
                    />
                  )}
                  <div className="relative z-10">
                    <span className="text-[8px] bg-white/20 text-white px-2 py-0.5 rounded-full font-bold uppercase tracking-wider">
                      {b.tag || "PROMOTION"}
                    </span>
                    <h4 className="font-extrabold text-xs mt-1 leading-tight">{b.title}</h4>
                    {b.subtitle && <p className="text-[9px] text-white/80 mt-0.5 leading-tight">{b.subtitle}</p>}
                  </div>
                  <div className="relative z-10 flex items-center justify-between mt-2">
                    <span className="text-[8px] bg-white text-gray-900 px-2 py-0.5 rounded-full font-bold">
                      {b.button_text || "Claim Offer"}
                    </span>
                  </div>
                </div>

                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-1.5">
                    <span className="w-1.5 h-1.5 rounded-full bg-primary" />
                    <span className={`text-[10px] font-bold ${
                      b.is_approved ? "text-green-600 dark:text-green-400" : "text-orange-500"
                    }`}>
                      {b.is_approved ? "Approved & Live" : "Pending Approval"}
                    </span>
                  </div>
                  <button
                    onClick={() => handleDelete(b.id)}
                    className="text-[10px] font-bold text-error hover:bg-error/5 px-2.5 py-1 rounded-lg transition"
                  >
                    Delete
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
