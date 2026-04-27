import "package:flutter/material.dart";
import "package:dozy_go/pages/map_page.dart";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "DoziGo",
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: MapPage(),
    );
  }
}

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Dozi Go"), centerTitle: true,
//      backgroundColor: Colors.grey,
//       ),

//       body: Padding(
//         padding: EdgeInsets.all(16),
//         child: Center(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               SizedBox(height: 3),
//               Text("Relax - Doze - Arrive Right" ,
//               style: TextStyle(
//                 fontSize: 14,
//                 color : Colors.grey[700],

//               ),
//               textAlign: TextAlign.center,
//               ),
//               SizedBox(height: 12),
//               ElevatedButton(onPressed: (){}, child: Text("Select Destination"),
//               ),
//               ]
//               ),
//         ),
//       ),
//     );
//   }
// }
