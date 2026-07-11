import requests

BASE_URL = 'http://localhost:8000/api/v1'

# Login as rider with provided credentials
print('Rider logging in...')
login_res = requests.post(f'{BASE_URL}/auth/login', json={
    'email': 'rider@gmail.com',
    'password': 'Rider@123'
})
print(f'Login status: {login_res.status_code}')
print(f'Response: {login_res.text[:500]}')

if login_res.status_code == 200:
    data = login_res.json()
    token = data['access_token']
    headers = {'Authorization': f'Bearer {token}'}
    
    user_name = data['user']['name']
    user_role = data['user']['role']
    print(f'\nRider logged in: {user_name}')
    print(f'Role: {user_role}')
    
    # Go online
    print('\nRider going online...')
    online_res = requests.post(f'{BASE_URL}/riders/online', headers=headers, json={
        'vehicle_type': 'motorcycle',
        'license_number': 'TEST-LIC-123'
    })
    print(f'Online status: {online_res.status_code}')
    print(f'Response: {online_res.json()}')
    
    # Check available orders
    print('\nChecking available orders...')
    available_res = requests.get(f'{BASE_URL}/riders/available-orders', headers=headers)
    print(f'Available orders status: {available_res.status_code}')
    orders = available_res.json()
    print(f'Found {len(orders)} available orders')
    
    if orders:
        order = orders[0]
        print(f'\nOrder details:')
        print(f'  ID: {order["id"]}')
        print(f'  Restaurant: {order["restaurant_name"]}')
        print(f'  Total: GHS {order["total"]}')
        print(f'  Pickup: {order["pickup_address"]}')
        print(f'  Delivery: {order["delivery_address"]}')
        
        # Accept order
        print(f'\nAccepting order...')
        accept_res = requests.post(f'{BASE_URL}/dispatch/{order["id"]}/accept', headers=headers)
        print(f'Accept status: {accept_res.status_code}')
        print(f'Response: {accept_res.json()}')
    else:
        print('No orders available for pickup')
else:
    print('Login failed')
