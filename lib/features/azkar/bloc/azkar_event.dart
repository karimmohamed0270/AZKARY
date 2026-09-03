import 'package:equatable/equatable.dart';

abstract class AzkarEvent extends Equatable {
  const AzkarEvent();

  @override
  List<Object?> get props => [];
}

class LoadAzkarCategoriesEvent extends AzkarEvent {}

class LoadAzkarByCategoryEvent extends AzkarEvent {
  final String category;
  const LoadAzkarByCategoryEvent(this.category);

  @override
  List<Object?> get props => [category];
}

class DecrementZikrCountEvent extends AzkarEvent {
  final int zikrId;
  const DecrementZikrCountEvent(this.zikrId);

  @override
  List<Object?> get props => [zikrId];
}

class ResetZikrProgressEvent extends AzkarEvent {
  final String category;
  const ResetZikrProgressEvent(this.category);

  @override
  List<Object?> get props => [category];
}

class LoadAsmaaAllahEvent extends AzkarEvent {}
