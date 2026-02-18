import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/trip.dart';
import '../models/user_profile.dart';
import '../services/post_service.dart';
import '../services/trip_service.dart';
import '../services/google_places_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final PostService _postService = PostService();
  final TripService _tripService = TripService();
  final GooglePlacesService _placesService = GooglePlacesService();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  File? _selectedImage;
  List<Trip> _userTrips = [];
  Trip? _selectedTrip;
  String _visibility = 'followers';
  bool _isLoading = false;
  bool _isFetchingTrips = true;

  // Mentions
  List<dynamic> _mentionSuggestions = []; 
  bool _showMentions = false;
  String _mentionQuery = '';

  // Location suggestions
  List<Map<String, dynamic>> _locationSuggestions = [];
  bool _showLocationSuggestions = false;
  bool _isAutoSelectingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadUserTrips();
    _pickImage(); 
    _captionController.addListener(_onCaptionChanged);
    _locationController.addListener(_onLocationChanged);
  }

  @override
  void dispose() {
    _captionController.removeListener(_onCaptionChanged);
    _locationController.removeListener(_onLocationChanged);
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onCaptionChanged() async {
    final text = _captionController.text;
    final selection = _captionController.selection;
    
    if (selection.baseOffset <= 0) {
      if (_showMentions) setState(() => _showMentions = false);
      return;
    }

    // Look back from cursor for '@'
    final lastAtPos = text.lastIndexOf('@', selection.baseOffset - 1);
    if (lastAtPos != -1) {
      final query = text.substring(lastAtPos + 1, selection.baseOffset);
      // Ensure no space between @ and cursor
      if (!query.contains(' ')) {
        setState(() {
          _showMentions = true;
          _mentionQuery = query;
        });
        _fetchMentions(query);
        return;
      }
    }

    if (_showMentions) setState(() => _showMentions = false);
  }

  Future<void> _fetchMentions(String query) async {
    if (query.isEmpty) {
      setState(() => _mentionSuggestions = []);
      return;
    }
    final results = await _postService.searchUsers(query);
    if (mounted && _showMentions) {
      setState(() => _mentionSuggestions = results);
    }
  }

  void _selectUser(UserProfile user) {
    final text = _captionController.text;
    final selection = _captionController.selection;
    final lastAtPos = text.lastIndexOf('@', selection.baseOffset - 1);
    
    if (lastAtPos != -1) {
      final newText = text.replaceRange(lastAtPos, selection.baseOffset, "@${user.username} ");
      _captionController.text = newText;
      _captionController.selection = TextSelection.fromPosition(TextPosition(offset: lastAtPos + (user.username?.length ?? 0) + 2));
    }
    
    setState(() => _showMentions = false);
  }

  void _onLocationChanged() {
    if (_isAutoSelectingLocation) return;
    
    final query = _locationController.text.trim();
    if (query.length >= 3) {
      if (!_showLocationSuggestions) setState(() => _showLocationSuggestions = true);
      _fetchLocationSuggestions(query);
    } else {
      if (_showLocationSuggestions) setState(() => _showLocationSuggestions = false);
    }
  }

  Future<void> _fetchLocationSuggestions(String query) async {
    final results = await _placesService.getAutocompleteSuggestions(query);
    if (mounted && _showLocationSuggestions) {
      setState(() => _locationSuggestions = results);
    }
  }

  void _selectLocation(Map<String, dynamic> suggestion) {
    setState(() {
      _isAutoSelectingLocation = true;
      _locationController.text = suggestion['main_text'];
      _showLocationSuggestions = false;
      _locationSuggestions = [];
    });
    
    // Reset the flag after a short delay to allow the text change to propagate
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _isAutoSelectingLocation = false);
    });
  }

  Future<void> _loadUserTrips() async {
    try {
      final trips = await _tripService.getUserTripsFuture();
      setState(() {
        _userTrips = trips;
        _isFetchingTrips = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingTrips = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Built-in compression as requested
    );

    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<File?> _compressImage(File file) async {
    // 1. Get user profile to check HD preference
    final profile = await _postService.getCurrentUserProfile();
    final bool isHD = profile?.uploadHdPosts ?? false;

    if (isHD) return file; // Skip compression if HD is ON

    // 2. Compress the image
    final filePath = file.absolute.path;
    final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
    final outPath = "${filePath.substring(0, lastIndex)}_compressed.jpg";

    final compressedXFile = await FlutterImageCompress.compressAndGetFile(
      filePath, 
      outPath,
      quality: 70,
      minWidth: 1080,
      minHeight: 1080,
    );

    return compressedXFile != null ? File(compressedXFile.path) : null;
  }

  Future<void> _handlePost() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an image")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      
      // 1. Compress Image
      final File? optimizedImage = await _compressImage(_selectedImage!);
      if (optimizedImage == null) throw Exception("Image processing failed");

      // 2. Create Post
      await _postService.createPost(
        imageFile: optimizedImage,
        fileName: fileName,
        caption: _captionController.text.trim(),
        location: _locationController.text.trim(),
        visibility: _visibility,
        tripId: _selectedTrip?.id,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post shared! 🌍✨")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel", style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w500)),
        ),
        leadingWidth: 80,
        title: Text("New Post", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isLoading 
              ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
              : TextButton(
                  onPressed: _handlePost,
                  child: Text("Post", style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE PREVIEW
            GestureDetector(
              onTap: _pickImage,
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    image: _selectedImage != null 
                        ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _selectedImage == null 
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text("Tap to select image", style: GoogleFonts.inter(color: Colors.grey)),
                          ],
                        )
                      : null,
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // CAPTION
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _captionController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: "Write a caption...",
                    hintStyle: GoogleFonts.inter(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                  style: GoogleFonts.inter(fontSize: 15),
                ),
                if (_showMentions && _mentionSuggestions.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _mentionSuggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = _mentionSuggestions[index];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) 
                                ? NetworkImage(user.avatarUrl!) as ImageProvider
                                : null,
                            child: (user.avatarUrl == null || user.avatarUrl!.isEmpty) 
                                ? Text((user.username != null && user.username!.isNotEmpty) ? user.username![0].toUpperCase() : '?', style: const TextStyle(fontSize: 10))
                                : null,
                          ),
                          title: Text(user.displayName ?? user.username ?? 'Traveler', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text("@${user.username}", style: GoogleFonts.inter(fontSize: 11, color: Colors.blueAccent)),
                          onTap: () => _selectUser(user),
                        );
                      },
                    ),
                  ),
              ],
            ),

            const Divider(),

            // LOCATION
            Stack(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined, color: Colors.blueAccent),
                  title: TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      hintText: "Add Location",
                      border: InputBorder.none,
                    ),
                    style: GoogleFonts.inter(fontSize: 15),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: () {
                      _locationController.clear();
                      setState(() {
                        _showLocationSuggestions = false;
                        _locationSuggestions = [];
                      });
                    },
                  ),
                ),
                if (_showLocationSuggestions && _locationSuggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 50),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _locationSuggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final suggestion = _locationSuggestions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          title: Text(suggestion['main_text'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text(suggestion['description'] ?? '', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => _selectLocation(suggestion),
                        );
                      },
                    ),
                  ),
              ],
            ),

            const Divider(),

            // TRIP SELECT (Optional)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.luggage_outlined, color: Colors.orangeAccent),
              title: _isFetchingTrips 
                  ? const LinearProgressIndicator()
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<Trip?>(
                        value: _selectedTrip,
                        hint: Text("Associate with Trip (Optional)", style: GoogleFonts.inter(fontSize: 15, color: Colors.grey)),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<Trip?>(value: null, child: Text("None")),
                          ..._userTrips.map((trip) => DropdownMenuItem(
                            value: trip,
                            child: Text(trip.name, style: GoogleFonts.inter(fontSize: 15)),
                          )),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedTrip = val;
                            // If user selects trip, visibility can be 'trip'
                            // If they deselect, and visibility was 'trip', reset to 'followers'
                            if (val == null && _visibility == 'trip') {
                              _visibility = 'followers';
                            }
                          });
                        },
                      ),
                    ),
            ),

            const Divider(),

            // VISIBILITY
            const SizedBox(height: 16),
            Text("Visibility", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildVisibilityChip('followers', Icons.people_outline, "Followers"),
                const SizedBox(width: 8),
                _buildVisibilityChip('public', Icons.public, "Public"),
                if (_selectedTrip != null) ...[
                  const SizedBox(width: 8),
                  _buildVisibilityChip('trip', Icons.lock_outline, "Trip Only"),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityChip(String value, IconData icon, String label) {
    final bool isSelected = _visibility == value;
    return GestureDetector(
      onTap: () => setState(() => _visibility = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 13, color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
