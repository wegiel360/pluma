import React, { useState, useEffect } from 'react';
import { TabType, UserProfile } from '../types';
import { getSavedAccounts } from '../lib/savedAccounts';

interface NavigationRailProps {
  activeTab: TabType;
  setActiveTab: (tab: TabType) => void;
  currentUser: UserProfile;
  allUsers: UserProfile[];
  onSwitchUser: (username: string) => void;
  onLogout: () => void;
}

export const NavigationRail: React.FC<NavigationRailProps> = ({
  activeTab,
  setActiveTab,
  currentUser,
  onSwitchUser,
  onLogout
}) => {
  const [savedAccounts, setSavedAccounts] = useState<UserProfile[]>([]);

  useEffect(() => {
    setSavedAccounts(getSavedAccounts());
  }, [currentUser]);

  return (
    <nav className="fixed bottom-2 left-2 right-2 h-16 md:relative md:bottom-auto md:left-auto md:right-auto md:top-auto md:w-full md:h-full flex flex-row md:flex-col items-center justify-around md:justify-start px-3 md:px-0 md:py-8 z-50 floating-glass rounded-2xl md:rounded-none border border-white/10 md:border-r md:border-y-0 md:border-l-0 select-none shadow-2xl backdrop-blur-2xl">
      {/* Top Logo (hidden on mobile bottom bar, visible on tablet/desktop) */}
      <div 
        onClick={() => setActiveTab('pulpit')}
        className="hidden md:flex flex-col items-center gap-2 cursor-pointer mb-8 group"
      >
        <div className="w-10 h-10 flex items-center justify-center group-hover:scale-110 transition-transform">
          <img 
            src="/logo-kogut-100x100.png" 
            alt="Pluma Logo" 
            className="w-full h-full object-contain drop-shadow-[0_0_10px_rgba(255,184,112,0.4)]" 
          />
        </div>
      </div>

      {/* Main Navigation Items */}
      <div className="flex flex-row md:flex-col gap-2 sm:gap-6 items-center justify-around w-full md:w-auto md:flex-1">
        {/* Pulpit */}
        <button
          onClick={() => setActiveTab('pulpit')}
          className={`w-11 h-11 md:w-12 md:h-12 flex items-center justify-center rounded-full transition-all duration-300 relative group cursor-pointer ${
            activeTab === 'pulpit'
              ? 'text-primary bg-primary/10 shadow-[0_0_12px_rgba(255,184,112,0.2)]'
              : 'text-on-surface-variant hover:bg-white/10 hover:text-primary'
          }`}
          title="Pulpit"
        >
          <span className="material-symbols-outlined text-[22px] md:text-[24px]">dashboard</span>
          <span className="hidden md:block absolute left-full ml-4 px-2.5 py-1 bg-surface-container-high text-xs rounded-md opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity whitespace-nowrap z-50 shadow-lg border border-white/10 lowercase">
            pulpit
          </span>
        </button>

        {/* Osoby */}
        <button
          onClick={() => setActiveTab('osoby')}
          className={`w-11 h-11 md:w-12 md:h-12 flex items-center justify-center rounded-full transition-all duration-300 relative group cursor-pointer ${
            activeTab === 'osoby'
              ? 'text-primary bg-primary/10 shadow-[0_0_12px_rgba(255,184,112,0.2)]'
              : 'text-on-surface-variant hover:bg-white/10 hover:text-primary'
          }`}
          title="Osoby"
        >
          <span className="material-symbols-outlined text-[22px] md:text-[24px]">group</span>
          <span className="hidden md:block absolute left-full ml-4 px-2.5 py-1 bg-surface-container-high text-xs rounded-md opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity whitespace-nowrap z-50 shadow-lg border border-white/10 lowercase">
            osoby
          </span>
        </button>

        {/* Profil */}
        <button
          onClick={() => setActiveTab('profil')}
          className={`w-11 h-11 md:w-12 md:h-12 flex items-center justify-center rounded-full transition-all duration-300 relative group cursor-pointer ${
            activeTab === 'profil'
              ? 'text-primary bg-primary/10 shadow-[0_0_12px_rgba(255,184,112,0.2)]'
              : 'text-on-surface-variant hover:bg-white/10 hover:text-primary'
          }`}
          title="Profil"
        >
          <span 
            className="material-symbols-outlined text-[22px] md:text-[24px]"
            style={activeTab === 'profil' ? { fontVariationSettings: "'FILL' 1" } : {}}
          >
            person
          </span>
          <span className="hidden md:block absolute left-full ml-4 px-2.5 py-1 bg-surface-container-high text-xs rounded-md opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity whitespace-nowrap z-50 shadow-lg border border-white/10 lowercase">
            profil
          </span>
        </button>
      </div>

      {/* Account Switcher & Logout */}
      <div className="flex flex-row md:flex-col gap-2 md:gap-3 items-center shrink-0">
        <div
          className="relative group cursor-pointer"
          onClick={() => setActiveTab('profil')}
        >
          <img
            src={currentUser.pfp || '/logo-kogut-500x500.png'}
            alt={currentUser.username}
            className="w-8 h-8 md:w-10 md:h-10 rounded-full border-2 border-primary shadow-sm"
          />
          <span className="hidden md:block absolute left-full ml-4 px-2.5 py-1 bg-surface-container-high text-xs rounded-md opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity whitespace-nowrap z-50 shadow-lg border border-white/10 font-mono">
            @{currentUser.username}
          </span>
        </div>

        <button
          onClick={onLogout}
          className="w-8 h-8 flex items-center justify-center rounded-full text-on-surface-variant/50 hover:text-red-400 hover:bg-red-500/10 transition-colors cursor-pointer"
          title="Wyloguj się"
        >
          <span className="material-symbols-outlined text-[18px]">logout</span>
        </button>
      </div>
    </nav>
  );
};
