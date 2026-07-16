import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/order_service.dart';
import '../services/customer_service.dart';

class GasBookingScreen extends ConsumerStatefulWidget {
  const GasBookingScreen({super.key});

  @override
  ConsumerState<GasBookingScreen> createState() => _GasBookingScreenState();
}

class _HomeScreenGasBanner {} // Dummy token for referencing home screen gas

class _GasBookingScreenState extends ConsumerState<GasBookingScreen> {
  String _selectedSize = '12.5 kg';
  String _fillType = 'Maximum Fill'; // Maximum Fill or Customize Fill
  final _customAmountController = TextEditingController(text: '100');
  
  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _deliveryTime = const TimeOfDay(hour: 14, minute: 0);

  bool _isSubmitting = false;

  final List<String> _sizes = ['6 kg', '12.5 kg', '14 kg', '22 kg', '50 kg'];

  Map<String, double> _gasPrices = {
    '6 kg': 75.0,
    '12.5 kg': 150.0,
    '14 kg': 180.0,
    '22 kg': 280.0,
    '50 kg': 600.0,
  };

  @override
  void initState() {
    super.initState();
    _loadGasPrices();
  }

  Future<void> _loadGasPrices() async {
    final prices = await CustomerService().getGasPrices();
    if (prices != null && prices.isNotEmpty && mounted) {
      setState(() {
        _gasPrices = prices;
      });
    }
  }

  double get _basePrice {
    if (_fillType == 'Customize Fill') {
      return double.tryParse(_customAmountController.text) ?? 0.0;
    }
    return _gasPrices[_selectedSize] ?? 150.0;
  }

  double get _deliveryFee => 15.0;
  double get _totalPrice => _basePrice + _deliveryFee;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _deliveryDate) {
      setState(() {
        _deliveryDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _deliveryTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _deliveryTime) {
      setState(() {
        _deliveryTime = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (_basePrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid fill amount')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final formattedTime = '${_deliveryTime.hour.toString().padLeft(2, '0')}:${_deliveryTime.minute.toString().padLeft(2, '0')}';
      final formattedDate = '${_deliveryDate.year}-${_deliveryDate.month.toString().padLeft(2, '0')}-${_deliveryDate.day.toString().padLeft(2, '0')}';
      
      final orderResult = await OrderService().createOrder(
        orderType: 'parcel',
        restaurantName: 'LPG Gas Depot (Tarkwa)',
        pickupAddress: 'Gas Filling Station Main Depot',
        deliveryAddress: 'Customer Delivery Address (Scheduled)',
        items: [
          {
            'name': 'LPG Refill ($_selectedSize - $_fillType)',
            'quantity': 1,
            'price': _basePrice,
          }
        ],
        subtotal: _basePrice,
        deliveryFee: _deliveryFee,
        tax: 0.0,
        total: _totalPrice,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.primary, size: 28),
                SizedBox(width: 10),
                Text('Booking Successful!'),
              ],
            ),
            content: Text(
              'Your gas refill booking ($_selectedSize) has been scheduled successfully for $formattedDate at $formattedTime.\n\nTotal: ₵${_totalPrice.toStringAsFixed(2)}',
              style: GoogleFonts.inter(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // close dialog
                  context.go('/home'); // back to home
                },
                child: const Text('Back to Home', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scheduling booking: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedDate = '${_deliveryDate.day}/${_deliveryDate.month}/${_deliveryDate.year}';
    final formattedTime = _deliveryTime.format(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'LPG Gas Refill Service',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Card showing cylinder info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SCHEDULED FILLING ONLY',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Safe, Certified LPG Home Refills',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Standardized scales and certified weights.',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.gas_meter, size: 56, color: Colors.white70),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Gas Cylinder Size Selector
            Text(
              'Select Cylinder Size',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _sizes.length,
                separatorBuilder: (c, i) => const SizedBox(width: 10),
                itemBuilder: (c, i) {
                  final size = _sizes[i];
                  final isSelected = _selectedSize == size;
                  return ChoiceChip(
                    label: Text(size, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedSize = size;
                        });
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Fill Option (Maximum or Customize)
            Text(
              'Select Fill Type',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _fillType = 'Maximum Fill'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _fillType == 'Maximum Fill'
                            ? AppColors.primary.withOpacity(0.08)
                            : Colors.white,
                        border: Border.all(
                          color: _fillType == 'Maximum Fill'
                              ? AppColors.primary
                              : Colors.grey.shade200,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.battery_full,
                              color: _fillType == 'Maximum Fill' ? AppColors.primary : Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            'Maximum Fill',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _fillType = 'Customize Fill'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _fillType == 'Customize Fill'
                            ? AppColors.primary.withOpacity(0.08)
                            : Colors.white,
                        border: Border.all(
                          color: _fillType == 'Customize Fill'
                              ? AppColors.primary
                              : Colors.grey.shade200,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.edit_road,
                              color: _fillType == 'Customize Fill' ? AppColors.primary : Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            'Customize Fill',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_fillType == 'Customize Fill') ...[
              Text(
                'Enter Custom Cedi Amount (GHS)',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _customAmountController,
                keyboardType: TextInputType.number,
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  prefixText: '₵ ',
                  hintText: 'Minimum GHS 20.00',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Scheduled Date & Time Selector
            Text(
              'Scheduled Delivery Details',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text('Date', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _selectDate(context),
                        child: Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text('Time Slot', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _selectTime(context),
                        child: Text(formattedTime, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Delivery Speed (Schedule Info)
            Text(
              'Delivery Speed',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Schedule Only (LPG gas fillings are safely handled via scheduled transport orders only).',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Summary List
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Refill Value', style: GoogleFonts.inter(color: Colors.grey.shade600)),
                      Text('₵${_basePrice.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Delivery Service Fee', style: GoogleFonts.inter(color: Colors.grey.shade600)),
                      Text('₵${_deliveryFee.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Estimated Cost', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('₵${_totalPrice.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Booking Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Book Refill Now', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
