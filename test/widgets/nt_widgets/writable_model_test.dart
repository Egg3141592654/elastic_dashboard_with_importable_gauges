import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elastic_dashboard/services/nt4_client.dart';
import 'package:elastic_dashboard/services/nt4_type.dart';
import 'package:elastic_dashboard/services/nt_connection.dart';
import 'package:elastic_dashboard/services/nt_widget_registry.dart';
import 'package:elastic_dashboard/widgets/draggable_containers/models/nt_widget_container_model.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/multi_topic/combo_box_chooser.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/multi_topic/split_button_chooser.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/single_topic/number_slider.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/single_topic/text_display.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/single_topic/toggle_button.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/single_topic/toggle_switch.dart';
import '../../test_util.dart';
import '../../test_util.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  group('Text Display', () {
    late NTConnection ntConnection;

    setUp(() {
      ntConnection = createMockOnlineNT4(
        virtualTopics: [
          NT4Topic(
            name: 'Test/Display Value',
            type: NT4Type.double(),
            properties: {},
          ),
        ],
        virtualValues: {'Test/Display Value': 0.0},
      );
    });

    TextDisplayModel createModel() => TextDisplayModel(
      ntConnection: ntConnection,
      preferences: preferences,
      topic: 'Test/Display Value',
      dataType: NT4Type.double(),
      period: 0.100,
    );

    test('does not save a value until one is written', () {
      final model = createModel();

      expect(model.lastWrittenValue, isNull);
      expect(model.toJson().containsKey('value'), isFalse);
    });

    test('saves the last value the user submitted', () {
      final model = createModel();

      model.publishData('3.53');

      expect(model.lastWrittenValue, 3.53);
      expect(model.toJson()['value'], 3.53);
    });

    test('restores the saved value from json', () {
      final model = TextDisplayModel.fromJson(
        ntConnection: ntConnection,
        preferences: preferences,
        jsonData: {
          'topic': 'Test/Display Value',
          'data_type': NT4Type.double().serialize(),
          'period': 0.100,
          'value': 3.53,
        },
      );

      expect(model.lastWrittenValue, 3.53);
    });

    test('round trips the written value through save and load', () {
      final model = createModel();
      model.publishData('3.53');

      final restored = TextDisplayModel.fromJson(
        ntConnection: ntConnection,
        preferences: preferences,
        jsonData: model.toJson(),
      );

      expect(restored.lastWrittenValue, 3.53);
      expect(restored.toJson()['value'], 3.53);
    });
  });

  group('Number Slider', () {
    test('saves the value written while dragging', () {
      final ntConnection = createMockOnlineNT4(
        virtualTopics: [
          NT4Topic(
            name: 'Test/Double Value',
            type: NT4Type.double(),
            properties: {},
          ),
        ],
        virtualValues: {'Test/Double Value': 0.0},
      );

      final model = NumberSliderModel(
        ntConnection: ntConnection,
        preferences: preferences,
        topic: 'Test/Double Value',
        dataType: NT4Type.double(),
        period: 0.100,
      );

      model.publishValue(2.5);

      expect(model.lastWrittenValue, 2.5);
      expect(model.toJson()['value'], 2.5);
    });

    test('saves an integer value when the topic is an int', () {
      final ntConnection = createMockOnlineNT4(
        virtualTopics: [
          NT4Topic(
            name: 'Test/Int Value',
            type: NT4Type.int(),
            properties: {},
          ),
        ],
        virtualValues: {'Test/Int Value': 0},
      );

      final model = NumberSliderModel(
        ntConnection: ntConnection,
        preferences: preferences,
        topic: 'Test/Int Value',
        dataType: NT4Type.int(),
        period: 0.100,
      );

      model.publishValue(3.7);

      expect(model.lastWrittenValue, 4);
      expect(model.toJson()['value'], 4);
    });

    test('restores the saved value from json', () {
      final ntConnection = createMockOnlineNT4();

      final model = NumberSliderModel.fromJson(
        ntConnection: ntConnection,
        preferences: preferences,
        jsonData: {
          'topic': 'Test/Double Value',
          'data_type': NT4Type.double().serialize(),
          'period': 0.100,
          'value': 2.5,
        },
      );

      expect(model.lastWrittenValue, 2.5);
    });
  });

  group('ComboBox Chooser', () {
    late NTConnection ntConnection;

    setUp(() {
      ntConnection = createMockOnlineNT4(
        virtualTopics: [
          NT4Topic(
            name: 'Test/Chooser/options',
            type: NT4Type.array(NT4Type.string()),
            properties: {},
          ),
        ],
        virtualValues: {
          'Test/Chooser/options': ['Auto', 'Teleop'],
        },
      );
    });

    test('saves the last selected option', () {
      final model = ComboBoxChooserModel(
        ntConnection: ntConnection,
        preferences: preferences,
        topic: 'Test/Chooser',
        period: 0.100,
      );

      model.publishSelectedValue('Teleop');

      expect(model.lastWrittenValue, 'Teleop');
      expect(model.toJson()['value'], 'Teleop');
    });

    test('restores the saved selection from json', () {
      final model = ComboBoxChooserModel.fromJson(
        ntConnection: ntConnection,
        preferences: preferences,
        jsonData: {
          'topic': 'Test/Chooser',
          'period': 0.100,
          'value': 'Teleop',
        },
      );

      expect(model.lastWrittenValue, 'Teleop');
    });
  });

  group('Split Button Chooser', () {
    late NTConnection ntConnection;

    setUp(() {
      ntConnection = createMockOnlineNT4(
        virtualTopics: [
          NT4Topic(
            name: 'Test/Chooser/options',
            type: NT4Type.array(NT4Type.string()),
            properties: {},
          ),
        ],
        virtualValues: {
          'Test/Chooser/options': ['Auto', 'Teleop'],
        },
      );
    });

    test('saves the last selected option', () {
      final model = SplitButtonChooserModel(
        ntConnection: ntConnection,
        preferences: preferences,
        topic: 'Test/Chooser',
        period: 0.100,
      );

      model.publishSelectedValue('Auto');

      expect(model.lastWrittenValue, 'Auto');
      expect(model.toJson()['value'], 'Auto');
    });

    test('restores the saved selection from json', () {
      final model = SplitButtonChooserModel.fromJson(
        ntConnection: ntConnection,
        preferences: preferences,
        jsonData: {
          'topic': 'Test/Chooser',
          'period': 0.100,
          'value': 'Auto',
        },
      );

      expect(model.lastWrittenValue, 'Auto');
    });
  });

  group('Toggle Switch', () {
    late NTConnection ntConnection;

    setUp(() {
      ntConnection = createMockOnlineNT4(
        virtualTopics: [
          NT4Topic(
            name: 'Test/Boolean Value',
            type: NT4Type.boolean(),
            properties: {},
          ),
        ],
        virtualValues: {'Test/Boolean Value': false},
      );
    });

    test('saves the last toggled value', () {
      final model = ToggleSwitchModel(
        ntConnection: ntConnection,
        preferences: preferences,
        topic: 'Test/Boolean Value',
        dataType: NT4Type.boolean(),
        period: 0.100,
      );

      model.publishValue(true);

      expect(model.lastWrittenValue, true);
      expect(model.toJson()['value'], true);
    });

    test('restores the saved value from json', () {
      final model = ToggleSwitchModel.fromJson(
        ntConnection: ntConnection,
        preferences: preferences,
        jsonData: {
          'topic': 'Test/Boolean Value',
          'data_type': 'boolean',
          'period': 0.100,
          'value': true,
        },
      );

      expect(model.lastWrittenValue, true);
    });
  });

  group('Toggle Button', () {
    late NTConnection ntConnection;

    setUp(() {
      ntConnection = createMockOnlineNT4(
        virtualTopics: [
          NT4Topic(
            name: 'Test/Boolean Value',
            type: NT4Type.boolean(),
            properties: {},
          ),
        ],
        virtualValues: {'Test/Boolean Value': false},
      );
    });

    test('saves the last toggled value', () {
      final model = ToggleButtonModel(
        ntConnection: ntConnection,
        preferences: preferences,
        topic: 'Test/Boolean Value',
        dataType: NT4Type.boolean(),
        period: 0.100,
      );

      model.publishValue(true);

      expect(model.lastWrittenValue, true);
      expect(model.toJson()['value'], true);
    });

    test('restores the saved value from json', () {
      final model = ToggleButtonModel.fromJson(
        ntConnection: ntConnection,
        preferences: preferences,
        jsonData: {
          'topic': 'Test/Boolean Value',
          'data_type': 'boolean',
          'period': 0.100,
          'value': true,
        },
      );

      expect(model.lastWrittenValue, true);
    });
  });

  group('Auto republish on connect', () {
    late MockNTConnection ntConnection;

    setUp(() {
      ntConnection = createMockOnlineNT4(
        virtualTopics: [
          NT4Topic(
            name: 'Test/Display Value',
            type: NT4Type.double(),
            properties: {},
          ),
        ],
        virtualValues: {'Test/Display Value': 0.0},
      );
    });

    test('publishes the restored value immediately when already connected', () {
      TextDisplayModel.fromJson(
        ntConnection: ntConnection,
        preferences: preferences,
        jsonData: {
          'topic': 'Test/Display Value',
          'data_type': NT4Type.double().serialize(),
          'period': 0.100,
          'value': 3.53,
        },
      );

      expect(ntConnection.getLastAnnouncedValue('Test/Display Value'), 3.53);
    });

    test('re-asserts the last written value over a robot-set value', () {
      final model = TextDisplayModel(
        ntConnection: ntConnection,
        preferences: preferences,
        topic: 'Test/Display Value',
        dataType: NT4Type.double(),
        period: 0.100,
      );
      model.publishData('3.53');

      // Simulate the robot pushing a different value onto the topic.
      ntConnection.updateDataFromTopicName('Test/Display Value', 9.9);
      expect(ntConnection.getLastAnnouncedValue('Test/Display Value'), 9.9);

      // This is the callback fired on (re)connect.
      model.publishLastWrittenValue();
      expect(ntConnection.getLastAnnouncedValue('Test/Display Value'), 3.53);
    });

    test('does nothing on connect when no value was ever written', () {
      final model = TextDisplayModel(
        ntConnection: ntConnection,
        preferences: preferences,
        topic: 'Test/Display Value',
        dataType: NT4Type.double(),
        period: 0.100,
      );

      model.publishLastWrittenValue();

      expect(model.lastWrittenValue, isNull);
      expect(ntConnection.getLastAnnouncedValue('Test/Display Value'), 0.0);
    });

    test('registers a reconnect listener on creation and removes it on '
        'dispose', () {
      final model = TextDisplayModel(
        ntConnection: ntConnection,
        preferences: preferences,
        topic: 'Test/Display Value',
        dataType: NT4Type.double(),
        period: 0.100,
      );

      verify(ntConnection.addConnectedListener(any)).called(1);

      model.dispose();

      verify(ntConnection.removeConnectedListener(any)).called(1);
    });
  });

  test('written value is persisted through the container save codepath', () {
    final ntConnection = createMockOnlineNT4(
      virtualTopics: [
        NT4Topic(
          name: 'Test/Display Value',
          type: NT4Type.double(),
          properties: {},
        ),
      ],
      virtualValues: {'Test/Display Value': 0.0},
    );

    final textDisplayModel = TextDisplayModel(
      ntConnection: ntConnection,
      preferences: preferences,
      topic: 'Test/Display Value',
      dataType: NT4Type.double(),
      period: 0.100,
    );
    textDisplayModel.publishData('3.53');

    final container = NTWidgetContainerModel(
      ntConnection: ntConnection,
      preferences: preferences,
      initialPosition: Rect.zero,
      title: 'Setpoint',
      childModel: textDisplayModel,
    );

    final json = container.toJson();
    expect(json['properties']['value'], 3.53);

    // Rebuild the child model from the exported properties and confirm the
    // value survives the load path used when opening a dashboard file.
    final restored = NTWidgetRegistry.buildNTModelFromJson(
      ntConnection,
      preferences,
      json['type'],
      json['properties'],
    );
    expect((restored as TextDisplayModel).lastWrittenValue, 3.53);
  });
}
