import { useState } from "react";
import {
  Store,
  MapPin,
  Clock,
  Check,
  ChevronRight,
  ChevronLeft,
  Utensils,
  Phone,
  Mail,
  Globe,
  Sparkles,
  Camera,
  AlertCircle,
} from "lucide-react";
import { motion, AnimatePresence } from "motion/react";

interface OnboardingViewProps {
  onComplete: (data: OnboardingData) => void;
  loading?: boolean;
}

export interface OnboardingData {
  name: string;
  description: string;
  restaurant_type: string;
  address: string;
  phone: string;
  email: string;
  logo_url: string;
  opening_hours: Record<string, { open: string; close: string; closed: boolean }>;
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

const DEFAULT_HOURS: Record<string, { open: string; close: string; closed: boolean }> = {
  monday: { open: "08:00", close: "22:00", closed: false },
  tuesday: { open: "08:00", close: "22:00", closed: false },
  wednesday: { open: "08:00", close: "22:00", closed: false },
  thursday: { open: "08:00", close: "22:00", closed: false },
  friday: { open: "08:00", close: "22:00", closed: false },
  saturday: { open: "09:00", close: "23:00", closed: false },
  sunday: { open: "10:00", close: "21:00", closed: false },
};

const LOGO_SUGGESTIONS = [
  "https://lh3.googleusercontent.com/aida-public/AB6AXuAaS8d7dJRJSyw4nxMO-eZ3MOzO9uyYYDLN7sizqM4yDfzaXMDrMHfLrXJVHwl_Ddf_Mdn857JXDc3L3eid3xEhUPIjt1HRrwvrP-c5RmPckAZhbw7tGUot3ad3H_iP7u3gncOaDUNG-fmR8md2rfzWwfvuJgwuh1u0Yy1AgsXOBxvxceMoustCNYZXlPsLcrPTKSiBszDV2D0y3mS2flMevEcob39siLBMNRt3M6bG1moGExyLu75uq9PMe407WJ-wVoh3updhQZQ",
  "https://lh3.googleusercontent.com/aida-public/AB6AXuBKBAhsQLG1R46JlfzVVp2Qy_Rr9A57cPwSUw-qOaFsaZruMg_WMfhLdsdUSpTDQl-89-fiPSkoSP_do1-OkscWEIs6Wfx-oWyvCKseN2yDB3LW9zZjdgKEZ50_fuRWHOE4pVXIXL5A9GtKtFlU_I5hma_jyGfpyp-LjDvge5Dgc4ygwqGOiCgf3e2BX7M-1-rn8hrawx2SRECHPNctgyF8GP6XwGgF6ESnn5_3iF23XZyrE6aHDMfLbQnoDerO1TzbfHOB1-yFXEE",
];

export default function OnboardingView({ onComplete, loading }: OnboardingViewProps) {
  const [step, setStep] = useState(0);
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [restaurantType, setRestaurantType] = useState("");
  const [address, setAddress] = useState("");
  const [phone, setPhone] = useState("");
  const [email, setEmail] = useState("");
  const [logoUrl, setLogoUrl] = useState("");
  const [openingHours, setOpeningHours] = useState(DEFAULT_HOURS);
  const [errors, setErrors] = useState<Record<string, string>>({});

  const steps = [
    { title: "Restaurant Info", icon: Store, description: "Tell us about your restaurant" },
    { title: "Contact & Location", icon: MapPin, description: "Where can customers find you?" },
    { title: "Opening Hours", icon: Clock, description: "When are you open?" },
    { title: "Review & Launch", icon: Check, description: "Almost ready to go!" },
  ];

  const validateStep = (stepIndex: number): boolean => {
    const newErrors: Record<string, string> = {};

    if (stepIndex === 0) {
      if (!name.trim()) newErrors.name = "Restaurant name is required";
      if (!restaurantType) newErrors.restaurantType = "Select a restaurant type";
    } else if (stepIndex === 1) {
      if (!address.trim()) newErrors.address = "Address is required";
      if (address.trim().length < 5) newErrors.address = "Address must be at least 5 characters";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleNext = () => {
    if (validateStep(step)) {
      setStep((prev) => Math.min(prev + 1, steps.length - 1));
    }
  };

  const handleBack = () => {
    setStep((prev) => Math.max(prev - 1, 0));
  };

  const handleSubmit = () => {
    onComplete({
      name: name.trim(),
      description: description.trim(),
      restaurant_type: restaurantType,
      address: address.trim(),
      phone: phone.trim(),
      email: email.trim(),
      logo_url: logoUrl,
      opening_hours: openingHours,
    });
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
    <div className="min-h-screen bg-background text-on-background flex items-center justify-center p-4">
      <div className="w-full max-w-lg">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="flex items-center justify-center gap-3 mb-4">
            <div className="w-14 h-14 bg-primary rounded-2xl flex items-center justify-center shadow-lg">
              <Utensils className="h-7 w-7 text-on-primary" />
            </div>
          </div>
          <h1 className="font-display text-2xl font-extrabold text-on-surface">Set Up Your Restaurant</h1>
          <p className="text-sm text-on-surface-variant mt-1">Complete your profile to start receiving orders</p>
        </div>

        {/* Step Indicators */}
        <div className="flex items-center justify-center gap-2 mb-8">
          {steps.map((s, idx) => (
            <div key={idx} className="flex items-center">
              <div
                className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold transition-all ${
                  idx < step
                    ? "bg-primary text-on-primary"
                    : idx === step
                    ? "bg-primary-container text-on-primary-container ring-2 ring-primary ring-offset-2 ring-offset-background"
                    : "bg-surface-container-high text-on-surface-variant"
                }`}
              >
                {idx < step ? <Check className="h-4 w-4" /> : idx + 1}
              </div>
              {idx < steps.length - 1 && (
                <div
                  className={`w-8 h-0.5 mx-1 transition-all ${
                    idx < step ? "bg-primary" : "bg-surface-container-high"
                  }`}
                />
              )}
            </div>
          ))}
        </div>

        {/* Step Content */}
        <div className="bg-surface rounded-3xl shadow-xl border border-outline-variant/20 overflow-hidden">
          <div className="p-6 border-b border-outline-variant/20">
            <div className="flex items-center gap-3">
              {(() => {
                const Icon = steps[step].icon;
                return <Icon className="h-5 w-5 text-primary" />;
              })()}
              <div>
                <h2 className="font-display font-bold text-lg text-on-surface">{steps[step].title}</h2>
                <p className="text-xs text-on-surface-variant">{steps[step].description}</p>
              </div>
            </div>
          </div>

          <div className="p-6">
            <AnimatePresence mode="wait">
              <motion.div
                key={step}
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
                transition={{ duration: 0.2 }}
              >
                {/* Step 0: Restaurant Info */}
                {step === 0 && (
                  <div className="space-y-4">
                    <div>
                      <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">
                        Restaurant Name *
                      </label>
                      <input
                        type="text"
                        value={name}
                        onChange={(e) => setName(e.target.value)}
                        placeholder="e.g. Mama's Kitchen"
                        className="w-full px-4 py-3 bg-surface-container rounded-xl border border-outline-variant/30 text-sm font-semibold focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
                      />
                      {errors.name && (
                        <p className="text-xs text-error mt-1 flex items-center gap-1">
                          <AlertCircle className="h-3 w-3" /> {errors.name}
                        </p>
                      )}
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">
                        Restaurant Type *
                      </label>
                      <div className="grid grid-cols-3 gap-2">
                        {RESTAURANT_TYPES.map((type) => (
                          <button
                            key={type}
                            type="button"
                            onClick={() => setRestaurantType(type)}
                            className={`px-3 py-2.5 rounded-xl text-xs font-bold border transition-all ${
                              restaurantType === type
                                ? "bg-primary text-on-primary border-primary"
                                : "bg-surface-container text-on-surface-variant border-outline-variant/30 hover:border-primary/50"
                            }`}
                          >
                            {type}
                          </button>
                        ))}
                      </div>
                      {errors.restaurantType && (
                        <p className="text-xs text-error mt-1 flex items-center gap-1">
                          <AlertCircle className="h-3 w-3" /> {errors.restaurantType}
                        </p>
                      )}
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">
                        Description (optional)
                      </label>
                      <textarea
                        rows={3}
                        value={description}
                        onChange={(e) => setDescription(e.target.value)}
                        placeholder="Tell customers what makes your restaurant special..."
                        className="w-full px-4 py-3 bg-surface-container rounded-xl border border-outline-variant/30 text-sm font-semibold focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20 resize-none"
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-on-surface-variant uppercase mb-2">
                        Restaurant Logo (optional)
                      </label>
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
                            onClick={() => setLogoUrl(url)}
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

                {/* Step 1: Contact & Location */}
                {step === 1 && (
                  <div className="space-y-4">
                    <div>
                      <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">
                        Address *
                      </label>
                      <div className="relative">
                        <MapPin className="absolute left-3 top-3 h-4 w-4 text-on-surface-variant" />
                        <input
                          type="text"
                          value={address}
                          onChange={(e) => setAddress(e.target.value)}
                          placeholder="e.g. 123 Oxford Street, Osu, Accra"
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
                      <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">
                        Phone Number
                      </label>
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
                      <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1.5">
                        Email (optional)
                      </label>
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

                    <div className="bg-primary/5 rounded-xl p-4 border border-primary/10">
                      <div className="flex items-start gap-2">
                        <Globe className="h-4 w-4 text-primary mt-0.5 shrink-0" />
                        <p className="text-xs text-on-surface-variant leading-relaxed">
                          Your address will be shown to customers. Make sure it's accurate so delivery riders can find you easily.
                        </p>
                      </div>
                    </div>
                  </div>
                )}

                {/* Step 2: Opening Hours */}
                {step === 2 && (
                  <div className="space-y-3">
                    <p className="text-xs text-on-surface-variant mb-4">
                      Set your operating hours. You can toggle individual days on/off.
                    </p>

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

                {/* Step 3: Review */}
                {step === 3 && (
                  <div className="space-y-4">
                    <div className="bg-surface-container rounded-xl p-4 space-y-3">
                      <h3 className="text-xs font-bold text-on-surface-variant uppercase tracking-wider">Restaurant Details</h3>
                      
                      <div className="flex items-center gap-3">
                        {logoUrl ? (
                          <div className="w-12 h-12 rounded-xl overflow-hidden border border-outline-variant/30 shrink-0">
                            <img src={logoUrl} alt="Logo" className="w-full h-full object-cover" referrerPolicy="no-referrer" />
                          </div>
                        ) : (
                          <div className="w-12 h-12 rounded-xl bg-primary/20 flex items-center justify-center shrink-0">
                            <Store className="h-6 w-6 text-primary" />
                          </div>
                        )}
                        <div>
                          <p className="font-bold text-on-surface text-sm">{name || "Not set"}</p>
                          <p className="text-xs text-on-surface-variant">{restaurantType || "Not set"}</p>
                        </div>
                      </div>

                      {description && (
                        <p className="text-xs text-on-surface-variant leading-relaxed">{description}</p>
                      )}
                    </div>

                    <div className="bg-surface-container rounded-xl p-4 space-y-2">
                      <h3 className="text-xs font-bold text-on-surface-variant uppercase tracking-wider">Location & Contact</h3>
                      <div className="flex items-center gap-2 text-sm text-on-surface">
                        <MapPin className="h-4 w-4 text-primary shrink-0" />
                        <span>{address || "Not set"}</span>
                      </div>
                      {phone && (
                        <div className="flex items-center gap-2 text-sm text-on-surface">
                          <Phone className="h-4 w-4 text-primary shrink-0" />
                          <span>{phone}</span>
                        </div>
                      )}
                      {email && (
                        <div className="flex items-center gap-2 text-sm text-on-surface">
                          <Mail className="h-4 w-4 text-primary shrink-0" />
                          <span>{email}</span>
                        </div>
                      )}
                    </div>

                    <div className="bg-surface-container rounded-xl p-4">
                      <h3 className="text-xs font-bold text-on-surface-variant uppercase tracking-wider mb-2">Opening Hours</h3>
                      <div className="space-y-1">
                        {DAYS.map((day) => {
                          const hours = openingHours[day];
                          return (
                            <div key={day} className="flex justify-between text-xs">
                              <span className="font-semibold text-on-surface capitalize">{day.slice(0, 3)}</span>
                              <span className={hours.closed ? "text-error font-bold" : "text-on-surface-variant"}>
                                {hours.closed ? "Closed" : `${formatTime(hours.open)} - ${formatTime(hours.close)}`}
                              </span>
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  </div>
                )}
              </motion.div>
            </AnimatePresence>
          </div>

          {/* Footer Navigation */}
          <div className="p-6 pt-0 flex gap-3">
            {step > 0 && (
              <button
                onClick={handleBack}
                className="flex items-center gap-1 px-5 py-3 border border-outline-variant rounded-xl text-xs font-bold text-on-surface-variant hover:bg-surface-container transition-all"
              >
                <ChevronLeft className="h-4 w-4" /> Back
              </button>
            )}
            <button
              onClick={step === steps.length - 1 ? handleSubmit : handleNext}
              disabled={loading}
              className="flex-1 flex items-center justify-center gap-2 py-3 bg-primary text-on-primary rounded-xl text-xs font-bold hover:brightness-110 disabled:opacity-50 transition-all shadow-md"
            >
              {loading ? (
                "Setting up..."
              ) : step === steps.length - 1 ? (
                <>
                  <Sparkles className="h-4 w-4" /> Launch Restaurant
                </>
              ) : (
                <>
                  Continue <ChevronRight className="h-4 w-4" />
                </>
              )}
            </button>
          </div>
        </div>

        {/* Skip option */}
        <button
          onClick={() => onComplete({
            name: "Restaurant",
            description: "",
            restaurant_type: "Fast Food",
            address: "Accra, Ghana",
            phone: "",
            email: "",
            logo_url: "",
            opening_hours: DEFAULT_HOURS,
          })}
          className="w-full mt-4 py-2 text-on-surface-variant text-xs font-bold hover:text-on-surface transition-all text-center"
        >
          Skip for now
        </button>
      </div>
    </div>
  );
}

function formatTime(time: string): string {
  const [h, m] = time.split(":");
  const hour = parseInt(h);
  const ampm = hour >= 12 ? "PM" : "AM";
  const displayHour = hour % 12 || 12;
  return `${displayHour}:${m} ${ampm}`;
}
