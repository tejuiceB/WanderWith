import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';
import '../services/trip_service.dart';
import '../services/auth_service.dart';
import '../models/trip.dart';
import '../services/google_places_service.dart';
import 'trip_dashboard_screen.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _placesService = GooglePlacesService();
  final uuid = const Uuid(); 
  
  List<Map<String, dynamic>> _locationSuggestions = [];
  String? _selectedPhotoUrl;
  bool _isFetchingPhoto = false;
  
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
  bool _isBudgetExpanded = false;
  String _visibility = 'public';

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

  void _onLocationChanged(String value) {
    if (value.isEmpty) {
      setState(() => _locationSuggestions = []);
      return;
    }
    _fetchLocationSuggestions(value);
  }

  void _fetchLocationSuggestions(String query) async {
    final suggestions = await _placesService.getAutocompleteSuggestions(query);
    setState(() => _locationSuggestions = suggestions);
  }

  Future<void> _selectLocation(Map<String, dynamic> suggestion) async {
    _locationController.text = suggestion['description'];
    setState(() => _locationSuggestions = []);
    
    // Fetch place photo
    setState(() => _isFetchingPhoto = true);
    final details = await _placesService.searchPlace(suggestion['description']);
    if (details != null && details['image_url'] != null) {
      setState(() {
        _selectedPhotoUrl = details['image_url'];
        _isFetchingPhoto = false;
      });
    } else {
      setState(() {
        _selectedPhotoUrl = null;
        _isFetchingPhoto = false;
      });
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

      String? finalCoverUrl;
      if (_selectedPhotoUrl != null) {
         // Generate a temp tripId for image path (or use v4)
         final tempTripId = uuid.v4();
         finalCoverUrl = await tripService.uploadTripCover(_selectedPhotoUrl!, tempTripId);
      }

      final tripId = await tripService.createTrip(
        name: _nameController.text,
        location: _locationController.text,
        startDate: startDate,
        endDate: endDate,
        isDateDecided: _isDatesDecided,
        creatorUid: user.id,
        budgetCurrency: _selectedCurrency,
        estimatedCost: totalBudget,
        coverImageUrl: finalCoverUrl,
        visibility: _visibility,
        joinCode: _visibility == 'private' ? uuid.v4().substring(0, 8).toUpperCase() : null,
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
          'estimated_cost': totalBudget,
          'days': startDate != null && endDate != null ? endDate.difference(startDate).inDays + 1 : 3,
        },
        coverImageUrl: finalCoverUrl,
        visibility: _visibility,
        joinCode: _visibility == 'private' ? uuid.v4().substring(0, 8).toUpperCase() : null,
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Emotional Header Section
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 150),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildTripNameSection(),
                    const SizedBox(height: 32),
                    _buildLocationSection(),
                    const SizedBox(height: 32),
                    _buildDatesSection(),
                    const SizedBox(height: 32),
                    _buildVisibilitySection(),
                    const SizedBox(height: 32),
                    _buildBudgetSection(),
                  ]),
                ),
              ),
            ],
          ),

          // Back Button Overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.9),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildCTA(),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedPhotoUrl != null)
          Container(
            height: MediaQuery.of(context).size.height * 0.25,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: CachedNetworkImageProvider(_selectedPhotoUrl!),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.7)],
                ),
              ),
              padding: const EdgeInsets.all(24),
              alignment: Alignment.bottomLeft,
              child: Text(
                _nameController.text.isEmpty ? "Your Adventure" : _nameController.text,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          )
        else
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 60, left: 24, right: 24, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Plan Your Next\nAdventure 🌍",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Start building memories with your crew.",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTripNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TRIP NAME",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          onChanged: (val) => setState(() {}),
          decoration: InputDecoration(
            hintText: "e.g. Summer in Santorini",
            hintStyle: TextStyle(color: Colors.grey.shade300),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "DESTINATION",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              TextField(
                controller: _locationController,
                onChanged: _onLocationChanged,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: "Where are you going?",
                  prefixIcon: const Icon(Icons.location_on, color: Colors.blueAccent),
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                ),
              ),
              if (_locationSuggestions.isNotEmpty)
                ..._locationSuggestions.map((s) => ListTile(
                  leading: const Icon(Icons.place_outlined, size: 20),
                  title: Text(s['description'], style: const TextStyle(fontSize: 14)),
                  onTap: () => _selectLocation(s),
                )).toList(),
              if (_isFetchingPhoto)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.transparent),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "TRIP DATES",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 1),
            ),
            Row(
              children: [
                Text("Not decided yet", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Switch(
                  value: !_isDatesDecided,
                  onChanged: (val) {
                    setState(() {
                      _isDatesDecided = !val;
                      if (!_isDatesDecided) _dateRange = null;
                    });
                  },
                  activeColor: Colors.blueAccent,
                ),
              ],
            ),
          ],
        ),
        if (_isDatesDecided)
          InkWell(
            onTap: _pickDateRange,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: Colors.blueAccent),
                  const SizedBox(width: 16),
                  Text(
                    _dateRange == null
                        ? "Select Dates"
                        : "${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d, y').format(_dateRange!.end)}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _dateRange == null ? Colors.blueAccent : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blueAccent),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text("Dates will be decided later ⏳", style: TextStyle(color: Colors.grey)),
          ),
      ],
    );
  }

  Widget _buildBudgetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isBudgetExpanded = !_isBudgetExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "OPTIONAL BUDGET",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 1),
              ),
              Icon(
                _isBudgetExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.blueAccent,
              ),
            ],
          ),
        ),
        if (_isBudgetExpanded) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedCurrency,
                  decoration: const InputDecoration(labelText: "Currency", border: InputBorder.none),
                  items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _selectedCurrency = val!),
                ),
                const Divider(),
                TextField(
                  controller: _breakdownOther,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    hintText: "Total Estimated Budget",
                    border: InputBorder.none,
                    prefixText: "${_selectedCurrency} ",
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.blueAccent),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCTA() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Create Trip", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          const Text("You can edit details anytime.", style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildVisibilitySection() {
    final userProfile = Provider.of<AuthService>(context, listen: false).userProfile;
    if (userProfile?.role != 'agency') return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TRIP VISIBILITY",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text("Public"),
                subtitle: const Text("Searchable and open for join requests"),
                value: 'public',
                groupValue: _visibility,
                onChanged: (val) => setState(() => _visibility = val!),
                activeColor: Colors.blueAccent,
              ),
              RadioListTile<String>(
                title: const Text("Private"),
                subtitle: const Text("Invite only via join code"),
                value: 'private',
                groupValue: _visibility,
                onChanged: (val) => setState(() => _visibility = val!),
                activeColor: Colors.blueAccent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
