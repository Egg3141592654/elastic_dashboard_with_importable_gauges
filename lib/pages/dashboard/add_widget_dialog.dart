import 'package:flutter/material.dart';

import 'package:popover/popover.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elastic_dashboard/services/nt4_type.dart';
import 'package:elastic_dashboard/services/nt_connection.dart';
import 'package:elastic_dashboard/services/nt_widget_registry.dart';
import 'package:elastic_dashboard/widgets/dialog_widgets/dialog_dropdown_chooser.dart';
import 'package:elastic_dashboard/widgets/dialog_widgets/dialog_text_input.dart';
import 'package:elastic_dashboard/widgets/dialog_widgets/dialog_toggle_switch.dart';
import 'package:elastic_dashboard/widgets/dialog_widgets/layout_drag_tile.dart';
import 'package:elastic_dashboard/widgets/dialog_widgets/nt_widget_drag_tile.dart';
import 'package:elastic_dashboard/widgets/draggable_containers/models/layout_container_model.dart';
import 'package:elastic_dashboard/widgets/draggable_containers/models/nt_widget_container_model.dart';
import 'package:elastic_dashboard/widgets/draggable_containers/models/widget_container_model.dart';
import 'package:elastic_dashboard/widgets/draggable_dialog.dart';
import 'package:elastic_dashboard/widgets/network_tree/networktables_tree.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/single_topic/text_display.dart';
import 'package:elastic_dashboard/widgets/tab_grid.dart';

class AddWidgetDialog extends StatefulWidget {
  final NTConnection ntConnection;
  final SharedPreferences preferences;
  final TabGridModel grid;
  final int gridIndex;

  final void Function(Offset globalPosition, WidgetContainerModel widget)
  onNTDragUpdate;
  final void Function(WidgetContainerModel widget) onNTDragEnd;

  final void Function(Offset globalPosition, LayoutContainerModel widget)
  onLayoutDragUpdate;
  final void Function(LayoutContainerModel widget) onLayoutDragEnd;

  final void Function() onClose;

  const AddWidgetDialog({
    super.key,
    required this.ntConnection,
    required this.preferences,
    required this.grid,
    required this.gridIndex,
    required this.onNTDragUpdate,
    required this.onNTDragEnd,
    required this.onLayoutDragUpdate,
    required this.onLayoutDragEnd,
    required this.onClose,
  });

  @override
  State<AddWidgetDialog> createState() => _AddWidgetDialogState();
}

class _AddWidgetDialogState extends State<AddWidgetDialog> {
  static final List<NT4Type> _customDataTypes = [
    NT4Type.string(),
    NT4Type.double(),
    NT4Type.int(),
    NT4Type.boolean(),
  ];

  final TextEditingController searchTextController = TextEditingController();
  final TextEditingController customTopicController = TextEditingController();
  NT4Type _customDataType = NT4Type.string();
  bool _hideMetadata = true;
  String _searchQuery = '';

  /// Builds a text entry widget for a topic that doesn't have to be announced
  /// on network tables; typing into it publishes the topic to the server.
  /// Entered names are placed under the SmartDashboard table so robot code can
  /// read them with the SmartDashboard API.
  NTWidgetContainerModel? _createTextEntryWidget() {
    String topic = customTopicController.text.trim();
    while (topic.startsWith('/')) {
      topic = topic.substring(1);
    }
    if (topic.isEmpty) {
      return null;
    }
    if (!topic.startsWith('SmartDashboard/')) {
      topic = 'SmartDashboard/$topic';
    }
    topic = '/$topic';

    TextDisplayModel model = TextDisplayModel(
      ntConnection: widget.ntConnection,
      preferences: widget.preferences,
      topic: topic,
      dataType: _customDataType,
      showSubmitButton: true,
    );

    return NTWidgetContainerModel(
      ntConnection: widget.ntConnection,
      preferences: widget.preferences,
      initialPosition: Rect.fromLTWH(
        0.0,
        0.0,
        NTWidgetRegistry.getDefaultWidth(model),
        NTWidgetRegistry.getDefaultHeight(model),
      ),
      title: topic.substring(topic.lastIndexOf('/') + 1),
      childModel: model,
    );
  }

  void onRemove(TabGridModel grid) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      grid.removeDragInWidget();
    });
  }

  @override
  void didUpdateWidget(AddWidgetDialog oldWidget) {
    if (widget.gridIndex != oldWidget.gridIndex ||
        widget.grid != oldWidget.grid) {
      onRemove(oldWidget.grid);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) => DraggableDialog(
    dialog: Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            spreadRadius: -12.5,
            offset: Offset(5.0, 5.0),
            color: Colors.black87,
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.all(10.0),
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              const Icon(Icons.drag_handle, color: Colors.grey),
              const SizedBox(height: 10),
              Text(
                'Add Widget',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const TabBar(
                tabs: [
                  Tab(text: 'Network Tables'),
                  Tab(text: 'Layouts'),
                  Tab(text: 'Custom'),
                ],
              ),
              const SizedBox(height: 5),
              Expanded(
                child: TabBarView(
                  children: [
                    NetworkTableTree(
                      ntConnection: widget.ntConnection,
                      preferences: widget.preferences,
                      searchQuery: _searchQuery,
                      listLayoutBuilder: widget.grid.createListLayout,
                      hideMetadata: _hideMetadata,
                      gridIndex: widget.gridIndex,
                      onDragUpdate: widget.onNTDragUpdate,
                      onDragEnd: widget.onNTDragEnd,
                      onRemoveWidget: () => onRemove(widget.grid),
                    ),
                    ListView(
                      children: [
                        LayoutDragTile(
                          gridIndex: widget.gridIndex,
                          title: 'List Layout',
                          icon: Icons.table_rows,
                          layoutBuilder: widget.grid.createListLayout,
                          onDragUpdate: widget.onLayoutDragUpdate,
                          onDragEnd: widget.onLayoutDragEnd,
                          onRemoveWidget: () => onRemove(widget.grid),
                        ),
                      ],
                    ),
                    ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 4.0,
                          ),
                          child: Text(
                            'Create a widget for a topic that isn\'t published '
                            'on network tables yet. The topic is placed under '
                            'the SmartDashboard table, and values submitted to '
                            'it are published to the server.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: DialogTextInput(
                            label: 'Topic Name',
                            textEditingController: customTopicController,
                            allowEmptySubmission: true,
                            onSubmit: (value) {},
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: DialogDropdownChooser<NT4Type>(
                            choices: _customDataTypes,
                            initialValue: _customDataType,
                            nameMap: (type) => type.serialize(),
                            onSelectionChanged: (type) {
                              if (type != null) {
                                setState(() => _customDataType = type);
                              }
                            },
                          ),
                        ),
                        NTWidgetDragTile(
                          gridIndex: widget.gridIndex,
                          title: 'Text Entry',
                          icon: Icons.edit_note,
                          widgetBuilder: _createTextEntryWidget,
                          onDragUpdate: widget.onNTDragUpdate,
                          onDragEnd: widget.onNTDragEnd,
                          onRemoveWidget: () => onRemove(widget.grid),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        showPopover(
                          context: context,
                          direction: PopoverDirection.top,
                          transitionDuration: const Duration(
                            milliseconds: 100,
                          ),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          barrierColor: Colors.transparent,
                          width: 200.0,
                          bodyBuilder: (context) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: DialogToggleSwitch(
                              label: 'Hide Metadata',
                              initialValue: _hideMetadata,
                              onToggle: (value) {
                                setState(() => _hideMetadata = value);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 40.0,
                      child: DialogTextInput(
                        onSubmit: (value) =>
                            setState(() => _searchQuery = value),
                        allowEmptySubmission: true,
                        updateOnChanged: true,
                        label: 'Search',
                        textEditingController: searchTextController,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onClose,
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
