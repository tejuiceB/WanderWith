import 'dart:io';

void main() {
  final file = File('c:\\Users\\Tejas\\OneDrive\\Desktop\\WanderWith\\lib\\screens\\profile_screen.dart');
  var content = file.readAsStringSync();
  
  // 1. Remove _isUpdatingLocation state variable
  content = content.replaceFirst('bool _isUpdatingLocation = false;', '');

  // 2. Update _showEditProfile save logic
  // We need to inject the GPS fetch before updateProfile
  final saveLogicOld = '''
                           setSheetState(() => isSaving = true);
                           try {
                              await Provider.of<AuthService>(context, listen: false).updateProfile(
                                 displayName: cName.text,
                                 username: cUsername.text.toLowerCase().trim(),
                                 bio: cBio.text,
                              );
                              
                              if (ctx.mounted) Navigator.pop(ctx);
''';

  final saveLogicNew = '''
                           setSheetState(() => isSaving = true);
                           try {
                              // Auto-fetch location
                              double? lat, lng;
                              String? city, country;
                              
                              try {
                                bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                                if (serviceEnabled) {
                                  LocationPermission permission = await Geolocator.checkPermission();
                                  if (permission == LocationPermission.denied) {
                                    permission = await Geolocator.requestPermission();
                                  }
                                  
                                  if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
                                    Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
                                    lat = pos.latitude;
                                    lng = pos.longitude;
                                    
                                    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
                                    if (placemarks.isNotEmpty) {
                                      city = placemarks.first.locality ?? placemarks.first.subAdministrativeArea;
                                      country = placemarks.first.country;
                                    }
                                  }
                                }
                              } catch (e) {
                                print("Silent location fetch failed: \$e");
                              }

                              await Provider.of<AuthService>(context, listen: false).updateProfile(
                                 displayName: cName.text,
                                 username: cUsername.text.toLowerCase().trim(),
                                 bio: cBio.text,
                                 latitude: lat,
                                 longitude: lng,
                                 city: city,
                                 country: country,
                              );
                              
                              if (ctx.mounted) Navigator.pop(ctx);
''';

  content = content.replaceFirst(saveLogicOld.trim(), saveLogicNew.trim());

  // 3. Remove the "Update Current Location" button from _buildActionButtons
  // It's in an if (isMe) block
  final buttonBlock = RegExp(r'if \(isMe\) \.\.\. \[.*?OutlinedButton\.icon\(.*?onPressed: _isUpdatingLocation \? null : _updateCurrentLocation,.*?label: Text\(_isUpdatingLocation \? "Updating Location\.\.\." : "Update Current Location \(GPS\)",.*?\),.*?      \),.*?   \),.*?\]', dotAll: true);
  content = content.replaceFirst(buttonBlock, '');

  // 4. Remove _updateCurrentLocation method
  final methodBlock = RegExp(r'Future<void> _updateCurrentLocation\(\) async \{.*?\}', dotAll: true);
  content = content.replaceFirst(methodBlock, '');

  file.writeAsStringSync(content);
}
