import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }
}
