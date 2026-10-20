import { useState, useEffect } from 'react'
import { api } from '../api'

interface Banner {
  id: string
  title: string
  subtitle: string | null
  tag: string | null
  button_text: string | null
  route: string | null
  image_url: string | null
  colors: string[]
  created_by: string
  creator_name: string
  is_approved: boolean
  created_at: string
}

export default function BannersView() {
  const [banners, setBanners] = useState<Banner[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  
  // Form State
  const [title, setTitle] = useState('')
  const [subtitle, setSubtitle] = useState('')
  const [tag, setTag] = useState('')
  const [buttonText, setButtonText] = useState('Claim Offer')
  const [route, setRoute] = useState('/food-delivery')
  const [imageUrl, setImageUrl] = useState('')
  const [startColor, setStartColor] = useState('#064E3B')
  const [endColor, setEndColor] = useState('#065F46')
  const [submitting, setSubmitting] = useState(false)

  const fetchBanners = async () => {
    setLoading(true)
    try {
      const data = await api.getAdminBanners()
      setBanners(data)
    } catch (e: any) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchBanners()
  }, [])

  const handleApprove = async (id: string) => {
    try {
      await api.approveAdminBanner(id)
      setBanners((prev) =>
        prev.map((b) => (b.id === id ? { ...b, is_approved: true } : b))
      )
    } catch (e: any) {
      alert(`Error approving: ${e.message}`)
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this banner?')) return
    try {
      await api.deleteAdminBanner(id)
      setBanners((prev) => prev.filter((b) => b.id !== id))
    } catch (e: any) {
      alert(`Error deleting: ${e.message}`)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!title.trim()) {
      alert('Title is required')
      return
    }
    setSubmitting(true)
    try {
      const newBanner = await api.createAdminBanner({
        title,
        subtitle: subtitle || null,
        tag: tag || null,
        button_text: buttonText || 'Claim Offer',
        route: route || '/food-delivery',
        image_url: imageUrl || null,
        colors: [startColor, endColor],
      })
      setBanners((prev) => [newBanner, ...prev])
      // Reset form
      setTitle('')
      setSubtitle('')
      setTag('')
      setButtonText('Claim Offer')
      setRoute('/food-delivery')
      setImageUrl('')
      setStartColor('#064E3B')
      setEndColor('#065F46')
      alert('Banner created successfully!')
    } catch (e: any) {
      alert(`Error creating banner: ${e.message}`)
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold text-gray-900">Banners Management</h2>
        <span className="text-sm text-gray-500">{banners.length} total banners</span>
      </div>

      {error && (
        <div className="p-4 bg-red-50 text-red-700 rounded-lg border border-red-100 text-sm">
          {error}
        </div>
      )}

      {/* Grid: Left - Creation form, Right - Banners list */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Creation Form */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5 h-fit space-y-4">
          <h3 className="font-semibold text-gray-900 text-lg border-b pb-2">Create Global Banner</h3>
          <form onSubmit={handleSubmit} className="space-y-3.5">
            <div>
              <label className="block text-xs font-semibold text-gray-500 uppercase">Banner Tag</label>
              <input
                type="text"
                placeholder="e.g. LIMITED TIME, PROMO"
                value={tag}
                onChange={(e) => setTag(e.target.value)}
                className="w-full mt-1 px-3 py-2 bg-gray-50 border border-gray-200 rounded-lg text-sm focus:bg-white focus:border-primary-500 focus:outline-none transition"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-gray-500 uppercase">Title *</label>
              <input
                type="text"
                placeholder="e.g. 20% OFF Your First Order"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="w-full mt-1 px-3 py-2 bg-gray-50 border border-gray-200 rounded-lg text-sm focus:bg-white focus:border-primary-500 focus:outline-none transition"
                required
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-gray-500 uppercase">Subtitle / Code</label>
              <input
                type="text"
                placeholder="e.g. Use code SWIFT20 at checkout"
                value={subtitle}
                onChange={(e) => setSubtitle(e.target.value)}
                className="w-full mt-1 px-3 py-2 bg-gray-50 border border-gray-200 rounded-lg text-sm focus:bg-white focus:border-primary-500 focus:outline-none transition"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-semibold text-gray-500 uppercase">Button Label</label>
                <input
                  type="text"
                  placeholder="Claim Offer"
                  value={buttonText}
                  onChange={(e) => setButtonText(e.target.value)}
                  className="w-full mt-1 px-3 py-2 bg-gray-50 border border-gray-200 rounded-lg text-sm focus:bg-white focus:border-primary-500 focus:outline-none transition"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-500 uppercase">Route / Path</label>
                <input
                  type="text"
                  placeholder="/food-delivery"
                  value={route}
                  onChange={(e) => setRoute(e.target.value)}
                  className="w-full mt-1 px-3 py-2 bg-gray-50 border border-gray-200 rounded-lg text-sm focus:bg-white focus:border-primary-500 focus:outline-none transition"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-gray-500 uppercase">Image URL (Optional)</label>
              <input
                type="text"
                placeholder="https://images.unsplash.com/photo-..."
                value={imageUrl}
                onChange={(e) => setImageUrl(e.target.value)}
                className="w-full mt-1 px-3 py-2 bg-gray-50 border border-gray-200 rounded-lg text-sm focus:bg-white focus:border-primary-500 focus:outline-none transition"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-semibold text-gray-500 uppercase">Start Color</label>
                <div className="flex gap-2 mt-1">
                  <input
                    type="color"
                    value={startColor}
                    onChange={(e) => setStartColor(e.target.value)}
                    className="w-8 h-8 rounded border border-gray-200 cursor-pointer"
                  />
                  <input
                    type="text"
                    value={startColor}
                    onChange={(e) => setStartColor(e.target.value)}
                    className="w-full px-2 py-1 bg-gray-50 border border-gray-200 rounded-lg text-xs"
                  />
                </div>
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-500 uppercase">End Color</label>
                <div className="flex gap-2 mt-1">
                  <input
                    type="color"
                    value={endColor}
                    onChange={(e) => setEndColor(e.target.value)}
                    className="w-8 h-8 rounded border border-gray-200 cursor-pointer"
                  />
                  <input
                    type="text"
                    value={endColor}
                    onChange={(e) => setEndColor(e.target.value)}
                    className="w-full px-2 py-1 bg-gray-50 border border-gray-200 rounded-lg text-xs"
                  />
                </div>
              </div>
            </div>

            {/* Live Preview */}
            <div className="border border-dashed border-gray-300 rounded-xl p-3 bg-gray-50 mt-4">
              <span className="text-[10px] font-bold text-gray-400 uppercase">Live Banner Preview</span>
              <div 
                className="w-full rounded-xl p-4 mt-1 text-white relative overflow-hidden flex flex-col justify-between"
                style={{ 
                  background: `linear-gradient(135deg, ${startColor}, ${endColor})`,
                  minHeight: '110px'
                }}
              >
                {/* Background image overlay */}
                {imageUrl && (
                  <div 
                    className="absolute inset-0 bg-cover bg-center opacity-25 mix-blend-overlay"
                    style={{ backgroundImage: `url(${imageUrl})` }}
                  />
                )}
                <div className="relative z-10">
                  <span className="text-[9px] bg-white/20 text-white px-2 py-0.5 rounded-full font-bold uppercase tracking-wider">
                    {tag || 'LIMITED TIME'}
                  </span>
                  <h4 className="font-extrabold text-sm mt-1.5 leading-tight">{title || 'Your Promo Title'}</h4>
                  <p className="text-[10px] text-white/80 mt-0.5">{subtitle || 'Your Promo subtitle text'}</p>
                </div>
                <div className="relative z-10 flex items-center justify-between mt-2">
                  <span className="text-[9px] bg-white text-gray-900 px-2.5 py-1 rounded-full font-bold">
                    {buttonText || 'Claim Offer'}
                  </span>
                  <span className="text-[8px] text-white/50">{route}</span>
                </div>
              </div>
            </div>

            <button
              type="submit"
              disabled={submitting}
              className="w-full py-2.5 bg-primary-600 text-white rounded-lg font-semibold hover:bg-primary-700 disabled:opacity-50 transition cursor-pointer"
            >
              {submitting ? 'Creating...' : 'Publish Banner'}
            </button>
          </form>
        </div>

        {/* Banners List */}
        <div className="lg:col-span-2 space-y-4">
          {loading ? (
            <p className="text-center text-gray-500 py-8">Loading banners...</p>
          ) : banners.length === 0 ? (
            <p className="text-center text-gray-500 py-8 bg-white border rounded-xl">No banners found</p>
          ) : (
            <div className="space-y-4">
              {banners.map((b) => (
                <div 
                  key={b.id} 
                  className={`bg-white rounded-xl shadow-sm border p-4 flex flex-col md:flex-row items-stretch gap-4 transition ${
                    b.is_approved ? 'border-gray-100' : 'border-orange-200 bg-orange-50/10'
                  }`}
                >
                  {/* Banner Preview Block */}
                  <div 
                    className="w-full md:w-56 shrink-0 rounded-xl p-3.5 text-white relative overflow-hidden flex flex-col justify-between"
                    style={{ 
                      background: `linear-gradient(135deg, ${b.colors[0] || '#123526'}, ${b.colors[1] || '#0f766e'})`,
                      minHeight: '100px'
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
                        {b.tag || 'PROMO'}
                      </span>
                      <h4 className="font-extrabold text-xs mt-1 leading-tight">{b.title}</h4>
                      {b.subtitle && <p className="text-[9px] text-white/80 mt-0.5 leading-tight">{b.subtitle}</p>}
                    </div>
                    <div className="relative z-10 flex items-center justify-between mt-2.5">
                      <span className="text-[8px] bg-white text-gray-900 px-2 py-0.5 rounded-full font-bold">
                        {b.button_text || 'View'}
                      </span>
                    </div>
                  </div>

                  {/* Banner Details & Actions */}
                  <div className="flex-1 flex flex-col justify-between min-w-0">
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-semibold text-gray-400">CREATED BY:</span>
                        <span className="text-xs font-bold text-gray-700 truncate">{b.creator_name}</span>
                        {!b.is_approved && (
                          <span className="px-2 py-0.5 rounded-full text-[9px] font-bold bg-orange-100 text-orange-700 flex items-center gap-1 uppercase tracking-wider animate-pulse">
                            Pending Approval
                          </span>
                        )}
                      </div>
                      <p className="text-xs text-gray-400 mt-1">
                        Date: {new Date(b.created_at).toLocaleDateString()} at {new Date(b.created_at).toLocaleTimeString()}
                      </p>
                      <p className="text-xs text-gray-500 mt-2 font-medium">
                        Target Action: <span className="bg-gray-100 px-1.5 py-0.5 rounded text-[10px] font-bold font-mono">{b.route}</span>
                      </p>
                    </div>

                    <div className="flex items-center gap-2 mt-4 pt-2 border-t border-gray-100">
                      {!b.is_approved && (
                        <button
                          onClick={() => handleApprove(b.id)}
                          className="px-3.5 py-1.5 bg-green-600 text-white rounded-lg text-xs font-bold hover:bg-green-700 transition cursor-pointer"
                        >
                          Approve Banner
                        </button>
                      )}
                      <button
                        onClick={() => handleDelete(b.id)}
                        className="px-3.5 py-1.5 bg-red-50 text-red-600 rounded-lg text-xs font-bold hover:bg-red-100 transition cursor-pointer ml-auto"
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
