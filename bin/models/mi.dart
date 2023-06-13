import 'package:json_annotation/json_annotation.dart';

part 'mi.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class MiDevice {
  int? did;
  String? hardware;
  String? deviceId;

  MiDevice();

  factory MiDevice.fromJson(Map<String, dynamic> json) =>
      _$MiDeviceFromJson(json);

  Map<String, dynamic> toJson() => _$MiDeviceToJson(this);
}

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class MiToken {
  int? userId;
  String? deviceId;
  String? passToken;
  Map<String, MiServiceToken> services;

  MiToken.empty() : services = {};

  MiToken(this.userId, this.deviceId, this.passToken, this.services);

  factory MiToken.fromJson(Map<String, dynamic> json) =>
      _$MiTokenFromJson(json);

  Map<String, dynamic> toJson() => _$MiTokenToJson(this);
}

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class MiServiceToken {
  final String token;
  final String ssecurity;

  MiServiceToken(this.token, this.ssecurity);

  factory MiServiceToken.fromJson(Map<String, dynamic> json) =>
      _$MiServiceTokenFromJson(json);

  Map<String, dynamic> toJson() => _$MiServiceTokenToJson(this);
}
