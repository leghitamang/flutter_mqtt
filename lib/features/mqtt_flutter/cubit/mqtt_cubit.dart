import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mqtt_flutter/features/messages/message.dart';

part 'mqtt_state.dart';

class MqttCubit extends Cubit<MqttState> {
  MqttCubit({required this.messageCubit}) : super(MqttState.disconnected);

  final MessageCubit messageCubit;

  late MqttServerClient _client;
  late MqttBrowserClient _browserClient;
  late String _topic;
  late StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>
      messageSubscription;

  void connect({required host, required identifier, required topic}) async {
    try {
      if (kIsWeb) {
        _browserClient = MqttBrowserClient('ws://$host', identifier);
        _topic = topic;
        _browserClient.keepAlivePeriod = 20;
        _browserClient.port = 8080;
        _browserClient.onDisconnected = _onDisconnect;
        _browserClient.logging(on: true);
        _browserClient.pongCallback = _pong;
        _browserClient.onConnected = _onConnected;
        _browserClient.websocketProtocols =
            MqttClientConstants.protocolsSingleDefault;
        emit(MqttState.connecting);
        await _browserClient.connect();
      } else {
        _client = MqttServerClient(host, identifier);
        _topic = topic;
        _client.keepAlivePeriod = 20;
        _client.secure = false;
        _client.onDisconnected = _onDisconnect;
        _client.logging(on: true);
        _client.securityContext = SecurityContext.defaultContext;
        _client.onConnected = _onConnected;
        _client.onBadCertificate = (dynamic a) => true;
        emit(MqttState.connecting);
        await _client.connect();
      }
    } catch (e) {
      log(e.toString());
      disconnect();
    }
  }

  void _onConnected() {
    if (kIsWeb) {
      _browserClient.subscribe(_topic, MqttQos.atMostOnce);
      _browserClient.updates!.listen(_handleReceivedMessage);
    } else {
      _client.subscribe(_topic, MqttQos.atMostOnce);
      _client.updates!.listen(_handleReceivedMessage);
    }
    log('Connected');
    emit(MqttState.connected);
  }

  void _handleReceivedMessage(
      List<MqttReceivedMessage<MqttMessage>> rawMessage) {
    final recMess = rawMessage[0].payload as MqttPublishMessage;
    final pt =
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
    messageCubit.updateMessage(pt);
  }

  void disconnect() {
    kIsWeb ? _browserClient.disconnect() : _client.disconnect();
  }

  void publish(String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);
    kIsWeb
        ? _browserClient.publishMessage(
            _topic, MqttQos.atMostOnce, builder.payload!)
        : _client.publishMessage(_topic, MqttQos.atMostOnce, builder.payload!);
  }

  void _pong() {
    log('EXAMPLE::Ping response client callback invoked');
  }

  void _onDisconnect() {
    log('Disconnected');
    messageCubit.clearMessage();
    emit(MqttState.disconnected);
  }

  @override
  Future<void> close() {
    messageSubscription.cancel();
    return super.close();
  }
}
