abstract class ControllerState {
  const ControllerState();
}

class IdleState extends ControllerState {}

class LoadingState extends ControllerState {}

class DoneState extends ControllerState {}

class ErrorState extends ControllerState {
  final String message;

  ErrorState({required this.message});
}
