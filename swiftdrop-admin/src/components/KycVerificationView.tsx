import React, { useState } from 'react';

type ApplicationStatus = 'Pending' | 'Approved' | 'Rejected';

interface RiderApplication {
  id: string;
  name: string;
  phone: string;
  vehicleType: string;
  licenseNumber: string;
  appliedDate: string;
  status: ApplicationStatus;
}

interface MerchantApplication {
  id: string;
  restaurantName: string;
  ownerName: string;
  address: string;
  type: string;
  appliedDate: string;
  status: ApplicationStatus;
}

const mockRiders: RiderApplication[] = [
  { id: 'r1', name: 'Kwame Mensah', phone: '+233241234567', vehicleType: 'Motorcycle', licenseNumber: 'GL-1234-23', appliedDate: '2026-07-18', status: 'Pending' },
  { id: 'r2', name: 'Ama Osei', phone: '+233551234567', vehicleType: 'Bicycle', licenseNumber: 'N/A', appliedDate: '2026-07-17', status: 'Approved' },
  { id: 'r3', name: 'Kofi Annan', phone: '+233201234567', vehicleType: 'Motorcycle', licenseNumber: 'GL-9876-21', appliedDate: '2026-07-18', status: 'Pending' },
  { id: 'r4', name: 'Yaw Appiah', phone: '+233271234567', vehicleType: 'Car', licenseNumber: 'GR-456-22', appliedDate: '2026-07-16', status: 'Rejected' },
  { id: 'r5', name: 'Abena Yeboah', phone: '+233261234567', vehicleType: 'Motorcycle', licenseNumber: 'GL-3333-24', appliedDate: '2026-07-18', status: 'Pending' },
];

const mockMerchants: MerchantApplication[] = [
  { id: 'm1', restaurantName: 'Taste of Accra', ownerName: 'Esi Mansa', address: 'Osu Oxford Street', type: 'Local', appliedDate: '2026-07-18', status: 'Pending' },
  { id: 'm2', restaurantName: 'Burger Palace', ownerName: 'John Doe', address: 'East Legon', type: 'Fast Food', appliedDate: '2026-07-15', status: 'Approved' },
  { id: 'm3', restaurantName: 'Spicy Bite', ownerName: 'Grace Owusu', address: 'Madina', type: 'Local', appliedDate: '2026-07-17', status: 'Rejected' },
  { id: 'm4', restaurantName: 'Kelewele Hub', ownerName: 'Kwesi Asare', address: 'Cantonments', type: 'Snacks', appliedDate: '2026-07-18', status: 'Pending' },
];

export default function KycVerificationView() {
  const [activeTab, setActiveTab] = useState<'riders' | 'merchants'>('riders');
  const [riders, setRiders] = useState(mockRiders);
  const [merchants, setMerchants] = useState(mockMerchants);

  const handleRiderAction = (id: string, action: 'Approved' | 'Rejected') => {
    if (confirm(`Are you sure you want to ${action.toLowerCase()} this rider?`)) {
      setRiders(prev => prev.map(r => r.id === id ? { ...r, status: action } : r));
    }
  };

  const handleMerchantAction = (id: string, action: 'Approved' | 'Rejected') => {
    if (confirm(`Are you sure you want to ${action.toLowerCase()} this merchant?`)) {
      setMerchants(prev => prev.map(m => m.id === id ? { ...m, status: action } : m));
    }
  };

  const pendingReviews = riders.filter(r => r.status === 'Pending').length + merchants.filter(m => m.status === 'Pending').length;
  const approvedToday = 12; // Mock value
  const rejectedToday = 3; // Mock value
  const totalVerified = 1540; // Mock value

  const getStatusBadge = (status: ApplicationStatus) => {
    const styles = {
      Pending: 'bg-yellow-100 text-yellow-800',
      Approved: 'bg-green-100 text-green-800',
      Rejected: 'bg-red-100 text-red-800',
    };
    return <span className={`px-2 py-1 rounded-full text-xs font-medium ${styles[status]}`}>{status}</span>;
  };

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-gray-900">KYC & Verification Hub</h2>
      
      {/* Stats Row */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
          <p className="text-sm text-gray-500">Pending Reviews</p>
          <p className="text-2xl font-bold text-gray-900 mt-1">{pendingReviews}</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
          <p className="text-sm text-gray-500">Approved Today</p>
          <p className="text-2xl font-bold text-green-600 mt-1">{approvedToday}</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
          <p className="text-sm text-gray-500">Rejected Today</p>
          <p className="text-2xl font-bold text-red-600 mt-1">{rejectedToday}</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
          <p className="text-sm text-gray-500">Total Verified</p>
          <p className="text-2xl font-bold text-primary-600 mt-1">{totalVerified}</p>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-gray-200">
        <button
          className={`px-6 py-3 font-medium text-sm transition-colors ${activeTab === 'riders' ? 'border-b-2 border-primary-600 text-primary-600' : 'text-gray-500 hover:text-gray-700'}`}
          onClick={() => setActiveTab('riders')}
        >
          Rider Applications
        </button>
        <button
          className={`px-6 py-3 font-medium text-sm transition-colors ${activeTab === 'merchants' ? 'border-b-2 border-primary-600 text-primary-600' : 'text-gray-500 hover:text-gray-700'}`}
          onClick={() => setActiveTab('merchants')}
        >
          Merchant Applications
        </button>
      </div>

      {/* Content */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        {activeTab === 'riders' ? (
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Phone</th>
                <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Vehicle Type</th>
                <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">License Number</th>
                <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Applied Date</th>
                <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                <th className="text-right px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {riders.map(rider => (
                <tr key={rider.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{rider.name}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{rider.phone}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{rider.vehicleType}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{rider.licenseNumber}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{rider.appliedDate}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{getStatusBadge(rider.status)}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    {rider.status === 'Pending' && (
                      <div className="flex justify-end gap-2">
                        <button onClick={() => handleRiderAction(rider.id, 'Approved')} className="text-white bg-green-500 hover:bg-green-600 px-3 py-1 rounded-md transition-colors">Approve</button>
                        <button onClick={() => handleRiderAction(rider.id, 'Rejected')} className="text-white bg-red-500 hover:bg-red-600 px-3 py-1 rounded-md transition-colors">Reject</button>
                      </div>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Restaurant Name</th>
                <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Owner Name</th>
                <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Address</th>
                <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
                <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Applied Date</th>
                <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                <th className="text-right px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {merchants.map(merchant => (
                <tr key={merchant.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{merchant.restaurantName}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{merchant.ownerName}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{merchant.address}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{merchant.type}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{merchant.appliedDate}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{getStatusBadge(merchant.status)}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    {merchant.status === 'Pending' && (
                      <div className="flex justify-end gap-2">
                        <button onClick={() => handleMerchantAction(merchant.id, 'Approved')} className="text-white bg-green-500 hover:bg-green-600 px-3 py-1 rounded-md transition-colors">Approve</button>
                        <button onClick={() => handleMerchantAction(merchant.id, 'Rejected')} className="text-white bg-red-500 hover:bg-red-600 px-3 py-1 rounded-md transition-colors">Reject</button>
                      </div>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
