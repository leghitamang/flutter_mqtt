import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'message_state.dart';

class MessageCubit extends Cubit<MessageState> {
  MessageCubit() : super(const MessageState(''));

  void updateMessage(String receivedMessage) {
    String newMessage = state.message + '\n' + receivedMessage;
    emit(state.copyWith(message: newMessage));
  }

  void clearMessage() {
    emit(state.copyWith(message: ''));
  }
}
