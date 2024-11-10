import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class PrivacyStatementPage extends StatefulWidget {
  final VoidCallback toggleTheme;

  const PrivacyStatementPage({super.key, required this.toggleTheme});

  @override
  State<PrivacyStatementPage> createState() => _PrivacyStatementPageState();
}

class _PrivacyStatementPageState extends State<PrivacyStatementPage> {
  String _privacyPolicy = "加载中";

  @override
  void initState() {
    _loadPrivacyPolicy();
    super.initState();
  }

  Future<void> _loadPrivacyPolicy() async {
    final privacyPolicy = await rootBundle.loadString('assets/template.txt');
    setState(() {
      _privacyPolicy = privacyPolicy;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私政策'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrivacyPolicy,
          ),
        ],
        leading: IconButton(
          icon: Icon(
            Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode
                : Icons.dark_mode,
          ),
          onPressed: widget.toggleTheme,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ham Toolkit 隐私政策', style: Theme.of(context).textTheme.headlineLarge),
              Text('2024-11-10', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 16),
              Text(_privacyPolicy)
            ],
          ),
        ),
      ),
    );
  }
}