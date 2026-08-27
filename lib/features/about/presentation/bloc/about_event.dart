/*
 * CareHub Plus — Apresentação / Eventos Sobre
 *
 * Declara as intenções aceitas pelo BLoC da página institucional.
 *
 * Author: Vitoria Lana
 * Created on: 27/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

part of 'about_bloc.dart';

abstract class AboutEvent extends Equatable {
  const AboutEvent();

  @override
  List<Object?> get props => [];
}

class AboutLoadEvent extends AboutEvent {
  const AboutLoadEvent();
}
