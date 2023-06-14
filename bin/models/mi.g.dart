// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mi.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MiDevice _$MiDeviceFromJson(Map<String, dynamic> json) => MiDevice()
  ..did = json['did'] as int?
  ..hardware = json['hardware'] as String?
  ..deviceId = json['device_id'] as String?;

Map<String, dynamic> _$MiDeviceToJson(MiDevice instance) => <String, dynamic>{
      'did': instance.did,
      'hardware': instance.hardware,
      'device_id': instance.deviceId,
    };

MiToken _$MiTokenFromJson(Map<String, dynamic> json) => MiToken(
      json['user_id'] as int?,
      json['device_id'] as String?,
      json['pass_token'] as String?,
      (json['services'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, MiServiceToken.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$MiTokenToJson(MiToken instance) => <String, dynamic>{
      'user_id': instance.userId,
      'device_id': instance.deviceId,
      'pass_token': instance.passToken,
      'services': instance.services.map((k, e) => MapEntry(k, e.toJson())),
    };

MiServiceToken _$MiServiceTokenFromJson(Map<String, dynamic> json) =>
    MiServiceToken(
      json['token'] as String,
      json['ssecurity'] as String,
    );

Map<String, dynamic> _$MiServiceTokenToJson(MiServiceToken instance) =>
    <String, dynamic>{
      'token': instance.token,
      'ssecurity': instance.ssecurity,
    };
