import '../FileManager/file_manager.dart';

class ProfileModel {
  final String name;
  final String? desc;
  final DateTime date;
  final int teamNum;
  final String bgImgName;

  ProfileModel({
    required this.name,
    this.desc,
    required this.date,
    required this.teamNum,
    required this.bgImgName
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
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
    saveToJsonFile(toJson(), name, "profile.json");
  }
}
