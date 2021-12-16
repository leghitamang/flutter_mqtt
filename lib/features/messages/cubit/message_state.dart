part of 'message_cubit.dart';

class MessageState extends Equatable {
  const MessageState(this.message);

  final String message;

  MessageState copyWith({String? message}) {
    return MessageState(message ?? this.message);
  }

  @override
  List<Object> get props => [message];
}
