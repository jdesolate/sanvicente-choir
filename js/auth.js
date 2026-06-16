import { supabase } from './supabase-client.js';

export async function signIn(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data;
}

export async function signOut() {
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}

export async function getSession() {
  const { data: { session } } = await supabase.auth.getSession();
  return session;
}

export async function getProfile() {
  const session = await getSession();
  if (!session) return null;
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', session.user.id)
    .single();
  if (error) return null;
  return data;
}

// Redirects to redirectTo if not authenticated. Returns the session if authenticated.
export async function requireAuth(redirectTo = '/pages/login.html') {
  const session = await getSession();
  if (!session) {
    window.location.href = redirectTo;
    return null;
  }
  // Block inactive members even if their session is still valid
  const profile = await getProfile();
  if (profile?.status === 'inactive') {
    await supabase.auth.signOut();
    window.location.href = '/pages/login.html?inactive=1';
    return null;
  }
  return session;
}

export async function sendPasswordResetEmail(email, redirectTo) {
  const { error } = await supabase.auth.resetPasswordForEmail(email, { redirectTo });
  if (error) throw error;
}

export async function updatePassword(newPassword) {
  const { error } = await supabase.auth.updateUser({ password: newPassword });
  if (error) throw error;
}

// Redirects if the user doesn't have the required role or higher.
// Role hierarchy: member < secretary < admin
// Returns the profile if authorized.
export async function requireRole(role, redirectTo = '/index.html') {
  const profile = await getProfile();
  if (!profile) {
    window.location.href = '/pages/login.html';
    return null;
  }
  if (profile.status === 'inactive') {
    await supabase.auth.signOut();
    window.location.href = '/pages/login.html?inactive=1';
    return null;
  }
  const hierarchy = { member: 1, secretary: 2, admin: 3, super_admin: 4 };
  const required = hierarchy[role] ?? 1;
  const actual   = hierarchy[profile.role] ?? 0;
  if (actual < required) {
    window.location.href = redirectTo;
    return null;
  }
  return profile;
}
