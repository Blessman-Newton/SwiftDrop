import requests

BASE_URL = 'http://localhost:8000/api/v1'

# Login as rider
rider_login = requests.post(f'{BASE_URL}/auth/login', json={
    'email': 'newrider@swiftdrop.com',
    'password': 'Rider123'
})
rider_token = rider_login.json()['access_token']

# Go online
requests.post(f'{BASE_URL}/riders/online',
    headers={'Authorization': f'Bearer {rider_token}'},
    json={'vehicle_type': 'motorcycle', 'license_number': 'TEST-123'}
)

# Get available orders
available_res = requests.get(f'{BASE_URL}/riders/available-orders',
    headers={'Authorization': f'Bearer {rider_token}'})
available_orders = available_res.json()

print(f'Rider found {len(available_orders)} available orders:')
for order in available_orders:
    print(f"  ID: {order.get('id', 'N/A')}")
    print(f"  Restaurant: {order.get('restaurant_name', 'N/A')}")
    print(f"  Total: GHS {order.get('total', 'N/A')}")
    print(f"  Pickup: {order.get('pickup_address', 'N/A')}")
    print(f"  Delivery: {order.get('delivery_address', 'N/A')}")
    print()

# Check if our specific order is there
target_order_id = 'd6c03405-1311-4269-b477-fddd6ca6bf4d'
found = any(order.get('id') == target_order_id for order in available_orders)
if found:
    print(f"[SUCCESS] Order {target_order_id} is visible to rider!")
else:
    print(f"[NOT FOUND] Order {target_order_id} is NOT visible to rider")
