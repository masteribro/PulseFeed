import 'package:equatable/equatable.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeAudioState extends HomeState {
  final bool isPlaying;
  const HomeAudioState(this.isPlaying);

  @override
  List<Object?> get props => [isPlaying];
}

class HomeVideoState extends HomeState {
  final bool isPlaying;
  const HomeVideoState(this.isPlaying);

  @override
  List<Object?> get props => [isPlaying];
}

class HomeDocumentState extends HomeState {
  final bool isLoading;
  final bool isViewing;
  final String? filePath;
  final String? error;

  const HomeDocumentState({
    this.isLoading = false,
    this.isViewing = false,
    this.filePath,
    this.error,
  });

  @override
  List<Object?> get props => [isLoading, isViewing, filePath, error];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}