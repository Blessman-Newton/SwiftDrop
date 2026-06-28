import React, { useState } from 'react';
import { 
  Download, 
  Filter, 
  Search, 
  Calendar, 
  ChevronRight, 
  ChevronLeft,
  ChevronDown,
  ChevronUp,
  Info,
  Code,
  History,
  ShieldCheck,
  AlertTriangle,
  InfoIcon,
  CheckCircle2,
  Lock,
  ArrowRight
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { AuditLog } from '../types';

export default function AuditSecurityView() {
  const [searchQuery, setSearchQuery] = useState('');
  const [activeChip, setActiveChip] = useState<'all' | 'security' | 'financial' | 'account' | 'system'>('all');
  const [expandedLogId, setExpandedLogId] = useState<string | null>(null);

  // Initial audit and security logs
  const [logs, setLogs] = useState<AuditLog[]>([
    {
      id: '1',
      user: 'Sarah Connor',
      avatarText: 'SC',
      action: 'Failed Login Attempt (Brute Force)',
      resource: 'Auth_Portal',
      severity: 'critical',
      timestamp: '2 mins ago',
      ip: '192.168.1.104',
      details: {
        userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        location: 'Berlin, Germany',
        attemptCount: 15,
        meta: { event: "AUTH_FAILED", ip: "192.168.1.104", origin: "vpn", action: "block_user" }
      }
    },
    {
      id: '2',
      user: 'Marcus Sterling',
      avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB7uHlJaXWXgZwPsOGNYK6_Uc_UziTVR3_6g60Rum7ejZA5h16qSYr2hOikdG_6D1uurMsALlOaGmudenwLip4Ke46gYnBJCMNv2WyJhEXRrdedHYoqwGrl5uOVpcJ-2-_UkaHjNi4ALqRuVtOtdSue-NfRw_h5NsXcf6dVc5Leq77PbObPxsGDanG8GNe5QsjRZGR6spIU-yxxmkKU3ube7-O0Y5mXrta4s3zHZZQ1K7gffE2EgO014VfHsMGHjDOL9rLdAjaoKXg',
      action: 'Updated Payout Schedule',
      resource: 'Fin_Core_API',
      severity: 'info',
      timestamp: 'Today, 10:42 AM',
      ip: '10.0.0.15',
      details: {
        change: {
          before: 'payout_interval: "WEEKLY"',
          after: 'payout_interval: "DAILY"'
        },
        description: 'Manual scheduler override initiated. Auth Token signature checked and validated.'
      }
    },
    {
      id: '3',
      user: 'System Process',
      avatarText: 'SYS',
      action: 'Database Schema Migration',
      resource: 'DB_Cluster_Main',
      severity: 'warning',
      timestamp: 'Yesterday, 11:15 PM',
      ip: 'AWS_REGION_US_1',
      details: {
        description: 'Successful table alter mapping on "deliveries_v3". CPU Load peaked at 48% during transaction index allocation.',
        meta: { batch_id: "77x-88y", latency_ms: 1420 }
      }
    },
    {
      id: '4',
      user: 'Elena Ricci',
      avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDlc4PM6KLPyF0W6Bt76WG0_iSr2g7NWhgC_80obwAE3stKNgWJq7r63W62cHCjnqmhMbuwBBayjAHRq_ap2kwxQOJuahBKJucS1frpCvl3nhnOo775eY1dSHi02AshniHEn6hNHeIt7fqiQm8eNdkWUtJv6FW3YvRP6EM5_-cUt7wTQvbRrIwhToSn_45_zDSDppKW4w2WPBEZOm3_lgGQizVikNRKwh2z2_EHJiXR5DXxEpKK7Zj3Njgj3QrILTkDSsdIAzAhgu4',
      action: 'Created New Merchant Account',
      resource: 'Admin_Console',
      severity: 'info',
      timestamp: '2 days ago',
      ip: '172.20.10.2',
      details: {
        description: 'Provisioned merchant account ID: 55210 for partner restaurant: "Green Garden Deli". API client tokens generated.',
        meta: { merchant_id: "55210", company: "Green Garden Deli" }
      }
    }
  ]);

  // Handle click on row to toggle drawer
  const toggleRow = (id: string) => {
    setExpandedLogId(prevId => prevId === id ? null : id);
  };

  // Filter logs by search and active category tab
  const filteredLogs = logs.filter(log => {
    // Category check
    if (activeChip === 'security' && log.severity !== 'critical') {
      if (log.resource !== 'Auth_Portal') return false;
    }
    if (activeChip === 'financial' && log.resource !== 'Fin_Core_API') return false;
    if (activeChip === 'account' && log.resource !== 'Admin_Console') return false;
    if (activeChip === 'system' && log.resource !== 'DB_Cluster_Main') return false;

    // Search query check
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      return (
        log.user.toLowerCase().includes(q) ||
        log.action.toLowerCase().includes(q) ||
        log.resource.toLowerCase().includes(q) ||
        log.ip.toLowerCase().includes(q)
      );
    }
    return true;
  });

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-12">
      
      {/* 1. Header & Quick Actions */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-surface-container-low/40 p-4 rounded-2xl border border-outline-variant/20">
        <div>
          <span className="text-xs text-outline font-semibold">Ledger & Access Logs</span>
          <p className="text-sm font-bold text-on-surface mt-0.5">Real-time system telemetry audits</p>
        </div>
        <div className="flex gap-2">
          <button className="flex items-center gap-1.5 bg-surface-container-high dark:bg-surface-container text-on-surface px-4 py-2.5 rounded-xl font-bold text-xs hover:bg-surface-container-highest transition-all active:scale-95 cursor-pointer border border-outline-variant/30">
            <Download className="w-4 h-4 text-outline" />
            <span>Export Logs</span>
          </button>
          <button className="flex items-center gap-1.5 bg-primary text-on-primary px-4 py-2.5 rounded-xl font-bold text-xs hover:bg-primary-hover transition-all active:scale-95 cursor-pointer shadow-sm">
            <Filter className="w-4 h-4" />
            <span>Advanced Filters</span>
          </button>
        </div>
      </div>

      {/* 2. Search & Chip Filters Panel */}
      <div className="bg-surface-container-lowest dark:bg-surface-container-low p-4 rounded-2xl border border-outline-variant/20 shadow-sm space-y-4">
        {/* Search Bar */}
        <div className="relative">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4.5 h-4.5 text-outline pointer-events-none" />
          <input 
            type="text"
            placeholder="Search logs by operator, action, system resource or IP address..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-11 pr-4 py-3 bg-surface-container-low dark:bg-surface-container/40 rounded-xl text-sm border-none text-on-surface placeholder-outline/60 focus:outline-none focus:ring-2 focus:ring-primary focus:bg-surface-container-lowest"
          />
        </div>

        {/* Chip Selectors */}
        <div className="flex flex-wrap items-center gap-2">
          {[
            { id: 'all', label: 'All Logs' },
            { id: 'security', label: 'Security' },
            { id: 'financial', label: 'Financial' },
            { id: 'account', label: 'Account' },
            { id: 'system', label: 'System' }
          ].map((chip) => (
            <button
              key={chip.id}
              onClick={() => setActiveChip(chip.id as any)}
              className={`px-3.5 py-1.5 rounded-full text-xs font-semibold transition-all cursor-pointer ${
                activeChip === chip.id 
                  ? 'bg-primary text-on-primary shadow-sm' 
                  : 'bg-surface-container-low dark:bg-surface-container hover:bg-surface-container-high text-on-surface-variant'
              }`}
            >
              {chip.label}
            </button>
          ))}
          <div className="h-5 w-[1px] bg-outline-variant/30 mx-1 hidden sm:block"></div>
          <button className="flex items-center gap-1.5 text-primary text-xs font-bold hover:underline cursor-pointer">
            <Calendar className="w-3.5 h-3.5" />
            <span>Last 24 Hours</span>
          </button>
        </div>
      </div>

      {/* 3. Log list grid */}
      <div className="bg-surface-container-lowest dark:bg-surface-container-low rounded-2xl border border-outline-variant/25 shadow-sm overflow-hidden">
        {/* Header Column Labels */}
        <div className="hidden md:grid grid-cols-12 gap-4 px-5 py-3 border-b border-outline-variant/20 bg-surface-container-low/40 text-[10px] font-bold text-outline uppercase tracking-wider">
          <div className="col-span-5 flex items-center gap-1">
            <span>User & Action</span>
            <ChevronDown className="w-3.5 h-3.5" />
          </div>
          <div className="col-span-2">Resource</div>
          <div className="col-span-2">Severity</div>
          <div className="col-span-2">Timestamp</div>
          <div className="col-span-1 text-right">Metadata</div>
        </div>

        {/* Rows */}
        <div className="divide-y divide-outline-variant/15">
          {filteredLogs.map((log) => {
            const isExpanded = expandedLogId === log.id;
            return (
              <div 
                key={log.id}
                className="transition-all duration-200"
              >
                {/* Row Trigger */}
                <div 
                  onClick={() => toggleRow(log.id)}
                  className={`grid grid-cols-1 md:grid-cols-12 gap-4 px-5 py-4 items-center cursor-pointer transition-colors ${
                    isExpanded ? 'bg-primary/5 dark:bg-primary/10' : 'hover:bg-primary/5'
                  }`}
                >
                  {/* User & Action */}
                  <div className="col-span-1 md:col-span-5 flex items-center gap-3">
                    {/* User profile / Icon */}
                    {log.avatarUrl ? (
                      <div className="w-9 h-9 rounded-full overflow-hidden shrink-0 border border-outline-variant/20">
                        <img src={log.avatarUrl} alt={log.user} className="w-full h-full object-cover" referrerPolicy="no-referrer" />
                      </div>
                    ) : (
                      <div className={`w-9 h-9 rounded-full flex items-center justify-center shrink-0 font-bold text-xs ${
                        log.severity === 'critical' ? 'bg-error-container text-on-error-container' : 'bg-surface-container-high dark:bg-surface-container text-on-surface'
                      }`}>
                        {log.avatarText}
                      </div>
                    )}
                    <div className="min-w-0">
                      <p className="font-bold text-xs text-on-surface truncate">{log.user}</p>
                      <p className="text-[11px] text-on-surface-variant font-medium mt-0.5 truncate">{log.action}</p>
                    </div>
                  </div>

                  {/* Resource */}
                  <div className="col-span-1 md:col-span-2 text-xs font-semibold text-on-surface-variant md:block flex justify-between">
                    <span className="md:hidden text-outline uppercase text-[10px]">Resource:</span>
                    <span>{log.resource}</span>
                  </div>

                  {/* Severity */}
                  <div className="col-span-1 md:col-span-2 md:block flex justify-between">
                    <span className="md:hidden text-outline uppercase text-[10px]">Severity:</span>
                    <span className={`px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-wider ${
                      log.severity === 'critical' ? 'bg-error/15 text-error' :
                      log.severity === 'warning' ? 'bg-tertiary/10 text-tertiary' :
                      'bg-primary-container/20 text-on-primary-container'
                    }`}>
                      {log.severity}
                    </span>
                  </div>

                  {/* Timestamp */}
                  <div className="col-span-1 md:col-span-2 text-[11px] text-on-surface-variant md:block flex justify-between">
                    <span className="md:hidden text-outline uppercase text-[10px]">Time:</span>
                    <span>{log.timestamp}</span>
                  </div>

                  {/* IP/Meta (Right aligned) */}
                  <div className="col-span-1 md:col-span-1 md:text-right text-[11px] font-mono text-outline md:block flex justify-between">
                    <span className="md:hidden text-outline uppercase text-[10px]">Metadata:</span>
                    <span className="flex items-center md:justify-end gap-1 group-hover:text-primary transition-colors">
                      {log.ip}
                      {isExpanded ? <ChevronUp className="w-3.5 h-3.5" /> : <ChevronDown className="w-3.5 h-3.5" />}
                    </span>
                  </div>
                </div>

                {/* Expanded Details Drawer */}
                <AnimatePresence>
                  {isExpanded && (
                    <motion.div 
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: 'auto', opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      className="overflow-hidden bg-surface-container-low/40 dark:bg-surface-container/20 border-t border-b border-outline-variant/15"
                    >
                      <div className="p-5 grid grid-cols-1 md:grid-cols-2 gap-6">
                        
                        {/* Details parameters */}
                        <div className="space-y-3">
                          <h4 className="text-xs font-bold text-on-surface flex items-center gap-1.5 pb-1 border-b border-outline-variant/20 uppercase tracking-wide">
                            <InfoIcon className="w-4 h-4 text-primary" />
                            <span>Event Audit Trails</span>
                          </h4>

                          <ul className="space-y-2 text-xs font-semibold text-on-surface-variant">
                            {log.details.userAgent && (
                              <li className="flex flex-col gap-1">
                                <span className="text-[10px] text-outline uppercase">User Agent</span>
                                <span className="text-on-surface leading-normal bg-surface-container-low p-2 rounded-xl text-[11px] break-all">{log.details.userAgent}</span>
                              </li>
                            )}
                            {log.details.location && (
                              <li className="flex justify-between items-center bg-surface-container-low p-2 rounded-xl">
                                <span className="text-[10px] text-outline uppercase">Login Location</span>
                                <span className="text-on-surface text-xs font-bold">{log.details.location}</span>
                              </li>
                            )}
                            {log.details.attemptCount && (
                              <li className="flex justify-between items-center bg-error/5 p-2 rounded-xl border border-error/15">
                                <span className="text-[10px] text-error uppercase">Consecutive Fails</span>
                                <span className="text-error text-xs font-black">{log.details.attemptCount} Attempts</span>
                              </li>
                            )}
                            {log.details.description && (
                              <li className="flex flex-col gap-1 bg-surface-container-low p-3 rounded-xl">
                                <span className="text-[10px] text-outline uppercase">Activity Description</span>
                                <span className="text-on-surface leading-normal">{log.details.description}</span>
                              </li>
                            )}

                            {/* Configuration delta check */}
                            {log.details.change && (
                              <li className="space-y-2">
                                <span className="text-[10px] text-outline uppercase block">Configuration Change Log</span>
                                <div className="flex items-center gap-3">
                                  <div className="flex-1 bg-error/5 p-2 rounded-xl border border-error/10">
                                    <span className="text-[9px] text-error font-black uppercase">Before</span>
                                    <p className="text-[11px] font-mono text-on-surface-variant mt-1">{log.details.change.before}</p>
                                  </div>
                                  <ArrowRight className="w-4 h-4 text-outline" />
                                  <div className="flex-1 bg-primary/5 p-2 rounded-xl border border-primary/10">
                                    <span className="text-[9px] text-primary font-black uppercase">After</span>
                                    <p className="text-[11px] font-mono text-primary font-bold mt-1">{log.details.change.after}</p>
                                  </div>
                                </div>
                              </li>
                            )}
                          </ul>
                        </div>

                        {/* Payload JSON display */}
                        <div>
                          <h4 className="text-xs font-bold text-on-surface flex items-center gap-1.5 pb-1 border-b border-outline-variant/20 uppercase tracking-wide mb-3">
                            <Code className="w-4 h-4 text-primary" />
                            <span>Raw JSON Context</span>
                          </h4>

                          <div className="bg-on-background dark:bg-black/80 text-primary-fixed-dim font-mono text-[10px] p-4 rounded-2xl overflow-x-auto shadow-inner leading-relaxed border border-outline-variant/20">
                            {JSON.stringify(log.details.meta || { id: log.id, action: log.action, resource: log.resource, ip: log.ip, severity: log.severity }, null, 2)}
                          </div>
                        </div>

                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            );
          })}
        </div>

        {/* Table pagination footer */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 px-5 py-4 bg-surface-container-low/20 border-t border-outline-variant/20">
          <p className="text-xs text-on-surface-variant">
            Showing <span className="font-bold text-on-surface">1-{filteredLogs.length}</span> of <span className="font-bold text-on-surface">{logs.length}</span> ledger entries
          </p>

          <div className="flex items-center gap-1">
            <button className="p-1.5 rounded-lg border border-outline-variant/30 text-on-surface-variant hover:bg-surface-container-low cursor-pointer disabled:opacity-30 disabled:pointer-events-none" disabled>
              <ChevronLeft className="w-4 h-4" />
            </button>
            <button className="px-3 py-1 text-xs font-bold bg-primary text-on-primary rounded-lg">1</button>
            <button className="px-3 py-1 text-xs font-bold hover:bg-surface-container-low rounded-lg text-on-surface-variant">2</button>
            <button className="px-3 py-1 text-xs font-bold hover:bg-surface-container-low rounded-lg text-on-surface-variant">3</button>
            <span className="text-outline text-xs px-1">...</span>
            <button className="px-3 py-1 text-xs font-bold hover:bg-surface-container-low rounded-lg text-on-surface-variant">124</button>
            <button className="p-1.5 rounded-lg border border-outline-variant/30 text-on-surface-variant hover:bg-surface-container-low cursor-pointer">
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

    </div>
  );
}
