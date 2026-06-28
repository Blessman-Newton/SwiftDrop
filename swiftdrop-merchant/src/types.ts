export interface MenuItem {
  id: string;
  name: string;
  description: string;
  price: number;
  category: string;
  image: string;
  inStock: boolean;
  soldCount: number;
  soldTrend: string;
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
  avatarUrl?: string;
}
