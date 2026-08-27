/*
 * CareHub Plus — Apresentação / Estado Sobre
 *
 * Mantém o status do carregamento e o conteúdo institucional renderizado pela
 * página, incluindo mensagem amigável para falhas de leitura.
 *
 * Author: Vitoria Lana
 * Created on: 27/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

part of 'about_bloc.dart';

enum AboutStatus { initial, loading, success, failure }

class AboutState extends Equatable {
  const AboutState({
    this.status = AboutStatus.initial,
    this.content,
    this.errorMessage,
  });

  final AboutStatus status;
  final AboutContentEntity? content;
  final String? errorMessage;

  AboutState copyWith({
    AboutStatus? status,
    AboutContentEntity? content,
    String? errorMessage,
  }) {
    return AboutState(
      status: status ?? this.status,
      content: content ?? this.content,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, content, errorMessage];
}
