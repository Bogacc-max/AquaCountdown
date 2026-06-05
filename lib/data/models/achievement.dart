enum AchievementType {
  ilkYudum,
  ucGun,
  yediGun,
  otuzGun,
  erkenKus,
  geceSavascisi,
  litrelik,
  onBinKulubu,
  tamIsabet,
  haftaSonuSavascisi,
}

class Achievement {
  final AchievementType type;
  final String id;
  final String title;
  final String description;
  final String icon;
  final int target;
  int progress;
  DateTime? unlockedAt;

  Achievement({
    required this.type,
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    this.progress = 0,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;
  double get progressRatio =>
      target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

  static List<Achievement> all() => [
        Achievement(
          type: AchievementType.ilkYudum,
          id: 'ilk_yudum',
          title: 'İlk Yudum',
          description: 'İlk su kaydını oluştur',
          icon: '💧',
          target: 1,
        ),
        Achievement(
          type: AchievementType.ucGun,
          id: 'uc_gun',
          title: '3 Günlük Seri',
          description: '3 gün üst üste hedefini tamamla',
          icon: '🔥',
          target: 3,
        ),
        Achievement(
          type: AchievementType.yediGun,
          id: 'yedi_gun',
          title: 'Haftalık Şampiyon',
          description: '7 gün üst üste hedefini tamamla',
          icon: '🏆',
          target: 7,
        ),
        Achievement(
          type: AchievementType.otuzGun,
          id: 'otuz_gun',
          title: 'Ay Yıldızı',
          description: '30 gün üst üste hedefini tamamla',
          icon: '⭐',
          target: 30,
        ),
        Achievement(
          type: AchievementType.erkenKus,
          id: 'erken_kus',
          title: 'Erken Kuş',
          description: 'Sabah 7\'den önce su iç',
          icon: '🐦',
          target: 1,
        ),
        Achievement(
          type: AchievementType.geceSavascisi,
          id: 'gece_savascisi',
          title: 'Gece Savaşçısı',
          description: 'Gece 22\'den sonra su iç',
          icon: '🌙',
          target: 1,
        ),
        Achievement(
          type: AchievementType.litrelik,
          id: 'litrelik',
          title: 'Litrelik',
          description: 'Tek seferde 1 litre veya daha fazla ekle',
          icon: '🫗',
          target: 1,
        ),
        Achievement(
          type: AchievementType.onBinKulubu,
          id: 'on_bin_kulubu',
          title: '10K Kulübü',
          description: 'Toplamda 10 litre su iç',
          icon: '🎖️',
          target: 10000,
        ),
        Achievement(
          type: AchievementType.tamIsabet,
          id: 'tam_isabet',
          title: 'Tam İsabet',
          description: 'Hedefini tam olarak tuttur (ne eksik ne fazla)',
          icon: '🎯',
          target: 1,
        ),
        Achievement(
          type: AchievementType.haftaSonuSavascisi,
          id: 'hafta_sonu_savascisi',
          title: 'Hafta Sonu Savaşçısı',
          description: 'Cumartesi ve Pazar hedefini tamamla',
          icon: '💪',
          target: 1,
        ),
      ];
}
