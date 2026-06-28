export enum Screen {
  LOGIN = 'LOGIN',
  DASHBOARD = 'DASHBOARD',
  ACTIVE_DELIVERY = 'ACTIVE_DELIVERY',
  NAVIGATION = 'NAVIGATION',
  EARNINGS = 'EARNINGS'
}

export interface ActivityItem {
  id: string;
  merchant: string;
  distance: string;
  timeAgo: string;
  amount: number;
  type: 'restaurant' | 'pharmacy' | 'grocery';
}

export interface Transaction {
  id: string;
  title: string;
  timestamp: string;
  amount: number;
  isBonus: boolean;
}

export interface NavigationState {
  currentStreet: string;
  nextStreet: string;
  distanceToTurn: number; // in meters
  totalDistance: number; // in km
  timeRemaining: number; // in minutes
  arrivalTime: string;
}

export interface Toast {
  id: string;
  message: string;
  type: 'success' | 'error' | 'info';
}
