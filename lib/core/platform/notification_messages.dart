class NotificationMessages {
  static const _morning = [
    (title: '☀️ Günaydın!', body: 'Güne bir bardak su ile başla.'),
    (title: '💧 Sabah rutinin', body: 'Vücudun gece boyunca su kaybetti, telafi zamanı!'),
    (title: '🌅 Yeni gün, yeni hedef', body: 'Bardağın dolu, boşaltmaya hazır mısın?'),
    (title: '💪 Enerjik bir sabah', body: 'Su içmek metabolizmayı hızlandırır. Hadi başla!'),
    (title: '🥤 İlk yudum', body: 'Kahvaltıdan önce bir bardak su harika olur.'),
  ];

  static const _afternoon = [
    (title: '☀️ Öğle molası', body: 'Bardağın seni bekliyor. Bir yudum iç!'),
    (title: '💧 Su vakti geldi', body: 'Gün ortasında hidrasyon şart!'),
    (title: '⚡ Enerji düşüyor mu?', body: 'Kahve yerine bir bardak su dene.'),
    (title: '🎯 Hedefe doğru', body: 'Günlük hedefine ulaşmak için su içmeye devam!'),
    (title: '💦 Küçük bir mola', body: 'Ekrandan kalk, bir bardak su iç, geri dön.'),
  ];

  static const _evening = [
    (title: '🌙 Akşam suyu', body: 'Yatmadan önce son bir bardak.'),
    (title: '🌟 Gün bitmeden', body: 'Hedefine ulaşmak için hâlâ vakit var!'),
    (title: '💧 Son sprint', body: 'Bugünkü hedefini tamamla, yarın daha güçlü başla.'),
    (title: '😌 Rahatla ve iç', body: 'Akşam bir bardak su uyku kalitesini artırır.'),
  ];

  static const _streakMessages = [
    (title: '🔥 Seri devam!', body: '{streak} gündür hedefine ulaşıyorsun. Harika!'),
    (title: '💪 Alışkanlık oluşuyor', body: '{streak} günlük seri! Bırakma!'),
    (title: '🏆 Disiplin', body: '{streak} gün üst üste. Sen bir şampiyonsun!'),
  ];

  static ({String title, String body}) getForTime(int hour, {int streak = 0}) {
    if (streak >= 3) {
      final pool = _streakMessages;
      final index = DateTime.now().day % pool.length;
      final msg = pool[index];
      return (
        title: msg.title,
        body: msg.body.replaceAll('{streak}', '$streak'),
      );
    }

    final pool = hour < 12 ? _morning : hour < 18 ? _afternoon : _evening;
    final index = DateTime.now().day % pool.length;
    return pool[index];
  }
}
