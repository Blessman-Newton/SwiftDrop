import React, { useState, useMemo } from 'react';

type Role = 'Rider' | 'Merchant';
type PayoutStatus = 'Pending' | 'Approved' | 'Rejected';

interface PayoutRequest {
  id: string;
  requesterName: string;
  role: Role;
  amount: number;
  momoProvider: string;
  momoNumber: string;
  requestedDate: string;
  status: PayoutStatus;
}

const mockPayouts: PayoutRequest[] = [
  { id: 'p1', requesterName: 'Kwame Mensah', role: 'Rider', amount: 150.50, momoProvider: 'MTN', momoNumber: '0241234567', requestedDate: '2026-07-18T09:00:00Z', status: 'Pending' },
  { id: 'p2', requesterName: 'Taste of Accra', role: 'Merchant', amount: 1200.00, momoProvider: 'Vodafone', momoNumber: '0201234567', requestedDate: '2026-07-17T14:30:00Z', status: 'Approved' },
  { id: 'p3', requesterName: 'Ama Osei', role: 'Rider', amount: 85.00, momoProvider: 'AirtelTigo', momoNumber: '0271234567', requestedDate: '2026-07-18T10:15:00Z', status: 'Pending' },
  { id: 'p4', requesterName: 'Burger Palace', role: 'Merchant', amount: 850.25, momoProvider: 'MTN', momoNumber: '0249876543', requestedDate: '2026-07-18T11:45:00Z', status: 'Pending' },
  { id: 'p5', requesterName: 'Yaw Appiah', role: 'Rider', amount: 200.00, momoProvider: 'MTN', momoNumber: '0551234567', requestedDate: '2026-07-16T08:20:00Z', status: 'Rejected' },
  { id: 'p6', requesterName: 'Spicy Bite', role: 'Merchant', amount: 450.00, momoProvider: 'Vodafone', momoNumber: '0501234567', requestedDate: '2026-07-18T12:00:00Z', status: 'Pending' },
  { id: 'p7', requesterName: 'Kofi Annan', role: 'Rider', amount: 110.00, momoProvider: 'AirtelTigo', momoNumber: '0261234567', requestedDate: '2026-07-17T16:00:00Z', status: 'Approved' },
];

export default function PayoutApprovalView() {
  const [payouts, setPayouts] = useState(mockPayouts);
  const [roleFilter, setRoleFilter] = useState<'All' | Role>('All');
  const [statusFilter, setStatusFilter] = useState<'All' | PayoutStatus>('All');

  const filteredPayouts = useMemo(() => {
    return payouts.filter(p => {
      if (roleFilter !== 'All' && p.role !== roleFilter) return false;
      if (statusFilter !== 'All' && p.status !== statusFilter) return false;
      return true;
    });
  }, [payouts, roleFilter, statusFilter]);

  const handleAction = (id: string, action: 'Approved' | 'Rejected') => {
    if (confirm(`Are you sure you want to ${action.toLowerCase()} this payout?`)) {
      setPayouts(prev => prev.map(p => p.id === id ? { ...p, status: action } : p));
    }
  };

  const totalPendingGHS = payouts.filter(p => p.status === 'Pending').reduce((sum, p) => sum + p.amount, 0);
  const approvedThisWeek = 45; // Mock value
  const floatBalance = 15000.00; // Mock value

  const getStatusBadge = (status: PayoutStatus) => {
    const styles = {
      Pending: 'bg-yellow-100 text-yellow-800',
      Approved: 'bg-green-100 text-green-800',
      Rejected: 'bg-red-100 text-red-800',
    };
    return <span className={`px-2 py-1 rounded-full text-xs font-medium ${styles[status]}`}>{status}</span>;
  };

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-gray-900">Payout Approval</h2>
      
      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
          <p className="text-sm text-gray-500">Total Pending Payouts</p>
          <p className="text-2xl font-bold text-gray-900 mt-1">GHS {totalPendingGHS.toFixed(2)}</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
          <p className="text-sm text-gray-500">Approved This Week</p>
          <p className="text-2xl font-bold text-green-600 mt-1">{approvedThisWeek}</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
          <p className="text-sm text-gray-500">System Float Balance</p>
          <p className="text-2xl font-bold text-primary-600 mt-1">GHS {floatBalance.toFixed(2)}</p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex gap-4 items-center bg-white p-4 rounded-xl shadow-sm border border-gray-100">
        <div>
          <label className="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Role</label>
          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value as 'All' | Role)}
            className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 outline-none text-sm"
          >
            <option value="All">All Roles</option>
            <option value="Rider">Rider</option>
            <option value="Merchant">Merchant</option>
          </select>
        </div>
        <div>
          <label className="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Status</label>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as 'All' | PayoutStatus)}
            className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 outline-none text-sm"
          >
            <option value="All">All Statuses</option>
            <option value="Pending">Pending</option>
            <option value="Approved">Approved</option>
            <option value="Rejected">Rejected</option>
          </select>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Requester Name</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Role</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Amount (GHS)</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">MoMo Provider</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">MoMo Number</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Requested Date</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
              <th className="text-right px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {filteredPayouts.map(payout => (
              <tr key={payout.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{payout.requesterName}</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">
                  <span className={`px-2 py-1 rounded-md text-xs font-medium ${payout.role === 'Rider' ? 'bg-blue-100 text-blue-800' : 'bg-purple-100 text-purple-800'}`}>
                    {payout.role}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-bold text-gray-900">{payout.amount.toFixed(2)}</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{payout.momoProvider}</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 font-mono">{payout.momoNumber}</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{new Date(payout.requestedDate).toLocaleString()}</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{getStatusBadge(payout.status)}</td>
                <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  {payout.status === 'Pending' && (
                    <div className="flex justify-end gap-2">
                      <button onClick={() => handleAction(payout.id, 'Approved')} className="text-white bg-green-500 hover:bg-green-600 px-3 py-1 rounded-md transition-colors">Approve</button>
                      <button onClick={() => handleAction(payout.id, 'Rejected')} className="text-white bg-red-500 hover:bg-red-600 px-3 py-1 rounded-md transition-colors">Reject</button>
                    </div>
                  )}
                </td>
              </tr>
            ))}
            {filteredPayouts.length === 0 && (
              <tr>
                <td colSpan={8} className="px-6 py-8 text-center text-sm text-gray-500">No payout requests found matching the filters.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
