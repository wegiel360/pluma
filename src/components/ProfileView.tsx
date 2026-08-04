import React, { useState } from 'react';
import { UserProfile } from '../types';
import { updateUserInFirestore, uploadUserAsset } from '../lib/firebase';
import { formatJoinedDate, compressAndConvertToWebp } from '../lib/imageUtils';

interface ProfileViewProps {
  currentUser: UserProfile;
  onUserUpdated: (updatedUser: UserProfile) => void;
  accentColor: string;
  setAccentColor: (color: string) => void;
}

export const ProfileView: React.FC<ProfileViewProps> = ({
  currentUser,
  onUserUpdated,
  accentColor,
  setAccentColor
}) => {
  const [isEditingBio, setIsEditingBio] = useState<boolean>(false);
  const [bioText, setBioText] = useState<string>(currentUser.bio || 'i use arch btw');
  
  const [bannerUrl, setBannerUrl] = useState<string>(
    currentUser.banner || '/bliss-1024p.jpg'
  );
  const [isEditingBanner, setIsEditingBanner] = useState<boolean>(false);

  const [pfpUrl, setPfpUrl] = useState<string>(
    currentUser.pfp || '/logo-kogut-500x500.png'
  );
  const [isEditingPfp, setIsEditingPfp] = useState<boolean>(false);

  const [customColor, setCustomColor] = useState<string>('#ff70b8');
  const [isSaving, setIsSaving] = useState<boolean>(false);
  const [uploadError, setUploadError] = useState<string | null>(null);

  const handleSaveBio = async () => {
    setIsSaving(true);
    try {
      await updateUserInFirestore(currentUser.username, { bio: bioText });
      onUserUpdated({ ...currentUser, bio: bioText });
      setIsEditingBio(false);
    } catch (err) {
      console.error('Error updating bio:', err);
    } finally {
      setIsSaving(false);
    }
  };

  const handleBannerFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setIsSaving(true);
    setUploadError(null);
    try {
      // 1. Convert to WebP and ensure <1MB base64 compression
      const webpBase64 = await compressAndConvertToWebp(file, 1600);
      // 2. Upload to Firebase Storage and delete old asset if present
      const newUrl = await uploadUserAsset(
        currentUser.username,
        'banner',
        webpBase64,
        currentUser.banner
      );
      setBannerUrl(newUrl);
      await updateUserInFirestore(currentUser.username, { banner: newUrl });
      onUserUpdated({ ...currentUser, banner: newUrl });
      setIsEditingBanner(false);
    } catch (err: any) {
      console.error('Błąd wgrywania baneru:', err);
      setUploadError(err?.message || 'Błąd obróbki pliku baneru.');
    } finally {
      setIsSaving(false);
    }
  };

  const handlePfpFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setIsSaving(true);
    setUploadError(null);
    try {
      // 1. Convert to WebP and ensure <1MB base64 compression
      const webpBase64 = await compressAndConvertToWebp(file, 600);
      // 2. Upload to Firebase Storage and delete old asset if present
      const newUrl = await uploadUserAsset(
        currentUser.username,
        'pfp',
        webpBase64,
        currentUser.pfp
      );
      setPfpUrl(newUrl);
      await updateUserInFirestore(currentUser.username, { pfp: newUrl });
      onUserUpdated({ ...currentUser, pfp: newUrl });
      setIsEditingPfp(false);
    } catch (err: any) {
      console.error('Błąd wgrywania zdjęcia profilowego:', err);
      setUploadError(err?.message || 'Błąd obróbki zdjęcia profilowego.');
    } finally {
      setIsSaving(false);
    }
  };

  const handleColorChange = async (colorHex: string) => {
    setAccentColor(colorHex);
    document.documentElement.style.setProperty('--accent-color', colorHex);
    document.documentElement.style.setProperty('--color-primary', colorHex);
    try {
      await updateUserInFirestore(currentUser.username, { color: colorHex });
      onUserUpdated({ ...currentUser, color: colorHex });
    } catch (err) {
      console.error('Error saving color preference:', err);
    }
  };

  const currentColor = (currentUser.color || accentColor || '#ffb870').toLowerCase();

  return (
    <main className="w-full h-full relative z-10 p-3 sm:p-5 md:p-8 pb-24 md:pb-8 overflow-y-auto custom-scrollbar min-w-0">
      <div className="max-w-6xl mx-auto space-y-6 md:space-y-8 min-w-0">
        
        {/* Profile Header Section */}
        <section className="relative">
          {/* 21:9 Banner */}
          <div className="w-full aspect-[21/8] min-h-[120px] rounded-2xl md:rounded-[3rem] overflow-hidden floating-glass border-white/5 relative group">
            <img
              src={bannerUrl}
              alt="Banner"
              className="w-full h-full object-cover filter brightness-90 grayscale-[0.1]"
              style={{ objectPosition: '50% 20%' }}
            />
            {/* Gradient Overlay */}
            <div className="absolute inset-0 bg-gradient-to-t from-[#061700]/90 via-[#061700]/20 to-transparent" />
            <div className="absolute inset-0 bg-primary/5 pointer-events-none" />

            <button
              onClick={() => setIsEditingBanner(!isEditingBanner)}
              className="absolute top-3 right-3 md:top-6 md:right-6 bg-white/10 backdrop-blur-md px-3 py-1.5 md:px-4 md:py-2 rounded-full border border-white/10 text-[11px] md:text-xs flex items-center gap-1.5 md:gap-2 hover:bg-primary hover:text-on-primary transition-all lowercase cursor-pointer z-10"
            >
              <span className="material-symbols-outlined text-[16px] md:text-[18px]">upload_file</span>
              zmień tło z pc
            </button>
          </div>

          {/* Banner Edit Modal Overlay */}
          {isEditingBanner && (
            <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-md flex items-center justify-center p-4">
              <div className="glass-card p-6 max-w-lg w-full space-y-4 shadow-2xl border border-white/15">
                <div className="flex justify-between items-center border-b border-white/10 pb-3">
                  <h3 className="text-sm font-bold text-primary lowercase flex items-center gap-2">
                    <span className="material-symbols-outlined text-base">upload_file</span>
                    zmień tło profilu (baner z PC)
                  </h3>
                  <button
                    onClick={() => setIsEditingBanner(false)}
                    className="text-on-surface-variant hover:text-white cursor-pointer"
                  >
                    <span className="material-symbols-outlined text-lg">close</span>
                  </button>
                </div>
                <p className="text-xs text-on-surface-variant/80 font-mono">
                  wybierz plik z dysku. zostanie automatycznie przekonwertowany do formatu WebP z zachowaniem przezroczystości i skompresowany do &lt;1MB.
                </p>
                <input
                  type="file"
                  accept="image/*"
                  onChange={handleBannerFileSelect}
                  disabled={isSaving}
                  className="block w-full text-xs text-on-surface-variant file:mr-4 file:py-2.5 file:px-4 file:rounded-xl file:border-0 file:text-xs file:font-semibold file:bg-primary file:text-on-primary hover:file:opacity-90 cursor-pointer"
                />
                {isSaving && (
                  <p className="text-xs text-primary font-mono animate-pulse">
                    kompresowanie i zapisywanie obrazu...
                  </p>
                )}
              </div>
            </div>
          )}

          {/* Identity Info */}
          <div className="flex flex-col md:flex-row items-center md:items-end text-center md:text-left gap-3 md:gap-6 -mt-10 sm:-mt-12 md:-mt-16 px-3 sm:px-4 md:px-12 relative z-20">
            <div className="relative group">
              <div 
                onClick={() => setIsEditingPfp(true)}
                className="w-28 h-28 sm:w-32 sm:h-32 md:w-36 md:h-36 rounded-full border-4 sm:border-8 border-[#061700]/80 shadow-2xl overflow-hidden floating-glass p-0.5 cursor-pointer relative bg-[#061700]/90"
              >
                <img
                  src={pfpUrl}
                  alt={currentUser.username}
                  className="w-full h-full rounded-full object-cover"
                />
                <div className="absolute inset-0 bg-black/50 rounded-full flex flex-col items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity text-white text-center p-2">
                  <span className="material-symbols-outlined text-xl sm:text-2xl">upload</span>
                  <span className="text-[9px] sm:text-[10px] font-mono mt-0.5">zmień pfp</span>
                </div>
              </div>
            </div>

            <div className="flex-1 pb-1 sm:pb-4">
              <h1 className="text-2xl sm:text-3xl md:text-4xl font-bold text-primary tracking-tight lowercase">
                @{currentUser.username}
              </h1>
              <p className="text-[11px] sm:text-xs text-on-surface-variant/80 font-mono lowercase mt-0.5 sm:mt-1">
                dołączył {formatJoinedDate(currentUser.createdAt)}
              </p>
            </div>

            <div className="flex gap-2 sm:gap-4 pb-2 sm:pb-4">
              <button
                onClick={() => setIsEditingBio(!isEditingBio)}
                className="px-5 py-2.5 sm:px-8 sm:py-3 rounded-full bg-primary text-on-primary font-medium text-xs transition-all hover:shadow-lg hover:shadow-primary/20 active:scale-95 lowercase cursor-pointer"
              >
                edytuj bio
              </button>
            </div>
          </div>

          {/* PFP Edit Modal Overlay */}
          {isEditingPfp && (
            <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-md flex items-center justify-center p-4">
              <div className="glass-card p-6 max-w-lg w-full space-y-4 shadow-2xl border border-white/15">
                <div className="flex justify-between items-center border-b border-white/10 pb-3">
                  <h3 className="text-sm font-bold text-primary lowercase flex items-center gap-2">
                    <span className="material-symbols-outlined text-base">account_circle</span>
                    zmień zdjęcie profilowe (PFP z PC)
                  </h3>
                  <button
                    onClick={() => setIsEditingPfp(false)}
                    className="text-on-surface-variant hover:text-white cursor-pointer"
                  >
                    <span className="material-symbols-outlined text-lg">close</span>
                  </button>
                </div>
                <p className="text-xs text-on-surface-variant/80 font-mono">
                  wybierz plik graficzny z dysku. system skompresuje obraz do formatu WebP z obsługą przezroczystości (&lt;1MB).
                </p>
                <input
                  type="file"
                  accept="image/*"
                  onChange={handlePfpFileSelect}
                  disabled={isSaving}
                  className="block w-full text-xs text-on-surface-variant file:mr-4 file:py-2.5 file:px-4 file:rounded-xl file:border-0 file:text-xs file:font-semibold file:bg-primary file:text-on-primary hover:file:opacity-90 cursor-pointer"
                />
                {isSaving && (
                  <p className="text-xs text-primary font-mono animate-pulse">
                    kompresowanie i zapisywanie zdjęcia...
                  </p>
                )}
              </div>
            </div>
          )}

          {uploadError && (
            <p className="text-xs text-red-400 mt-2 ml-12 font-mono">{uploadError}</p>
          )}
        </section>

        {/* Content Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 px-2">
          {/* Bio Column */}
          <div className="lg:col-span-4 space-y-8">
            <div className="glass-card p-8">
              <div className="flex items-center gap-3 mb-6">
                <span className="material-symbols-outlined text-primary/80">fingerprint</span>
                <h2 className="text-xs font-mono text-on-surface-variant/80 uppercase tracking-wider lowercase">
                  o mnie
                </h2>
              </div>

              {isEditingBio ? (
                <div className="space-y-3">
                  <textarea
                    value={bioText}
                    onChange={(e) => setBioText(e.target.value)}
                    className="w-full bg-black/40 border border-white/10 rounded-xl p-3 text-xs text-on-surface outline-none focus:border-primary"
                    rows={4}
                  />
                  <div className="flex justify-end gap-2">
                    <button
                      onClick={() => setIsEditingBio(false)}
                      className="px-3 py-1.5 rounded-lg text-xs text-on-surface-variant"
                    >
                      anuluj
                    </button>
                    <button
                      onClick={handleSaveBio}
                      disabled={isSaving}
                      className="neon-button px-4 py-1.5 rounded-lg text-xs font-bold text-on-primary cursor-pointer"
                    >
                      zapisz
                    </button>
                  </div>
                </div>
              ) : (
                <p className="text-sm text-on-surface leading-relaxed font-light">
                  {currentUser.bio || 'i use arch btw'}
                </p>
              )}
            </div>
          </div>

          {/* Customization Column */}
          <div className="lg:col-span-8">
            <div className="glass-card p-10 overflow-hidden relative">
              <div className="absolute -top-12 -right-12 w-48 h-48 bg-primary/10 blur-[80px] rounded-full pointer-events-none" />

              <div className="flex items-center gap-3 mb-6">
                <span className="material-symbols-outlined text-primary/80">palette</span>
                <h2 className="text-xs font-mono text-on-surface-variant/80 uppercase tracking-wider lowercase">
                  personalizacja wyglądu
                </h2>
              </div>

              <p className="text-xs text-on-surface-variant/80 mb-10 lowercase">
                wybierz swój unikalny kolor profilu tego użytkownika, który odmieni interfejs.
              </p>

              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-6 gap-6">
                {/* Bursztyn */}
                <button
                  onClick={() => handleColorChange('#ffb870')}
                  className="flex flex-col items-center gap-4 group cursor-pointer"
                >
                  <div
                    className={`w-12 h-12 rounded-full bg-[#ffb870] shadow-lg transition-transform group-hover:scale-110 ${
                      currentColor === '#ffb870' ? 'ring-4 ring-[#ffb870]/40 shadow-[#ffb870]/30 scale-105' : ''
                    }`}
                  />
                  <span className="text-xs font-mono text-on-surface-variant/80 lowercase">bursztyn</span>
                </button>

                {/* Morska */}
                <button
                  onClick={() => handleColorChange('#67dac2')}
                  className="flex flex-col items-center gap-4 group cursor-pointer"
                >
                  <div
                    className={`w-12 h-12 rounded-full bg-[#67dac2] shadow-lg transition-transform group-hover:scale-110 ${
                      currentColor === '#67dac2' ? 'ring-4 ring-[#67dac2]/40 shadow-[#67dac2]/30 scale-105' : ''
                    }`}
                  />
                  <span className="text-xs font-mono text-on-surface-variant/80 lowercase">morska</span>
                </button>

                {/* Błękit */}
                <button
                  onClick={() => handleColorChange('#92cfea')}
                  className="flex flex-col items-center gap-4 group cursor-pointer"
                >
                  <div
                    className={`w-12 h-12 rounded-full bg-[#92cfea] shadow-lg transition-transform group-hover:scale-110 ${
                      currentColor === '#92cfea' ? 'ring-4 ring-[#92cfea]/40 shadow-[#92cfea]/30 scale-105' : ''
                    }`}
                  />
                  <span className="text-xs font-mono text-on-surface-variant/80 lowercase">błękit</span>
                </button>

                {/* Płynny */}
                <button
                  onClick={() => handleColorChange('#98ff98')}
                  className="flex flex-col items-center gap-4 group cursor-pointer"
                >
                  <div
                    className={`w-12 h-12 rounded-full bg-[#98FF98] shadow-lg transition-transform group-hover:scale-110 ${
                      currentColor === '#98ff98' ? 'ring-4 ring-[#98ff98]/40 shadow-[#98ff98]/30 scale-105' : ''
                    }`}
                  />
                  <span className="text-xs font-mono text-on-surface-variant/80 lowercase">płynny</span>
                </button>

                {/* Grafit */}
                <button
                  onClick={() => handleColorChange('#d2eabb')}
                  className="flex flex-col items-center gap-4 group cursor-pointer"
                >
                  <div
                    className={`w-12 h-12 rounded-full bg-[#d2eabb] shadow-lg transition-transform group-hover:scale-110 ${
                      currentColor === '#d2eabb' ? 'ring-4 ring-[#d2eabb]/40 shadow-[#d2eabb]/30 scale-105' : ''
                    }`}
                  />
                  <span className="text-xs font-mono text-on-surface-variant/80 lowercase">grafit</span>
                </button>

                {/* Dynamic Color Picker (Własny kolor z palety) */}
                <label className="flex flex-col items-center gap-4 group cursor-pointer relative">
                  <div
                    className="w-12 h-12 rounded-full border-2 border-white/30 flex items-center justify-center transition-all group-hover:scale-110 overflow-hidden relative shadow-lg"
                    style={{
                      background: 'conic-gradient(from 0deg, red, yellow, lime, aqua, blue, magenta, red)',
                    }}
                  >
                    <input
                      type="color"
                      value={currentColor}
                      onChange={(e) => {
                        setCustomColor(e.target.value);
                        handleColorChange(e.target.value);
                      }}
                      className="absolute inset-0 opacity-0 w-full h-full cursor-pointer"
                      title="Wybierz dowolny kolor z palety"
                    />
                    <div
                      className="w-5 h-5 rounded-full border-2 border-white shadow-md pointer-events-none"
                      style={{ backgroundColor: currentColor }}
                    />
                  </div>
                  <span className="text-xs font-mono text-on-surface-variant/80 lowercase flex items-center gap-1">
                    <span className="material-symbols-outlined text-xs">palette</span>
                    własny
                  </span>
                </label>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
};
