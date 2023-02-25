import 'dart:convert';

import 'package:http/http.dart';

export 'package:frontend/exception.dart';

typedef Json = Map<String, dynamic>;
typedef FromJson<T> = T Function(Json);
typedef ToJson<T> = Json Function(T);

extension Deserialization on Response {
  T deserialize<T>(FromJson<T> fromJson) {
    return fromJson(jsonDecode(utf8.decode(bodyBytes)));
  }
}
