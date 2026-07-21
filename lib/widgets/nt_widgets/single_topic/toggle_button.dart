import 'package:flutter/material.dart';

import 'package:dot_cast/dot_cast.dart';
import 'package:provider/provider.dart';

import 'package:elastic_dashboard/widgets/nt_widgets/nt_widget.dart';

class ToggleButtonModel extends SingleTopicNTWidgetModel with NTWritableModel {
  @override
  String type = ToggleButton.widgetType;

  ToggleButtonModel({
    required super.ntConnection,
    required super.preferences,
    required super.topic,
    super.dataType,
    super.period,
    super.ntStructMeta,
  }) : super();

  ToggleButtonModel.fromJson({
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

class ToggleButton extends NTWidget {
  static const String widgetType = 'Toggle Button';

  const ToggleButton({super.key}) : super();

  @override
  Widget build(BuildContext context) {
    ToggleButtonModel model = cast(context.watch<NTWidgetModel>());

    return ValueListenableBuilder(
      valueListenable: model.subscription!,
      builder: (context, data, child) {
        bool value = tryCast(data) ?? false;

        String buttonText = model.topic.substring(
          model.topic.lastIndexOf('/') + 1,
        );

        Size buttonSize = MediaQuery.of(context).size;

        ThemeData theme = Theme.of(context);

        return GestureDetector(
          onTapUp: (_) {
            model.publishValue(!value);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: buttonSize.width * 0.01,
              vertical: buttonSize.height * 0.01,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 10),
              width: buttonSize.width,
              height: buttonSize.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(2, 2),
                    blurRadius: 10.0,
                    spreadRadius: -5,
                    color: Colors.black,
                  ),
                ],
                color: (value)
                    ? theme.colorScheme.primaryContainer
                    : const Color.fromARGB(255, 50, 50, 50),
              ),
              child: Center(
                child: Text(
                  buttonText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
