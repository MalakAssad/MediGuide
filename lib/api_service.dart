import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://malak22330598.mywebcommunity.org";

  // ---- Helpers: robust decoding with error capture ----
  static Map<String, dynamic> _safeDecodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {
        "status": "error",
        "message": "Response is not a JSON object",
        "raw": body,
      };
    } catch (e) {
      return {"status": "error", "message": "Invalid JSON", "raw": body};
    }
  }

  static List<dynamic> _safeDecodeList(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is List) return decoded;
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> _postJson(
    String file,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse("$baseUrl/$file");
    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    final decoded = _safeDecodeMap(res.body);
    if (decoded["status"] == "error") {
      // Log server response for debugging
      // ignore: avoid_print
      print("[$file] ${decoded['message']}: ${decoded['raw']}");
    }
    return decoded;
  }

  static Future<List<dynamic>> _postJsonList(
    String file,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse("$baseUrl/$file");
    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    final decoded = _safeDecodeList(res.body);
    if (decoded.isEmpty && res.body.startsWith("<")) {
      // ignore: avoid_print
      print("[$file] Server returned HTML (likely PHP error): ${res.body}");
    }
    return decoded;
  }

  static Future<Map<String, dynamic>> _postForm(
    String file,
    Map<String, String> body,
  ) async {
    final uri = Uri.parse("$baseUrl/$file");
    final res = await http.post(uri, body: body); // form-encoded
    final decoded = _safeDecodeMap(res.body);
    if (decoded["status"] == "error") {
      // ignore: avoid_print
      print("[$file] ${decoded['message']}: ${decoded['raw']}");
    }
    return decoded;
  }

  // ---------- AUTH (unchanged) ----------
  static Future<Map<String, dynamic>> signup(
    String username,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/signup.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/login.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );
    return jsonDecode(res.body);
  }

  // ---------- MEDS (JSON) ----------
  static Future<List<dynamic>> getMedications(String uid) {
    return _postJsonList("getMeds.php", {"uid": uid});
  }

  static Future<bool> addMedication({
    required String uid,
    required String name,
    required String dose,
    required String time,
  }) async {
    final data = await _postJson("addMed.php", {
      "uid": uid,
      "name": name,
      "dose": dose,
      "time": time,
      "taken": 0,
    });
    // ignore: avoid_print
    print("addMedication resp: $data");
    return data["status"] == "success";
  }

  static Future<bool> updateMedication({
    required String uid,
    required String mid,
    required int taken,
  }) async {
    final data = await _postJson("updateMed.php", {
      "uid": uid,
      "mid": mid,
      "taken": taken,
    });
    return data["status"] == "success";
  }

  static Future<bool> deleteMedication({
    required String uid,
    required String mid,
  }) async {
    final data = await _postJson("deleteMed.php", {"uid": uid, "mid": mid});
    return data["status"] == "success";
  }

  // ---------- READINGS ----------
  static Future<bool> addReading({
    required String uid, // ← MUST be String
    required int bp,
    required int sugar,
    required String advice,
  }) async {
    final data = await _postJson("addReading.php", {
      "uid": uid, // ← send as String
      "bp": bp,
      "sugar": sugar,
      "advice": advice,
    });
    print("addReading resp: $data");
    return data["status"] == "success";
  }

  // Use JSON for fetching readings (your PHP decodes JSON)
  static Future<List<dynamic>> getReadings(String uid) {
    // Ensure the PHP file name is correct on the server: getReadings.php
    return _postJsonList("getReadings.php", {"uid": uid});
  }
}
