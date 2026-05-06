/// 沖縄県 市区町村 41 （2025年時点の構成。出典: 総務省・沖縄県公表に準拠した一覧）。
class OkinawaMunicipalitySection {
  const OkinawaMunicipalitySection({
    required this.header,
    required this.names,
  });

  final String header;
  final List<String> names;
}

const List<OkinawaMunicipalitySection> kOkinawaMunicipalitySections = [
  OkinawaMunicipalitySection(
    header: '市',
    names: [
      '那覇市',
      '宜野湾市',
      '石垣市',
      '浦添市',
      '名護市',
      '糸満市',
      '沖縄市',
      '豊見城市',
      'うるま市',
      '宮古島市',
      '南城市',
    ],
  ),
  OkinawaMunicipalitySection(
    header: '国頭郡',
    names: [
      '国頭村',
      '大宜味村',
      '東村',
      '今帰仁村',
      '本部町',
      '恩納村',
      '宜野座村',
      '金武町',
      '伊江村',
    ],
  ),
  OkinawaMunicipalitySection(
    header: '中頭郡',
    names: [
      '読谷村',
      '嘉手納町',
      '北谷町',
      '北中城村',
      '中城村',
      '西原町',
    ],
  ),
  OkinawaMunicipalitySection(
    header: '島尻郡',
    names: [
      '与那原町',
      '南風原町',
      '渡嘉敷村',
      '座間味村',
      '粟国村',
      '渡名喜村',
      '南大東村',
      '北大東村',
      '伊平屋村',
      '伊是名村',
      '久米島町',
      '八重瀬町',
    ],
  ),
  OkinawaMunicipalitySection(
    header: '宮古郡',
    names: [
      '多良間村',
    ],
  ),
  OkinawaMunicipalitySection(
    header: '八重山郡',
    names: [
      '竹富町',
      '与那国町',
    ],
  ),
];

/// 全件フラット（件数確認用・41想定）。
List<String> get kAllOkinawaMunicipalityNames => [
      for (final s in kOkinawaMunicipalitySections) ...s.names,
    ];
