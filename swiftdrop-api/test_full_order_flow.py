import requests
import json

BASE_URL = 'http://localhost:8000/api/v1'

print("=" * 60)
print("COMPLETE ORDER FLOW TEST")
print("=" * 60)

# Step 1: Customer places order
print("\n[STEP 1] Customer places order from Amina's Locals")
print("-" * 60)

customer_login = requests.post(f'{BASE_URL}/auth/login', json={
    'email': 'customer@test.com',
    'password': 'customer123'
})
customer_token = customer_login.json()['access_token']
print(f"[OK] Customer logged in: {customer_login.json()['user']['name']}")

order_res = requests.post(f'{BASE_URL}/orders', 
    headers={'Authorization': f'Bearer {customer_token}'},
    json={
        'order_type': 'food',
        'restaurant_id': 'ffe6acb5-848f-448e-b75f-23fba7dc95a8',
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

order_data = order_res.json()
order_id = order_data['id']
print(f"[OK] Order placed: {order_id}")
print(f"     Status: {order_data['status']}")
print(f"     Total: GHS {order_data['total']}")

# Step 2: Merchant confirms order
print("\n[STEP 2] Merchant confirms the order")
print("-" * 60)

merchant_login = requests.post(f'{BASE_URL}/auth/login', json={
    'email': 'merchant@test.com',
    'password': 'merchant123'
})
merchant_token = merchant_login.json()['access_token']
print(f"[OK] Merchant logged in: {merchant_login.json()['user']['name']}")

# Get merchant's orders
orders_res = requests.get(f'{BASE_URL}/merchants/orders', 
    headers={'Authorization': f'Bearer {merchant_token}'})
orders = orders_res.json()
print(f"[OK] Merchant has {len(orders)} orders")

# Find our order and confirm it
for order in orders:
    if order['id'] == order_id:
        print(f"[OK] Found order {order_id}")
        print(f"     Current status: {order['status']}")
        
        # Confirm the order
        confirm_res = requests.patch(f'{BASE_URL}/merchants/orders/{order_id}/status',
            headers={'Authorization': f'Bearer {merchant_token}'},
            json={'status': 'confirmed'}
        )
        
        if confirm_res.status_code == 200:
            print(f"[OK] Order confirmed! New status: {confirm_res.json()['status']}")
        else:
            print(f"[ERROR] Failed to confirm: {confirm_res.text}")
        break

# Step 3: Rider checks available orders
print("\n[STEP 3] Rider checks available orders")
print("-" * 60)

rider_login = requests.post(f'{BASE_URL}/auth/login', json={
    'email': 'newrider@swiftdrop.com',
    'password': 'Rider123'
})
rider_token = rider_login.json()['access_token']
print(f"[OK] Rider logged in: {rider_login.json()['user']['name']}")

# Rider goes online
online_res = requests.post(f'{BASE_URL}/riders/online',
    headers={'Authorization': f'Bearer {rider_token}'},
    json={'vehicle_type': 'motorcycle', 'license_number': 'TEST-123'}
)
print(f"[OK] Rider went online")

# Check available orders
available_res = requests.get(f'{BASE_URL}/riders/available-orders',
    headers={'Authorization': f'Bearer {rider_token}'})
available_orders = available_res.json()

print(f"[OK] Found {len(available_orders)} available orders")

# Check if our order is in the list
order_found = False
for order in available_orders:
    if order['id'] == order_id:
        order_found = True
        print(f"\n[SUCCESS] Order {order_id} is now visible to rider!")
        print(f"     Restaurant: {order['restaurant_name']}")
        print(f"     Total: GHS {order['total']}")
        print(f"     Pickup: {order['pickup_address']}")
        print(f"     Delivery: {order['delivery_address']}")
        break

if not order_found:
    print(f"\n[WARN] Order {order_id} not found in available orders")
    print(f"     Available order IDs: {[o['id'] for o in available_orders]}")

print("\n" + "=" * 60)
print("FLOW TEST COMPLETE")
print("=" * 60)
