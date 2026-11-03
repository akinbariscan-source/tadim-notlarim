// Tadım Notlarım — web sürümünde etiket okuma (OCR).
// iOS/Android sürümü Google ML Kit kullanır; web'de Tesseract.js tarayıcıda çalışır.
// Fotoğraf hiçbir sunucuya gönderilmez; yalnızca okuma motoru ve dil dosyaları
// ilk kullanımda CDN'den indirilir.
(function () {
  var TESSERACT_URL = 'https://cdn.jsdelivr.net/npm/tesseract.js@5.1.1/dist/tesseract.min.js';
  var loading = null;
  var workerPromise = null;

  function loadScript() {
    if (window.Tesseract) return Promise.resolve();
    if (loading) return loading;
    loading = new Promise(function (resolve, reject) {
      var s = document.createElement('script');
      s.src = TESSERACT_URL;
      s.onload = function () { resolve(); };
      s.onerror = function () { loading = null; reject(new Error('Okuma motoru yüklenemedi (internet bağlantısını kontrol et).')); };
      document.head.appendChild(s);
    });
    return loading;
  }

  function getWorker() {
    if (!workerPromise) {
      workerPromise = loadScript().then(function () {
        // Türkçe + İngilizce: Öküzgözü, Boğazkere gibi adlar için Türkçe karakterler.
        return window.Tesseract.createWorker(['eng', 'tur']);
      }).catch(function (e) { workerPromise = null; throw e; });
    }
    return workerPromise;
  }

  function collectLines(data) {
    var lines = [];
    if (data.lines && data.lines.length) {
      lines = data.lines;
    } else if (data.blocks) {
      data.blocks.forEach(function (b) {
        (b.paragraphs || []).forEach(function (p) {
          (p.lines || []).forEach(function (l) { lines.push(l); });
        });
      });
    }
    return lines
      .filter(function (l) { return l && l.text && l.bbox && (l.confidence === undefined || l.confidence > 30); })
      .map(function (l) {
        return { text: l.text.trim(), x0: l.bbox.x0, y0: l.bbox.y0, x1: l.bbox.x1, y1: l.bbox.y1 };
      });
  }

  // Dart tarafı: lib/services/ocr/ocr_web.dart → tadimOcr(Uint8List) → JSON metni
  window.tadimOcr = async function (bytes) {
    var worker = await getWorker();
    var url = URL.createObjectURL(new Blob([bytes]));
    try {
      var result = await worker.recognize(url, {}, { text: true, blocks: true });
      return JSON.stringify({ lines: collectLines(result.data || {}) });
    } finally {
      URL.revokeObjectURL(url);
    }
  };
})();
