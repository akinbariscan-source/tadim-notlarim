import 'package:flutter/material.dart';

import '../models/tasting.dart';
import '../services/repository.dart';
import 'flow/tasting_flow_page.dart';
import 'saved_list_page.dart';
import 'similarity_prompt.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  int _flowGeneration = 0;

  Future<void> _onSaved(Tasting saved) async {
    setState(() {
      _flowGeneration++; // yeni, boş bir form
      _index = 1; // Kayıtlı Şaraplar
    });
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    await runSimilarityPrompt(context, saved);
  }

  @override
  Widget build(BuildContext context) {
    final repo = TastingRepository.instance;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          TastingFlowPage(key: ValueKey(_flowGeneration), onSaved: _onSaved),
          const SavedListPage(),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          final count = repo.all.length;
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.add_a_photo_outlined),
                selectedIcon: Icon(Icons.add_a_photo),
                label: 'Yeni Tadım',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.wine_bar_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.wine_bar),
                ),
                label: 'Kayıtlı Şaraplar',
              ),
            ],
          );
        },
      ),
    );
  }
}
