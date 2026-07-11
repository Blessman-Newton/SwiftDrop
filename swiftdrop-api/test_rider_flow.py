import requests

BASE_URL = 'http://localhost:8000/api/v1'

# Login as new rider
print("Logging in as new rider...")
login_res = requests.post(f'{BASE_URL}/auth/login', json={
    'email': 'newrider@swiftdrop.com',
    'password': 'Rider123'
})

if login_res.status_code != 200:
    print(f"Login failed: {login_res.text}")
    exit(1)

data = login_res.json()
token = data['access_token']
headers = {'Authorization': f'Bearer {token}'}

print(f"Login successful! User: {data['user']['name']}")

# Go online
print("\nGoing online...")
online_res = requests.post(f'{BASE_URL}/riders/online', headers=headers, json={
    'vehicle_type': 'motorcycle',
    'license_number': 'TEST-123'
})
print(f"Status: {online_res.status_code}")
print(f"Response: {online_res.json()}")

# Check available orders
print("\nChecking available orders...")
available_res = requests.get(f'{BASE_URL}/riders/available-orders', headers=headers)
print(f"Status: {available_res.status_code}")
orders = available_res.json()
print(f"Found {len(orders)} available orders")

if orders:
    order = orders[0]
    print(f"\nOrder details:")
    print(f"  ID: {order['id']}")
    print(f"  Restaurant: {order['restaurant_name']}")
    print(f"  Total: GHS {order['total']}")
    print(f"  Pickup: {order['pickup_address']}")
    print(f"  Delivery: {order['delivery_address']}")
    
    # Accept order
    print(f"\nAccepting order...")
    accept_res = requests.post(f'{BASE_URL}/dispatch/{order["id"]}/accept', headers=headers)
    print(f"Status: {accept_res.status_code}")
    print(f"Response: {accept_res.json()}")
    
    if accept_res.status_code == 200:
        # Pick up order
        print("\nPicking up order...")
        pickup_res = requests.put(f'{BASE_URL}/rider-profile/active-delivery/status', 
                                 headers=headers, 
                                 json={'status': 'picked_up'})
        print(f"Status: {pickup_res.status_code}")
        print(f"Response: {pickup_res.json()}")
        
        # Deliver order
        print("\nDelivering order...")
        deliver_res = requests.put(f'{BASE_URL}/rider-profile/active-delivery/status', 
                                  headers=headers, 
                                  json={'status': 'delivered'})
        print(f"Status: {deliver_res.status_code}")
        print(f"Response: {deliver_res.json()}")
else:
    print("No orders available for pickup")
