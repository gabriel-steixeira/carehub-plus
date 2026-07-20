import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Model representing a first-aid / emergency protocol guide.
class SosProtocolModel extends Equatable {
  const SosProtocolModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.steps,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<String> steps;

  @override
  List<Object?> get props => [id, title, description, icon, steps];
}
