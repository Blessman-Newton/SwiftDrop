export type Screen = 'fleet' | 'dashboard' | 'wallet' | 'reports' | 'security';

export interface Hub {
  id: string;
  name: string;
  status: 'peak' | 'congested' | 'normal' | 'low';
  statusText: string;
  rating: number;
  capacity: number;
  pendingOrders: number;
}

export interface Payout {
  id: string;
  recipient: string;
  recipientId: string;
  avatarText: string;
  type: string;
  status: 'completed' | 'processing' | 'failed';
  amount: number;
}

export interface AuditLog {
  id: string;
  user: string;
  avatarUrl?: string;
  avatarText?: string;
  action: string;
  resource: string;
  severity: 'critical' | 'warning' | 'info';
  timestamp: string;
  ip: string;
  details: {
    userAgent?: string;
    location?: string;
    attemptCount?: number;
    meta?: Record<string, any>;
    change?: {
      before: string;
      after: string;
    };
    description?: string;
  };
}

export interface MetricCard {
  title: string;
  value: string;
  trend: string;
  trendType: 'up' | 'down';
  timeframe: string;
}
