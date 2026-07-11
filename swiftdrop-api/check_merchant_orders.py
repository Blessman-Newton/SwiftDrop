import requests

BASE_URL = 'http://localhost:8000/api/v1'

# Login as merchant
merchant_login = requests.post(f'{BASE_URL}/auth/login', json={
    'email': 'merchant@test.com',
    'password': 'merchant123'
})
merchant_token = merchant_login.json()['access_token']

# Get all merchant orders
orders_res = requests.get(f'{BASE_URL}/merchants/orders', 
    headers={'Authorization': f'Bearer {merchant_token}'})
orders = orders_res.json()

print(f'Merchant has {len(orders)} orders:')
for order in orders:
    print(f"  ID: {order.get('id', 'N/A')}")
    print(f"  Restaurant: {order.get('restaurant_name', order.get('restaurant', 'N/A'))}")
    print(f"  Status: {order.get('status', 'N/A')}")
    print(f"  Total: GHS {order.get('total', 'N/A')}")
    print(f"  Keys: {list(order.keys())}")
    print()
