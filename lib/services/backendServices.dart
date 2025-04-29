// import 'package:http/http.dart' as http;

// class BackendServices {
//   final String baseUrl = 'https://localhost:3000'; // Replace with your actual base URL
  

//   Future<void> register(String email, String password) async {

//   }

//   Future<void> login(String email, String password) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/login'),
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//       },
//       body: jsonEncode(<String, String>{
//         'email': email,
//         'password': password,
//       }),
//     );

//     if (response.statusCode == 200) {
//       // Handle successful login
//     } else {
//       // Handle login error
//     }
//   }

// }