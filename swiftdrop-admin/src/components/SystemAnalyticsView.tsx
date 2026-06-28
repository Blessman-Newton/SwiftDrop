import React, { useState } from 'react';
import { 
  Timer, 
  Map, 
  CheckCircle, 
  FileSpreadsheet, 
  ChevronDown, 
  Zap, 
  Cpu, 
  AlertOctagon,
  Sparkles,
  TrendingDown,
  TrendingUp,
  RotateCcw,
  Clock
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

export default function SystemAnalyticsView() {
  const [timeframe, setTimeframe] = useState<'30' | '90' | '180'>('30');
  const [hoveredCell, setHoveredCell] = useState<{ row: string; col: number } | null>(null);

  // Cohort retention decay dataset mapping
  const initialCohortData = {
    '30': [
      { cohort: 'Jan 2024', users: '12,450', m1: '100%', m2: '78%', m3: '64%', m4: '52%' },
      { cohort: 'Feb 2024', users: '15,200', m1: '100%', m2: '82%', m3: '69%', m4: '--' },
      { cohort: 'Mar 2024', users: '18,100', m1: '100%', m2: '85%', m3: '--', m4: '--' }
    ],
    '90': [
      { cohort: 'Oct 2023', users: '10,120', m1: '100%', m2: '71%', m3: '59%', m4: '48%' },
      { cohort: 'Nov 2023', users: '11,400', m1: '100%', m2: '74%', m3: '61%', m4: '50%' },
      { cohort: 'Dec 2023', users: '13,900', m1: '100%', m2: '79%', m3: '66%', m4: '55%' }
    ],
    '180': [
      { cohort: 'May 2023', users: '8,200', m1: '100%', m2: '65%', m3: '51%', m4: '40%' },
      { cohort: 'Jun 2023', users: '9,100', m1: '100%', m2: '68%', m3: '54%', m4: '42%' },
      { cohort: 'Jul 2023', users: '9,850', m1: '100%', m2: '70%', m3: '58%', m4: '46%' }
    ]
  };

  const activeCohort = initialCohortData[timeframe] || initialCohortData['30'];

  // Heatmap rows
  const heatmapRows = [
    { name: 'Downtown', cells: [0.1, 0.3, 0.6, 0.9, 0.8, 0.5, 0.2] },
    { name: 'Suburbs', cells: [0.2, 0.4, 0.3, 0.2, 0.6, 0.8, 0.4] },
    { name: 'Tech Park', cells: [0.05, 0.1, 0.8, 0.9, 0.6, 0.1, 0.05] }
  ];

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-12">
      
      {/* 1. Filter Timeline Toolbar */}
      <section className="flex flex-col md:flex-row justify-between items-start md:items-center gap-3 bg-surface-container-low/40 p-4 rounded-2xl border border-outline-variant/20">
        <div>
          <h2 className="text-lg font-bold text-on-surface">System Performance Auditing</h2>
          <p className="text-xs text-on-surface-variant">Real-time cohort decays & SLA latency maps</p>
        </div>
        <div className="relative">
          <select 
            value={timeframe}
            onChange={(e) => setTimeframe(e.target.value as any)}
            className="appearance-none bg-surface-container dark:bg-surface-container-low border border-outline-variant/30 text-on-surface text-xs font-semibold px-4 py-2 pr-8 rounded-full focus:outline-none cursor-pointer focus:border-primary"
          >
            <option value="30">Last 30 Days</option>
            <option value="90">Last 90 Days</option>
            <option value="180">Last 180 Days</option>
          </select>
          <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-outline pointer-events-none" />
        </div>
      </section>

      {/* 2. Operational Efficiency: Bento Stats */}
      <section className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* Avg Pickup Time */}
        <div className="bg-surface-container-lowest dark:bg-surface-container-low p-5 rounded-2xl shadow-sm border border-outline-variant/20 flex flex-col justify-between h-40">
          <div className="flex justify-between items-start">
            <div>
              <p className="text-on-surface-variant text-xs font-bold uppercase tracking-wider mb-1">Avg Pickup Time</p>
              <h3 className="text-3xl font-extrabold text-on-surface">6.4 <span className="text-sm font-normal text-outline">min</span></h3>
            </div>
            <div className="bg-primary/10 p-2.5 rounded-xl text-primary">
              <Timer className="w-5 h-5" />
            </div>
          </div>
          <div className="flex items-center gap-1 text-primary text-xs font-bold">
            <TrendingDown className="w-4 h-4" />
            <span>-1.2m vs last period</span>
          </div>
        </div>

        {/* Avg Dropoff Time */}
        <div className="bg-surface-container-lowest dark:bg-surface-container-low p-5 rounded-2xl shadow-sm border border-outline-variant/20 flex flex-col justify-between h-40">
          <div className="flex justify-between items-start">
            <div>
              <p className="text-on-surface-variant text-xs font-bold uppercase tracking-wider mb-1">Avg Dropoff Time</p>
              <h3 className="text-3xl font-extrabold text-on-surface">18.2 <span className="text-sm font-normal text-outline">min</span></h3>
            </div>
            <div className="bg-tertiary-container/10 p-2.5 rounded-xl text-tertiary">
              <Map className="w-5 h-5" />
            </div>
          </div>
          <div className="flex items-center gap-1 text-primary text-xs font-bold">
            <TrendingDown className="w-4 h-4" />
            <span>-0.8m vs last period</span>
          </div>
        </div>

        {/* SLA Adherence */}
        <div className="bg-surface-container-lowest dark:bg-surface-container-low p-5 rounded-2xl shadow-sm border border-outline-variant/20 flex flex-col justify-between h-40">
          <div className="flex justify-between items-start">
            <div>
              <p className="text-on-surface-variant text-xs font-bold uppercase tracking-wider mb-1">SLA Adherence</p>
              <h3 className="text-3xl font-extrabold text-on-surface">98.4 <span className="text-sm font-normal text-outline">%</span></h3>
            </div>
            <div className="bg-primary-container/15 p-2.5 rounded-xl text-on-primary-container">
              <CheckCircle className="w-5 h-5" />
            </div>
          </div>
          <div className="flex items-center gap-1 text-primary text-xs font-bold">
            <TrendingUp className="w-4 h-4" />
            <span>+2.1% vs last period</span>
          </div>
        </div>
      </section>

      {/* 3. Main Data Visualizations Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        
        {/* Customer Retention Cohort Table */}
        <div className="lg:col-span-7 bg-surface-container-lowest dark:bg-surface-container-low p-6 rounded-2xl shadow-sm border border-outline-variant/20 flex flex-col justify-between">
          <div>
            <div className="flex justify-between items-center mb-6">
              <h4 className="text-base font-bold text-on-surface">Customer Retention Cohort</h4>
              <button className="text-primary font-bold text-xs flex items-center gap-1 hover:underline cursor-pointer">
                Download CSV <FileSpreadsheet className="w-4 h-4" />
              </button>
            </div>
            
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="text-outline text-xs font-bold border-b border-outline-variant/20">
                    <th className="pb-3 pr-4 uppercase tracking-wider">Cohort</th>
                    <th className="pb-3 px-2 uppercase tracking-wider">Users</th>
                    <th className="pb-3 px-2 uppercase tracking-wider text-center">M1</th>
                    <th className="pb-3 px-2 uppercase tracking-wider text-center">M2</th>
                    <th className="pb-3 px-2 uppercase tracking-wider text-center">M3</th>
                    <th className="pb-3 px-2 uppercase tracking-wider text-center">M4</th>
                  </tr>
                </thead>
                <tbody className="text-xs font-bold text-on-surface divide-y divide-outline-variant/10">
                  {activeCohort.map((row, idx) => (
                    <tr key={idx}>
                      <td className="py-4 pr-4 font-black">{row.cohort}</td>
                      <td className="py-4 px-2 text-on-surface-variant font-medium">{row.users}</td>
                      
                      <td className="py-2 px-1">
                        <div className="bg-primary text-on-primary rounded-lg py-2 text-center text-[10px] shadow-sm">
                          {row.m1}
                        </div>
                      </td>
                      
                      <td className="py-2 px-1">
                        <div className="bg-primary/70 text-on-primary rounded-lg py-2 text-center text-[10px]">
                          {row.m2}
                        </div>
                      </td>

                      <td className="py-2 px-1">
                        <div className={`rounded-lg py-2 text-center text-[10px] ${
                          row.m3 === '--' ? 'bg-surface-container text-outline/60' : 'bg-primary/50 text-on-primary'
                        }`}>
                          {row.m3}
                        </div>
                      </td>

                      <td className="py-2 px-1">
                        <div className={`rounded-lg py-2 text-center text-[10px] ${
                          row.m4 === '--' ? 'bg-surface-container text-outline/60' : 'bg-primary/30 text-on-primary'
                        }`}>
                          {row.m4}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Peak Demand Heatmap */}
        <div className="lg:col-span-5 bg-surface-container-lowest dark:bg-surface-container-low p-6 rounded-2xl shadow-sm border border-outline-variant/20 flex flex-col justify-between">
          <div>
            <h4 className="text-base font-bold text-on-surface mb-2">Peak Demand Periods</h4>
            <p className="text-[11px] text-on-surface-variant mb-4">Traffic load distribution map (08:00 — 22:00)</p>

            <div className="space-y-4">
              {heatmapRows.map((row) => (
                <div key={row.name} className="flex items-center gap-3">
                  <span className="w-16 text-xs font-bold text-on-surface-variant">{row.name}</span>
                  <div className="flex-1 h-8 flex gap-1.5">
                    {row.cells.map((weight, idx) => (
                      <div 
                        key={idx}
                        onMouseEnter={() => setHoveredCell({ row: row.name, col: idx })}
                        onMouseLeave={() => setHoveredCell(null)}
                        className="flex-1 rounded-md transition-all duration-300 relative cursor-pointer"
                        style={{ 
                          backgroundColor: 'var(--primary)',
                          opacity: weight,
                          transform: hoveredCell?.row === row.name && hoveredCell?.col === idx ? 'scale(1.15)' : 'scale(1)',
                          zIndex: hoveredCell?.row === row.name && hoveredCell?.col === idx ? 10 : 1
                        }}
                      >
                        {/* Interactive Demand weight indicator popup */}
                        {hoveredCell?.row === row.name && hoveredCell?.col === idx && (
                          <div className="absolute -top-10 left-1/2 -translate-x-1/2 bg-on-surface text-surface-container-lowest text-[9px] font-black px-1.5 py-0.5 rounded shadow whitespace-nowrap z-30">
                            {(weight * 100).toFixed(0)}% load
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Legend */}
          <div className="flex justify-end items-center gap-3 mt-6 pt-4 border-t border-outline-variant/15">
            <span className="text-[10px] font-bold text-outline uppercase">Low</span>
            <div className="flex h-2.5 w-24 rounded-full overflow-hidden">
              <div className="h-full w-1/4 bg-primary" style={{ opacity: 0.1 }}></div>
              <div className="h-full w-1/4 bg-primary" style={{ opacity: 0.4 }}></div>
              <div className="h-full w-1/4 bg-primary" style={{ opacity: 0.7 }}></div>
              <div className="h-full w-1/4 bg-primary" style={{ opacity: 0.95 }}></div>
            </div>
            <span className="text-[10px] font-bold text-outline uppercase">Peak</span>
          </div>
        </div>

      </div>

      {/* 4. System Infrastructure Health (Dark Slate Container) */}
      <section className="bg-inverse-surface text-inverse-on-surface p-6 rounded-2xl relative overflow-hidden shadow-lg">
        {/* Ambient absolute layer design */}
        <div className="absolute right-0 top-0 h-full w-1/3 opacity-15 pointer-events-none bg-gradient-to-l from-primary-container to-transparent"></div>
        
        <h4 className="text-base font-extrabold mb-5 relative z-10 flex items-center gap-2">
          <Cpu className="text-primary-container w-5 h-5 animate-spin" style={{ animationDuration: '6s' }} />
          <span>System Infrastructure Health</span>
        </h4>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 relative z-10">
          
          {/* API Latency */}
          <div className="space-y-2">
            <p className="text-[10px] font-black opacity-70 tracking-wider uppercase">API Latency (p95)</p>
            <div className="flex items-end gap-2">
              <span className="text-3xl font-black">124ms</span>
              <span className="text-primary-container text-xs font-bold mb-1 flex items-center">
                <TrendingDown className="w-3.5 h-3.5" />
                -8%
              </span>
            </div>
            <div className="w-full h-1 bg-white/10 rounded-full overflow-hidden">
              <div className="w-[75%] h-full bg-primary-container rounded-full"></div>
            </div>
          </div>

          {/* Uptime */}
          <div className="space-y-2">
            <p className="text-[10px] font-black opacity-70 tracking-wider uppercase">App Uptime</p>
            <div className="flex items-end gap-2">
              <span className="text-3xl font-black">99.998%</span>
              <span className="text-primary-container text-xs font-bold mb-1">STABLE</span>
            </div>
            <div className="w-full h-1 bg-white/10 rounded-full overflow-hidden">
              <div className="w-[99%] h-full bg-primary-container rounded-full"></div>
            </div>
          </div>

          {/* Error Rate */}
          <div className="space-y-2">
            <p className="text-[10px] font-black opacity-70 tracking-wider uppercase">Error Rate</p>
            <div className="flex items-end gap-2">
              <span className="text-3xl font-black text-error-container">0.042%</span>
              <span className="text-error-container text-xs font-bold mb-1 flex items-center">
                <AlertOctagon className="w-3.5 h-3.5" />
                +0.001
              </span>
            </div>
            <div className="w-full h-1 bg-white/10 rounded-full overflow-hidden">
              <div className="w-[5%] h-full bg-error rounded-full"></div>
            </div>
          </div>

        </div>
      </section>

      {/* 5. Comparative Insights Summary */}
      <section className="bg-surface-container-high dark:bg-surface-container/30 p-6 rounded-2xl border border-outline-variant/30">
        <h4 className="font-extrabold text-base text-on-surface mb-4">Operational Highlights</h4>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 shrink-0 bg-surface-container-lowest dark:bg-surface-container-low rounded-full flex items-center justify-center text-primary shadow-sm">
              <TrendingUp className="w-5 h-5" />
            </div>
            <div>
              <p className="font-bold text-sm text-on-surface">Fleet Growth Acceleration</p>
              <p className="text-on-surface-variant text-xs leading-relaxed mt-1">
                Onboarded 420 new delivery drivers this month, maintaining an 85% background clearance pass rate. Average driver earnings elevated by 12% across all sectors.
              </p>
            </div>
          </div>

          <div className="flex items-start gap-4">
            <div className="w-12 h-12 shrink-0 bg-surface-container-lowest dark:bg-surface-container-low rounded-full flex items-center justify-center text-tertiary shadow-sm">
              <Sparkles className="w-5 h-5" />
            </div>
            <div>
              <p className="font-bold text-sm text-on-surface">Routing Optimization Impact</p>
              <p className="text-on-surface-variant text-xs leading-relaxed mt-1">
                Successful integration of V3 Dynamic Fleet Routing into downtown grids reduced fossil load by 9% and slashed late drop-offs by 14% since early Monday.
              </p>
            </div>
          </div>
        </div>
      </section>

    </div>
  );
}
