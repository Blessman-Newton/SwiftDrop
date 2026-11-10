const BASE = import.meta.env.VITE_API_URL || '/api/v1'

function friendlyApiError(error: unknown, status?: number, detail?: unknown): Error {
  const text = typeof detail === 'string' ? detail.toLowerCase() : ''
  if (error instanceof TypeError || text.includes('network') || text.includes('fetch')) {
    return new Error('We could not connect to the server. Please check your internet connection and try again.')
  }
  if (status === 401) return new Error('Your session has expired. Please sign in again.')
  if (status === 403) return new Error('You do not have permission to perform this action.')
  if (status === 404) return new Error('The requested information could not be found.')
  if (status === 409 || text.includes('already exists') || text.includes('already registered')) {
    return new Error('That information is already in use. Please check it and try again.')
  }
  if (status === 422) return new Error('Please check the information entered and try again.')
  if (status !== undefined && status >= 500) {
    return new Error('Something went wrong on our side. Please try again in a moment.')
  }
  if (text.includes('invalid') && text.includes('password')) {
    return new Error('The email or password is incorrect.')
  }
  return new Error('We could not complete that request. Please try again.')
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  }

  let res: Response
  try {
    res = await fetch(`${BASE}${path}`, { ...options, headers, credentials: 'include' })
  } catch (error) {
    throw friendlyApiError(error)
  }

  if (res.status === 401) {
    window.location.reload()
    throw friendlyApiError(undefined, 401)
  }

  if (!res.ok) {
    const body = await res.json().catch(() => ({}))
    const detail = body.detail || body.error || `HTTP ${res.status}`
    throw friendlyApiError(undefined, res.status, detail)
  }

  return res.json()
}

export const api = {
  // Auth
  signUp: (email: string, password: string, phone: string, name?: string) =>
    request<{ user: any }>('/auth/signup', {
      method: 'POST',
      body: JSON.stringify({ email, password, phone, name }),
    }),

  loginWithEmail: (email: string, password: string) =>
    request<{ user: any }>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    }),

  sendOtp: (phone: string) =>
    request<{ message: string; phone: string; dev_code?: string }>('/auth/send-otp', {
      method: 'POST',
      body: JSON.stringify({ phone }),
    }),

  verifyOtp: (phone: string, code: string) =>
    request<{ user: any }>('/auth/verify-otp', {
      method: 'POST',
      body: JSON.stringify({ phone, code }),
    }),

  logout: () => request<{ message: string }>('/auth/logout', { method: 'POST' }),

  me: () => request<any>('/auth/me'),
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

  // Cosmetics
  getAdminCosmetics: () => request<any[]>('/admin/cosmetics'),

  createAdminCosmetic: (body: { name: string; description?: string; price: number; image_url?: string }) =>
    request<any>('/admin/cosmetics', {
      method: 'POST',
      body: JSON.stringify(body),
    }),

  toggleAdminCosmetic: (id: string) =>
    request<any>(`/admin/cosmetics/${id}/toggle`, {
      method: 'PATCH',
    }),

  // Gas settings
  getGasPrices: () => request<Record<string, number>>('/admin/settings/gas-prices'),

  updateGasPrices: (prices: Record<string, number>) =>
    request<any>('/admin/settings/gas-prices', {
      method: 'POST',
      body: JSON.stringify(prices),
    }),

  // Banners
  getAdminBanners: () => request<any[]>('/banners/admin'),
  approveAdminBanner: (id: string) => request<any>(`/banners/${id}/approve`, { method: 'PUT' }),
  deleteAdminBanner: (id: string) => request<any>(`/banners/${id}`, { method: 'DELETE' }),
  createAdminBanner: (body: any) => request<any>('/banners', {
    method: 'POST',
    body: JSON.stringify(body),
  }),
}
