import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  Bloc.transformer = sequential();
  runApp(MixologyApp(
    apiBaseUrl: Uri.http('localhost:8080'),
  ));
}
