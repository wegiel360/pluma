import React, { useState, useEffect, useRef } from 'react';
import { UserProfile, Message } from '../types';
import { 
  sendMessageToFirestore, 
  deleteMessageFromFirestore,
  subscribeConversationMessages, 
  getOrCreateUser 
} from '../lib/firebase';
import { compressAndConvertToWebp, convertVideoToBase64 } from '../lib/imageUtils';

interface MessagingViewProps {
  currentUser: UserProfile;
  allUsers: UserProfile[];
}

export const MessagingView: React.FC<MessagingViewProps> = ({ currentUser, allUsers }) => {
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedPerson, setSelectedPerson] = useState<UserProfile | null>(() => {
    return allUsers.find(u => u.username !== currentUser.username) || allUsers[0] || null;
  });
  const [mobileShowChat, setMobileShowChat] = useState<boolean>(false);
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputText, setInputText] = useState<string>('');
  
  // Media attachments state
  const [attachedMediaBase64, setAttachedMediaBase64] = useState<string>('');
  const [attachedMediaType, setAttachedMediaType] = useState<'image' | 'video' | null>(null);
  const [isCompressing, setIsCompressing] = useState<boolean>(false);
  
  // Modal state
  const [showAddUserModal, setShowAddUserModal] = useState<boolean>(false);
  const [modalSearchQuery, setModalSearchQuery] = useState<string>('');
  const [customUsername, setCustomUsername] = useState<string>('');
  const [sending, setSending] = useState<boolean>(false);

  const messagesEndRef = useRef<HTMLDivElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Auto-select first contact if none selected
  useEffect(() => {
    if (!selectedPerson && allUsers.length > 0) {
      const other = allUsers.find(u => u.username !== currentUser.username) || allUsers[0];
      setSelectedPerson(other);
    }
  }, [allUsers, currentUser, selectedPerson]);

  const handleDeleteMessage = async (msgId: string) => {
    try {
      // Immediate UI update for instant feedback
      setMessages((prev) => prev.filter((m) => m.id !== msgId));
      await deleteMessageFromFirestore(msgId);
    } catch (err) {
      console.error('Błąd usuwania wiadomości:', err);
    }
  };

  // Subscribe to real-time messages with Firestore
  useEffect(() => {
    if (!selectedPerson) return;
    const unsubscribe = subscribeConversationMessages(
      currentUser.username,
      selectedPerson.username,
      (newMsgs) => {
        setMessages(newMsgs);
        setTimeout(() => {
          messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
        }, 100);
      }
    );
    return () => unsubscribe();
  }, [currentUser.username, selectedPerson]);

  const handleSend = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!selectedPerson) return;
    const textToSend = inputText.trim();
    if (!textToSend && !attachedMediaBase64) return;

    // Optimistic UI update for immediate user feedback
    const tempId = 'temp-' + Date.now();
    const optimisticMsg: Message = {
      id: tempId,
      sender: currentUser.username,
      recipient: selectedPerson.username,
      text: textToSend,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      imageUrl: attachedMediaType === 'image' ? attachedMediaBase64 : undefined,
      videoUrl: attachedMediaType === 'video' ? attachedMediaBase64 : undefined,
      isImage: attachedMediaType === 'image',
      isVideo: attachedMediaType === 'video',
      createdAt: Date.now()
    };

    setMessages((prev) => [...prev, optimisticMsg]);
    const currentInput = textToSend;
    const currentMedia = attachedMediaBase64;
    const currentType = attachedMediaType;

    setInputText('');
    setAttachedMediaBase64('');
    setAttachedMediaType(null);

    setSending(true);
    try {
      await sendMessageToFirestore(
        currentUser.username,
        selectedPerson.username,
        currentInput,
        currentType === 'image' ? currentMedia : undefined,
        currentType === 'video' ? currentMedia : undefined
      );
    } catch (err) {
      console.error('Error sending message to Firestore:', err);
      // Remove optimistic message if failure occurs
      setMessages((prev) => prev.filter((m) => m.id !== tempId));
      alert('Nie udało się wysłać wiadomości. Sprawdź połączenie.');
    } finally {
      setSending(false);
    }
  };

  const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setIsCompressing(true);
    try {
      if (file.type.startsWith('video/')) {
        const videoBase64 = await convertVideoToBase64(file);
        setAttachedMediaBase64(videoBase64);
        setAttachedMediaType('video');
      } else {
        const webpBase64 = await compressAndConvertToWebp(file, 1000);
        setAttachedMediaBase64(webpBase64);
        setAttachedMediaType('image');
      }
    } catch (err: any) {
      alert(err?.message || 'Błąd obróbki pliku w czacie.');
    } finally {
      setIsCompressing(false);
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  };

  const handleSelectFromGrid = (user: UserProfile) => {
    setSelectedPerson(user);
    setShowAddUserModal(false);
    setMobileShowChat(true);
  };

  const handleAddCustomUser = async (e: React.FormEvent) => {
    e.preventDefault();
    const clean = customUsername.trim().toLowerCase().replace(/^@/, '');
    if (!clean) return;
    try {
      const newUser = await getOrCreateUser(clean);
      setSelectedPerson(newUser);
      setShowAddUserModal(false);
      setCustomUsername('');
    } catch (err) {
      console.error('Error adding person:', err);
    }
  };

  const filteredUsers = allUsers.filter(u => 
    u.username.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (u.displayName && u.displayName.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  const modalFilteredUsers = allUsers.filter(u => 
    u.username !== currentUser.username && (
      u.username.toLowerCase().includes(modalSearchQuery.toLowerCase()) ||
      (u.displayName && u.displayName.toLowerCase().includes(modalSearchQuery.toLowerCase())) ||
      (u.bio && u.bio.toLowerCase().includes(modalSearchQuery.toLowerCase()))
    )
  );

  return (
    <main className="w-full h-full p-2 sm:p-4 md:p-6 pb-24 md:pb-6 flex flex-col relative z-10 overflow-hidden min-w-0">
      {/* Messaging Layout Container */}
      <div className="flex-1 glass-card border border-white/10 rounded-2xl md:rounded-[2.5rem] flex flex-col md:grid md:grid-cols-[280px_1fr] lg:grid-cols-[320px_1fr] overflow-hidden shadow-2xl min-h-0">
        {/* Sidebar: Conversation List */}
        <aside className={`w-full h-full border-b md:border-b-0 md:border-r border-white/10 flex flex-col shrink-0 min-h-0 overflow-hidden ${
          mobileShowChat ? 'hidden md:flex' : 'flex flex-1'
        }`}>
          <div className="p-4 sm:p-5 border-b border-white/10 flex items-center justify-between">
            <h2 className="text-xs font-bold font-mono text-on-surface-variant uppercase tracking-widest">
              osoby ({filteredUsers.length})
            </h2>
            <button
              onClick={() => setShowAddUserModal(true)}
              className="text-xs text-primary hover:underline flex items-center gap-1 font-mono cursor-pointer"
            >
              + znajdź osobę
            </button>
          </div>

          <div className="p-3 border-b border-white/5">
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="szukaj w rozmowach..."
              className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-1.5 text-xs text-on-surface outline-none focus:border-primary/50"
            />
          </div>

          <div className="flex-1 overflow-y-auto custom-scrollbar space-y-1 p-3">
            {filteredUsers.length === 0 ? (
              <div className="p-4 text-xs text-on-surface-variant/60 text-center font-mono">
                brak wyników
              </div>
            ) : (
              filteredUsers.map((u) => {
                const isSelected = selectedPerson?.username === u.username;
                const isSelf = u.username === currentUser.username;
                const userPfp = u.pfp || '/logo-kogut-500x500.png';

                return (
                  <div
                    key={u.username}
                    onClick={() => {
                      setSelectedPerson(u);
                      setMobileShowChat(true);
                    }}
                    className={`flex items-center gap-3.5 p-3 sm:p-3.5 rounded-2xl cursor-pointer transition-all ${
                      isSelected
                        ? 'bg-primary/10 text-primary shadow-sm'
                        : 'hover:bg-white/5 text-on-surface'
                    }`}
                  >
                    <div className="relative shrink-0">
                      <img
                        src={userPfp}
                        alt={u.username}
                        className="w-10 h-10 sm:w-11 sm:h-11 rounded-full border border-primary/20 object-cover p-0.5 bg-black/20"
                      />
                      <div className="absolute bottom-0.5 right-0.5 w-2.5 h-2.5 sm:w-3 sm:h-3 bg-emerald-400 border-2 border-[#061700] rounded-full" />
                    </div>

                    <div className="flex-1 min-w-0">
                      <div className="flex justify-between items-center mb-0.5">
                        <h4 className="text-sm font-bold truncate">@{u.username}</h4>
                        {isSelf && <span className="text-[10px] text-primary/70 font-mono">(ty)</span>}
                      </div>
                      <p className="text-xs text-on-surface-variant/70 truncate font-light">
                        {u.bio || 'użytkownik pluma'}
                      </p>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </aside>

        {/* Chat Window */}
        <section className={`flex-1 flex-col bg-surface-container/5 overflow-hidden ${
          !mobileShowChat ? 'hidden md:flex' : 'flex h-full'
        }`}>
          {selectedPerson ? (
            <>
              {/* Chat Header */}
              <header className="h-16 sm:h-20 px-4 sm:px-8 flex items-center justify-between border-b border-white/10 shrink-0">
                <div className="flex items-center gap-3 sm:gap-4">
                  {/* Mobile Back Button */}
                  <button
                    onClick={() => setMobileShowChat(false)}
                    className="md:hidden p-2 -ml-2 rounded-xl text-primary hover:bg-white/10 flex items-center justify-center cursor-pointer"
                    title="Wstecz do listy"
                  >
                    <span className="material-symbols-outlined text-xl">arrow_back</span>
                  </button>

                  <img
                    src={selectedPerson.pfp || '/logo-kogut-500x500.png'}
                    alt={selectedPerson.username}
                    className="w-9 h-9 sm:w-10 sm:h-10 rounded-full border border-primary/20 object-cover bg-black/20 shrink-0"
                  />
                  <div className="min-w-0">
                    <h3 className="text-sm sm:text-base font-medium text-on-surface truncate">
                      czat z @{selectedPerson.username}
                    </h3>
                    <p className="text-[10px] text-emerald-400 flex items-center gap-1.5 opacity-80 font-mono">
                      <span className="w-1.5 h-1.5 bg-emerald-400 rounded-full" />
                      online
                    </p>
                  </div>
                </div>
              </header>

              {/* Messages Body */}
              <div className="flex-1 overflow-y-auto p-4 sm:p-8 flex flex-col gap-4 sm:gap-6 custom-scrollbar">
                <div className="flex justify-center mb-1">
                  <span className="px-3 py-0.5 sm:px-4 sm:py-1 rounded-full bg-white/5 text-[9px] sm:text-[10px] text-on-surface-variant font-mono uppercase tracking-widest backdrop-blur-md border border-white/5">
                    dzisiaj
                  </span>
                </div>

                {messages.length === 0 ? (
                  <div className="flex-1 flex flex-col items-center justify-center text-center p-8 text-on-surface-variant/60 font-mono text-xs">
                    <span className="material-symbols-outlined text-4xl mb-2 text-primary/40">mark_chat_unread</span>
                    <p>brak wiadomości. napisz coś do @{selectedPerson.username}!</p>
                  </div>
                ) : (
                  messages.map((msg) => {
                    const isMe = msg.sender === currentUser.username;
                    return (
                      <div
                        key={msg.id}
                        className={`group relative flex items-end gap-3 max-w-[75%] ${isMe ? 'self-end flex-row-reverse' : 'self-start'}`}
                      >
                        {!isMe && (
                          <img
                            src={selectedPerson.pfp || '/logo-kogut-500x500.png'}
                            alt={selectedPerson.username}
                            className="w-7 h-7 rounded-full shrink-0 object-cover bg-black/20"
                          />
                        )}

                        <div
                          className={`relative p-4 rounded-3xl text-sm leading-relaxed border shadow-sm ${
                            isMe
                              ? 'bg-primary/20 text-on-surface border-primary/20 rounded-br-none'
                              : 'bg-white/5 backdrop-blur-xl text-on-surface border-white/10 rounded-bl-none'
                          }`}
                        >
                          {msg.isImage && msg.imageUrl && (
                            <img
                              src={msg.imageUrl}
                              alt="Załącznik zdjęcia"
                              className="max-w-xs max-h-56 rounded-xl object-contain mb-2 border border-white/10 bg-black/30"
                            />
                          )}
                          {msg.isVideo && msg.videoUrl && (
                            <div className="mb-2 max-w-xs overflow-hidden rounded-xl border border-white/10 bg-black/50">
                              <video
                                controls
                                autoPlay={false}
                                src={msg.videoUrl}
                                className="w-full max-h-56 rounded-xl object-cover"
                              />
                            </div>
                          )}
                          {msg.text && <p className="whitespace-pre-wrap">{msg.text}</p>}
                          
                          <div className="flex items-center justify-between gap-3 mt-1.5 pt-1 border-t border-white/5">
                            <button
                              onClick={() => handleDeleteMessage(msg.id)}
                              className="opacity-70 group-hover:opacity-100 transition-opacity p-1 text-red-400 hover:text-red-300 hover:bg-red-500/10 rounded-lg flex items-center gap-1 text-[10px] font-mono cursor-pointer"
                              title="Usuń wiadomość"
                            >
                              <span className="material-symbols-outlined text-xs">delete</span>
                              <span>usuń</span>
                            </button>

                            <p
                              className={`text-[9px] font-mono ml-auto ${
                                isMe ? 'text-primary/70' : 'text-on-surface-variant/60'
                              }`}
                            >
                              {msg.timestamp}
                            </p>
                          </div>
                        </div>
                      </div>
                    );
                  })
                )}
                <div ref={messagesEndRef} />
              </div>

              {/* Chat Input Area */}
              <footer className="p-3 sm:p-6 border-t border-white/10 shrink-0">
                {/* Media attachment preview badge */}
                {attachedMediaBase64 && (
                  <div className="mb-3 max-w-4xl mx-auto flex items-center gap-3 p-2 px-4 bg-black/50 border border-primary/30 rounded-2xl w-fit">
                    {attachedMediaType === 'image' ? (
                      <img
                        src={attachedMediaBase64}
                        alt="Załącznik"
                        className="w-10 h-10 object-cover rounded-lg border border-white/10 bg-black/20"
                      />
                    ) : (
                      <div className="w-10 h-10 rounded-lg bg-primary/20 border border-primary/40 flex items-center justify-center text-primary">
                        <span className="material-symbols-outlined text-lg">movie</span>
                      </div>
                    )}
                    <span className="text-xs text-primary font-mono">
                      załączono {attachedMediaType === 'video' ? 'plik wideo' : 'obraz WebP (<1MB)'}
                    </span>
                    <button
                      type="button"
                      onClick={() => {
                        setAttachedMediaBase64('');
                        setAttachedMediaType(null);
                      }}
                      className="text-on-surface-variant hover:text-red-400 cursor-pointer ml-2"
                    >
                      <span className="material-symbols-outlined text-sm">close</span>
                    </button>
                  </div>
                )}

                <form
                  onSubmit={handleSend}
                  className="max-w-4xl mx-auto flex items-center gap-2 sm:gap-3 bg-white/5 backdrop-blur-2xl border border-white/15 rounded-full px-3.5 sm:px-5 py-1.5 sm:py-2.5 focus-within:ring-1 focus-within:ring-primary/30 transition-all"
                >
                  <input
                    type="file"
                    ref={fileInputRef}
                    accept="image/*,video/*"
                    className="hidden"
                    onChange={handleFileSelect}
                  />

                  <button
                    type="button"
                    onClick={() => fileInputRef.current?.click()}
                    disabled={isCompressing}
                    className="text-on-surface-variant hover:text-primary transition-colors cursor-pointer relative"
                    title="Prześlij zdjęcie lub film z PC"
                  >
                    <span className="material-symbols-outlined text-2xl">attach_file</span>
                  </button>

                  <input
                    type="text"
                    value={inputText}
                    onChange={(e) => setInputText(e.target.value)}
                    placeholder={
                      isCompressing
                        ? 'przetwarzanie pliku wideo/obrazu...'
                        : `napisz wiadomość do @${selectedPerson.username}...`
                    }
                    className="flex-1 bg-transparent border-none focus:ring-0 outline-none text-sm text-on-surface placeholder-on-surface-variant/40"
                  />

                  <button
                    type="submit"
                    disabled={sending || isCompressing}
                    className="w-10 h-10 flex items-center justify-center bg-primary text-on-primary rounded-full hover:scale-105 active:scale-95 transition-all shadow-lg shadow-primary/20 cursor-pointer disabled:opacity-50"
                  >
                    <span className="material-symbols-outlined text-xl" style={{ fontVariationSettings: "'FILL' 1" }}>
                      send
                    </span>
                  </button>
                </form>
              </footer>
            </>
          ) : (
            <div className="flex-1 flex items-center justify-center text-on-surface-variant/50 font-mono text-xs">
              wybierz osobę, aby rozpocząć rozmowę
            </div>
          )}
        </section>
      </div>

      {/* Grid Modal for Selecting/Adding Friends */}
      {showAddUserModal && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-md flex items-center justify-center p-4">
          <div className="glass-card p-6 md:p-8 max-w-2xl w-full max-h-[85vh] flex flex-col gap-5 border border-white/15 shadow-2xl rounded-3xl">
            <div className="flex justify-between items-center border-b border-white/10 pb-4">
              <div>
                <h3 className="text-lg font-bold text-primary lowercase flex items-center gap-2">
                  <span className="material-symbols-outlined">group_add</span>
                  wybierz osobę z platformy
                </h3>
                <p className="text-xs text-on-surface-variant/70 font-mono">
                  kliknij w kartę użytkownika, aby nawiązać kontakt i rozpocząć rozmowę
                </p>
              </div>
              <button
                onClick={() => setShowAddUserModal(false)}
                className="p-2 rounded-full hover:bg-white/10 text-on-surface-variant hover:text-white transition-colors"
              >
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>

            {/* Search within Modal */}
            <div className="relative">
              <span className="material-symbols-outlined absolute left-3.5 top-2.5 text-on-surface-variant/50 text-sm">
                search
              </span>
              <input
                type="text"
                value={modalSearchQuery}
                onChange={(e) => setModalSearchQuery(e.target.value)}
                placeholder="szukaj użytkownika po nazwie lub opis..."
                className="w-full bg-black/40 border border-white/10 rounded-2xl pl-10 pr-4 py-2 text-xs text-on-surface outline-none focus:border-primary/50"
              />
            </div>

            {/* User Grid Cards */}
            <div className="flex-1 overflow-y-auto custom-scrollbar grid grid-cols-1 sm:grid-cols-2 gap-3.5 pr-1">
              {modalFilteredUsers.length === 0 ? (
                <div className="col-span-2 py-8 text-center text-xs text-on-surface-variant/60 font-mono">
                  brak zarejestrowanych osób pasujących do szukania
                </div>
              ) : (
                modalFilteredUsers.map((u) => {
                  const pfp = u.pfp || '/logo-kogut-500x500.png';
                  return (
                    <div
                      key={u.username}
                      onClick={() => handleSelectFromGrid(u)}
                      className="p-4 rounded-2xl bg-white/5 border border-white/10 hover:border-primary/50 hover:bg-primary/5 transition-all cursor-pointer flex items-center justify-between gap-3 group"
                    >
                      <div className="flex items-center gap-3 min-w-0">
                        <img
                          src={pfp}
                          alt={u.username}
                          className="w-12 h-12 rounded-full border border-primary/30 object-cover bg-black/30 shrink-0"
                        />
                        <div className="min-w-0">
                          <h4 className="text-sm font-bold text-on-surface group-hover:text-primary transition-colors truncate">
                            @{u.username}
                          </h4>
                          <p className="text-[11px] text-on-surface-variant/70 truncate">
                            {u.bio || 'użytkownik pluma'}
                          </p>
                        </div>
                      </div>

                      <button
                        type="button"
                        className="px-3 py-1.5 rounded-xl bg-primary/10 border border-primary/30 text-[11px] font-mono text-primary font-bold group-hover:bg-primary group-hover:text-on-primary transition-all shrink-0"
                      >
                        czatuj
                      </button>
                    </div>
                  );
                })
              )}
            </div>

            {/* Manual custom username fallback form */}
            <form onSubmit={handleAddCustomUser} className="border-t border-white/10 pt-4 flex items-center gap-2">
              <input
                type="text"
                value={customUsername}
                onChange={(e) => setCustomUsername(e.target.value)}
                placeholder="lub wpisz nowy pseudonim..."
                className="flex-1 h-10 px-4 rounded-xl text-xs bg-black/40 border border-white/10 text-on-surface outline-none focus:border-primary"
              />
              <button
                type="submit"
                className="px-4 py-2 rounded-xl text-xs font-bold bg-primary text-on-primary hover:scale-105 transition-all cursor-pointer"
              >
                dodaj
              </button>
            </form>
          </div>
        </div>
      )}

      {/* Modal for adding user */}
    </main>
  );
};
