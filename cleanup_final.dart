import 'dart:io';

void main() {
  final file = File(r'c:\Users\Tejas\OneDrive\Desktop\WanderWith\lib\screens\profile_screen.dart');
  var content = file.readAsStringSync();
  
  // Find the end of _handleShareProfile
  // It contains 'subject: "WanderWith Profile",' and then ends with '}'
  final searchStr = 'subject: "WanderWith Profile",';
  int shareIdx = content.indexOf(searchStr);
  if (shareIdx == -1) {
    print("Could not find share string.");
    return;
  }
  
  int endOfShareMethod = content.indexOf('}', shareIdx);
  if (endOfShareMethod == -1) {
    print("Could not find end of share method.");
    return;
  }
  
  // Find the start of class _SliverAppBarDelegate
  int sliverStart = content.indexOf('class _SliverAppBarDelegate');
  if (sliverStart == -1) {
    print("Could not find SliverDelegate.");
    return;
  }
  
  // Find the '}' before sliverStart (this should be the end of _ProfileScreenState)
  int classEnd = content.lastIndexOf('}', sliverStart);
  if (classEnd == -1 || classEnd <= endOfShareMethod) {
    print("Could not find class end.");
    return;
  }
  
  // Wipe everything between endOfShareMethod + 1 and classEnd
  // But we want to keep the final '}' of the class.
  // Actually, let's just wipe from endOfShareMethod + 1 to classEnd.
  
  String newContent = content.substring(0, endOfShareMethod + 1) + 
                     '\n}\n\n' + 
                     content.substring(sliverStart);
                     
  file.writeAsStringSync(newContent);
  print("Cleanup successful.");
}
