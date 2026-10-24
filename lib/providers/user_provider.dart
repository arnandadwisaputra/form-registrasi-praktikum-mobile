import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  User _user = User(name: '', email: '');
  bool _isLoading = true;
  bool _isDarkMode = false; // Latihan 1
  int _visitCount = 0; // Latihan 2

  // Getters
  User get user => _user;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  int get visitCount => _visitCount;

  UserProvider() {
    _initProvider();
  }

  Future<void> _initProvider() async {
    await _loadUser();
    await _loadThemePreference();
    await _handleVisitCounter();
  }

  // --- LATIHAN 2: Counter Kunjungan ---
  Future<void> _handleVisitCounter() async {
    final prefs = await SharedPreferences.getInstance();
    _visitCount = prefs.getInt('visit_count') ?? 0;
    _visitCount++; // Increment counter setiap aplikasi dibuka
    await prefs.setInt('visit_count', _visitCount);
    notifyListeners();
  }

  // --- LATIHAN 1: Preferensi Tema ---
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', value);
    notifyListeners();
  }

  // --- Load & Simpan Data User Utama ---
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final email = prefs.getString('user_email') ?? '';
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final favorites = prefs.getStringList('favorites') ?? []; // Latihan 3

    _user = User(
      name: name,
      email: email,
      isLoggedIn: isLoggedIn,
      favorites: favorites,
    );
    _isLoading = false;
    notifyListeners();
  }

  // --- LATIHAN 5: Validasi Keamanan ---
  Future<String?> validateAndSaveProfile(User newUser) async {
    _isLoading = true;
    notifyListeners();

    // Validasi Karakter Berbahaya (XSS/Script Injection)
    final scriptRegex = RegExp(r'<script.*?>.*?</script>|[^a-zA-Z0-9\s@.]');
    if (scriptRegex.hasMatch(newUser.name)) {
      _isLoading = false;
      notifyListeners();
      return "Nama mengandung karakter ilegal atau berbahaya!";
    }

    final prefs = await SharedPreferences.getInstance();

    // Simulasi Cek Apakah Email Sudah Digunakan Pengguna Lain
    String? existingEmail = prefs.getString('registered_email_database');
    if (existingEmail != null &&
        existingEmail == newUser.email &&
        _user.email != newUser.email) {
      _isLoading = false;
      notifyListeners();
      return "Email sudah terdaftar oleh pengguna lain!";
    }

    // Simpan ke SharedPreferences
    await prefs.setString('user_name', newUser.name);
    await prefs.setString('user_email', newUser.email);
    await prefs.setBool('is_logged_in', newUser.isLoggedIn);
    // Simpan email simulasi database lokal
    await prefs.setString('registered_email_database', newUser.email);

    _user = newUser;
    _isLoading = false;
    notifyListeners();
    return null; // Return null jika sukses
  }

  // --- LATIHAN 3: Kelola Daftar Favorit ---
  Future<void> addFavorite(String item) async {
    if (item.trim().isEmpty) return;
    final updatedFavorites = List<String>.from(_user.favorites)
      ..add(item.trim());
    _user = _user.copyWith(favorites: updatedFavorites);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', updatedFavorites);
    notifyListeners();
  }

  Future<void> removeFavorite(int index) async {
    final updatedFavorites = List<String>.from(_user.favorites)
      ..removeAt(index);
    _user = _user.copyWith(favorites: updatedFavorites);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', updatedFavorites);
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.setBool('is_logged_in', false);
    // Preferensi hobi/favorit dihapus saat logout penuh
    await prefs.remove('favorites');

    _user = User(name: '', email: '', isLoggedIn: false, favorites: []);
    notifyListeners();
  }
}
