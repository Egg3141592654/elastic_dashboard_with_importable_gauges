import 'package:flutter/material.dart';

import 'package:dot_cast/dot_cast.dart';
import 'package:provider/provider.dart';

import 'package:elastic_dashboard/services/nt4_client.dart';
import 'package:elastic_dashboard/services/nt4_type.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/nt_widget.dart';

class SplitButtonChooserModel extends MultiTopicNTWidgetModel
    with NTWritableModel {
  @override
  String type = SplitButtonChooser.widgetType;

  String get optionsTopicName => '$topic/options';
  String get selectedTopicName => '$topic/selected';
  String get activeTopicName => '$topic/active';
  String get defaultTopicName => '$topic/default';

  late NT4Subscription optionsSubscription;
  late NT4Subscription selectedSubscription;
  late NT4Subscription activeSubscription;
  late NT4Subscription defaultSubscription;

  @override
  List<NT4Subscription> get subscriptions => [
    optionsSubscription,
    selectedSubscription,
    activeSubscription,
    defaultSubscription,
  ];

  late Listenable chooserStateListenable;

  String? previousDefault;
  String? previousSelected;
  String? previousActive;
  List<String>? previousOptions;

  NT4Topic? _selectedTopic;

  SplitButtonChooserModel({
    required super.ntConnection,
    required super.preferences,
    required super.topic,
    super.period,
  }) : super();

  SplitButtonChooserModel.fromJson({
    required super.ntConnection,
    required super.preferences,
    required Map<String, dynamic> jsonData,
  }) : super.fromJson(jsonData: jsonData) {
    restoreWrittenValue(jsonData);
  }

  @override
  void initializeSubscriptions() {
    optionsSubscription = ntConnection.subscribe(
      optionsTopicName,
      super.period,
    );
    selectedSubscription = ntConnection.subscribe(
      selectedTopicName,
      super.period,
    );
    activeSubscription = ntConnection.subscribe(activeTopicName, super.period);
    defaultSubscription = ntConnection.subscribe(
      defaultTopicName,
      super.period,
    );
    chooserStateListenable = Listenable.merge(subscriptions);
    chooserStateListenable.addListener(onChooserStateUpdate);

    previousOptions = null;
    previousActive = null;
    previousDefault = null;
    previousSelected = null;

    // Initial caching of the chooser state, when switching
    // topics the listener won't be called, so we have to call it manually
    onChooserStateUpdate();
  }

  @override
  void resetSubscription() {
    unpublishSelectedTopic();
    chooserStateListenable.removeListener(onChooserStateUpdate);

    super.resetSubscription();
  }

  @override
  void softDispose({bool deleting = false}) {
    if (deleting) {
      unpublishSelectedTopic();
    }
  }

  void onChooserStateUpdate() {
    List<Object?>? rawOptions = optionsSubscription.value
        ?.tryCast<List<Object?>>();

    List<String>? currentOptions = rawOptions?.whereType<String>().toList();

    String? currentActive = tryCast(activeSubscription.value);
    if (currentActive != null && currentActive.isEmpty) {
      currentActive = null;
    }

    String? currentSelected = tryCast(selectedSubscription.value);
    if (currentSelected != null && currentSelected.isEmpty) {
      currentSelected = null;
    }

    String? currentDefault = tryCast(defaultSubscription.value);
    if (currentDefault != null && currentDefault.isEmpty) {
      currentDefault = null;
    }

    bool hasValue =
        currentOptions != null ||
        currentActive != null ||
        currentDefault != null;

    bool publishCurrent =
        hasValue && previousSelected != null && currentSelected == null;

    // We only want to publish the selected topic if we're getting values
    // from the others, since it means the chooser is published on network tables
    if (hasValue) {
      publishSelectedTopic();
    }

    if (currentOptions != null) {
      previousOptions = currentOptions;
    }
    if (currentSelected != null) {
      previousSelected = currentSelected;
    }
    if (currentActive != null) {
      previousActive = currentActive;
    }
    if (currentDefault != null) {
      previousDefault = currentDefault;
    }

    if (publishCurrent) {
      publishSelectedValue(previousSelected, true);
    }

    notifyListeners();
  }

  void publishSelectedTopic() {
    if (_selectedTopic != null &&
        ntConnection.isTopicPublished(_selectedTopic)) {
      return;
    }

    NT4Topic? existing = ntConnection.getTopicFromName(selectedTopicName);

    if (existing != null) {
      existing.properties.addAll({'retained': true});
      ntConnection.publishTopic(existing);
      _selectedTopic = existing;
    } else {
      _selectedTopic = ntConnection.publishNewTopic(
        selectedTopicName,
        NT4Type.string(),
        properties: {'retained': true},
      );
    }
  }

  void unpublishSelectedTopic() {
    if (_selectedTopic != null &&
        ntConnection.isTopicPublished(_selectedTopic)) {
      ntConnection.unpublishTopic(_selectedTopic!);
    }
    _selectedTopic = null;
  }

  void publishSelectedValue(String? selected, [bool initial = false]) {
    if (selected == null || !ntConnection.isNT4Connected) {
      return;
    }

    if (_selectedTopic == null ||
        !ntConnection.isTopicPublished(_selectedTopic)) {
      publishSelectedTopic();
    }

    ntConnection.updateDataFromTopic(
      _selectedTopic!,
      selected,
      initial ? 0 : null,
    );

    setLastWrittenValue(selected);
  }

  @override
  void publishLastWrittenValue() {
    // No-op: the chooser re-asserts its selection on its own via
    // onChooserStateUpdate when the robot (re)publishes the chooser, so
    // republishing here would be redundant.
  }
}

class SplitButtonChooser extends NTWidget {
  static const String widgetType = 'Split Button Chooser';

  const SplitButtonChooser({super.key}) : super();

  @override
  Widget build(BuildContext context) {
    SplitButtonChooserModel model = cast(context.watch<NTWidgetModel>());

    // Fall back to the last written value so a restored selection is shown
    // even before the robot connects and publishes the chooser.
    String? preview =
        model.previousSelected ??
        model.previousDefault ??
        tryCast<String>(model.lastWrittenValue);

    // Always keep the shown selection in the options list, otherwise a restored
    // value that isn't among the robot's published options renders no button.
    List<String> options = [...?model.previousOptions];
    if (preview != null && preview.isNotEmpty && !options.contains(preview)) {
      options.add(preview);
    }

    bool showWarning = model.previousActive != preview;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: ToggleButtons(
              onPressed: (index) {
                model.publishSelectedValue(options[index]);
              },
              isSelected: options
                  .map((String option) => option == preview)
                  .toList(),
              children: options
                  .map(
                    (String option) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(option),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(width: 5),
        (showWarning)
            ? const Tooltip(
                message:
                    'Selected value has not been published to Network Tables.\nRobot code will not be receiving the correct value.',
                child: Icon(Icons.priority_high, color: Colors.red),
              )
            : const Icon(Icons.check, color: Colors.green),
      ],
    );
  }
}
