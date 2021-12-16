import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mqtt_flutter/const/mqqt_const.dart';
import 'package:mqtt_flutter/features/messages/message.dart';
import 'package:mqtt_flutter/features/mqtt_flutter/cubit/mqtt_cubit.dart';
import 'package:mqtt_flutter/features/theme/cubit/theme_cubit.dart';

import 'package:mqtt_flutter/utils/utility.dart';
import 'package:uuid/uuid.dart';

class MqttFlutterPage extends StatelessWidget {
  const MqttFlutterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => MessageCubit(),
        ),
        BlocProvider(
          create: (context) => MqttCubit(
            messageCubit: BlocProvider.of<MessageCubit>(context),
          ),
        ),
      ],
      child: const MqttFlutterView(),
    );
  }
}

class MqttFlutterView extends StatefulWidget {
  const MqttFlutterView({
    Key? key,
  }) : super(key: key);

  @override
  State<MqttFlutterView> createState() => _MqttFlutterViewState();
}

class _MqttFlutterViewState extends State<MqttFlutterView> {
  @override
  void initState() {
    _hostController = TextEditingController();
    _topicController = TextEditingController();
    _messageController = TextEditingController();
    super.initState();
  }

  late TextEditingController _hostController;
  late TextEditingController _topicController;
  late TextEditingController _messageController;

  @override
  void dispose() {
    _hostController.dispose();
    _topicController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mqtt Flutter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: context.read<ThemeCubit>().toggleTheme,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: BlocBuilder<MqttCubit, MqttState>(
          builder: (context, state) {
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: connectionStatusColor(state),
                  child: Text(
                    connectionStatus(state),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Host (Broker Address)', style: lableStyle),
                      TextField(
                        enabled: state == MqttState.disconnected,
                        controller: _hostController,
                        decoration: const InputDecoration(
                          hintText: 'Enter Host / Broker Address',
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Topic', style: lableStyle),
                      TextField(
                        enabled: state == MqttState.disconnected,
                        controller: _topicController,
                        decoration: const InputDecoration(
                          hintText: 'Enter Topic ',
                        ),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (state == MqttState.connected)
                                  ? disconnect
                                  : null,
                              child: const Text('Disconnected'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (state == MqttState.disconnected)
                                  ? connect
                                  : null,
                              child: const Text('Connect'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      state == MqttState.connected
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        enabled: state == MqttState.connected,
                                        controller: _messageController,
                                        textInputAction: TextInputAction.send,
                                        onSubmitted: (value) =>
                                            publish(_messageController.text),
                                        decoration: const InputDecoration(
                                          hintText: 'Enter Message.. ',
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.send),
                                      onPressed: state == MqttState.connected
                                          ? () =>
                                              publish(_messageController.text)
                                          : null,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Text('Messages', style: lableStyle),
                                const SizedBox(height: 10),
                                BlocBuilder<MessageCubit, MessageState>(
                                  builder: (context, messageState) {
                                    return Text(
                                      messageState.message,
                                      style: const TextStyle(
                                        fontSize: 15,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            )
                          : Container(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void publish(String message) {
    if (_messageController.text == '') {
      Utility.showErrorToast('Empty message found');
    } else {
      context.read<MqttCubit>().publish(message);
      _messageController.clear();
    }
  }

  void connect() {
    if (_hostController.text == '' || _topicController.text == '') {
      Utility.showErrorToast('Invalid host or topic');
    } else {
      const uuid = Uuid();
      context.read<MqttCubit>().connect(
            host: _hostController.text,
            identifier: uuid.toString(),
            topic: _topicController.text,
          );
    }
  }

  void disconnect() {
    context.read<MqttCubit>().disconnect();
  }

  String connectionStatus(MqttState state) {
    switch (state) {
      case MqttState.connected:
        return 'Connected';
      case MqttState.connecting:
        return 'Connecting...';
      case MqttState.disconnected:
        return 'Disconnected';
      default:
        return 'State not available';
    }
  }

  Color connectionStatusColor(MqttState state) {
    switch (state) {
      case MqttState.connected:
        return connectedColor;
      case MqttState.connecting:
        return connectingColor;
      case MqttState.disconnected:
        return disconnectedColor;
      default:
        return const Color(0xff808080);
    }
  }
}
