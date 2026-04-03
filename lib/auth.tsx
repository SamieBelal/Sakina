import React, { createContext, useContext, useEffect, useState } from 'react';
import { Session, User } from '@supabase/supabase-js';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { supabase, updateStreak } from './supabase';

const GUEST_KEY = '@sakina_is_guest';

interface AuthContextValue {
  user: User | null;
  session: Session | null;
  isGuest: boolean;
  isLoading: boolean;
  signUp: (email: string, password: string) => Promise<string | null>;
  signIn: (email: string, password: string) => Promise<string | null>;
  signOut: () => Promise<void>;
  continueAsGuest: () => Promise<void>;
  upgradeGuest: (email: string, password: string) => Promise<string | null>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [isGuest, setIsGuest] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Check for existing session or guest flag
    const init = async () => {
      if (supabase) {
        const { data } = await supabase.auth.getSession();
        setSession(data.session);
        setUser(data.session?.user ?? null);
      }
      const guest = await AsyncStorage.getItem(GUEST_KEY);
      if (guest === 'true') setIsGuest(true);
      setIsLoading(false);
    };
    init();

    if (!supabase) return;
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, s) => {
      setSession(s);
      setUser(s?.user ?? null);
    });
    return () => subscription.unsubscribe();
  }, []);

  const signUp = async (email: string, password: string): Promise<string | null> => {
    if (!supabase) return 'Supabase not configured';
    const { error } = await supabase.auth.signUp({ email, password });
    return error?.message ?? null;
  };

  const signIn = async (email: string, password: string): Promise<string | null> => {
    if (!supabase) return 'Supabase not configured';
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    return error?.message ?? null;
  };

  const signOut = async () => {
    if (supabase) await supabase.auth.signOut();
    await AsyncStorage.removeItem(GUEST_KEY);
    setIsGuest(false);
  };

  const continueAsGuest = async () => {
    await AsyncStorage.setItem(GUEST_KEY, 'true');
    setIsGuest(true);
  };

  // Sign up and sync local streak to Supabase
  const upgradeGuest = async (email: string, password: string): Promise<string | null> => {
    if (!supabase) return 'Supabase not configured';
    const { data, error } = await supabase.auth.signUp({ email, password });
    if (error) return error.message;
    if (data.user) {
      await updateStreak(data.user.id);
      await AsyncStorage.removeItem(GUEST_KEY);
      setIsGuest(false);
    }
    return null;
  };

  return (
    <AuthContext.Provider value={{ user, session, isGuest, isLoading, signUp, signIn, signOut, continueAsGuest, upgradeGuest }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
