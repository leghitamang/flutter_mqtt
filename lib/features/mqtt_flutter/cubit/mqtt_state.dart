part of 'mqtt_cubit.dart';

// abstract class MqttState extends Equatable {
//   const MqttState();

//   @override
//   List<Object> get props => [];
// }

// class MqttInitial extends MqttState {}

enum MqttState {connected,connecting, disconnected}
