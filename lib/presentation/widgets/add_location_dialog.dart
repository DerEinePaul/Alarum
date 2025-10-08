import 'package:flutter/material.dart';
import 'clock_widget.dart';

class AddLocationDialog extends StatefulWidget {
  final Function(TimeZoneLocation) onLocationAdded;

  const AddLocationDialog({super.key, required this.onLocationAdded});

  @override
  State<AddLocationDialog> createState() => _AddLocationDialogState();
}

class _AddLocationDialogState extends State<AddLocationDialog> {
  final List<TimeZoneLocation> _predefinedLocations = [
    TimeZoneLocation(name: 'New York', timezone: 'America/New_York', country: 'USA'),
    TimeZoneLocation(name: 'London', timezone: 'Europe/London', country: 'UK'),
    TimeZoneLocation(name: 'Berlin', timezone: 'Europe/Berlin', country: 'Germany'),
    TimeZoneLocation(name: 'Tokyo', timezone: 'Asia/Tokyo', country: 'Japan'),
    TimeZoneLocation(name: 'Shanghai', timezone: 'Asia/Shanghai', country: 'China'),
    TimeZoneLocation(name: 'Sydney', timezone: 'Australia/Sydney', country: 'Australia'),
    TimeZoneLocation(name: 'Los Angeles', timezone: 'America/Los_Angeles', country: 'USA'),
  ];

  List<TimeZoneLocation> _filteredLocations = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredLocations = _predefinedLocations;
    _searchController.addListener(_filterLocations);
  }

  void _filterLocations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLocations = _predefinedLocations
          .where((location) =>
              location.name.toLowerCase().contains(query) ||
              location.country.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Location',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search cities...',
                prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredLocations.length,
                itemBuilder: (context, index) {
                  final location = _filteredLocations[index];
                  return ListTile(
                    title: Text(
                      location.name,
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      location.country,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    onTap: () {
                      widget.onLocationAdded(location);
                      Navigator.of(context).pop();
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}