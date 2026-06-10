import { supabase } from './supabase-client.js';

export async function signIn(email, password) {}

export async function signOut() {}

export async function getSession() {}

export async function getProfile() {}

export function requireAuth(redirectTo = '/pages/login.html') {}

export function requireRole(role, redirectTo = '/index.html') {}
