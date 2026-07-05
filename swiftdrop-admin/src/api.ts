const BASE = import.meta.env.VITE_API_URL || '/api/v1'

function getToken(): string | null {
  return localStorage.getItem('admin_token')
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getToken()
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  }
  if (token) headers['Authorization'] = `Bearer ${token}`

  const res = await fetch(`${BASE}${path}`, { ...options, headers })

  if (res.status === 401) {
    localStorage.removeItem('admin_token')
    window.location.reload()
    throw new Error('Unauthorized')
  }

  if (!res.ok) {
    const body = await res.json().catch(() => ({}))
    throw new Error(body.detail || `HTTP ${res.status}`)
  }

  return res.json()
}

export const api = {
  // Auth
  signUp: (email: string, password: string, phone: string, name?: string) =>
    request<{ access_token: string; user: any }>('/auth/signup', {
      method: 'POST',
      body: JSON.stringify({ email, password, phone, name, role: 'admin' }),
    }),

  loginWithEmail: (email: string, password: string) =>
    request<{ access_token: string; user: any }>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    }),

  sendOtp: (phone: string) =>
    request<{ message: string; phone: string; dev_code?: string }>('/auth/send-otp', {
      method: 'POST',
      body: JSON.stringify({ phone }),
    }),

  verifyOtp: (phone: string, code: string) =>
    request<{ access_token: string; user: any }>('/auth/verify-otp', {
      method: 'POST',
      body: JSON.stringify({ phone, code }),
    }),

  // Dashboard
  getDashboard: () => request<any>('/admin/dashboard'),

  // Users
  getUsers: (role?: string, search?: string) => {
    const params = new URLSearchParams()
    if (role) params.set('role', role)
    if (search) params.set('search', search)
    return request<any[]>(`/admin/users?${params}`)
  },

  getUser: (id: string) => request<any>(`/admin/users/${id}`),

  banUser: (id: string, reason?: string) =>
    request<any>(`/admin/users/${id}/ban`, {
      method: 'PATCH',
      body: JSON.stringify({ reason }),
    }),

  // Riders
  getRiders: (search?: string) => {
    const params = new URLSearchParams()
    if (search) params.set('search', search)
    return request<any[]>(`/admin/riders?${params}`)
  },

  banRider: (id: string, reason?: string) =>
    request<any>(`/admin/riders/${id}/ban`, {
      method: 'PATCH',
      body: JSON.stringify({ reason }),
    }),

  // Orders
  getOrders: (status?: string, search?: string) => {
    const params = new URLSearchParams()
    if (status) params.set('status', status)
    if (search) params.set('search', search)
    return request<any[]>(`/admin/orders?${params}`)
  },

  // Restaurants
  getRestaurants: () => request<any[]>('/admin/restaurants'),

  getRestaurantMenu: (restaurantId: string) =>
    request<any[]>(`/admin/restaurants/${restaurantId}/menu`),

  toggleRestaurant: (id: string) =>
    request<any>(`/admin/restaurants/${id}/toggle`, { method: 'PATCH' }),

  // Analytics
  getAnalytics: (days?: number) => {
    const params = days ? `?days=${days}` : ''
    return request<any>(`/admin/analytics${params}`)
  },

  // Notifications
  sendNotification: (userId: string, title: string, body: string, type: string) =>
    request<any>('/notifications/send', {
      method: 'POST',
      body: JSON.stringify({ user_id: userId, title, body, type }),
    }),
}
