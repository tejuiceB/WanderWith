import 'dart:io';

void main() {
  final file = File(r'c:\Users\Tejas\OneDrive\Desktop\WanderWith\lib\screens\profile_screen.dart');
  var lines = file.readAsLinesSync();
  
  // Find where _handleShareProfile ends
  int endOfShare = -1;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('Share.share(') && i + 2 < lines.length && lines[i+1].contains('subject: "WanderWith Profile",') && lines[i+2].contains(');')) {
       for (int j = i+3; j < lines.length; j++) {
         if (lines[j].trim() == '}' || lines[j].trim() == '   }') {
            endOfShare = j;
            break;
         }
       }
       break;
    }
  }

  // Find where _SliverAppBarDelegate starts
  int startOfSliver = lines.indexWhere((l) => l.contains('class _SliverAppBarDelegate'));

  if (endOfShare != -1 && startOfSliver != -1 && startOfSliver > endOfShare + 1) {
    print("Found gap between line ${endOfShare + 1} and $startOfSliver. Cleaning up...");
    int classEnd = -1;
    for (int k = startOfSliver - 1; k > endOfShare; k--) {
      if (lines[k].trim() == '}') {
        classEnd = k;
        break;
      }
    }

    if (classEnd != -1) {
      lines.removeRange(endOfShare + 1, classEnd);
      file.writeAsStringSync(lines.join('\n'));
      print("Cleanup successful.");
    } else {
       print("Could not find closing brace for ProfileScreenState before SliverDelegate.");
    }
  } else {
    print("Could not find method boundaries. endOfShare: $endOfShare, startOfSliver: $startOfSliver");
  }
}
