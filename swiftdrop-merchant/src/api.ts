// Local-first: the Vite dev server proxies /api to the local FastAPI service.
// Set VITE_API_URL explicitly only when intentionally testing another API.
const API_BASE = import.meta.env.VITE_API_URL || '/api/v1';

function friendlyApiError(error: unknown, status?: number, detail?: unknown): Error {
  const text = typeof detail === 'string' ? detail.toLowerCase() : '';
  if (error instanceof TypeError || text.includes('network') || text.includes('fetch')) {
    return new Error('We could not connect to the server. Please check your internet connection and try again.');
  }
  if (status === 401) return new Error('Your session has expired. Please sign in again.');
  if (status === 403) return new Error('You do not have permission to perform this action.');
  if (status === 404) return new Error('The requested information could not be found.');
  if (status === 409 || text.includes('already exists') || text.includes('already registered')) {
    return new Error('That information is already in use. Please check it and try again.');
  }
  if (status === 422) return new Error('Please check the information entered and try again.');
  if (status !== undefined && status >= 500) {
    return new Error('Something went wrong on our side. Please try again in a moment.');
  }
  if (text.includes('invalid') && text.includes('password')) {
    return new Error('The email or password is incorrect.');
  }
  return new Error('We could not complete that request. Please try again.');
}

async function apiFetch(path: string, options: RequestInit = {}) {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };

  let res: Response;
  try {
    res = await fetch(`${API_BASE}${path}`, { ...options, headers, credentials: 'include' });
  } catch (error) {
    throw friendlyApiError(error);
  }

  if (res.status === 401) {
    window.location.reload();
    throw friendlyApiError(undefined, 401);
  }

  if (!res.ok) {
    const error = await res.json().catch(() => ({ detail: res.statusText }));
    throw friendlyApiError(undefined, res.status, error.detail || error.error);
  }

  return res.json();
}

// Auth
export async function signUp(email: string, password: string, phone: string, name?: string) {
  const data = await apiFetch('/auth/signup', {
    method: 'POST',
    body: JSON.stringify({ email, password, phone, name }),
  });
  return data;
}

export async function loginWithEmail(email: string, password: string) {
  const data = await apiFetch('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  });
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
  return data;
}

export async function logout() {
  try {
    await apiFetch('/auth/logout', { method: 'POST' });
  } catch (_) {}
  window.location.reload();
}

export async function me() {
  return apiFetch('/auth/me');
}

export async function isAuthenticated() {
  try {
    await me();
    return true;
  } catch (_) {
    return false;
  }
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
  return statusMap[apiStatus.toLowerCase()] || apiStatus.toLowerCase();
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

export async function completeOnboarding() {
  return apiFetch('/merchants/complete-onboarding', {
    method: 'POST',
  });
}

// Banners
export async function getMerchantBanners() {
  return apiFetch('/banners/merchant');
}

export async function createMerchantBanner(banner: any) {
  return apiFetch('/banners', {
    method: 'POST',
    body: JSON.stringify(banner),
  });
}

export async function deleteMerchantBanner(id: string) {
  return apiFetch(`/banners/${id}`, {
    method: 'DELETE',
  });
}