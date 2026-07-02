import { useState, useEffect } from "react";
import {
  Store,
  MapPin,
  Clock,
  Phone,
  Mail,
  Globe,
  Save,
  ChevronDown,
  ChevronUp,
  AlertCircle,
  CheckCircle,
  Utensils,
  Truck,
  DollarSign,
} from "lucide-react";
import { Restaurant } from "../types";
import { motion } from "motion/react";

interface SettingsViewProps {
  restaurant: Restaurant;
  onSave: (data: Partial<Restaurant>) => Promise<void>;
  loading?: boolean;
}

const RESTAURANT_TYPES = [
  "Fast Food",
  "Local Food",
  "Continental",
  "Chinese",
  "Indian",
  "Pizza",
  "Grill & BBQ",
  "Bakery",
  "Cafe",
  "Buffet",
  "Seafood",
  "Vegan",
];

const DAYS = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"];

const LOGO_SUGGESTIONS = [
  "https://lh3.googleusercontent.com/aida-public/AB6AXuAaS8d7dJRJSyw4nxMO-eZ3MOzO9uyYYDLN7sizqM4yDfzaXMDrMHfLrXJVHwl_Ddf_Mdn857JXDc3L3eid3xEhUPIjt1HRrwvrP-c5RmPckAZhbw7tGUot3ad3H_iP7u3gncOaDUNG-fmR8md2rfzWwfvuJgwuh1u0Yy1AgsXOBxvxceMoustCNYZXlPsLcrPTKSiBszDV2D0y3mS2flMevEcob39siLBMNRt3M6bG1moGExyLu75uq9PMe407WJ-wVoh3updhQZQ",
  "https://lh3.googleusercontent.com/aida-public/AB6AXuBKBAhsQLG1R46JlfzVVp2Qy_Rr9A57cPwSUw-qOaFsaZruMg_WMfhLdsdUSpTDQl-89-fiPSkoSP_do1-OkscWEIs6Wfx-oWyvCKseN2yDB3LW9zZjdgKEZ50_fuRWHOE4pVXIXL5A9GtKtFlU_I5hma_jyGfpyp-LjDvge5Dgc4ygwqGOiCgf3e2BX7M-1-rn8hrawx2SRECHPNctgyF8GP6XwGgF6ESnn5_3iF23XZyrE6aHDMfLbQnoDerO1TzbfHOB1-yFXEE",
];

function parseOpeningHours(hours: Record<string, unknown> | null): Record<string, { open: string; close: string; closed: boolean }> {
  const defaults: Record<string, { open: string; close: string; closed: boolean }> = {
    monday: { open: "08:00", close: "22:00", closed: false },
    tuesday: { open: "08:00", close: "22:00", closed: false },
    wednesday: { open: "08:00", close: "22:00", closed: false },
    thursday: { open: "08:00", close: "22:00", closed: false },
    friday: { open: "08:00", close: "22:00", closed: false },
    saturday: { open: "09:00", close: "23:00", closed: false },
    sunday: { open: "10:00", close: "21:00", closed: false },
  };

  if (!hours) return defaults;

  const result = { ...defaults };
  for (const day of DAYS) {
    const dayData = hours[day] as { open?: string; close?: string; closed?: boolean } | undefined;
    if (dayData) {
      result[day] = {
        open: dayData.open || defaults[day].open,
        close: dayData.close || defaults[day].close,
        closed: dayData.closed || false,
      };
    }
  }
  return result;
}

function formatTime(time: string): string {
  const [h, m] = time.split(":");
  const hour = parseInt(h);
  const ampm = hour >= 12 ? "PM" : "AM";
  const displayHour = hour % 12 || 12;
  return `${displayHour}:${m} ${ampm}`;
}

export default function SettingsView({ restaurant, onSave, loading }: SettingsViewProps) {
  const [name, setName] = useState(restaurant.name);
  const [description, setDescription] = useState(restaurant.description || "");
  const [restaurantType, setRestaurantType] = useState(restaurant.restaurant_type || "");
  const [logoUrl, setLogoUrl] = useState(restaurant.logo_url || "");
  const [address, setAddress] = useState(restaurant.address);
  const [phone, setPhone] = useState(restaurant.phone || "");
  const [email, setEmail] = useState(restaurant.email || "");
  const [deliveryTime, setDeliveryTime] = useState(restaurant.delivery_time || "");
  const [deliveryFee, setDeliveryFee] = useState(String(restaurant.delivery_fee || ""));
  const [minimumOrder, setMinimumOrder] = useState(String(restaurant.minimum_order || ""));
  const [openingHours, setOpeningHours] = useState(() => parseOpeningHours(restaurant.opening_hours));

  const [saved, setSaved] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [expandedSections, setExpandedSections] = useState<Record<string, boolean>>({
    basic: true,
    contact: true,
    hours: false,
    delivery: false,
  });

  useEffect(() => {
    setName(restaurant.name);
    setDescription(restaurant.description || "");
    setRestaurantType(restaurant.restaurant_type || "");
    setLogoUrl(restaurant.logo_url || "");
    setAddress(restaurant.address);
    setPhone(restaurant.phone || "");
    setEmail(restaurant.email || "");
    setDeliveryTime(restaurant.delivery_time || "");
    setDeliveryFee(String(restaurant.delivery_fee || ""));
    setMinimumOrder(String(restaurant.minimum_order || ""));
    setOpeningHours(parseOpeningHours(restaurant.opening_hours));
  }, [restaurant]);

  const toggleSection = (section: string) => {
    setExpandedSections((prev) => ({ ...prev, [section]: !prev[section] }));
  };

  const validate = (): boolean => {
    const newErrors: Record<string, string> = {};
    if (!name.trim()) newErrors.name = "Restaurant name is required";
    if (!address.trim()) newErrors.address = "Address is required";
    if (address.trim().length < 5) newErrors.address = "Address must be at least 5 characters";
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSave = async () => {
    if (!validate()) return;
    setSaved(false);
    await onSave({
      name: name.trim(),
      description: description.trim() || undefined,
      restaurant_type: restaurantType || undefined,
      logo_url: logoUrl || undefined,
      address: address.trim(),
      phone: phone.trim() || undefined,
      email: email.trim() || undefined,
      delivery_time: deliveryTime || undefined,
      delivery_fee: deliveryFee ? parseFloat(deliveryFee) : undefined,
      minimum_order: minimumOrder ? parseFloat(minimumOrder) : undefined,
      opening_hours: openingHours,
    });
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  };

  const updateHours = (day: string, field: "open" | "close" | "closed", value: string | boolean) => {
    setOpeningHours((prev) => ({
      ...prev,
      [day]: { ...prev[day], [field]: value },
    }));
  };

  const applyToAll = (day: string) => {
    const template = openingHours[day];
    const updated = { ...openingHours };
    DAYS.forEach((d) => {
      updated[d] = { ...template };
    });
    setOpeningHours(updated);
  };

  return (
    <div className="space-y-6 max-w-2xl">
      {/* Header */}
      <section className="flex flex-col gap-2">
        <h1 className="font-display text-2xl font-bold text-on-surface tracking-tight">Restaurant Settings</h1>
        <p className="text-sm text-on-surface-variant">Manage your restaurant profile and operational details.</p>
      </section>

      {/* Save indicator */}
      {saved && (
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex items-center gap-2 p-3 bg-primary/10 border border-primary/20 rounded-xl text-sm text-primary font-semibold"
        >
          <CheckCircle className="h-4 w-4" /> Changes saved successfully
        </motion.div>
      )}

      {/* Basic Info Section */}
      <div className="bg-surface-container-lowest rounded-2xl border border-outline-variant/20 overflow-hidden">
        <button
          onClick={() => toggleSection("basic")}
          className="w-full flex items-center justify-between p-5 hover:bg-surface-container-low/50 transition-colors"
        >
          <div className="flex items-center gap-3">
            <div className="p-2 bg-primary/10 rounded-xl">
              <Store className="h-5 w-5 text-primary" />
            </div>
            <div className="text-left">
              <h3 className="font-bold text-sm text-on-surface">Basic Information</h3>
              <p className="text-xs text-on-surface-variant">Name, type, logo, and description</p>
            </div>
          </div>
          {expandedSections.basic ? <ChevronUp className="h-5 w-5 text-on-surface-variant" /> : <ChevronDown className="h-5 w-5 text-on-surface-variant" />}
        </button>

        {expandedSections.basic && (
          <div className="px-5 pb-5 space-y-4 border-t border-outline-variant/20 pt-4">
            <div>
              <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">Restaurant Name *</label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full px-4 py-3 bg-surface-container rounded-xl border border-outline-variant/30 text-sm font-semibold focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
              />
              {errors.name && (
                <p className="text-xs text-error mt-1 flex items-center gap-1">
                  <AlertCircle className="h-3 w-3" /> {errors.name}
                </p>
              )}
            </div>

            <div>
              <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">Restaurant Type</label>
              <div className="grid grid-cols-3 gap-2">
                {RESTAURANT_TYPES.map((type) => (
                  <button
                    key={type}
                    type="button"
                    onClick={() => setRestaurantType(restaurantType === type ? "" : type)}
                    className={`px-3 py-2 rounded-xl text-xs font-bold border transition-all ${
                      restaurantType === type
                        ? "bg-primary text-on-primary border-primary"
                        : "bg-surface-container text-on-surface-variant border-outline-variant/30 hover:border-primary/50"
                    }`}
                  >
                    {type}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">Description</label>
              <textarea
                rows={3}
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Tell customers what makes your restaurant special..."
                className="w-full px-4 py-3 bg-surface-container rounded-xl border border-outline-variant/30 text-sm font-semibold focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20 resize-none"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-on-surface-variant uppercase mb-2">Restaurant Logo</label>
              <div className="flex items-center gap-3">
                {logoUrl && (
                  <div className="w-16 h-16 rounded-xl overflow-hidden border border-outline-variant/30 shrink-0">
                    <img src={logoUrl} alt="Logo preview" className="w-full h-full object-cover" referrerPolicy="no-referrer" />
                  </div>
                )}
                <div className="flex-1">
                  <input
                    type="url"
                    value={logoUrl}
                    onChange={(e) => setLogoUrl(e.target.value)}
                    placeholder="Paste image URL..."
                    className="w-full px-4 py-2.5 bg-surface-container rounded-xl border border-outline-variant/30 text-sm font-semibold focus:outline-none focus:border-primary"
                  />
                </div>
              </div>
              <div className="flex gap-2 mt-2">
                {LOGO_SUGGESTIONS.map((url, idx) => (
                  <button
                    key={idx}
                    type="button"
                    onClick={() => setLogoUrl(logoUrl === url ? "" : url)}
                    className={`w-10 h-10 rounded-lg overflow-hidden border-2 transition-all ${
                      logoUrl === url ? "border-primary scale-105" : "border-transparent opacity-60 hover:opacity-100"
                    }`}
                  >
                    <img src={url} alt="Logo option" className="w-full h-full object-cover" referrerPolicy="no-referrer" />
                  </button>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Contact & Location Section */}
      <div className="bg-surface-container-lowest rounded-2xl border border-outline-variant/20 overflow-hidden">
        <button
          onClick={() => toggleSection("contact")}
          className="w-full flex items-center justify-between p-5 hover:bg-surface-container-low/50 transition-colors"
        >
          <div className="flex items-center gap-3">
            <div className="p-2 bg-secondary-container/30 rounded-xl">
              <MapPin className="h-5 w-5 text-on-secondary-container" />
            </div>
            <div className="text-left">
              <h3 className="font-bold text-sm text-on-surface">Contact & Location</h3>
              <p className="text-xs text-on-surface-variant">Address, phone, and email</p>
            </div>
          </div>
          {expandedSections.contact ? <ChevronUp className="h-5 w-5 text-on-surface-variant" /> : <ChevronDown className="h-5 w-5 text-on-surface-variant" />}
        </button>

        {expandedSections.contact && (
          <div className="px-5 pb-5 space-y-4 border-t border-outline-variant/20 pt-4">
            <div>
              <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">Address *</label>
              <div className="relative">
                <MapPin className="absolute left-3 top-3 h-4 w-4 text-on-surface-variant" />
                <input
                  type="text"
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  className="w-full pl-10 pr-4 py-3 bg-surface-container rounded-xl border border-outline-variant/30 text-sm font-semibold focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
                />
              </div>
              {errors.address && (
                <p className="text-xs text-error mt-1 flex items-center gap-1">
                  <AlertCircle className="h-3 w-3" /> {errors.address}
                </p>
              )}
            </div>

            <div>
              <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">Phone Number</label>
              <div className="relative">
                <Phone className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-on-surface-variant" />
                <input
                  type="tel"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="+233 24 123 4567"
                  className="w-full pl-10 pr-4 py-3 bg-surface-container rounded-xl border border-outline-variant/30 text-sm font-semibold focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">Email</label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-on-surface-variant" />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="restaurant@example.com"
                  className="w-full pl-10 pr-4 py-3 bg-surface-container rounded-xl border border-outline-variant/30 text-sm font-semibold focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
                />
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Opening Hours Section */}
      <div className="bg-surface-container-lowest rounded-2xl border border-outline-variant/20 overflow-hidden">
        <button
          onClick={() => toggleSection("hours")}
          className="w-full flex items-center justify-between p-5 hover:bg-surface-container-low/50 transition-colors"
        >
          <div className="flex items-center gap-3">
            <div className="p-2 bg-tertiary-container/20 rounded-xl">
              <Clock className="h-5 w-5 text-tertiary" />
            </div>
            <div className="text-left">
              <h3 className="font-bold text-sm text-on-surface">Opening Hours</h3>
              <p className="text-xs text-on-surface-variant">When your restaurant is open</p>
            </div>
          </div>
          {expandedSections.hours ? <ChevronUp className="h-5 w-5 text-on-surface-variant" /> : <ChevronDown className="h-5 w-5 text-on-surface-variant" />}
        </button>

        {expandedSections.hours && (
          <div className="px-5 pb-5 space-y-2 border-t border-outline-variant/20 pt-4">
            {DAYS.map((day) => {
              const hours = openingHours[day];
              const isClosed = hours.closed;
              return (
                <div
                  key={day}
                  className={`flex items-center gap-3 p-3 rounded-xl border transition-all ${
                    isClosed
                      ? "bg-surface-container border-outline-variant/20 opacity-60"
                      : "bg-surface-container border-outline-variant/30"
                  }`}
                >
                  <div className="w-24 shrink-0">
                    <span className="text-xs font-bold text-on-surface capitalize">{day}</span>
                  </div>

                  {!isClosed ? (
                    <>
                      <input
                        type="time"
                        value={hours.open}
                        onChange={(e) => updateHours(day, "open", e.target.value)}
                        className="flex-1 px-3 py-2 bg-surface rounded-lg border border-outline-variant/30 text-xs font-semibold focus:outline-none focus:border-primary"
                      />
                      <span className="text-xs text-on-surface-variant font-bold">to</span>
                      <input
                        type="time"
                        value={hours.close}
                        onChange={(e) => updateHours(day, "close", e.target.value)}
                        className="flex-1 px-3 py-2 bg-surface rounded-lg border border-outline-variant/30 text-xs font-semibold focus:outline-none focus:border-primary"
                      />
                    </>
                  ) : (
                    <span className="flex-1 text-center text-xs text-on-surface-variant font-bold">Closed</span>
                  )}

                  <div className="flex items-center gap-2">
                    <button
                      type="button"
                      onClick={() => applyToAll(day)}
                      className="text-[10px] text-primary font-bold hover:underline whitespace-nowrap"
                      title="Apply to all days"
                    >
                      All
                    </button>
                    <button
                      type="button"
                      onClick={() => updateHours(day, "closed", !isClosed)}
                      className={`relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ${
                        isClosed ? "bg-outline-variant" : "bg-primary"
                      }`}
                    >
                      <span
                        className={`pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow transition duration-200 ${
                          isClosed ? "translate-x-0" : "translate-x-4"
                        }`}
                      />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Delivery Settings Section */}
      <div className="bg-surface-container-lowest rounded-2xl border border-outline-variant/20 overflow-hidden">
        <button
          onClick={() => toggleSection("delivery")}
          className="w-full flex items-center justify-between p-5 hover:bg-surface-container-low/50 transition-colors"
        >
          <div className="flex items-center gap-3">
            <div className="p-2 bg-primary/10 rounded-xl">
              <Truck className="h-5 w-5 text-primary" />
            </div>
            <div className="text-left">
              <h3 className="font-bold text-sm text-on-surface">Delivery Settings</h3>
              <p className="text-xs text-on-surface-variant">Delivery time, fees, and minimum order</p>
            </div>
          </div>
          {expandedSections.delivery ? <ChevronUp className="h-5 w-5 text-on-surface-variant" /> : <ChevronDown className="h-5 w-5 text-on-surface-variant" />}
        </button>

        {expandedSections.delivery && (
          <div className="px-5 pb-5 space-y-4 border-t border-outline-variant/20 pt-4">
            <div>
              <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">Estimated Delivery Time</label>
              <div className="relative">
                <Clock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-on-surface-variant" />
                <input
                  type="text"
                  value={deliveryTime}
                  onChange={(e) => setDeliveryTime(e.target.value)}
                  placeholder="e.g. 25-35 min"
                  className="w-full pl-10 pr-4 py-3 bg-surface-container rounded-xl border border-outline-variant/30 text-sm font-semibold focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">Delivery Fee (GHS)</label>
                <div className="relative">
                  <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-on-surface-variant" />
                  <input
                    type="number"
                    step="0.50"
                    min="0"
                    value={deliveryFee}
                    onChange={(e) => setDeliveryFee(e.target.value)}
                    placeholder="0.00"
                    className="w-full pl-10 pr-4 py-3 bg-surface-container rounded-xl border border-outline-variant/30 text-sm font-semibold focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">Minimum Order (GHS)</label>
                <div className="relative">
                  <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-on-surface-variant" />
                  <input
                    type="number"
                    step="1"
                    min="0"
                    value={minimumOrder}
                    onChange={(e) => setMinimumOrder(e.target.value)}
                    placeholder="0.00"
                    className="w-full pl-10 pr-4 py-3 bg-surface-container rounded-xl border border-outline-variant/30 text-sm font-semibold focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
                  />
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Save Button */}
      <div className="flex justify-end pb-8">
        <button
          onClick={handleSave}
          disabled={loading}
          className="flex items-center gap-2 px-8 py-3 bg-primary text-on-primary rounded-xl font-bold text-sm hover:brightness-110 disabled:opacity-50 transition-all shadow-md"
        >
          <Save className="h-4 w-4" />
          {loading ? "Saving..." : "Save Changes"}
        </button>
      </div>
    </div>
  );
}
