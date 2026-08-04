import React, { useState, useEffect, useCallback } from 'react';

interface LocationItem {
  name: string;
  country?: string;
  admin1?: string;
  latitude: number;
  longitude: number;
}

interface HourlyForecastItem {
  time: string;
  rawHour: number;
  temp: number;
  icon: string;
  rainChance: number;
  condition: string;
}

interface WeatherState {
  cityName: string;
  temp: number;
  high: number;
  low: number;
  condition: string;
  humidity: number;
  windSpeed: number;
  pressure: number;
  icon: string;
  hourly: HourlyForecastItem[];
  lastUpdated: string;
}

const DEFAULT_LOCATION: LocationItem = {
  name: 'Jastrzębie-Zdrój',
  admin1: 'Śląsk',
  country: 'Polska',
  latitude: 49.9542,
  longitude: 18.5833
};

function getWmoDetails(code: number, isNight: boolean = false) {
  switch (code) {
    case 0:
      return { condition: 'Bezchmurnie', icon: isNight ? 'nights_stay' : 'sunny' };
    case 1:
      return { condition: 'Słonecznie', icon: isNight ? 'nights_stay' : 'sunny' };
    case 2:
      return { condition: 'Częściowe zachmurzenie', icon: isNight ? 'nights_stay' : 'partly_cloudy_day' };
    case 3:
      return { condition: 'Pochmurno', icon: 'cloud' };
    case 45:
    case 48:
      return { condition: 'Mgła', icon: 'foggy' };
    case 51:
    case 53:
    case 55:
      return { condition: 'Mżawka', icon: 'grain' };
    case 61:
    case 63:
    case 65:
      return { condition: 'Deszcz', icon: 'rainy' };
    case 71:
    case 73:
    case 75:
      return { condition: 'Opady śniegu', icon: 'ac_unit' };
    case 80:
    case 81:
    case 82:
      return { condition: 'Przelotny deszcz', icon: 'rainy' };
    case 95:
    case 96:
    case 99:
      return { condition: 'Burza', icon: 'thunderstorm' };
    default:
      return { condition: 'Umiarkowanie', icon: 'partly_cloudy_day' };
  }
}

export const DashboardView: React.FC = () => {
  const [currentLocation, setCurrentLocation] = useState<LocationItem>(DEFAULT_LOCATION);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [searchResults, setSearchResults] = useState<LocationItem[]>([]);
  const [isSearching, setIsSearching] = useState<boolean>(false);
  const [isLoadingWeather, setIsLoadingWeather] = useState<boolean>(false);
  const [now, setNow] = useState<Date>(new Date());

  const [weather, setWeather] = useState<WeatherState>({
    cityName: 'Jastrzębie-Zdrój, Śląsk',
    temp: 21,
    high: 24,
    low: 14,
    condition: 'Słonecznie',
    humidity: 52,
    windSpeed: 10,
    pressure: 1017,
    icon: 'sunny',
    hourly: [],
    lastUpdated: ''
  });

  // Digital clock interval (1 second)
  useEffect(() => {
    const timer = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  // Fetch Weather Data from Open-Meteo API
  const fetchWeather = useCallback(async (loc: LocationItem) => {
    setIsLoadingWeather(true);
    try {
      const url = `https://api.open-meteo.com/v1/forecast?latitude=${loc.latitude}&longitude=${loc.longitude}&current=temperature_2m,relative_humidity_2m,surface_pressure,wind_speed_10m,weather_code&hourly=temperature_2m,relative_humidity_2m,precipitation_probability,weather_code&daily=temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=2`;
      const res = await fetch(url);
      if (!res.ok) throw new Error('Błąd pobierania pogody');
      const data = await res.json();

      const current = data.current || {};
      const daily = data.daily || {};
      const hourly = data.hourly || {};

      const currentTemp = Math.round(current.temperature_2m ?? 20);
      const highTemp = Math.round(daily.temperature_2m_max?.[0] ?? currentTemp + 3);
      const lowTemp = Math.round(daily.temperature_2m_min?.[0] ?? currentTemp - 5);
      const humidity = Math.round(current.relative_humidity_2m ?? 50);
      const windSpeed = Math.round(current.wind_speed_10m ?? 10);
      const pressure = Math.round(current.surface_pressure ?? 1013);
      const code = current.weather_code ?? 0;

      const currentHour = new Date().getHours();
      const isNight = currentHour >= 22 || currentHour < 5;
      const { condition, icon } = getWmoDetails(code, isNight);

      // Format 24-hour hourly forecast
      const hourlyList: HourlyForecastItem[] = [];
      const times: string[] = hourly.time || [];
      const temps: number[] = hourly.temperature_2m || [];
      const rainChances: number[] = hourly.precipitation_probability || [];
      const codes: number[] = hourly.weather_code || [];

      // Find current hour index in forecast
      const nowISO = new Date().toISOString().substring(0, 13); // YYYY-MM-THH
      let startIndex = times.findIndex(t => t.startsWith(nowISO));
      if (startIndex === -1) startIndex = 0;

      for (let i = 0; i < 24; i++) {
        const idx = startIndex + i;
        if (idx < times.length) {
          const tDate = new Date(times[idx]);
          const hVal = tDate.getHours();
          const timeStr = `${String(hVal).padStart(2, '0')}:00`;
          const itemTemp = Math.round(temps[idx] ?? 20);
          const itemRain = Math.round(rainChances[idx] ?? 0);
          const itemCode = codes[idx] ?? 0;
          const itemNight = hVal >= 22 || hVal < 5;
          const details = getWmoDetails(itemCode, itemNight);

          hourlyList.push({
            time: i === 0 ? 'teraz' : timeStr,
            rawHour: hVal,
            temp: itemTemp,
            icon: details.icon,
            rainChance: itemRain,
            condition: details.condition
          });
        }
      }

      const displayLabel = [loc.name, loc.admin1 || loc.country].filter(Boolean).join(', ');
      const updateTimeString = `${String(new Date().getHours()).padStart(2, '0')}:${String(new Date().getMinutes()).padStart(2, '0')}`;

      setWeather({
        cityName: displayLabel,
        temp: currentTemp,
        high: highTemp,
        low: lowTemp,
        condition,
        humidity,
        windSpeed,
        pressure,
        icon,
        hourly: hourlyList,
        lastUpdated: updateTimeString
      });
    } catch (err) {
      console.warn('Nie udało się pobrać pogody z API Open-Meteo, używam danych lokalnych:', err);
    } finally {
      setIsLoadingWeather(false);
    }
  }, []);

  // 1-Hour Automatic Refresh Logic + Initial Fetch
  useEffect(() => {
    fetchWeather(currentLocation);

    const ONE_HOUR = 60 * 60 * 1000;
    const interval = setInterval(() => {
      fetchWeather(currentLocation);
    }, ONE_HOUR);

    return () => clearInterval(interval);
  }, [currentLocation, fetchWeather]);

  // Geocoding search handler for city input
  const handleSearchCities = async (query: string) => {
    setSearchQuery(query);
    if (!query.trim() || query.length < 2) {
      setSearchResults([]);
      return;
    }

    setIsSearching(true);
    try {
      const url = `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(query)}&count=5&language=pl&format=json`;
      const res = await fetch(url);
      if (!res.ok) throw new Error('Błąd geokodowania');
      const data = await res.json();
      if (data.results && Array.isArray(data.results)) {
        const locations: LocationItem[] = data.results.map((r: any) => ({
          name: r.name,
          admin1: r.admin1,
          country: r.country,
          latitude: r.latitude,
          longitude: r.longitude
        }));
        setSearchResults(locations);
      } else {
        setSearchResults([]);
      }
    } catch (e) {
      console.warn('Błąd wyszukiwania miast:', e);
      setSearchResults([]);
    } finally {
      setIsSearching(false);
    }
  };

  const selectCity = (loc: LocationItem) => {
    setCurrentLocation(loc);
    setSearchQuery('');
    setSearchResults([]);
  };

  const hours = String(now.getHours()).padStart(2, '0');
  const minutes = String(now.getMinutes()).padStart(2, '0');
  const seconds = String(now.getSeconds()).padStart(2, '0');

  const days = ['niedziela', 'poniedziałek', 'wtorek', 'środa', 'czwartek', 'piątek', 'sobota'];
  const months = ['stycznia', 'lutego', 'marca', 'kwietnia', 'maja', 'czerwca', 'lipca', 'sierpnia', 'września', 'października', 'listopada', 'grudnia'];

  const dayName = days[now.getDay()];
  const dateFormatted = `${now.getDate()} ${months[now.getMonth()]} ${now.getFullYear()}`;

  return (
    <main className="w-full h-full relative z-10 p-3 sm:p-5 md:p-8 pb-24 md:pb-8 overflow-y-auto custom-scrollbar flex flex-col items-center justify-start min-w-0">
      <div className="w-full max-w-6xl min-w-0">
        {/* Unified GlassCard Module */}
        <div className="glass-card p-4 sm:p-7 md:p-9 overflow-hidden shadow-2xl transition-all relative">
          <div className="relative z-10 grid grid-cols-1 lg:grid-cols-12 gap-6 lg:gap-8 items-stretch">
            {/* Weather Column */}
            <div className="lg:col-span-7 xl:col-span-8 flex flex-col gap-5 w-full min-w-0">
              <div className="flex items-center justify-between flex-wrap gap-2">
                <div className="flex items-center gap-2 sm:gap-3">
                  <span className="material-symbols-outlined text-primary text-xl sm:text-2xl">cloud</span>
                  <h2 className="text-[11px] sm:text-xs font-mono tracking-wider text-on-surface-variant/80 lowercase">
                    pogoda na żywo (odświeżanie co 1h)
                  </h2>
                </div>

                <div className="flex items-center gap-2">
                  <button
                    onClick={() => fetchWeather(currentLocation)}
                    disabled={isLoadingWeather}
                    className="p-1.5 rounded-full bg-white/5 hover:bg-white/10 border border-white/10 text-primary transition-all cursor-pointer disabled:opacity-50"
                    title="Odśwież pogodę teraz"
                  >
                    <span className={`material-symbols-outlined text-sm ${isLoadingWeather ? 'animate-spin' : ''}`}>
                      refresh
                    </span>
                  </button>
                  <span className="text-[10px] sm:text-[11px] font-mono text-emerald-400 bg-emerald-500/10 border border-emerald-500/20 px-2 py-0.5 sm:px-2.5 sm:py-1 rounded-full flex items-center gap-1.5">
                    <span className="w-1.5 h-1.5 bg-emerald-400 rounded-full animate-ping" />
                    {hours}:{minutes}:{seconds}
                  </span>
                </div>
              </div>

              {/* City Search Input Field & Geocoding Results */}
              <div className="relative z-20">
                <div className="flex items-center gap-2 bg-white/5 border border-white/10 focus-within:border-primary/50 rounded-2xl px-3 sm:px-3.5 py-2 transition-all">
                  <span className="material-symbols-outlined text-base text-primary">search</span>
                  <input
                    type="text"
                    value={searchQuery}
                    onChange={(e) => handleSearchCities(e.target.value)}
                    placeholder="Wpisz nazwę miasta (np. Warszawa, Katowice, Londyn)..."
                    className="bg-transparent text-xs text-on-surface outline-none w-full placeholder:text-on-surface-variant/50 font-mono"
                  />
                  {isSearching && (
                    <span className="material-symbols-outlined text-sm text-primary animate-spin">sync</span>
                  )}
                  {searchQuery && (
                    <button
                      onClick={() => {
                        setSearchQuery('');
                        setSearchResults([]);
                      }}
                      className="text-on-surface-variant hover:text-white"
                    >
                      <span className="material-symbols-outlined text-sm">close</span>
                    </button>
                  )}
                </div>

                {/* Dropdown Suggestions */}
                {searchResults.length > 0 && (
                  <div className="absolute left-0 right-0 top-full mt-2 bg-[#0c2500]/95 backdrop-blur-xl border border-white/15 rounded-2xl shadow-2xl overflow-hidden divide-y divide-white/5 z-50">
                    {searchResults.map((loc, idx) => (
                      <button
                        key={idx}
                        onClick={() => selectCity(loc)}
                        className="w-full text-left px-4 py-2.5 hover:bg-primary/20 transition-colors flex items-center justify-between text-xs text-on-surface cursor-pointer"
                      >
                        <span className="font-semibold">{loc.name}</span>
                        <span className="text-[10px] text-on-surface-variant/70 font-mono">
                          {[loc.admin1, loc.country].filter(Boolean).join(', ')}
                        </span>
                      </button>
                    ))}
                  </div>
                )}
              </div>

              {/* Active Location Display */}
              <div className="flex items-center justify-between text-xs font-mono text-on-surface-variant flex-wrap gap-2">
                <div className="flex items-center gap-1.5">
                  <span className="material-symbols-outlined text-sm text-primary">location_on</span>
                  <span className="text-on-surface font-semibold">{weather.cityName}</span>
                </div>
                {weather.lastUpdated && (
                  <span className="text-[10px] text-on-surface-variant/60">
                    Ostatnia zmiana: {weather.lastUpdated}
                  </span>
                )}
              </div>

              {/* Temp and High/Low */}
              <div className="flex flex-wrap items-center justify-between sm:justify-start gap-4 sm:gap-8 mt-1">
                <div className="flex items-center gap-2 sm:gap-3">
                  <span className="material-symbols-outlined text-4xl sm:text-5xl md:text-6xl text-primary animate-pulse">
                    {weather.icon}
                  </span>
                  <span className="text-5xl sm:text-7xl md:text-8xl font-bold text-on-surface tracking-tighter font-mono">
                    {weather.temp}°
                  </span>
                </div>
                <div className="flex flex-row sm:flex-col gap-3 sm:gap-1.5 bg-white/5 sm:bg-transparent px-3 py-1.5 sm:p-0 rounded-xl border border-white/5 sm:border-none">
                  <div className="flex items-center gap-1.5 text-primary font-mono">
                    <span className="material-symbols-outlined text-xs">arrow_upward</span>
                    <span className="text-sm sm:text-base font-bold">{weather.high}°</span>
                    <span className="text-[10px] text-on-surface-variant/60">max</span>
                  </div>
                  <div className="flex items-center gap-1.5 text-on-surface-variant/70 font-mono">
                    <span className="material-symbols-outlined text-xs">arrow_downward</span>
                    <span className="text-sm sm:text-base">{weather.low}°</span>
                    <span className="text-[10px] text-on-surface-variant/50">min</span>
                  </div>
                </div>
              </div>

              <p className="text-xs sm:text-sm text-on-surface-variant/90 capitalize">
                {weather.condition} — {weather.cityName}
              </p>

              {/* Detailed metrics grid */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5 sm:gap-3 pt-2 text-[11px] sm:text-xs font-mono">
                <div className="p-2.5 rounded-xl bg-white/5 border border-white/5 flex items-center gap-2.5">
                  <span className="material-symbols-outlined text-primary text-lg">humidity_low</span>
                  <div>
                    <p className="text-[9px] sm:text-[10px] text-on-surface-variant/60">wilgotność</p>
                    <p className="text-on-surface font-semibold">{weather.humidity}%</p>
                  </div>
                </div>
                <div className="p-2.5 rounded-xl bg-white/5 border border-white/5 flex items-center gap-2.5">
                  <span className="material-symbols-outlined text-primary text-lg">air</span>
                  <div>
                    <p className="text-[9px] sm:text-[10px] text-on-surface-variant/60">wiatr</p>
                    <p className="text-on-surface font-semibold">{weather.windSpeed} km/h</p>
                  </div>
                </div>
                <div className="p-2.5 rounded-xl bg-white/5 border border-white/5 flex items-center gap-2.5">
                  <span className="material-symbols-outlined text-primary text-lg">speed</span>
                  <div>
                    <p className="text-[9px] sm:text-[10px] text-on-surface-variant/60">ciśnienie</p>
                    <p className="text-on-surface font-semibold">{weather.pressure} hPa</p>
                  </div>
                </div>
              </div>

              {/* Hourly Forecast Header */}
              <div className="flex justify-between items-center mt-2 pt-4 border-t border-white/10">
                <span className="text-xs font-mono text-on-surface-variant/80 lowercase flex items-center gap-1.5">
                  <span className="material-symbols-outlined text-sm text-primary">schedule</span>
                  prognoza godzinowa 24h (od {hours}:00)
                </span>
                <span className="text-[10px] font-mono text-primary/70">przewijaj →</span>
              </div>

              {/* Hourly Forecast 24h Strip */}
              <div className="flex items-center gap-2.5 overflow-x-auto custom-scrollbar pb-2 pt-1 snap-x snap-mandatory">
                {weather.hourly.map((f, i) => (
                  <div
                    key={i}
                    className="snap-start flex flex-col items-center gap-1.5 p-2.5 sm:p-3 rounded-2xl bg-white/5 border border-white/5 hover:border-primary/40 transition-colors shrink-0 min-w-[68px] sm:min-w-[76px]"
                  >
                    <span className="text-[10px] font-mono text-on-surface-variant/70">{f.time}</span>
                    <span className="material-symbols-outlined text-primary text-lg">{f.icon}</span>
                    <span className="text-xs font-bold text-on-surface font-mono">{f.temp}°</span>
                    <span className="text-[9px] text-primary/70 font-mono flex items-center gap-0.5">
                      <span className="material-symbols-outlined text-[10px]">water_drop</span>
                      {f.rainChance}%
                    </span>
                  </div>
                ))}
              </div>
            </div>

            {/* Time & Date Column */}
            <div className="lg:col-span-5 xl:col-span-4 flex flex-col justify-between items-start lg:items-end gap-6 w-full min-w-0 p-4 sm:p-6 lg:p-0 bg-white/5 lg:bg-transparent rounded-2xl lg:rounded-none border border-white/10 lg:border-none lg:pl-6 lg:border-l lg:border-white/10">
              <div className="flex items-center gap-2.5">
                <span className="material-symbols-outlined text-primary text-xl sm:text-2xl">schedule</span>
                <h2 className="text-xs font-mono tracking-wider text-on-surface-variant/80 lowercase">
                  zegar cyfrowy
                </h2>
              </div>

              {/* Big Digital Clock */}
              <div className="flex flex-col items-start lg:items-end my-auto">
                <div className="text-5xl sm:text-6xl lg:text-7xl font-bold font-mono text-on-surface tracking-widest text-shadow-glow flex items-baseline gap-1">
                  <span>{hours}:{minutes}</span>
                  <span className="text-xl sm:text-2xl text-primary font-light">{seconds}</span>
                </div>
                <p className="text-base sm:text-lg text-primary font-medium mt-2 capitalize">
                  {dayName}
                </p>
                <p className="text-xs text-on-surface-variant/80 font-mono mt-1">
                  {dateFormatted}
                </p>
              </div>

              {/* Bottom status badge */}
              <div className="flex items-center gap-2 px-3 py-1 sm:px-3.5 sm:py-1.5 rounded-full bg-primary/10 border border-primary/20 text-xs text-primary font-mono">
                <span className="w-2 h-2 rounded-full bg-primary animate-pulse" />
                <span>strefa czasowa GMT+2</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
};

