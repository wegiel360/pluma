import { UserProfile } from '../types';

const SAVED_ACCOUNTS_KEY = 'pluma_saved_accounts';

/**
 * Retrieves the list of accounts saved on this device from localStorage
 */
export function getSavedAccounts(): UserProfile[] {
  try {
    const raw = localStorage.getItem(SAVED_ACCOUNTS_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch (e) {
    console.error('Error reading saved accounts:', e);
    return [];
  }
}

/**
 * Saves or updates a user profile in the local device saved accounts list
 */
export function saveAccountToLocal(user: UserProfile): void {
  try {
    const current = getSavedAccounts();
    const filtered = current.filter(u => u.username.toLowerCase() !== user.username.toLowerCase());
    const updated = [user, ...filtered];
    localStorage.setItem(SAVED_ACCOUNTS_KEY, JSON.stringify(updated));
  } catch (e) {
    console.error('Error saving account to local storage:', e);
  }
}

/**
 * Removes a saved account by username from local storage
 */
export function removeSavedAccountFromLocal(username: string): UserProfile[] {
  try {
    const current = getSavedAccounts();
    const updated = current.filter(u => u.username.toLowerCase() !== username.toLowerCase());
    localStorage.setItem(SAVED_ACCOUNTS_KEY, JSON.stringify(updated));
    return updated;
  } catch (e) {
    console.error('Error removing saved account:', e);
    return getSavedAccounts();
  }
}
