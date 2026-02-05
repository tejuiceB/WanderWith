import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/trip_service.dart';
import '../services/auth_service.dart';
import '../models/trip.dart';
import 'trip_dashboard_screen.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final uuid = const Uuid(); 
  
  // Budget Inputs
  String _selectedCurrency = 'USD';
  // Breakdown inputs
  final _breakdownTravel = TextEditingController();
  final _breakdownStay = TextEditingController();
  final _breakdownFood = TextEditingController();
  final _breakdownActivities = TextEditingController();
  final _breakdownOther = TextEditingController();

  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'INR', 'AUD', 'CAD', 'JPY'];

  DateTimeRange? _dateRange;
  bool _isLoading = false;
  bool _isDatesDecided = true; // Default to needing dates

  void _pickDateRange() async {
    final now = DateTime.now();
    // Normalize to start of day to avoid time issues preventing "Today" selection
    final firstDate = DateTime(now.year, now.month, now.day);
    
    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _createTrip() async {
    if (_nameController.text.isEmpty || _locationController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in Name and Location")));
        return;
    }
    
    // If dates decided, require dates
    if (_isDatesDecided && _dateRange == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select dates or uncheck 'Dates Decided'")));
       return;
    }

    setState(() => _isLoading = true);
    
    try {
      final user = Provider.of<AuthService>(context, listen: false).user;
      if (user == null) throw Exception("User not logged in");

      final tripService = TripService();
      // Logic adjusted: Send nulls if not decided
      final startDate = _isDatesDecided ? _dateRange!.start : null;
      final endDate = _isDatesDecided ? _dateRange!.end : null;

      // Validate dates not in past
      if (startDate != null) {
         final now = DateTime.now();
         final today = DateTime(now.year, now.month, now.day);
         if (startDate.isBefore(today)) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trip start date cannot be in the past!")));
             setState(() => _isLoading = false);
             return;
         }
      }

      // Start the create operation
      
      // Simply take total budget from the input
      double totalBudget = double.tryParse(_breakdownOther.text.trim()) ?? 0.0;

      final tripId = await tripService.createTrip(
        name: _nameController.text,
        location: _locationController.text,
        startDate: startDate,
        endDate: endDate,
        isDateDecided: _isDatesDecided,
        creatorUid: user.id,
        budgetCurrency: _selectedCurrency,
        estimatedCost: totalBudget, // Send simple double
      );
      
      // Construct local Trip object for immediate navigation
      final newTrip = Trip(
        id: tripId,
        name: _nameController.text,
        location: _locationController.text,
        startDate: startDate,
        endDate: endDate,
        isDateDecided: _isDatesDecided,
        createdBy: user.id,
        memberIds: [user.id],
        adminIds: [user.id],
        budgetCurrency: _selectedCurrency,
        metadata: {
          'status': 'planning',
          'budgetCurrency': _selectedCurrency,
          'estimated_cost': totalBudget
        }
      );

      if (mounted) setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => TripDashboardScreen(trip: newTrip))
      );

    } catch (e) {
      if (mounted) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Trip")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Trip Name", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: "e.g. Goa with the Boys",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text("Where to?", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: "e.g. Goa, India", 
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Dates", style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Checkbox(
                      value: !_isDatesDecided, 
                      onChanged: (val) {
                         setState(() {
                           _isDatesDecided = !val!;
                           if (!_isDatesDecided) _dateRange = null; // Clear dates if "Not decided"
                         });
                      }
                    ),
                    const Text("Not decided yet"),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            if (_isDatesDecided)
              InkWell(
                onTap: _pickDateRange,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Colors.blueAccent),
                      const SizedBox(width: 12),
                      Text(
                        _dateRange == null 
                            ? "Select Dates" 
                            : "${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d, y').format(_dateRange!.end)}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Text("Dates will be decided later ⏳", style: TextStyle(color: Colors.grey)),
              ),
            
            const SizedBox(height: 24),
            const Text("Budget Estimation", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                   DropdownButtonFormField<String>(
                     value: _selectedCurrency,
                     decoration: const InputDecoration(labelText: "Currency", border: OutlineInputBorder()),
                     items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                     onChanged: (val) => setState(() => _selectedCurrency = val!),
                   ),
                   const SizedBox(height: 16),
                   TextField(
                     controller: _breakdownOther, // Reusing existing controller for Total Budget
                     decoration: InputDecoration(
                       labelText: "Total Estimated Budget", 
                       hintText: "e.g. 15000",
                       border: const OutlineInputBorder(),
                       prefixText: "${_selectedCurrency} ",
                       prefixIcon: const Icon(Icons.attach_money),
                     ), 
                     keyboardType: TextInputType.number
                   ),
                   const SizedBox(height: 8),
                   const Text("You can add details later in the dashboard.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) 
                    : const Text("Create Trip Pipeline 🚀"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
