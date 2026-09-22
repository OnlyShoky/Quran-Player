import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:device_preview/presets.dart';

/// Opens the Device Preview selection modal sheet.
void showDevicePreviewSheet(BuildContext context) {
  final controller = DevicePreview.maybeController;
  if (controller == null) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DevicePreviewSheet(controller: controller),
  );
}

/// A wrapper widget that provides an in-app floating switcher for device_preview.
/// In release mode, this widget is a zero-overhead pass-through returning [child].
class DevicePreviewQuickSwitcher extends StatefulWidget {
  final Widget child;

  const DevicePreviewQuickSwitcher({super.key, required this.child});

  @override
  State<DevicePreviewQuickSwitcher> createState() =>
      _DevicePreviewQuickSwitcherState();
}

class _DevicePreviewQuickSwitcherState extends State<DevicePreviewQuickSwitcher> {
  Offset _position = const Offset(16, 120);
  bool _isCollapsed = false;
  bool _isHidden = false;

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) {
      return widget.child;
    }

    final controller = DevicePreview.maybeController;
    if (controller == null) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        if (!_isHidden)
          Positioned(
            left: _position.dx,
            top: _position.dy,
            child: ValueListenableBuilder<DeviceSimulation?>(
              valueListenable: controller.simulationListenable,
              builder: (context, simulation, _) {
                final presetName = _getPresetName(controller, simulation);
                final isSimulating = simulation != null && !simulation.isEmpty;

                return GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      final size = MediaQuery.of(context).size;
                      final newX = (_position.dx + details.delta.dx)
                          .clamp(8.0, size.width - 70.0);
                      final newY = (_position.dy + details.delta.dy)
                          .clamp(40.0, size.height - 70.0);
                      _position = Offset(newX, newY);
                    });
                  },
                  child: Material(
                    elevation: 6,
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSimulating
                            ? const Color(0xFF1E293B).withValues(alpha: 0.92)
                            : const Color(0xFF0F172A).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSimulating
                              ? const Color(0xFF38BDF8)
                              : Colors.white24,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => showDevicePreviewSheet(context),
                            borderRadius: BorderRadius.circular(18),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSimulating
                                      ? Icons.phone_iphone_rounded
                                      : Icons.devices_rounded,
                                  size: 18,
                                  color: isSimulating
                                      ? const Color(0xFF38BDF8)
                                      : Colors.white,
                                ),
                                if (!_isCollapsed) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    presetName ?? 'Preview',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isCollapsed = !_isCollapsed;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Icon(
                                _isCollapsed
                                    ? Icons.chevron_right_rounded
                                    : Icons.chevron_left_rounded,
                                size: 16,
                                color: Colors.white60,
                              ),
                            ),
                          ),
                          if (!_isCollapsed) ...[
                            const SizedBox(width: 2),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isHidden = true;
                                });
                                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Device preview floating button hidden. Open from Settings > Device Preview.',
                                    ),
                                    duration: const Duration(seconds: 4),
                                    action: SnackBarAction(
                                      label: 'Restore',
                                      onPressed: () {
                                        setState(() {
                                          _isHidden = false;
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(2.0),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: Colors.white38,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String? _getPresetName(
    DevicePreviewController controller,
    DeviceSimulation? simulation,
  ) {
    if (simulation == null || simulation.presetId == null) return null;
    final id = simulation.presetId;
    for (final p in controller.presets) {
      if (p.id == id) return p.name;
    }
    return 'Simulated';
  }
}

/// Modal Bottom Sheet displaying all devices and simulation controls.
class DevicePreviewSheet extends StatefulWidget {
  final DevicePreviewController controller;

  const DevicePreviewSheet({super.key, required this.controller});

  @override
  State<DevicePreviewSheet> createState() => _DevicePreviewSheetState();
}

class _DevicePreviewSheetState extends State<DevicePreviewSheet> {
  String _searchQuery = '';
  String _selectedCategory = 'All'; // 'All', 'iPhone', 'Android', 'Tablet', 'Desktop'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<DeviceSimulation?>(
      valueListenable: widget.controller.simulationListenable,
      builder: (context, simulation, _) {
        final currentPresetId = simulation?.presetId;
        final orientation = simulation?.orientation ?? Orientation.portrait;
        final hasKeyboard = simulation?.keyboardInset != null;
        final showSystemUi = simulation?.showSystemUi ?? true;

        // Current active preset object
        DevicePreset? activePreset;
        if (currentPresetId != null) {
          for (final p in widget.controller.presets) {
            if (p.id == currentPresetId) {
              activePreset = p;
              break;
            }
          }
        }

        final filteredPresets = _filterPresets(widget.controller.presets);

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131722) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Sheet Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title and Reset Action
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.devices_outlined, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Device Preview',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            activePreset != null
                                ? 'Active: ${activePreset.name}'
                                : 'Active: Real Device (No frame)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: activePreset != null
                                  ? theme.colorScheme.primary
                                  : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (activePreset != null)
                      TextButton.icon(
                        onPressed: () async {
                          await widget.controller.reset();
                          if (mounted) setState(() {});
                        },
                        icon: const Icon(Icons.restart_alt_rounded, size: 18),
                        label: const Text('Reset'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Controls Bar (Rotate, Keyboard, System UI)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: isDark ? Colors.black26 : Colors.grey.shade100,
                child: Row(
                  children: [
                    // Rotate
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: activePreset == null
                            ? null
                            : () async {
                                final nextOri =
                                    orientation == Orientation.portrait
                                        ? Orientation.landscape
                                        : Orientation.portrait;
                                await widget.controller.setOrientation(nextOri);
                              },
                        icon: Icon(
                          orientation == Orientation.portrait
                              ? Icons.stay_current_portrait_rounded
                              : Icons.stay_current_landscape_rounded,
                          size: 18,
                        ),
                        label: Text(
                          orientation == Orientation.portrait
                              ? 'Portrait'
                              : 'Landscape',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Keyboard
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: activePreset == null
                            ? null
                            : () async {
                                if (hasKeyboard) {
                                  await widget.controller.update(
                                    (s) => s.copyWith(keyboardInset: null),
                                  );
                                } else {
                                  final kbHeight =
                                      activePreset!.keyboardHeight(orientation) ??
                                          280.0;
                                  await widget.controller.update(
                                    (s) => s.copyWith(keyboardInset: kbHeight),
                                  );
                                }
                              },
                        icon: Icon(
                          Icons.keyboard_outlined,
                          size: 18,
                          color: hasKeyboard
                              ? theme.colorScheme.primary
                              : null,
                        ),
                        label: Text(
                          hasKeyboard ? 'Hide KB' : 'Raise KB',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasKeyboard
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // System UI Toggle
                    IconButton(
                      tooltip: 'Toggle System UI',
                      onPressed: activePreset == null
                          ? null
                          : () async {
                              await widget.controller.update(
                                (s) => s.copyWith(
                                  showSystemUi: !showSystemUi,
                                ),
                              );
                            },
                      icon: Icon(
                        showSystemUi
                            ? Icons.signal_cellular_alt_rounded
                            : Icons.signal_cellular_off_rounded,
                        size: 20,
                        color: showSystemUi
                            ? theme.colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // Search & Filter Categories
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: 'Search device (iPhone, Pixel, Galaxy...)',
                    hintStyle: const TextStyle(fontSize: 13),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E2536)
                        : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildFilterChip('All'),
                    const SizedBox(width: 6),
                    _buildFilterChip('iPhone'),
                    const SizedBox(width: 6),
                    _buildFilterChip('Android'),
                    const SizedBox(width: 6),
                    _buildFilterChip('Tablet'),
                    const SizedBox(width: 6),
                    _buildFilterChip('Desktop'),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Preset Device List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filteredPresets.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Real Device Item
                      final isSelected = activePreset == null;
                      return _buildDeviceTile(
                        title: 'Real Device / Pass-through',
                        subtitle: 'No simulation or frame applied',
                        icon: Icons.smartphone_rounded,
                        isSelected: isSelected,
                        onTap: () async {
                          await widget.controller.reset();
                          if (mounted) setState(() {});
                        },
                      );
                    }

                    final preset = filteredPresets[index - 1];
                    final isSelected = currentPresetId == preset.id;

                    final kindIcon = _getDeviceIcon(preset);
                    final sizeText =
                        '${preset.portraitSize.width.toInt()} × ${preset.portraitSize.height.toInt()} pt • @${preset.devicePixelRatio.toStringAsFixed(1)}x';
                    final brandYear = [
                      if (preset.brand != null) preset.brand!,
                      if (preset.year != null) '${preset.year}',
                    ].join(' • ');

                    return _buildDeviceTile(
                      title: preset.name,
                      subtitle: brandYear.isNotEmpty
                          ? '$brandYear ($sizeText)'
                          : sizeText,
                      icon: kindIcon,
                      isSelected: isSelected,
                      onTap: () async {
                        await widget.controller.applyPreset(
                          preset,
                          orientation: orientation,
                        );
                        if (mounted) setState(() {});
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String category) {
    final isSelected = _selectedCategory == category;
    final theme = Theme.of(context);

    return FilterChip(
      selected: isSelected,
      label: Text(category),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        color: isSelected
            ? theme.colorScheme.onPrimary
            : theme.textTheme.bodyMedium?.color,
      ),
      selectedColor: theme.colorScheme.primary,
      showCheckmark: false,
      onSelected: (_) {
        setState(() {
          _selectedCategory = category;
        });
      },
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildDeviceTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.12)
              : (isDark ? const Color(0xFF1E2536) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? Colors.white10 : Colors.black12),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.white12 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getDeviceIcon(DevicePreset preset) {
    if (preset.name.contains('iPhone') || preset.platform == TargetPlatform.iOS) {
      return preset.kind == DeviceKind.tablet
          ? Icons.tablet_mac_rounded
          : Icons.phone_iphone_rounded;
    }
    if (preset.kind == DeviceKind.tablet) {
      return Icons.tablet_android_rounded;
    }
    if (preset.kind == DeviceKind.desktop) {
      return Icons.laptop_mac_rounded;
    }
    return Icons.phone_android_rounded;
  }

  List<DevicePreset> _filterPresets(List<DevicePreset> all) {
    return all.where((p) {
      final name = p.name.toLowerCase();
      final brand = (p.brand ?? '').toLowerCase();

      // Search query
      if (_searchQuery.isNotEmpty) {
        final matches = name.contains(_searchQuery) || brand.contains(_searchQuery);
        if (!matches) return false;
      }

      // Category filter
      switch (_selectedCategory) {
        case 'iPhone':
          return name.contains('iphone');
        case 'Android':
          return p.platform == TargetPlatform.android &&
              p.kind == DeviceKind.phone;
        case 'Tablet':
          return p.kind == DeviceKind.tablet;
        case 'Desktop':
          return p.kind == DeviceKind.desktop;
        default:
          return true;
      }
    }).toList();
  }
}
