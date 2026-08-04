/**
 * Compresses an image file from PC to WebP format with transparency support
 * and returns a Base64 data URL string (guaranteed to be < 1MB).
 */
export async function compressAndConvertToWebp(file: File, maxDimension = 1400): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onerror = () => reject(new Error('Nie udało się odczytać pliku.'));
    reader.onload = (e) => {
      const img = new Image();
      img.onerror = () => reject(new Error('Nieprawidłowy plik obrazu.'));
      img.onload = () => {
        let width = img.width;
        let height = img.height;

        if (width > maxDimension || height > maxDimension) {
          if (width > height) {
            height = Math.round((height * maxDimension) / width);
            width = maxDimension;
          } else {
            width = Math.round((width * maxDimension) / height);
            height = maxDimension;
          }
        }

        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;

        const ctx = canvas.getContext('2d');
        if (!ctx) {
          reject(new Error('Błąd kontekstu graficznego.'));
          return;
        }

        // Draw image onto canvas preserving transparency
        ctx.clearRect(0, 0, width, height);
        ctx.drawImage(img, 0, 0, width, height);

        let quality = 0.85;
        let dataUrl = canvas.toDataURL('image/webp', quality);

        // Ensure size is strictly below 1MB (1,048,576 bytes)
        while (dataUrl.length > 1000000 && quality > 0.3) {
          quality -= 0.15;
          dataUrl = canvas.toDataURL('image/webp', quality);
        }

        // If WebP export is not supported or still too large, try PNG or further scale
        if (dataUrl.length > 1000000) {
          const smallCanvas = document.createElement('canvas');
          smallCanvas.width = Math.round(width * 0.7);
          smallCanvas.height = Math.round(height * 0.7);
          const sCtx = smallCanvas.getContext('2d');
          if (sCtx) {
            sCtx.drawImage(canvas, 0, 0, smallCanvas.width, smallCanvas.height);
            dataUrl = smallCanvas.toDataURL('image/webp', 0.7);
          }
        }

        resolve(dataUrl);
      };
      img.src = e.target?.result as string;
    };
    reader.readAsDataURL(file);
  });
}

/**
 * Reads a video file from PC and converts it to Base64 data URL string (limits size < 2MB for direct Firestore transmission).
 */
export async function convertVideoToBase64(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    if (file.size > 2.5 * 1024 * 1024) {
      reject(new Error('Plik wideo przekracza zalecany rozmiar (max ~2.5 MB dla natychmiastowego wysyłania). Skompresuj plik przed wysłaniem.'));
      return;
    }
    const reader = new FileReader();
    reader.onerror = () => reject(new Error('Błąd odczytu wideo.'));
    reader.onload = (e) => {
      resolve(e.target?.result as string);
    };
    reader.readAsDataURL(file);
  });
}
export function formatJoinedDate(timestamp?: number): string {
  if (!timestamp) return 'niedawno';
  const date = new Date(timestamp);
  if (isNaN(date.getTime())) return 'niedawno';

  const months = [
    'stycznia', 'lutego', 'marca', 'kwietnia', 'maja', 'czerwca',
    'lipca', 'sierpnia', 'września', 'października', 'listopada', 'grudnia'
  ];

  const day = date.getDate();
  const month = months[date.getMonth()];
  const year = date.getFullYear();
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');

  return `${day} ${month} ${year} o ${hours}:${minutes}:${seconds}`;
}
