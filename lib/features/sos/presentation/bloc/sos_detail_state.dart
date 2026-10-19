part of 'sos_detail_bloc.dart';

/// Situação da tela de detalhe do pedido de ajuda.
enum SosDetailStatus {
  /// Estado inicial, antes do primeiro carregamento.
  initial,

  /// Carregando os detalhes do pedido.
  loading,

  /// Detalhes carregados e prontos para exibir.
  success,

  /// Falha ao carregar os detalhes ou ao enviar o aceite.
  failure,

  /// Enviando o aceite ("Estou a caminho"). Mantém o detalhe já carregado.
  accepting,

  /// Aceite concluído: o pedido foi aceito por quem está na tela.
  accepted,
}

class SosDetailState extends Equatable {
  const SosDetailState({
    this.status = SosDetailStatus.initial,
    this.detail,
    this.errorMessage,
  });

  final SosDetailStatus status;
  final SosAlertDetailEntity? detail;
  final String? errorMessage;

  SosDetailState copyWith({
    SosDetailStatus? status,
    SosAlertDetailEntity? detail,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SosDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, detail, errorMessage];
}
