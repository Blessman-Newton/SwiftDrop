import requests

BASE_URL = 'http://localhost:8000/api/v1'

# Login as customer
customer_login = requests.post(f'{BASE_URL}/auth/login', json={
    'email': 'customer@test.com',
    'password': 'customer123'
})
customer_token = customer_login.json()['access_token']

# Get customer's orders
orders_res = requests.get(f'{BASE_URL}/orders', 
    headers={'Authorization': f'Bearer {customer_token}'})
orders = orders_res.json()

print(f'Customer has {len(orders)} orders:')
for order in orders:
    print(f"  ID: {order.get('id', 'N/A')}")
    print(f"  Restaurant: {order.get('restaurant_name', 'N/A')}")
    print(f"  Status: {order.get('status', 'N/A')}")
    print(f"  Total: GHS {order.get('total', 'N/A')}")
    print()
