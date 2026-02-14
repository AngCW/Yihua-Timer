import '../FileManager/file_manager.dart';

class EventModel {
  final String name;
  final String? desc;
  final DateTime date;
  final int teamNum;
  final String bgImgName;

  EventModel({
    required this.name,
    this.desc,
    required this.date,
    required this.teamNum,
    required this.bgImgName
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      name: json['name'] as String,
      desc: json['desc'] as String?,
      date: json['date'] as DateTime,
      teamNum: json['teamNum'] as int,
      bgImgName: json['bgImgName'] as String
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name' : name,
      'desc' : desc,
      'date' : date,
      'teamNum' : teamNum,
      'bgImgName' : bgImgName
    };
  }

  void saveToDevice() {
    saveToJsonFile(toJson(), name, "event.json");
  }
}
