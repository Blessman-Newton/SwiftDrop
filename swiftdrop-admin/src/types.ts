export interface User {
  id: string
  phone: string
  name: string | null
  email: string | null
  role: string
  avatar_url: string | null
  is_active: boolean
  is_verified: boolean
  created_at: string
}

export interface Rider extends User {
  is_online: boolean
  rating: number
  total_deliveries: number
  earnings_balance: number
  vehicle_type: string | null
  is_banned: boolean
}

export interface Restaurant {
  id: string
  name: string
  slug: string
  address: string
  phone: string | null
  email: string | null
  logo_url: string | null
  restaurant_type: string | null
  rating: number
  is_active: boolean
  menu_item_count: number
  total_orders: number
  created_at: string
}

export interface AdminMenuItem {
  id: string
  name: string
  description: string | null
  price: number
  category_name: string | null
  image_url: string | null
  is_available: boolean
  is_vegetarian: boolean
  is_spicy: boolean
  created_at: string | null
}

export interface AdminOrder {
  id: string
  order_no: string
  status: string
  customer_name: string
  rider_name: string | null
  restaurant_name: string | null
  order_type: string
  total: number
  payment_status: string
  created_at: string
}

export interface DashboardStats {
  total_users: number
  total_riders: number
  total_merchants: number
  total_orders: number
  total_revenue: number
  orders_today: number
  revenue_today: number
  active_riders: number
  pending_orders: number
  completed_orders_today: number
  cancelled_orders_today: number
  new_users_today: number
}

export interface AnalyticsData {
  orders_by_status: Record<string, number>
  orders_by_day: { date: string; count: number }[]
  revenue_by_day: { date: string; amount: number }[]
  top_restaurants: { name: string; orders: number }[]
  top_riders: { name: string; deliveries: number }[]
  user_growth: { date: string; count: number }[]
}
