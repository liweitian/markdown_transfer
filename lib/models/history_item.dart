class HistoryItem {
  final String id;
  final String title;
  final String date;
  final String size;
  final String type;
  final String rawData;
  final String localPath;

  HistoryItem({
    required this.id,
    required this.title,
    required this.date,
    required this.size,
    required this.type,
    required this.rawData,
    required this.localPath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'size': size,
    'type': type,
    'rawData': rawData,
    'localPath': localPath,
  };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
    id: json['id'],
    title: json['title'],
    date: json['date'],
    size: json['size'],
    type: json['type'],
    rawData: json['rawData'],
    localPath: json['localPath'],
  );
} 