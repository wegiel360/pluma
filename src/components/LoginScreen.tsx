import React, { useState, useEffect } from 'react';
import { getOrCreateUser } from '../lib/firebase';
import { getSavedAccounts, saveAccountToLocal, removeSavedAccountFromLocal } from '../lib/savedAccounts';
import { UserProfile } from '../types';

interface LoginScreenProps {
  onLoginSuccess: (user: UserProfile) => void;
}

export const LoginScreen: React.FC<LoginScreenProps> = ({ onLoginSuccess }) => {
  const [username, setUsername] = useState<string>('');
  const [password, setPassword] = useState<string>('');
  const [showPassword, setShowPassword] = useState<boolean>(false);
  const [isRegisterMode, setIsRegisterMode] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [savedAccounts, setSavedAccounts] = useState<UserProfile[]>([]);

  useEffect(() => {
    setSavedAccounts(getSavedAccounts());
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const cleanUsername = username.trim().toLowerCase().replace(/^@/, '');
    if (!cleanUsername) {
      setError('Wprowadź prawidłowy pseudonim');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const user = await getOrCreateUser(cleanUsername);
      saveAccountToLocal(user);
      onLoginSuccess(user);
    } catch (err: any) {
      console.error('Registration/login error:', err);
      setError(err?.message || 'Błąd podczas logowania/rejestracji');
    } finally {
      setLoading(false);
    }
  };

  const handleQuickAccountClick = async (accountUsername: string) => {
    setLoading(true);
    setError(null);
    try {
      const user = await getOrCreateUser(accountUsername);
      saveAccountToLocal(user);
      onLoginSuccess(user);
    } catch (err: any) {
      console.error('Quick login error:', err);
      setError('Nie udało się zalogować na konto @' + accountUsername);
    } finally {
      setLoading(false);
    }
  };

  const handleRemoveSavedAccount = (e: React.MouseEvent, accountUsername: string) => {
    e.stopPropagation();
    const updated = removeSavedAccountFromLocal(accountUsername);
    setSavedAccounts(updated);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-[#061700]">
      {/* Background Layer with Bliss */}
      <div 
        className="fixed inset-0 bg-cover bg-center filter brightness-50 z-0 scale-105 transition-transform duration-1000"
        style={{ backgroundImage: `url('/bliss-1024p.jpg')` }}
      />
      <div className="fixed inset-0 bg-surface-dim/40 backdrop-blur-[6px] z-0" />

      {/* Login Card Container */}
      <main className="w-full max-w-md relative z-10">
        <div className="liquid-glass-card iridescent-border p-8 md:p-12 flex flex-col items-center">
          {/* Logo Section */}
          <div className="mb-8 flex flex-col items-center gap-3">
            <div className="w-20 h-20 flex items-center justify-center">
              <img 
                src="/logo-kogut-250x250.png" 
                alt="Pluma logo" 
                className="w-full h-full object-contain drop-shadow-[0_0_15px_rgba(255,184,112,0.4)]"
              />
            </div>
            <h1 className="font-headline-lg text-3xl font-bold text-primary tracking-tight">
              pluma
            </h1>
            <p className="text-xs text-on-surface-variant/70 font-mono">liquid glass messenger</p>
          </div>

          {/* Error alert if any */}
          {error && (
            <div className="w-full mb-4 p-3 rounded-xl bg-error-container/60 border border-error/30 text-error text-xs text-center font-medium leading-relaxed">
              {error}
            </div>
          )}

          {/* Form Section */}
          <form onSubmit={handleSubmit} className="w-full space-y-5">
            {/* Username Field */}
            <div className="space-y-1.5">
              <label htmlFor="username" className="text-xs font-medium text-on-surface-variant/80 ml-1 block">
                Użytkownik
              </label>
              <div className="relative group">
                <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-primary/60 text-xl pointer-events-none transition-colors group-focus-within:text-primary">
                  person
                </span>
                <input
                  id="username"
                  type="text"
                  required
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  placeholder="wpisz swój pseudonim..."
                  className="input-glass w-full h-12 pl-12 pr-4 rounded-xl text-sm text-on-surface placeholder:text-on-surface-variant/40"
                />
              </div>
            </div>

            {/* Password Field */}
            <div className="space-y-1.5">
              <label htmlFor="password" className="text-xs font-medium text-on-surface-variant/80 ml-1 block">
                Hasło
              </label>
              <div className="relative group">
                <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-primary/60 text-xl pointer-events-none transition-colors group-focus-within:text-primary">
                  lock
                </span>
                <input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="input-glass w-full h-12 pl-12 pr-12 rounded-xl text-sm text-on-surface placeholder:text-on-surface-variant/40"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-on-surface-variant hover:text-primary transition-colors"
                >
                  <span className="material-symbols-outlined text-xl">
                    {showPassword ? 'visibility' : 'visibility_off'}
                  </span>
                </button>
              </div>
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={loading}
              className="neon-button w-full h-13 rounded-full flex items-center justify-center font-bold text-sm text-on-primary shadow-lg shadow-primary/20 mt-4 active:scale-98 transition-all cursor-pointer disabled:opacity-50"
            >
              {loading ? 'Ładowanie...' : (isRegisterMode ? 'Zarejestruj się' : 'Zaloguj się')}
            </button>
          </form>

          {/* Footer Links */}
          <footer className="mt-8 w-full space-y-6 text-center">
            <div className="space-y-2">
              <button
                type="button"
                onClick={() => setIsRegisterMode(!isRegisterMode)}
                className="text-xs text-on-surface-variant hover:text-primary transition-colors cursor-pointer"
              >
                {isRegisterMode ? 'Masz już konto? Zaloguj się' : 'Nie masz konta? Zarejestruj się'}
              </button>
            </div>

            {/* Saved Accounts / Multi-Account Switcher */}
            <div className="pt-6 border-t border-white/5 space-y-3">
              <p className="text-[10px] font-mono tracking-widest text-on-surface-variant/60 uppercase">
                zapisane konta na tym urządzeniu
              </p>

              {savedAccounts.length === 0 ? (
                <p className="text-xs text-on-surface-variant/40 font-mono py-2 italic">
                  brak zapisanych kont
                </p>
              ) : (
                <div className="flex flex-wrap justify-center gap-4 max-h-36 overflow-y-auto custom-scrollbar p-1">
                  {savedAccounts.map((acc) => (
                    <div
                      key={acc.username}
                      onClick={() => handleQuickAccountClick(acc.username)}
                      className="relative flex items-center gap-2.5 px-3 py-1.5 rounded-2xl bg-white/5 border border-white/10 hover:border-primary/50 hover:bg-white/10 transition-all cursor-pointer group"
                    >
                      <img
                        src={acc.pfp || '/logo-kogut-500x500.png'}
                        alt={acc.username}
                        className="w-7 h-7 rounded-full object-cover border border-primary/30"
                      />
                      <span className="text-xs font-mono font-medium text-on-surface group-hover:text-primary">
                        @{acc.username}
                      </span>
                      <button
                        type="button"
                        onClick={(e) => handleRemoveSavedAccount(e, acc.username)}
                        className="w-5 h-5 rounded-full hover:bg-red-500/20 text-on-surface-variant/50 hover:text-red-400 flex items-center justify-center transition-colors ml-1"
                        title="Usuń z zapisanych kont"
                      >
                        <span className="material-symbols-outlined text-xs">close</span>
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </footer>
        </div>
      </main>
    </div>
  );
};
