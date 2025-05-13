class HistoryItem {
  final String type;
  final String title;
  final String subtitle;
  final String date;
  final String iconPath;
  final Map<String, dynamic>? additionalData;

  HistoryItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.iconPath,
    this.additionalData,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'date': date,
      'iconPath': iconPath,
      'additionalData': additionalData,
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      type: json['type'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      date: json['date'] as String,
      iconPath: json['iconPath'] as String,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }
}
