const API_BASE = import.meta.env.VITE_API_URL || 'https://swiftdrop-fvcd.onrender.com/api/v1';

async function apiFetch(path: string, options: RequestInit = {}) {
  const token = localStorage.getItem('swiftdrop_merchant_token');
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const res = await fetch(`${API_BASE}${path}`, { ...options, headers });

  if (!res.ok) {
    const error = await res.json().catch(() => ({ detail: res.statusText }));
    throw new Error(error.detail || 'API Error');
  }

  return res.json();
}

// Auth
export async function signUp(email: string, password: string, phone: string, name?: string) {
  const data = await apiFetch('/auth/signup', {
    method: 'POST',
    body: JSON.stringify({ email, password, phone, name, role: 'merchant' }),
  });
  if (data.access_token) {
    localStorage.setItem('swiftdrop_merchant_token', data.access_token);
  }
  return data;
}

export async function loginWithEmail(email: string, password: string) {
  const data = await apiFetch('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  });
  if (data.access_token) {
    localStorage.setItem('swiftdrop_merchant_token', data.access_token);
  }
  return data;
}

export async function sendOtp(phone: string) {
  return apiFetch('/auth/send-otp', {
    method: 'POST',
    body: JSON.stringify({ phone }),
  });
}

export async function verifyOtp(phone: string, code: string) {
  const data = await apiFetch('/auth/verify-otp', {
    method: 'POST',
    body: JSON.stringify({ phone, code }),
  });
  if (data.access_token) {
    localStorage.setItem('swiftdrop_merchant_token', data.access_token);
  }
  return data;
}

export function logout() {
  localStorage.removeItem('swiftdrop_merchant_token');
}

export function isAuthenticated() {
  return !!localStorage.getItem('swiftdrop_merchant_token');
}

// Categories
export async function getCategories() {
  return apiFetch('/categories/all');
}

// Restaurant Profile (Onboarding)
export async function createRestaurant(restaurant: {
  name: string;
  description?: string;
  address: string;
  latitude?: number;
  longitude?: number;
  logo_url?: string;
  phone?: string;
  email?: string;
  opening_hours?: Record<string, unknown>;
  restaurant_type?: string;
  delivery_time?: string;
  delivery_fee?: number;
  minimum_order?: number;
}) {
  return apiFetch('/merchants/restaurant', {
    method: 'POST',
    body: JSON.stringify(restaurant),
  });
}

export async function getRestaurant() {
  return apiFetch('/merchants/restaurant');
}

export async function updateRestaurant(restaurant: {
  name?: string;
  description?: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  logo_url?: string;
  phone?: string;
  email?: string;
  opening_hours?: Record<string, unknown>;
  restaurant_type?: string;
  delivery_time?: string;
  delivery_fee?: number;
  minimum_order?: number;
  is_active?: boolean;
}) {
  return apiFetch('/merchants/restaurant', {
    method: 'PATCH',
    body: JSON.stringify(restaurant),
  });
}

// Menu
export async function getMenuItems() {
  return apiFetch('/merchants/menu');
}

export async function createMenuItem(item: {
  name: string;
  description?: string;
  price: number;
  category_id?: string;
  image_url?: string;
  is_available?: boolean;
  is_vegetarian?: boolean;
  is_spicy?: boolean;
  tags?: string[];
}) {
  return apiFetch('/merchants/menu', {
    method: 'POST',
    body: JSON.stringify(item),
  });
}

export async function updateMenuItem(itemId: string, updates: Record<string, unknown>) {
  return apiFetch(`/merchants/menu/${itemId}`, {
    method: 'PATCH',
    body: JSON.stringify(updates),
  });
}

export async function deleteMenuItem(itemId: string) {
  return apiFetch(`/merchants/menu/${itemId}`, {
    method: 'DELETE',
  });
}

export async function toggleStock(itemId: string) {
  return apiFetch(`/merchants/menu/${itemId}/toggle-stock`, {
    method: 'PATCH',
  });
}

// Orders
export async function getOrders(status?: string) {
  const query = status ? `?status=${status}` : '';
  const orders = await apiFetch(`/merchants/orders${query}`);
  // Map API statuses to frontend statuses
  return orders.map((order: any) => ({
    ...order,
    status: mapOrderStatus(order.status),
  }));
}

function mapOrderStatus(apiStatus: string): string {
  const statusMap: Record<string, string> = {
    'created': 'new',
    'confirmed': 'preparing',
    'preparing': 'preparing',
    'ready_for_pickup': 'awaiting_pickup',
    'picked_up': 'awaiting_pickup',
    'en_route': 'awaiting_pickup',
    'delivered': 'completed',
    'cancelled': 'declined',
  };
  return statusMap[apiStatus] || apiStatus;
}

export async function updateOrderStatus(orderId: string, status: string) {
  // Map frontend status to API status
  const apiStatusMap: Record<string, string> = {
    'new': 'confirmed',
    'preparing': 'preparing',
    'awaiting_pickup': 'ready',
    'ready': 'ready',
    'completed': 'completed',
    'declined': 'declined',
  };
  const apiStatus = apiStatusMap[status] || status;
  return apiFetch(`/merchants/orders/${orderId}/status`, {
    method: 'PATCH',
    body: JSON.stringify({ status: apiStatus }),
  });
}

// Dashboard
export async function getDashboardStats() {
  return apiFetch('/merchants/dashboard');
}

export async function getMerchantInfo() {
  return apiFetch('/merchants/info');
}