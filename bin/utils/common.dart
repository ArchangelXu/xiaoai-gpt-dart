import 'dart:typed_data';

extension Bytes on List<int>{
  Uint8List toBytes()=> Uint8List.fromList(this);
}