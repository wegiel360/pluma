import React, { useState, useEffect } from 'react';
import { TabType, UserProfile } from './types';
import { subscribeUsers, getOrCreateUser } from './lib/firebase';
import { saveAccountToLocal } from './lib/savedAccounts';
import { LoginScreen } from './components/LoginScreen';
import { NavigationRail } from './components/NavigationRail';
import { DashboardView } from './components/DashboardView';
import { MessagingView } from './components/MessagingView';
import { ProfileView } from './components/ProfileView';

export default function App() {
  const [currentUser, setCurrentUser] = useState<UserProfile | null>(null);
  const [allUsers, setAllUsers] = useState<UserProfile[]>([]);
  const [activeTab, setActiveTab] = useState<TabType>('pulpit');
  const [accentColor, setAccentColor] = useState<string>('#ffb870');
  const [windowWidth, setWindowWidth] = useState<number>(() => typeof window !== 'undefined' ? window.innerWidth : 1200);

  // Screen size detection hook
  useEffect(() => {
    const handleResize = () => setWindowWidth(window.innerWidth);
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  const deviceMode = windowWidth < 640 ? 'smartfon' : windowWidth < 1024 ? 'tablet' : 'komputer';
  const deviceIcon = windowWidth < 640 ? 'smartphone' : windowWidth < 1024 ? 'tablet_mac' : 'desktop_windows';

  // Synchronize accent color with CSS variables across the app
  useEffect(() => {
    const userColor = currentUser?.color || accentColor || '#ffb870';
    if (userColor !== accentColor) {
      setAccentColor(userColor);
    }
    document.documentElement.style.setProperty('--accent-color', userColor);
    document.documentElement.style.setProperty('--color-primary', userColor);
  }, [currentUser?.color, currentUser?.username]);

  // Real-time synchronization of registered users from Firestore
  useEffect(() => {
    const unsubscribe = subscribeUsers((usersList) => {
      setAllUsers(usersList);
      setCurrentUser((prev) => {
        if (!prev) return prev;
        const found = usersList.find((u) => u.username === prev.username);
        if (!found) return prev;
        // Preserve local color if found.color is missing or stale
        const activeColor = prev.color || found.color || '#ffb870';
        const updatedUser = {
          ...found,
          ...prev, // Keep current user state additions like newly selected color
          ...found, // Apply updated fields from remote
          color: activeColor // Ensure active user color is strictly preserved
        };
        saveAccountToLocal(updatedUser);
        return updatedUser;
      });
    });
    return () => unsubscribe();
  }, []);

  // Handle switching accounts from rail or login
  const handleSwitchUser = async (username: string) => {
    try {
      const user = await getOrCreateUser(username);
      setCurrentUser(user);
      saveAccountToLocal(user);
    } catch (err) {
      console.error('Error switching user:', err);
    }
  };

  const handleLogout = () => {
    setCurrentUser(null);
  };

  // If user is not logged in, show Login Screen
  if (!currentUser) {
    return (
      <LoginScreen
        onLoginSuccess={(user) => {
          setCurrentUser(user);
          saveAccountToLocal(user);
        }}
      />
    );
  }

  return (
    <div className="relative w-screen h-screen overflow-hidden grid grid-cols-1 md:grid-cols-[80px_1fr] bg-[#061700] text-[#d2eabb] font-sans selection:bg-[#ffb870]/30">
      {/* Background Layer with Bliss Image & Blur */}
      <div 
        className="fixed inset-0 bg-cover bg-center filter brightness-60 pointer-events-none scale-105 transition-transform duration-1000 z-0"
        style={{ backgroundImage: `url('/bliss-1024p.jpg')` }}
      />
      <div className="fixed inset-0 bg-[#061700]/30 backdrop-blur-[4px] pointer-events-none z-0" />

      {/* Adaptive Device Viewport Badge */}
      <div className="fixed top-2 right-3 z-50 pointer-events-none opacity-80 hover:opacity-100 transition-opacity">
        <span className="px-2.5 py-1 rounded-full bg-black/60 backdrop-blur-md border border-white/10 text-[10px] font-mono text-primary flex items-center gap-1.5 shadow-lg">
          <span className="material-symbols-outlined text-[13px]">{deviceIcon}</span>
          <span>{deviceMode} ({windowWidth}px)</span>
        </span>
      </div>

      {/* Navigation Rail Container */}
      <div className="z-40 pointer-events-auto">
        <NavigationRail
          activeTab={activeTab}
          setActiveTab={setActiveTab}
          currentUser={currentUser}
          allUsers={allUsers}
          onSwitchUser={handleSwitchUser}
          onLogout={handleLogout}
        />
      </div>

      {/* Main Content Area */}
      <main className="relative z-10 w-full h-full min-w-0 overflow-hidden flex flex-col">
        {activeTab === 'pulpit' && <DashboardView />}
        {activeTab === 'osoby' && <MessagingView currentUser={currentUser} allUsers={allUsers} />}
        {activeTab === 'profil' && (
          <ProfileView
            currentUser={currentUser}
            onUserUpdated={(updated) => {
              setCurrentUser(updated);
              saveAccountToLocal(updated);
            }}
            accentColor={accentColor}
            setAccentColor={setAccentColor}
          />
        )}
      </main>
    </div>
  );
}
