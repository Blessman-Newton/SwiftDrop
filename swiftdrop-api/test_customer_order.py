import requests
import json

BASE_URL = 'http://localhost:8000/api/v1'

print("=" * 60)
print("STEP 1: Customer places order from Amina's Locals")
print("=" * 60)

# Login as customer
login_res = requests.post(f'{BASE_URL}/auth/login', json={
    'email': 'customer@test.com',
    'password': 'customer123'
})

if login_res.status_code != 200:
    print(f"Customer login failed: {login_res.text}")
    exit(1)

customer_data = login_res.json()
customer_token = customer_data['access_token']
print(f"[OK] Customer logged in: {customer_data['user']['name']}")

# Place order from Amina's Locals
order_res = requests.post(f'{BASE_URL}/orders', 
    headers={'Authorization': f'Bearer {customer_token}'},
    json={
        'order_type': 'food',
        'restaurant_id': 'ffe6acb5-848f-448e-b75f-23fba7dc95a8',  # Amina's Locals
        'restaurant_name': "Amina's Locals",
        'pickup_address': '123 Oxford Street, Accra',
        'delivery_address': '123 Customer Street, Accra',
        'subtotal': 190.0,
        'delivery_fee': 15.0,
        'tax': 19.0,
        'discount': 0.0,
        'total': 224.0,
        'items': [
            {'name': 'Jollof Rice', 'quantity': 2, 'price': 80.0},
            {'name': 'Fufuo', 'quantity': 1, 'price': 30.0}
        ],
        'notes': 'Please deliver quickly'
    }
)

if order_res.status_code != 200:
    print(f"Order failed: {order_res.text}")
    exit(1)

order_data = order_res.json()
print(f"[OK] Order placed successfully!")
print(f"  Order ID: {order_data['id']}")
print(f"  Restaurant: {order_data['restaurant_name']}")
print(f"  Total: GHS {order_data['total']}")
print(f"  Status: {order_data['status']}")
print(f"  Items:")
for item in order_data['items']:
    print(f"    - {item['name']} x{item['quantity']} = GHS {item['price']}")

print("\n" + "=" * 60)
print("STEP 2: Rider checks available orders")
print("=" * 60)

# Login as rider
rider_login_res = requests.post(f'{BASE_URL}/auth/login', json={
    'email': 'newrider@swiftdrop.com',
    'password': 'Rider123'
})

if rider_login_res.status_code != 200:
    print(f"Rider login failed: {rider_login_res.text}")
    exit(1)

rider_data = rider_login_res.json()
rider_token = rider_data['access_token']
print(f"[OK] Rider logged in: {rider_data['user']['name']}")

# Go online
online_res = requests.post(f'{BASE_URL}/riders/online', 
    headers={'Authorization': f'Bearer {rider_token}'},
    json={'vehicle_type': 'motorcycle', 'license_number': 'TEST-123'}
)
print(f"[OK] Rider went online: {online_res.json()['message']}")

# Check available orders
available_res = requests.get(f'{BASE_URL}/riders/available-orders', 
    headers={'Authorization': f'Bearer {rider_token}'}
)

if available_res.status_code != 200:
    print(f"Failed to get available orders: {available_res.text}")
    exit(1)

available_orders = available_res.json()
print(f"\n[OK] Found {len(available_orders)} available orders:")

for i, order in enumerate(available_orders, 1):
    print(f"\n  Order {i}:")
    print(f"    ID: {order['id']}")
    print(f"    Restaurant: {order['restaurant_name']}")
    print(f"    Total: GHS {order['total']}")
    print(f"    Pickup: {order['pickup_address']}")
    print(f"    Delivery: {order['delivery_address']}")

# Check if our new order is in the list
order_ids = [o['id'] for o in available_orders]
if order_data['id'] in order_ids:
    print(f"\n[OK] SUCCESS: New order {order_data['id']} is visible to rider!")
else:
    print(f"\n[WARN] WARNING: New order {order_data['id']} not found in available orders")
    print(f"  Available order IDs: {order_ids}")

print("\n" + "=" * 60)
