export interface Category {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  image_url: string | null;
  display_order: number;
  is_active: boolean;
  parent_id: string | null;
  created_at: string | null;
}

export interface MenuItem {
  id: string;
  name: string;
  description: string;
  price: number;
  category: string;
  category_id: string | null;
  category_name: string | null;
  image: string;
  inStock: boolean;
  is_vegetarian: boolean;
  is_spicy: boolean;
  tags: string[];
  soldCount: number;
  soldTrend: string;
}

export interface Restaurant {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  image_url: string | null;
  logo_url: string | null;
  address: string;
  latitude: number | null;
  longitude: number | null;
  rating: number;
  delivery_time: string | null;
  delivery_fee: number;
  minimum_order: number;
  tags: string[] | null;
  is_active: boolean;
  phone: string | null;
  email: string | null;
  opening_hours: Record<string, unknown> | null;
  restaurant_type: string | null;
  owner_id: string | null;
  created_at: string | null;
  updated_at: string | null;
}

export interface OrderItem {
  name: string;
  quantity: number;
}

export type OrderStatus = 'new' | 'preparing' | 'awaiting_pickup' | 'ready' | 'completed' | 'declined';

export interface Order {
  id: string;
  orderNo: string;
  status: OrderStatus;
  customerName: string;
  items: OrderItem[];
  total: number;
  elapsedSeconds: number; // For counting up the timer
  createdAtStr: string; // Formatting like "12:45 PM"
  driverName?: string;
  driverStatus?: string;
  driverPhone?: string;
  driverAvatar?: string;
  avatarUrl?: string;
}