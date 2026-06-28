import '../models/models.dart';

final List<ActivityItem> riderActivityItems = [
  ActivityItem(
    id: 'a1',
    merchant: 'The Green Bistro',
    distance: '1.2 km',
    timeAgo: '25 min ago',
    amount: 15.50,
    type: 'restaurant',
  ),
  ActivityItem(
    id: 'a2',
    merchant: 'Central Pharma',
    distance: '0.8 km',
    timeAgo: '1h ago',
    amount: 8.75,
    type: 'pharmacy',
  ),
  ActivityItem(
    id: 'a3',
    merchant: 'Modern Market',
    distance: '2.1 km',
    timeAgo: '2h ago',
    amount: 12.00,
    type: 'grocery',
  ),
];

final List<Transaction> riderTransactions = [
  Transaction(id: 't1', title: 'Order #SD-8291', timestamp: '12:45 PM', amount: 18.40, isBonus: false),
  Transaction(id: 't2', title: 'Bonus: Peak Hour', timestamp: '11:30 AM', amount: 5.00, isBonus: true),
  Transaction(id: 't3', title: 'Order #SD-8284', timestamp: '10:15 AM', amount: 14.20, isBonus: false),
  Transaction(id: 't4', title: 'Order #SD-8276', timestamp: '9:00 AM', amount: 22.80, isBonus: false),
];

final DeliveryInfo currentDelivery = DeliveryInfo(
  orderNo: 'SW-9982',
  items: ['Classic Wagyu Burger', 'Truffle Loaded Fries', 'Craft Lemonade'],
  pickupName: 'The Burger Loft',
  pickupAddress: '455 West Grand Ave',
  dropoffAddress: '123 Oak St',
  dropoffDetails: 'Unit 4B (Gate code: 1234)',
  total: 32.50,
  estimatedTime: '8 mins',
);
