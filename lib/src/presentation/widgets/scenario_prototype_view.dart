import 'package:flutter/material.dart';

import '../../core/scenario.dart';
import '../../core/scenario_controller.dart';
import '../../testing/registry/scenario_test_registry.dart';
import '../theme/scenario_panel_theme.dart';

/// Device form-factor for previewing scenario flows in Prototype Mode.
enum PrototypeDevice {
  phone(
      label: 'Phone',
      width: 250,
      height: 480,
      radius: 28,
      border: 8,
      resolution: '390 × 844'),
  tablet(
      label: 'Tablet',
      width: 360,
      height: 460,
      radius: 20,
      border: 8,
      resolution: '820 × 1024'),
  desktop(
      label: 'Desktop',
      width: 500,
      height: 350,
      radius: 12,
      border: 6,
      resolution: '1440 × 900');

  const PrototypeDevice({
    required this.label,
    required this.width,
    required this.height,
    required this.radius,
    required this.border,
    required this.resolution,
  });

  final String label;
  final double width;
  final double height;
  final double radius;
  final double border;
  final String resolution;
}

/// Interactive 3-column studio for previewing scenarios as a prototype flow with
/// device frames, live inspections, reviewer notes, and export actions.
class ScenarioPrototypeView extends StatefulWidget {
  const ScenarioPrototypeView({
    super.key,
    required this.controller,
    this.testRegistry,
    required this.theme,
    this.initialScenarioId,
  });

  final ScenarioController controller;
  final ScenarioTestRegistry? testRegistry;
  final ScenarioPanelThemeData theme;
  final String? initialScenarioId;

  @override
  State<ScenarioPrototypeView> createState() => _ScenarioPrototypeViewState();
}

class _ScenarioPrototypeViewState extends State<ScenarioPrototypeView> {
  late String _selectedScenarioId;
  PrototypeDevice _device = PrototypeDevice.desktop;
  final Map<String, String> _reviewerNotes = {};
  late final TextEditingController _noteController;

  bool _exportOpen = false;
  String _exportFormat = 'html';
  bool _exportAllScenarios = true;
  bool _exportDeviceFrames = true;
  bool _exportNotes = true;
  bool _exportTestResults = false;

  @override
  void initState() {
    super.initState();
    _selectedScenarioId = widget.initialScenarioId ??
        widget.controller.selectedId ??
        (widget.controller.registry.scenarios.isNotEmpty
            ? widget.controller.registry.scenarios.first.id
            : '');
    _noteController = TextEditingController(
      text: _reviewerNotes[_selectedScenarioId] ?? '',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _selectScenario(String id) {
    if (_selectedScenarioId == id) return;
    _reviewerNotes[_selectedScenarioId] = _noteController.text;
    setState(() {
      _selectedScenarioId = id;
      _noteController.text = _reviewerNotes[id] ?? '';
    });
  }

  void _navigateRelative(int delta, List<Scenario> scenarios) {
    if (scenarios.isEmpty) return;
    final currentIndex =
        scenarios.indexWhere((s) => s.id == _selectedScenarioId);
    final nextIndex =
        (currentIndex + delta + scenarios.length) % scenarios.length;
    _selectScenario(scenarios[nextIndex].id);
  }

  @override
  Widget build(BuildContext context) {
    final panelTheme = widget.theme;
    final scenarios = widget.controller.registry.scenarios;
    final currentScenario = scenarios.firstWhere(
      (s) => s.id == _selectedScenarioId,
      orElse: () => scenarios.isNotEmpty
          ? scenarios.first
          : Scenario(
              id: 'none',
              name: 'No Scenario Selected',
              builder: (_) => const SizedBox.shrink(),
            ),
    );

    final testRegistry = widget.testRegistry ?? ScenarioTestRegistry.instance;
    final associatedTestsCount = testRegistry.allTests.where((t) {
      if (t.requiredScenarioId == currentScenario.id) return true;
      if (t.screen != null &&
          currentScenario.group != null &&
          t.screen!.toLowerCase() == currentScenario.group!.toLowerCase()) {
        return true;
      }
      return false;
    }).length;

    return Container(
      color: panelTheme.backgroundColor,
      child: Column(
        children: [
          _buildToolbar(panelTheme, scenarios),
          Expanded(
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Column 1: Scenario Flow Rail
                    _buildScenarioFlowRail(panelTheme, scenarios),
                    // Column 2: Center Stage Device Bezel
                    Expanded(
                      child: _buildCenterStage(panelTheme, currentScenario),
                    ),
                    // Column 3: Inspector Rail
                    _buildInspectorRail(
                      panelTheme,
                      currentScenario,
                      associatedTestsCount,
                      scenarios,
                    ),
                  ],
                ),
                if (_exportOpen)
                  Positioned(
                    top: 10,
                    right: 24,
                    child: _buildExportPopover(panelTheme, scenarios.length),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(
      ScenarioPanelThemeData panelTheme, List<Scenario> scenarios) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: panelTheme.borderColor)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Prototype Mode',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: panelTheme.textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Preview every scenario as a flow, then export it',
                style: TextStyle(
                  fontSize: 12.5,
                  color: panelTheme.subtitleColor,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Device Segmented Selector
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: panelTheme.chipColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: PrototypeDevice.values.map((d) {
                final selected = _device == d;
                return InkWell(
                  onTap: () => setState(() => _device = d),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: selected
                          ? const [
                              BoxShadow(
                                color: Color(0x2614142B),
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      d.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? panelTheme.primaryColor
                            : panelTheme.textColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 14),
          // Export Action Button
          FilledButton.icon(
            key: const ValueKey('prototype_export_button'),
            onPressed: () => setState(() => _exportOpen = !_exportOpen),
            icon: const Icon(Icons.file_download_outlined, size: 16),
            label: const Text('Export'),
            style: FilledButton.styleFrom(
              backgroundColor: panelTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioFlowRail(
      ScenarioPanelThemeData panelTheme, List<Scenario> scenarios) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: panelTheme.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'SCENARIO FLOW',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: panelTheme.subtitleColor,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: scenarios.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final scenario = scenarios[index];
                final isSelected = scenario.id == _selectedScenarioId;

                return InkWell(
                  onTap: () => _selectScenario(scenario.id),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF1F2FF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? panelTheme.primaryColor
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? panelTheme.primaryColor
                                : panelTheme.chipColor,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : panelTheme.textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                scenario.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: panelTheme.textColor,
                                ),
                              ),
                              if (scenario.group != null &&
                                  scenario.group!.trim().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  scenario.group!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: panelTheme.subtitleColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterStage(
      ScenarioPanelThemeData panelTheme, Scenario scenario) {
    return Container(
      color: const Color(0xFFECECF5),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: _device.width,
            height: _device.height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_device.radius),
              border: Border.all(
                color: const Color(0xFF14142B),
                width: _device.border,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4014142B),
                  blurRadius: 32,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(_device.radius - _device.border),
              child: Builder(
                builder: (previewContext) {
                  return scenario.builder(previewContext);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${scenario.name} · ${_device.resolution}',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: panelTheme.subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorRail(
    ScenarioPanelThemeData panelTheme,
    Scenario scenario,
    int testCount,
    List<Scenario> scenarios,
  ) {
    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: panelTheme.borderColor)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'INSPECTOR',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: panelTheme.subtitleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            scenario.name,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: panelTheme.textColor,
            ),
          ),
          if (scenario.description != null &&
              scenario.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              scenario.description!,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: panelTheme.subtitleColor,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Definition items
          _buildInspectorRow('ID', scenario.id,
              isMonospace: true, panelTheme: panelTheme),
          const SizedBox(height: 8),
          _buildInspectorRow('Group', scenario.group ?? 'Default',
              panelTheme: panelTheme),
          const SizedBox(height: 8),
          _buildInspectorRow('Meta', '${scenario.metadata.length} entries',
              panelTheme: panelTheme),
          const SizedBox(height: 8),
          _buildInspectorRow(
            'Tests',
            testCount == 1 ? '1 test' : '$testCount tests',
            panelTheme: panelTheme,
          ),
          const SizedBox(height: 20),
          Text(
            'Reviewer note',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: panelTheme.textColor,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _noteController,
            maxLines: 4,
            style: TextStyle(fontSize: 13, color: panelTheme.textColor),
            decoration: InputDecoration(
              hintText: 'Add context that exports with this screen',
              hintStyle: TextStyle(
                  fontSize: 13,
                  color: panelTheme.subtitleColor.withValues(alpha: 0.6)),
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: panelTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFDCDCEA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: panelTheme.primaryColor, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => _navigateRelative(-1, scenarios),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
              side: const BorderSide(color: Color(0xFFDCDCEA)),
              foregroundColor: panelTheme.textColor,
            ),
            child: const Text('Previous screen',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _navigateRelative(1, scenarios),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
              side: const BorderSide(color: Color(0xFFDCDCEA)),
              foregroundColor: panelTheme.textColor,
            ),
            child: const Text('Next screen',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorRow(
    String label,
    String value, {
    bool isMonospace = false,
    required ScenarioPanelThemeData panelTheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: panelTheme.subtitleColor),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: isMonospace ? 'monospace' : null,
              color: panelTheme.textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportPopover(
      ScenarioPanelThemeData panelTheme, int totalScenarios) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDCDCEA)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3814142B),
              blurRadius: 40,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Export prototype',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: panelTheme.textColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _exportOpen = false),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Formats row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _exportFormat = 'html'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _exportFormat == 'html'
                            ? const Color(0xFFF1F2FF)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _exportFormat == 'html'
                              ? panelTheme.primaryColor
                              : const Color(0xFFDCDCEA),
                          width: _exportFormat == 'html' ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HTML',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: panelTheme.textColor)),
                          const SizedBox(height: 2),
                          Text('Interactive, 1 file',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: panelTheme.subtitleColor)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _exportFormat = 'pdf'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _exportFormat == 'pdf'
                            ? const Color(0xFFF1F2FF)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _exportFormat == 'pdf'
                              ? panelTheme.primaryColor
                              : const Color(0xFFDCDCEA),
                          width: _exportFormat == 'pdf' ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PDF',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: panelTheme.textColor)),
                          const SizedBox(height: 2),
                          Text('Print-ready pages',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: panelTheme.subtitleColor)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildExportCheckbox(
              value: _exportAllScenarios,
              onChanged: (v) => setState(() => _exportAllScenarios = v ?? true),
              label: 'All $totalScenarios scenarios (not just active)',
              panelTheme: panelTheme,
            ),
            _buildExportCheckbox(
              value: _exportDeviceFrames,
              onChanged: (v) => setState(() => _exportDeviceFrames = v ?? true),
              label: 'Include device frames',
              panelTheme: panelTheme,
            ),
            _buildExportCheckbox(
              value: _exportNotes,
              onChanged: (v) => setState(() => _exportNotes = v ?? true),
              label: 'Include notes and metadata',
              panelTheme: panelTheme,
            ),
            _buildExportCheckbox(
              value: _exportTestResults,
              onChanged: (v) => setState(() => _exportTestResults = v ?? false),
              label: 'Append test results',
              panelTheme: panelTheme,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  setState(() => _exportOpen = false);
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    SnackBar(
                      content: Text(
                          'Exporting prototype as ${_exportFormat.toUpperCase()}...'),
                      backgroundColor: panelTheme.primaryColor,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: panelTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  _exportFormat == 'html' ? 'Export as HTML' : 'Export as PDF',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _exportFormat == 'html'
                  ? 'One self-contained file with a scenario navigator. Opens in any browser.'
                  : 'One scenario per A4 page, with a cover page and summary table.',
              style: TextStyle(
                  fontSize: 11.5, color: panelTheme.subtitleColor, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
    required ScenarioPanelThemeData panelTheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: panelTheme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: panelTheme.textColor),
            ),
          ),
        ],
      ),
    );
  }
}
