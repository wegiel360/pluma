import { UserProfile, Message } from '../types';

const API_BASE = '/api';

/**
 * Fetch or initialize a user profile via Flask API (SQLite)
 */
export async function getOrCreateUser(rawUsername: string): Promise<UserProfile> {
  const username = rawUsername.trim().toLowerCase().replace(/^@/, '');
  if (!username) {
    throw new Error('Nazwa użytkownika nie może być pusta');
  }

  try {
    const res = await fetch(`${API_BASE}/users/${username}`);
    if (res.ok) {
      const data = await res.json();
      if (data.status === 'success' && data.user) {
        return {
          id: data.user.username,
          username: data.user.username,
          displayName: data.user.username,
          bio: data.user.bio || 'użytkownik pluma',
          color: data.user.color || '#ffb870',
          pfp: data.user.pfp || '/logo-kogut-500x500.png',
          banner: data.user.banner || '/bliss-1024p.jpg',
          createdAt: data.user.createdAt || Date.now()
        };
      }
    }
  } catch (err) {
    console.warn('Flask API fetch user error, creating new:', err);
  }

  // Create new user in Flask SQLite
  const defaultUser: UserProfile = {
    id: username,
    username: username,
    displayName: username,
    bio: 'użytkownik pluma',
    color: '#ffb870',
    pfp: '/logo-kogut-500x500.png',
    banner: '/bliss-1024p.jpg',
    createdAt: Date.now()
  };

  try {
    await fetch(`${API_BASE}/users/${username}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        bio: defaultUser.bio,
        pfp: defaultUser.pfp,
        banner: defaultUser.banner,
        color: defaultUser.color
      })
    });
  } catch (err) {
    console.error('Error creating user via Flask API:', err);
  }

  return defaultUser;
}

/**
 * Fetch all users from Flask API
 */
export async function getAllUsers(): Promise<UserProfile[]> {
  try {
    const res = await fetch(`${API_BASE}/users`);
    if (res.ok) {
      const data = await res.json();
      if (data.status === 'success' && Array.isArray(data.users)) {
        return data.users.map((u: any) => ({
          id: u.username,
          username: u.username,
          displayName: u.username,
          bio: u.bio || '',
          color: u.color || '#ffb870',
          pfp: u.pfp || '/logo-kogut-500x500.png',
          banner: u.banner || '/bliss-1024p.jpg',
          createdAt: u.createdAt || Date.now()
        }));
      }
    }
  } catch (err) {
    console.error('Error getting all users from Flask API:', err);
  }
  return [];
}

/**
 * Subscribe to real-time users list via Flask API polling
 */
export function subscribeUsers(callback: (users: UserProfile[]) => void) {
  let active = true;

  const fetchUsers = async () => {
    if (!active) return;
    const users = await getAllUsers();
    if (active) callback(users);
  };

  fetchUsers();
  const interval = setInterval(fetchUsers, 2500);

  return () => {
    active = false;
    clearInterval(interval);
  };
}

/**
 * Send a message to Flask API (SQLite)
 */
export async function sendMessageToFirestore(
  sender: string, 
  recipient: string, 
  text: string,
  imageUrl?: string,
  videoUrl?: string
): Promise<void> {
  try {
    await fetch(`${API_BASE}/messages`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        sender,
        recipient,
        text,
        imageUrl,
        videoUrl
      })
    });
  } catch (err) {
    console.error('Error sending message via Flask API:', err);
  }
}

/**
 * Delete a message from Flask API
 */
export async function deleteMessageFromFirestore(messageId: string): Promise<void> {
  try {
    await fetch(`${API_BASE}/messages/${messageId}`, {
      method: 'DELETE'
    });
  } catch (err) {
    console.error('Error deleting message via Flask API:', err);
  }
}

/**
 * Subscribe to conversation messages between two users via Flask API polling
 */
export function subscribeConversationMessages(
  user1: string, 
  user2: string, 
  callback: (messages: Message[]) => void
) {
  let active = true;

  const fetchConversation = async () => {
    if (!active) return;
    try {
      const res = await fetch(`${API_BASE}/messages/${user1}/${user2}`);
      if (res.ok) {
        const data = await res.json();
        if (data.status === 'success' && Array.isArray(data.messages)) {
          if (active) callback(data.messages);
          return;
        }
      }
    } catch (err) {
      console.warn('Error fetching conversation from Flask API:', err);
    }
  };

  fetchConversation();
  const interval = setInterval(fetchConversation, 2000);

  return () => {
    active = false;
    clearInterval(interval);
  };
}

/**
 * Subscribe to all messages for preview cards via Flask API polling
 */
export function subscribeAllMessages(callback: (messages: Message[]) => void) {
  let active = true;

  const fetchAllMsgs = async () => {
    if (!active) return;
    try {
      const res = await fetch(`${API_BASE}/messages`);
      if (res.ok) {
        const data = await res.json();
        if (data.status === 'success' && Array.isArray(data.messages)) {
          if (active) callback(data.messages);
          return;
        }
      }
    } catch (err) {
      console.warn('Error fetching all messages from Flask API:', err);
    }
  };

  fetchAllMsgs();
  const interval = setInterval(fetchAllMsgs, 2500);

  return () => {
    active = false;
    clearInterval(interval);
  };
}

/**
 * Update user profile in Flask API
 */
export async function updateUserInFirestore(username: string, updates: Partial<UserProfile>): Promise<void> {
  try {
    await fetch(`${API_BASE}/users/${username}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        bio: updates.bio,
        pfp: updates.pfp,
        banner: updates.banner,
        color: updates.color
      })
    });
  } catch (err) {
    console.error('Error updating user in Flask API:', err);
  }
}

/**
 * Clear all messages in Flask API
 */
export async function clearAllFirestoreMessages(): Promise<void> {
  try {
    await fetch(`${API_BASE}/messages`, {
      method: 'DELETE'
    });
  } catch (err) {
    console.error('Error clearing all messages in Flask API:', err);
  }
}

/**
 * Upload asset URL / base64 string directly
 */
export async function uploadUserAsset(
  _username: string,
  _assetType: 'pfp' | 'banner',
  base64DataUrl: string,
  _oldAssetUrl?: string
): Promise<string> {
  return base64DataUrl;
}
