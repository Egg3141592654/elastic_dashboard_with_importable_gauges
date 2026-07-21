import 'package:flutter/material.dart';

import 'package:dot_cast/dot_cast.dart';
import 'package:provider/provider.dart';

import 'package:elastic_dashboard/widgets/nt_widgets/nt_widget.dart';

class ToggleSwitchModel extends SingleTopicNTWidgetModel with NTWritableModel {
  @override
  String type = ToggleSwitch.widgetType;

  ToggleSwitchModel({
    required super.ntConnection,
    required super.preferences,
    required super.topic,
    super.dataType,
    super.period,
    super.ntStructMeta,
  }) : super();

  ToggleSwitchModel.fromJson({
    required super.ntConnection,
    required super.preferences,
    required Map<String, dynamic> jsonData,
  }) : super.fromJson(jsonData: jsonData) {
    restoreWrittenValue(jsonData);
  }

  void publishValue(bool value) {
    if (ntStructMeta != null) {
      return;
    }

    bool alreadyPublished =
        ntTopic != null && ntConnection.isTopicPublished(ntTopic!);

    createTopicIfNull();

    if (ntTopic == null) {
      return;
    }

    if (!alreadyPublished) {
      ntConnection.publishTopic(ntTopic!);
    }

    ntConnection.updateDataFromTopic(ntTopic!, value);
    setLastWrittenValue(value);
  }

  @override
  void publishLastWrittenValue() {
    Object? value = lastWrittenValue;
    if (value is bool) {
      publishValue(value);
    }
  }
}

class ToggleSwitch extends NTWidget {
  static const String widgetType = 'Toggle Switch';

  const ToggleSwitch({super.key}) : super();

  @override
  Widget build(BuildContext context) {
    ToggleSwitchModel model = cast(context.watch<NTWidgetModel>());

    return ValueListenableBuilder(
      valueListenable: model.subscription!,
      builder: (context, data, child) {
        bool value = tryCast(data) ?? false;

        return Switch(
          value: value,
          onChanged: (bool value) {
            model.publishValue(value);
          },
        );
      },
    );
  }
}
