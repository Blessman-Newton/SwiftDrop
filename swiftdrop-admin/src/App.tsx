import { useState, useEffect, useCallback } from 'react'
import { api } from './api'
import type { DashboardStats, User, Rider, Restaurant, AdminOrder, AnalyticsData, AdminMenuItem } from './types'
import CosmeticsView from './components/CosmeticsView'
import GasSettingsView from './components/GasSettingsView'

type View = 'dashboard' | 'users' | 'riders' | 'orders' | 'restaurants' | 'analytics' | 'cosmetics' | 'gas_pricing'

const STATUS_COLORS: Record<string, string> = {
  CREATED: 'bg-yellow-100 text-yellow-800',
  CONFIRMED: 'bg-blue-100 text-blue-800',
  PREPARING: 'bg-orange-100 text-orange-800',
  READY_FOR_PICKUP: 'bg-purple-100 text-purple-800',
  PICKED_UP: 'bg-indigo-100 text-indigo-800',
  EN_ROUTE: 'bg-cyan-100 text-cyan-800',
  DELIVERED: 'bg-green-100 text-green-800',
  CANCELLED: 'bg-red-100 text-red-800',
}

function StatCard({ label, value, icon, color = 'bg-primary-500' }: { label: string; value: string | number; icon: string; color?: string }) {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-gray-500">{label}</p>
          <p className="text-2xl font-bold text-gray-900 mt-1">{value}</p>
        </div>
        <div className={`w-12 h-12 ${color} rounded-xl flex items-center justify-center text-white text-xl`}>
          {icon}
        </div>
      </div>
    </div>
  )
}

function LoginScreen({ onLogin }: { onLogin: (token: string) => void }) {
  const [mode, setMode] = useState<'login' | 'signup'>('login')
  const [usePhone, setUsePhone] = useState(false)
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [phone, setPhone] = useState('')
  const [name, setName] = useState('')
  const [code, setCode] = useState('')
  const [step, setStep] = useState<'form' | 'otp'>('form')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [devCode, setDevCode] = useState('')

  const handleEmailLogin = async () => {
    setLoading(true)
    setError('')
    try {
      const res = await api.loginWithEmail(email, password)
      localStorage.setItem('admin_token', res.access_token)
      onLogin(res.access_token)
    } catch (e: any) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }

  const handleSendOtp = async () => {
    setLoading(true)
    setError('')
    try {
      const res = await api.sendOtp(phone)
      setDevCode(res.dev_code || '')
      setStep('otp')
    } catch (e: any) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }

  const handleVerify = async () => {
    setLoading(true)
    setError('')
    try {
      const res = await api.verifyOtp(phone, code)
      localStorage.setItem('admin_token', res.access_token)
      onLogin(res.access_token)
    } catch (e: any) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }

  const handleSignup = async () => {
    setLoading(true)
    setError('')
    try {
      const res = await api.signUp(email, password, phone, name || undefined)
      localStorage.setItem('admin_token', res.access_token)
      onLogin(res.access_token)
    } catch (e: any) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }

  const handleSubmit = () => {
    if (mode === 'signup') {
      handleSignup()
    } else if (usePhone) {
      handleSendOtp()
    } else {
      handleEmailLogin()
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-600 to-primary-800 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl p-8 w-full max-w-md">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900">SwiftDrop</h1>
          <p className="text-gray-500 mt-2">Admin Dashboard</p>
        </div>

        {step === 'form' ? (
          <div className="space-y-4">
            {mode === 'signup' && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Full Name</label>
                <input
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="John Doe"
                  className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none"
                />
              </div>
            )}

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@swiftdrop.com"
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Password</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none"
              />
            </div>

            {(mode === 'signup' || usePhone) && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Phone Number</label>
                <input
                  type="tel"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="+233241234567"
                  className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none"
                />
              </div>
            )}

            {error && <p className="text-red-500 text-sm">{error}</p>}

            <button
              onClick={handleSubmit}
              disabled={loading}
              className="w-full bg-primary-600 text-white py-3 rounded-xl font-semibold hover:bg-primary-700 disabled:opacity-50 transition"
            >
              {loading ? 'Please wait...' : mode === 'signup' ? 'Create Account' : 'Login'}
            </button>

            {mode === 'login' && (
              <>
                <button
                  onClick={() => setUsePhone(!usePhone)}
                  className="w-full text-primary-600 py-2 text-sm hover:underline"
                >
                  {usePhone ? 'Use email & password instead' : 'Use phone number instead'}
                </button>
              </>
            )}

            <div className="text-center text-sm text-gray-500">
              {mode === 'login' ? "Don't have an account? " : 'Already have an account? '}
              <button
                onClick={() => { setMode(mode === 'login' ? 'signup' : 'login'); setError('') }}
                className="text-primary-600 font-semibold hover:underline"
              >
                {mode === 'login' ? 'Sign Up' : 'Sign In'}
              </button>
            </div>
          </div>
        ) : (
          <div className="space-y-4">
            <p className="text-sm text-gray-500 text-center">OTP sent to {phone}</p>
            {devCode && (
              <p className="text-xs font-mono font-bold text-primary-600 bg-primary-50 px-3 py-2 rounded-lg text-center">
                Dev OTP: {devCode}
              </p>
            )}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Enter OTP</label>
              <input
                type="text"
                value={code}
                onChange={(e) => setCode(e.target.value)}
                placeholder="6-digit code"
                maxLength={6}
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none text-center text-2xl tracking-widest"
              />
            </div>
            {error && <p className="text-red-500 text-sm">{error}</p>}
            <button
              onClick={handleVerify}
              disabled={loading || code.length < 6}
              className="w-full bg-primary-600 text-white py-3 rounded-xl font-semibold hover:bg-primary-700 disabled:opacity-50 transition"
            >
              {loading ? 'Verifying...' : 'Verify & Login'}
            </button>
            <button
              onClick={() => { setStep('form'); setCode(''); setError('') }}
              className="w-full text-primary-600 py-2 text-sm hover:underline"
            >
              Back to login
            </button>
          </div>
        )}
      </div>
    </div>
  )
}

function Sidebar({ view, setView }: { view: View; setView: (v: View) => void }) {
  const items: { key: View; label: string; icon: string }[] = [
    { key: 'dashboard', label: 'Dashboard', icon: '📊' },
    { key: 'users', label: 'Users', icon: '👥' },
    { key: 'riders', label: 'Riders', icon: '🏍️' },
    { key: 'orders', label: 'Orders', icon: '📦' },
    { key: 'restaurants', label: 'Restaurants', icon: '🍽️' },
    { key: 'cosmetics', label: 'Cosmetics', icon: '💄' },
    { key: 'gas_pricing', label: 'Gas Pricing', icon: '⛽' },
    { key: 'analytics', label: 'Analytics', icon: '📈' },
  ]

  return (
    <aside className="w-64 bg-gray-900 text-white min-h-screen p-4">
      <div className="px-4 py-6 border-b border-gray-700 mb-4">
        <h1 className="text-xl font-bold">SwiftDrop</h1>
        <p className="text-xs text-gray-400 mt-1">Admin Panel</p>
      </div>
      <nav className="space-y-1">
        {items.map((item) => (
          <button
            key={item.key}
            onClick={() => setView(item.key)}
            className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm transition ${
              view === item.key ? 'bg-primary-600 text-white' : 'text-gray-300 hover:bg-gray-800'
            }`}
          >
            <span className="text-lg">{item.icon}</span>
            {item.label}
          </button>
        ))}
      </nav>
    </aside>
  )
}

function DashboardView({ stats }: { stats: DashboardStats | null }) {
  if (!stats) return <div className="p-8 text-gray-500">Loading...</div>
  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-gray-900">Dashboard</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard label="Total Users" value={stats.total_users} icon="👥" color="bg-blue-500" />
        <StatCard label="Total Orders" value={stats.total_orders} icon="📦" color="bg-green-500" />
        <StatCard label="Total Revenue" value={`GHS ${stats.total_revenue.toFixed(2)}`} icon="💰" color="bg-yellow-500" />
        <StatCard label="Active Riders" value={stats.active_riders} icon="🏍️" color="bg-purple-500" />
      </div>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <StatCard label="Orders Today" value={stats.orders_today} icon="📋" color="bg-cyan-500" />
        <StatCard label="Revenue Today" value={`GHS ${stats.revenue_today.toFixed(2)}`} icon="💵" color="bg-emerald-500" />
        <StatCard label="New Users Today" value={stats.new_users_today} icon="🆕" color="bg-pink-500" />
      </div>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <StatCard label="Pending Orders" value={stats.pending_orders} icon="⏳" color="bg-orange-500" />
        <StatCard label="Completed Today" value={stats.completed_orders_today} icon="✅" color="bg-green-600" />
        <StatCard label="Cancelled Today" value={stats.cancelled_orders_today} icon="❌" color="bg-red-500" />
      </div>
    </div>
  )
}

function UsersView({ token }: { token: string }) {
  const [users, setUsers] = useState<User[]>([])
  const [search, setSearch] = useState('')
  const [roleFilter, setRoleFilter] = useState('')

  const loadUsers = useCallback(async () => {
    try {
      const data = await api.getUsers(roleFilter || undefined, search || undefined)
      setUsers(data)
    } catch (e) { console.error(e) }
  }, [roleFilter, search])

  useEffect(() => { loadUsers() }, [loadUsers])

  const handleBan = async (userId: string) => {
    if (!confirm('Toggle ban this user?')) return
    try {
      await api.banUser(userId, 'Admin action')
      loadUsers()
    } catch (e) { console.error(e) }
  }

  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-bold text-gray-900">Users</h2>
      <div className="flex gap-3">
        <input
          type="text"
          placeholder="Search by name or phone..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 outline-none"
        />
        <select
          value={roleFilter}
          onChange={(e) => setRoleFilter(e.target.value)}
          className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 outline-none"
        >
          <option value="">All Roles</option>
          <option value="customer">Customers</option>
          <option value="rider">Riders</option>
          <option value="admin">Admins</option>
        </select>
      </div>
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">User</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Phone</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Role</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Status</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Joined</th>
              <th className="text-right px-6 py-3 text-xs font-medium text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {users.map((user) => (
              <tr key={user.id} className="hover:bg-gray-50">
                <td className="px-6 py-4">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 bg-primary-100 text-primary-700 rounded-full flex items-center justify-center text-sm font-semibold">
                      {(user.name || user.phone)?.[0]?.toUpperCase()}
                    </div>
                    <span className="font-medium text-gray-900">{user.name || 'No name'}</span>
                  </div>
                </td>
                <td className="px-6 py-4 text-gray-600">{user.phone}</td>
                <td className="px-6 py-4">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                    user.role === 'admin' ? 'bg-red-100 text-red-700' :
                    user.role === 'rider' ? 'bg-blue-100 text-blue-700' :
                    'bg-green-100 text-green-700'
                  }`}>
                    {user.role}
                  </span>
                </td>
                <td className="px-6 py-4">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                    user.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                  }`}>
                    {user.is_active ? 'Active' : 'Banned'}
                  </span>
                </td>
                <td className="px-6 py-4 text-sm text-gray-500">
                  {new Date(user.created_at).toLocaleDateString()}
                </td>
                <td className="px-6 py-4 text-right">
                  <button
                    onClick={() => handleBan(user.id)}
                    className={`text-sm px-3 py-1 rounded-lg ${
                      user.is_active ? 'text-red-600 hover:bg-red-50' : 'text-green-600 hover:bg-green-50'
                    }`}
                  >
                    {user.is_active ? 'Ban' : 'Unban'}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {users.length === 0 && <p className="text-center py-8 text-gray-500">No users found</p>}
      </div>
    </div>
  )
}

function RidersView({ token }: { token: string }) {
  const [riders, setRiders] = useState<Rider[]>([])
  const [search, setSearch] = useState('')

  const loadRiders = useCallback(async () => {
    try {
      const data = await api.getRiders(search || undefined)
      setRiders(data)
    } catch (e) { console.error(e) }
  }, [search])

  useEffect(() => { loadRiders() }, [loadRiders])

  const handleBan = async (riderId: string) => {
    if (!confirm('Toggle ban this rider?')) return
    try {
      await api.banRider(riderId, 'Admin action')
      loadRiders()
    } catch (e) { console.error(e) }
  }

  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-bold text-gray-900">Riders</h2>
      <input
        type="text"
        placeholder="Search riders..."
        value={search}
        onChange={(e) => setSearch(e.target.value)}
        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 outline-none"
      />
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Rider</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Phone</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Status</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Rating</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Deliveries</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Balance</th>
              <th className="text-right px-6 py-3 text-xs font-medium text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {riders.map((rider) => (
              <tr key={rider.id} className="hover:bg-gray-50">
                <td className="px-6 py-4">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 bg-blue-100 text-blue-700 rounded-full flex items-center justify-center text-sm font-semibold">
                      {(rider.name || rider.phone)?.[0]?.toUpperCase()}
                    </div>
                    <span className="font-medium text-gray-900">{rider.name || 'No name'}</span>
                  </div>
                </td>
                <td className="px-6 py-4 text-gray-600">{rider.phone}</td>
                <td className="px-6 py-4">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                    rider.is_banned ? 'bg-red-100 text-red-700' :
                    rider.is_online ? 'bg-green-100 text-green-700' :
                    'bg-gray-100 text-gray-600'
                  }`}>
                    {rider.is_banned ? 'Banned' : rider.is_online ? 'Online' : 'Offline'}
                  </span>
                </td>
                <td className="px-6 py-4 text-gray-600">⭐ {rider.rating}</td>
                <td className="px-6 py-4 text-gray-600">{rider.total_deliveries}</td>
                <td className="px-6 py-4 text-gray-600">GHS {rider.earnings_balance.toFixed(2)}</td>
                <td className="px-6 py-4 text-right">
                  <button
                    onClick={() => handleBan(rider.id)}
                    className={`text-sm px-3 py-1 rounded-lg ${
                      !rider.is_banned ? 'text-red-600 hover:bg-red-50' : 'text-green-600 hover:bg-green-50'
                    }`}
                  >
                    {rider.is_banned ? 'Unban' : 'Ban'}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {riders.length === 0 && <p className="text-center py-8 text-gray-500">No riders found</p>}
      </div>
    </div>
  )
}

function OrdersView({ token }: { token: string }) {
  const [orders, setOrders] = useState<AdminOrder[]>([])
  const [statusFilter, setStatusFilter] = useState('')
  const [typeFilter, setTypeFilter] = useState('')

  useEffect(() => {
    api.getOrders(statusFilter || undefined).then(setOrders).catch(console.error)
  }, [statusFilter])

  const filteredOrders = orders.filter((order) => {
    if (!typeFilter) return true
    return order.order_type.toLowerCase() === typeFilter.toLowerCase()
  })

  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-bold text-gray-900">Orders</h2>
      
      {/* Status Filters */}
      <div className="flex gap-2 flex-wrap items-center">
        <span className="text-xs font-bold text-gray-500 mr-2">STATUS:</span>
        {['', 'CREATED', 'CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'PICKED_UP', 'EN_ROUTE', 'DELIVERED', 'CANCELLED'].map((s) => (
          <button
            key={s}
            onClick={() => setStatusFilter(s)}
            className={`px-3 py-1 text-xs rounded-lg ${
              statusFilter === s ? 'bg-primary-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            {s || 'All'}
          </button>
        ))}
      </div>

      {/* Type Filters */}
      <div className="flex gap-2 flex-wrap items-center">
        <span className="text-xs font-bold text-gray-500 mr-2">SERVICE TYPE:</span>
        {[
          { key: '', label: 'All Services' },
          { key: 'food', label: 'Food Delivery' },
          { key: 'parcel', label: 'Courier Pickup' },
          { key: 'gas', label: 'Gas Refills' },
          { key: 'cosmetics', label: 'Cosmetics' },
        ].map((t) => (
          <button
            key={t.key}
            onClick={() => setTypeFilter(t.key)}
            className={`px-3 py-1 text-xs rounded-lg ${
              typeFilter === t.key ? 'bg-pink-600 text-white font-bold' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Order</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Type</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Customer</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Restaurant</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Status</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Payment</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Total</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Date</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {filteredOrders.map((order) => (
              <tr key={order.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 font-medium text-gray-900">{order.order_no}</td>
                <td className="px-6 py-4">
                  <span className="px-2 py-1 rounded-full text-xs bg-gray-100 text-gray-600">{order.order_type}</span>
                </td>
                <td className="px-6 py-4 text-gray-600">{order.customer_name}</td>
                <td className="px-6 py-4 text-gray-600">{order.restaurant_name || '-'}</td>
                <td className="px-6 py-4">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${STATUS_COLORS[order.status] || 'bg-gray-100 text-gray-600'}`}>
                    {order.status}
                  </span>
                </td>
                <td className="px-6 py-4">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                    order.payment_status === 'paid' ? 'bg-green-100 text-green-700' :
                    order.payment_status === 'pending' ? 'bg-yellow-100 text-yellow-700' :
                    'bg-red-100 text-red-700'
                  }`}>
                    {order.payment_status}
                  </span>
                </td>
                <td className="px-6 py-4 font-medium text-gray-900">GHS {order.total.toFixed(2)}</td>
                <td className="px-6 py-4 text-sm text-gray-500">{new Date(order.created_at).toLocaleDateString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {filteredOrders.length === 0 && <p className="text-center py-8 text-gray-500">No orders found</p>}
      </div>
    </div>
  )
}

function RestaurantsView({ token }: { token: string }) {
  const [restaurants, setRestaurants] = useState<Restaurant[]>([])
  const [expandedId, setExpandedId] = useState<string | null>(null)
  const [menuItems, setMenuItems] = useState<Record<string, AdminMenuItem[]>>({})
  const [loadingMenu, setLoadingMenu] = useState<string | null>(null)

  useEffect(() => {
    api.getRestaurants().then(setRestaurants).catch(console.error)
  }, [])

  const handleToggle = async (id: string) => {
    if (!confirm('Toggle restaurant status?')) return
    try {
      await api.toggleRestaurant(id)
      setRestaurants((prev) => prev.map((r) => r.id === id ? { ...r, is_active: !r.is_active } : r))
    } catch (e) { console.error(e) }
  }

  const handleExpandMenu = async (restaurant: Restaurant) => {
    if (expandedId === restaurant.id) {
      setExpandedId(null)
      return
    }
    setExpandedId(restaurant.id)
    if (!menuItems[restaurant.id]) {
      setLoadingMenu(restaurant.id)
      try {
        const items = await api.getRestaurantMenu(restaurant.id)
        setMenuItems((prev) => ({ ...prev, [restaurant.id]: items }))
      } catch (e) {
        console.error(e)
      } finally {
        setLoadingMenu(null)
      }
    }
  }

  const formatHours = (hours: Record<string, unknown> | null) => {
    if (!hours) return null
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
    const openDays = days.filter((d) => {
      const dayData = hours[d] as { closed?: boolean } | undefined
      return dayData && !dayData.closed
    })
    if (openDays.length === 0) return 'Closed all week'
    if (openDays.length === 7) return 'Open daily'
    return `${openDays.length} days/week`
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold text-gray-900">Restaurants</h2>
        <span className="text-sm text-gray-500">{restaurants.length} total</span>
      </div>

      <div className="space-y-4">
        {restaurants.map((r) => (
          <div key={r.id} className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
            {/* Restaurant Header */}
            <div className="p-5">
              <div className="flex items-start justify-between">
                <div className="flex items-start gap-4">
                  {/* Logo */}
                  {r.logo_url ? (
                    <img src={r.logo_url} alt={r.name} className="w-14 h-14 rounded-xl object-cover border border-gray-200" referrerPolicy="no-referrer" />
                  ) : (
                    <div className="w-14 h-14 rounded-xl bg-primary-100 text-primary-700 flex items-center justify-center text-xl font-bold">
                      {r.name[0]}
                    </div>
                  )}
                  <div>
                    <div className="flex items-center gap-2">
                      <h3 className="font-semibold text-gray-900">{r.name}</h3>
                      {r.restaurant_type && (
                        <span className="px-2 py-0.5 rounded-full text-[10px] font-medium bg-blue-100 text-blue-700">{r.restaurant_type}</span>
                      )}
                    </div>
                    <p className="text-sm text-gray-500 mt-0.5">{r.address}</p>
                    <div className="flex items-center gap-4 mt-2 text-xs text-gray-500">
                      {r.phone && <span>📞 {r.phone}</span>}
                      {r.email && <span>✉️ {r.email}</span>}
                    </div>
                  </div>
                </div>
                <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${
                  r.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                }`}>
                  {r.is_active ? 'Active' : 'Inactive'}
                </span>
              </div>

              <div className="mt-4 flex items-center gap-6 text-sm text-gray-600">
                <span>⭐ {r.rating}</span>
                <span>📋 {r.menu_item_count} items</span>
                <span>📦 {r.total_orders} orders</span>
                {formatHours(null) && <span>🕐 {formatHours(null)}</span>}
              </div>

              <div className="mt-4 flex items-center gap-2">
                <button
                  onClick={() => handleExpandMenu(r)}
                  className="px-4 py-2 rounded-lg text-sm font-medium bg-primary-50 text-primary-700 hover:bg-primary-100 transition"
                >
                  {expandedId === r.id ? 'Hide Menu' : `View Menu (${r.menu_item_count})`}
                </button>
                <button
                  onClick={() => handleToggle(r.id)}
                  className={`px-4 py-2 rounded-lg text-sm font-medium ${
                    r.is_active ? 'bg-red-50 text-red-600 hover:bg-red-100' : 'bg-green-50 text-green-600 hover:bg-green-100'
                  }`}
                >
                  {r.is_active ? 'Deactivate' : 'Activate'}
                </button>
              </div>
            </div>

            {/* Expandable Menu Items */}
            {expandedId === r.id && (
              <div className="border-t border-gray-100 bg-gray-50 p-4">
                {loadingMenu === r.id ? (
                  <p className="text-center py-4 text-gray-500 text-sm">Loading menu items...</p>
                ) : menuItems[r.id]?.length === 0 ? (
                  <p className="text-center py-4 text-gray-500 text-sm">No menu items yet</p>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
                    {menuItems[r.id]?.map((item) => (
                      <div key={item.id} className="flex items-center gap-3 bg-white rounded-lg p-3 border border-gray-200">
                        {item.image_url ? (
                          <img src={item.image_url} alt={item.name} className="w-12 h-12 rounded-lg object-cover" referrerPolicy="no-referrer" />
                        ) : (
                          <div className="w-12 h-12 rounded-lg bg-gray-200 flex items-center justify-center text-gray-400 text-xs">No img</div>
                        )}
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-1">
                            <p className="text-sm font-medium text-gray-900 truncate">{item.name}</p>
                            {!item.is_available && (
                              <span className="px-1.5 py-0.5 rounded text-[9px] font-bold bg-red-100 text-red-600">OOS</span>
                            )}
                          </div>
                          <p className="text-xs text-gray-500">{item.category_name || 'Uncategorized'}</p>
                          <div className="flex items-center gap-2 mt-0.5">
                            <span className="text-sm font-semibold text-gray-900">GHS {item.price.toFixed(2)}</span>
                            {item.is_vegetarian && <span className="text-[10px] text-green-600 font-medium">Vegan</span>}
                            {item.is_spicy && <span className="text-[10px] text-red-600 font-medium">Spicy</span>}
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>
        ))}
      </div>
      {restaurants.length === 0 && <p className="text-center py-8 text-gray-500">No restaurants found</p>}
    </div>
  )
}

function AnalyticsView({ token }: { token: string }) {
  const [analytics, setAnalytics] = useState<AnalyticsData | null>(null)
  const [days, setDays] = useState(30)

  useEffect(() => {
    api.getAnalytics(days).then(setAnalytics).catch(console.error)
  }, [days])

  if (!analytics) return <div className="p-8 text-gray-500">Loading analytics...</div>

  const maxRevenue = Math.max(...analytics.revenue_by_day.map((d) => d.amount), 1)

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold text-gray-900">Analytics</h2>
        <select
          value={days}
          onChange={(e) => setDays(Number(e.target.value))}
          className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 outline-none"
        >
          <option value={7}>Last 7 days</option>
          <option value={30}>Last 30 days</option>
          <option value={90}>Last 90 days</option>
        </select>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Revenue Chart */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
          <h3 className="font-semibold text-gray-900 mb-4">Revenue Trend</h3>
          <div className="flex items-end gap-1 h-40">
            {analytics.revenue_by_day.map((d, i) => (
              <div key={i} className="flex-1 flex flex-col items-center gap-1">
                <div
                  className="w-full bg-primary-500 rounded-t"
                  style={{ height: `${(d.amount / maxRevenue) * 100}%`, minHeight: 2 }}
                />
                <span className="text-[10px] text-gray-400">{d.date.slice(5)}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Orders by Status */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
          <h3 className="font-semibold text-gray-900 mb-4">Orders by Status</h3>
          <div className="space-y-3">
            {Object.entries(analytics.orders_by_status).map(([status, count]) => (
              <div key={status} className="flex items-center gap-3">
                <span className={`px-2 py-1 rounded text-xs font-medium ${STATUS_COLORS[status] || 'bg-gray-100 text-gray-600'}`}>
                  {status}
                </span>
                <div className="flex-1 bg-gray-100 rounded-full h-2">
                  <div
                    className="bg-primary-500 h-2 rounded-full"
                    style={{ width: `${(count / Math.max(...Object.values(analytics.orders_by_status), 1)) * 100}%` }}
                  />
                </div>
                <span className="text-sm font-medium text-gray-700 w-8 text-right">{count}</span>
              </div>
            ))}
            {Object.keys(analytics.orders_by_status).length === 0 && (
              <p className="text-gray-500 text-sm">No order data yet</p>
            )}
          </div>
        </div>

        {/* Top Restaurants */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
          <h3 className="font-semibold text-gray-900 mb-4">Top Restaurants</h3>
          <div className="space-y-3">
            {analytics.top_restaurants.map((r, i) => (
              <div key={i} className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <span className="text-lg font-bold text-gray-300 w-6">{i + 1}</span>
                  <span className="text-gray-900">{r.name}</span>
                </div>
                <span className="text-sm text-gray-500">{r.orders} orders</span>
              </div>
            ))}
            {analytics.top_restaurants.length === 0 && (
              <p className="text-gray-500 text-sm">No restaurant data yet</p>
            )}
          </div>
        </div>

        {/* User Growth */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
          <h3 className="font-semibold text-gray-900 mb-4">User Growth</h3>
          <div className="flex items-end gap-1 h-32">
            {analytics.user_growth.map((d, i) => (
              <div key={i} className="flex-1 flex flex-col items-center gap-1">
                <div
                  className="w-full bg-green-500 rounded-t"
                  style={{ height: `${(d.count / Math.max(...analytics.user_growth.map((x) => x.count), 1)) * 100}%`, minHeight: 2 }}
                />
                <span className="text-[10px] text-gray-400">{d.date.slice(5)}</span>
              </div>
            ))}
          </div>
          {analytics.user_growth.length === 0 && (
            <p className="text-gray-500 text-sm text-center mt-4">No growth data yet</p>
          )}
        </div>
      </div>
    </div>
  )
}

export default function App() {
  const [token, setToken] = useState<string | null>(() => localStorage.getItem('admin_token'))
  const [view, setView] = useState<View>('dashboard')
  const [stats, setStats] = useState<DashboardStats | null>(null)

  useEffect(() => {
    if (token) {
      api.getDashboard().then(setStats).catch(console.error)
    }
  }, [token])

  const handleLogout = () => {
    localStorage.removeItem('admin_token')
    setToken(null)
    setStats(null)
  }

  if (!token) return <LoginScreen onLogin={setToken} />

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar view={view} setView={setView} />
      <main className="flex-1 p-6 overflow-auto">
        <div className="flex items-center justify-between mb-6">
          <div />
          <button onClick={handleLogout} className="text-sm text-gray-500 hover:text-red-600 transition">
            Logout
          </button>
        </div>
        {view === 'dashboard' && <DashboardView stats={stats} />}
        {view === 'users' && <UsersView token={token} />}
        {view === 'riders' && <RidersView token={token} />}
        {view === 'orders' && <OrdersView token={token} />}
        {view === 'restaurants' && <RestaurantsView token={token} />}
        {view === 'cosmetics' && <CosmeticsView />}
        {view === 'gas_pricing' && <GasSettingsView />}
        {view === 'analytics' && <AnalyticsView token={token} />}
      </main>
    </div>
  )
}
