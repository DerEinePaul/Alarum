import 'package:flutter/material.dart';
import '../widgets/clock_widget.dart';
import '../widgets/stopwatch_widget.dart';
import '../widgets/timer_widget.dart';
import '../widgets/alarm_list_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const ClockWidget(),
    const StopwatchWidget(),
    const TimerWidget(),
    const AlarmListWidget(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 600;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Alarum'),
          ),
          body: isDesktop
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _onItemTapped,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.access_time),
                          label: Text('Clock'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.timer),
                          label: Text('Stopwatch'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.hourglass_empty),
                          label: Text('Timer'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.alarm),
                          label: Text('Alarms'),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Center(
                        child: _widgetOptions.elementAt(_selectedIndex),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: _widgetOptions.elementAt(_selectedIndex),
                ),
          bottomNavigationBar: isDesktop
              ? null
              : BottomNavigationBar(
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.access_time),
                      label: 'Clock',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.timer),
                      label: 'Stopwatch',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.hourglass_empty),
                      label: 'Timer',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.alarm),
                      label: 'Alarms',
                    ),
                  ],
                  currentIndex: _selectedIndex,
                  selectedItemColor: Colors.amber[800],
                  onTap: _onItemTapped,
                ),
        );
      },
    );
  }
}