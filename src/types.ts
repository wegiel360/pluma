export interface UserProfile {
  id: string;
  username: string; // e.g. "wegiel", "maslo"
  displayName?: string;
  bio: string;
  color: string;
  pfp: string;
  banner: string;
  createdAt: number;
  lastActive?: number;
}

export interface Message {
  id: string;
  sender: string; // username
  recipient: string; // username
  text: string;
  timestamp: string; // formatted time e.g. "14:20"
  createdAt: number; // millis timestamp
  isImage?: boolean;
  imageUrl?: string;
  isVideo?: boolean;
  videoUrl?: string;
  isSpoiler?: boolean;
}

export type TabType = 'pulpit' | 'osoby' | 'profil';
