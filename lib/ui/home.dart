import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/core_state.dart';


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashScreen(),
      const ShopScreen(),
      SettingsScreen(
        onReminderSaved: () {
          if (!mounted) return;
          setState(() => selectedIndex = 0);
        },
      ),
    ];

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (value) => setState(() => selectedIndex = value),
        backgroundColor: const Color(0xFF101018),
        selectedItemColor: const Color(0xFFA3E635),
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class DashScreen extends StatelessWidget {
  const DashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final level = context.select<CoreState, int>((state) => state.level);
    final streak = context.select<CoreState, int>((state) => state.streak);
    final gems = context.select<CoreState, int>((state) => state.gems);
    final xp = context.select<CoreState, int>((state) => state.xp);
    final xpNeed = context.select<CoreState, int>((state) => state.xpNeed);
    final progress = xpNeed > 0 ? (xp / xpNeed).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B10),
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF0B0F12),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: const Color(0xFF14141D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LVL $level',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$streak day streak', style: const TextStyle(color: Colors.white70)),
                          Text('💎 $gems', style: const TextStyle(color: Colors.amber, fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: progress.toDouble(),
                          minHeight: 10,
                          color: const Color(0xFFA3E635),
                          backgroundColor: Colors.white12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('$xp / $xpNeed XP', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Daily Tasks', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: Selector<CoreState, List<Map<String, dynamic>>>(
                selector: (_, state) => state.tasks,
                builder: (context, tasks, _) {
                  if (tasks.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      child: Text(
                        'Create tasks here and tap them when they are complete to earn XP and gems. Stay consistent to build a powerful streak.',
                        style: TextStyle(color: Colors.white60, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: tasks.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final completed = task['done'] == true;
                      return Card(
                        color: const Color(0xFF12121A),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        child: ListTile(
                          title: Text(
                            task['title']?.toString() ?? '',
                            style: TextStyle(
                              color: completed ? Colors.white54 : Colors.white,
                              decoration: completed ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          leading: Icon(
                            completed ? Icons.check_circle : Icons.bolt,
                            color: completed ? Colors.green : const Color(0xFFA3E635),
                          ),
                          trailing: completed ? const Text('Done', style: TextStyle(color: Colors.green)) : null,
                          onTap: () => context.read<CoreState>().toggleTask(task['id']?.toString() ?? ''),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              color: const Color(0xFF12121A),
              height: 60,
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12),
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.ads_click, color: Colors.white24, size: 18),
                      SizedBox(height: 4),
                      Text(
                        'AdMob Banner - Ready for google_mobile_ads integration',
                        style: TextStyle(color: Colors.white24, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFA3E635),
        onPressed: () => _showAddTask(context),
        child: const Icon(Icons.add, color: Color(0xFF0B0B10)),
      ),
    );
  }

  void _showAddTask(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B0B10),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('New task', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'What will you accomplish today?',
                  hintStyle: TextStyle(color: Colors.white38),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFA3E635))),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    context.read<CoreState>().addTask(text);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('ADD TASK'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CoreState>();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B10),
      appBar: AppBar(
        title: const Text('VIP Pass'),
        backgroundColor: const Color(0xFF0B0F12),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              _VipHeroCard(vipActive: state.vip),
              const SizedBox(height: 16),
              const _VipFeatureList(),
              const SizedBox(height: 16),
              _VipPricingCards(vipActive: state.vip, onActivate: state.activateVip),
              const SizedBox(height: 16),
              const Text(
                'VIP includes Unlimited habits, Advanced interactive charts, and No Ads.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VipHeroCard extends StatelessWidget {
  final bool vipActive;

  const _VipHeroCard({required this.vipActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF14141D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: vipActive ? const Color(0xFFA3E635) : Colors.white12, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA3E635).withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VIP PASS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            vipActive ? 'STATUS: ACTIVE' : 'STATUS: LOCKED',
            style: TextStyle(
              color: vipActive ? const Color(0xFFA3E635) : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Aggressive premium performance mode.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: vipActive ? null : () => context.read<CoreState>().activateVip(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA3E635),
              disabledBackgroundColor: Colors.grey,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              vipActive ? 'VIP ACTIVE' : 'ACTIVATE VIP',
              style: TextStyle(
                color: vipActive ? Colors.black : const Color(0xFF0B0B10),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VipFeatureList extends StatelessWidget {
  const _VipFeatureList();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF14141D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WHAT YOU GET',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            const _VipBullet(text: 'Unlimited habits'),
            const _VipBullet(text: 'Advanced interactive charts'),
            const _VipBullet(text: 'No Ads'),
          ],
        ),
      ),
    );
  }
}

class _VipBullet extends StatelessWidget {
  final String text;

  const _VipBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.flash_on, color: Color(0xFFA3E635), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _VipPricingCards extends StatelessWidget {
  final bool vipActive;
  final VoidCallback onActivate;

  const _VipPricingCards({required this.vipActive, required this.onActivate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _VipPriceCard(
          title: 'Monthly Subscription',
          priceText: '\$2.99 / 99 TL',
          subtitle: 'Best for starting now',
          disabled: vipActive,
          onTap: onActivate,
        ),
        const SizedBox(height: 12),
        _VipPriceCard(
          title: 'Annual Subscription',
          priceText: '\$19.99 / 650 TL',
          subtitle: 'Maximum savings',
          disabled: vipActive,
          onTap: onActivate,
        ),
      ],
    );
  }
}

class _VipPriceCard extends StatelessWidget {
  final String title;
  final String priceText;
  final String subtitle;
  final bool disabled;
  final VoidCallback onTap;

  const _VipPriceCard({
    required this.title,
    required this.priceText,
    required this.subtitle,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF12121A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              priceText,
              style: const TextStyle(color: Color(0xFFA3E635), fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: disabled ? null : onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA3E635),
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  disabled ? 'VIP ACTIVE' : 'SUBSCRIBE',
                  style: TextStyle(
                    color: disabled ? Colors.black : const Color(0xFF0B0B10),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final VoidCallback onReminderSaved;

  const SettingsScreen({super.key, required this.onReminderSaved});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CoreState>();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B10),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF0B0F12),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: const Color(0xFF14141D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.white70),
                title: Text(state.userName, style: const TextStyle(color: Colors.white)),
                subtitle: Text(state.userEmail, style: const TextStyle(color: Colors.white70)),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: const Color(0xFF14141D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ListTile(
                leading: const Icon(Icons.alarm, color: Colors.white70),
                title: const Text('Daily reminder', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  MaterialLocalizations.of(context).formatTimeOfDay(state.reminderTime),
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                onTap: () async {
                  final coreState = context.read<CoreState>();
                  final selected = await showTimePicker(
                    context: context,
                    initialTime: state.reminderTime,
                  );

                  if (selected != null && context.mounted) {
                    await coreState.setDailyReminder(selected);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Daily reminder set for ${MaterialLocalizations.of(context).formatTimeOfDay(selected)}.',
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    widget.onReminderSaved();
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: const Color(0xFF14141D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF14141D),
                      title: const Text('Logout', style: TextStyle(color: Colors.white)),
                      content: const Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await context.read<CoreState>().signOut();
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

