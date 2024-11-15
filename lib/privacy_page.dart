import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyStatementPage extends StatefulWidget {
  final VoidCallback toggleTheme;

  const PrivacyStatementPage({super.key, required this.toggleTheme});

  @override
  State<PrivacyStatementPage> createState() => _PrivacyStatementPageState();
}

class _PrivacyStatementPageState extends State<PrivacyStatementPage> {
  String _privacyPolicy = "加载中";
  String _selectedApplication = 'Ham Toolkit';
  String _selectedPrivacyTitle = '隐私政策';
  String _selectedPrivacyDate = '2024-11-10';
  DocumentList? _applicationDocuments;
  DocumentList? _docDocuments;
  List<String> _applicationNames = [];
  List<String> _docTitles = [];
  bool _loading = true;
  bool _showDropdown = true;

  Client client = Client();
  late Account account;

  @override
  void initState() {
    _initAppwrite();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initAppwrite() async {
    client
        .setEndpoint(
            'https://d-app.last-remote.xyz:7356/v1') // Your API Endpoint
        .setProject('6737101500291d684581');
    account = Account(client);

    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionId');

    if (sessionId != null) {
      try {
        await account.getSession(sessionId: sessionId);
      } catch (e) {
        // If session is invalid, create a new one
        final session = await account.createAnonymousSession();
        await prefs.setString('sessionId', session.$id);
      }
    } else {
      final session = await account.createAnonymousSession();
      await prefs.setString('sessionId', session.$id);
    }

    _loadApplications();
  }
  Future<void> _loadApplications() async {
    final database = Databases(client);
    print('Loading applications');
    final apps = await database.listDocuments(
        databaseId: "privacydb", collectionId: "applications");
    print('Loaded applications: ${apps.documents.length}');
    setState(() {
      _applicationDocuments = apps;
      _selectedApplication = apps.documents.first.data['application_name'];
      _applicationNames = apps.documents
          .map((doc) => doc.data['application_name'].toString())
          .toList();
      print("Application names: $_applicationNames");
      _loading = false;
    });
  }

Future<void> _loadPrivacyDocuments() async {
  final database = Databases(client);
  print('Loading documents for application: $_selectedApplication');
  final selectedAppDoc = _applicationDocuments?.documents.firstWhere(
      (doc) => doc.data['application_name'] == _selectedApplication);
  print('Selected application: ${selectedAppDoc?.data}');
  final selectedAppId = selectedAppDoc?.$id;

  if (selectedAppId != null) {
    print('Loading documents for application ID: $selectedAppId');
    final docs = await database.listDocuments(
        databaseId: "privacydb", collectionId: "privacy_documents", queries: [
      Query.equal("application", selectedAppId)
    ]);
    print('Loaded documents: ${docs.documents.length}');
    setState(() {
      _docDocuments = docs;
      _selectedPrivacyTitle = docs.documents.first.data['title'];
      _docTitles = docs.documents
          .map((doc) => doc.data['title'].toString())
          .toList();
      _loading = false;
    });
    _loadPrivacyPolicy(docs.documents.first);
  } else {
    print('No application selected or application ID not found');
  }
}

Future<void> _loadPrivacyPolicy(Document document) async {
  setState(() {
    _privacyPolicy = document.data['content'];
    _selectedPrivacyTitle = document.data['title'];
    _selectedPrivacyDate = document.$updatedAt;
  });
}

void onApplicationChanged(String? value) {
  setState(() {
    _selectedApplication = value!;
    _loading = true;
  });
  _loadPrivacyDocuments();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('协议与隐私政策'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadPrivacyPolicy(_docDocuments!.documents.first),
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
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _loading
                  ? const CircularProgressIndicator()
                  : AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showDropdown ? buildDropdownButtons() : Container(),
              ),
              const SizedBox(height: 16),
              Text(_selectedPrivacyTitle,
                  style: Theme.of(context).textTheme.headlineLarge),
              Text(_selectedPrivacyDate,
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 16),
              Text(_privacyPolicy)
            ],
          ),
        ),
      ),
      floatingActionButton: _showDropdown
          ? null
          : FloatingActionButton(
        onPressed: () {
          setState(() {
            _showDropdown = true;
          });
        },
        child: const Icon(Icons.arrow_upward),
      ),
    );
  }

  Widget buildDropdownButtons() {
    return Card.outlined(
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Text("选择应用与协议:"),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _selectedApplication,
            items: _applicationNames
                .map((String value) => DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            ))
                .toList(),
            onChanged: onApplicationChanged,
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _selectedPrivacyTitle,
            items: _docTitles
                .map((String value) => DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            ))
                .toList(),
            onChanged: (a) {},
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              setState(() {
                _showDropdown = false;
              });
            },
            icon: const Icon(Icons.arrow_downward),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}