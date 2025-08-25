import 'package:flutter/material.dart';

@immutable
class UpgraderConfig {
  final Color primary;
  final double radius;
  const UpgraderConfig({required this.primary, this.radius = 12});
}
