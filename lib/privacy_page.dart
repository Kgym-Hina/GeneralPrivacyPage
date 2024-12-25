import 'dart:collection';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

// Appwrite constants
const String appwriteEndpoint = 'https://api.clarium-noctis.moe/v1';
const String appwriteProjectId = '6737101500291d684581';
const String appwriteDatabaseId = 'privacydb';
const String appwriteApplicationsCollectionId = 'applications';
const String appwritePrivacyDocumentsCollectionId = 'privacy_documents';
const String appwriteInformationCollectionId = 'information';

class PrivacyStatementPage extends StatefulWidget {
  final VoidCallback toggleTheme;

  const PrivacyStatementPage({super.key, required this.toggleTheme});

  @override
  State<PrivacyStatementPage> createState() => _PrivacyStatementPageState();
}

class _PrivacyStatementPageState extends State<PrivacyStatementPage> {
  String _privacyPolicy = "加载中";
  String _selectedApplication = 'Ham Toolkit';
  String _selectedPrivacyTitle = '加载中';
  String _selectedPrivacyDate = '2024-11-10';
  DocumentList? _applicationDocuments;
  DocumentList? _docDocuments;
  List<String> _applicationNames = [];
  List<String> _docTitles = [];
  HashMap<String, String> _informationTexts = HashMap();
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
        .setEndpoint(appwriteEndpoint) // Your API Endpoint
        .setProject(appwriteProjectId);
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
    _loadInformation();
  }

  Future<void> _loadInformation() async {
    final database = Databases(client);
    print('Loading information');
    final infoDocs = await database.listDocuments(
        databaseId: appwriteDatabaseId, collectionId: appwriteInformationCollectionId);
    print('Loaded information: ${infoDocs.documents.length}');
    setState(() {
      _informationTexts = infoDocs.documents.fold(HashMap(), (map, doc) {
        map[doc.data['Text']] = doc.data['Link'];
        return map;
      });
    });
  }

  Future<void> _loadApplications() async {
    final database = Databases(client);
    print('Loading applications');
    final apps = await database.listDocuments(
        databaseId: appwriteDatabaseId, collectionId: appwriteApplicationsCollectionId);
    print('Loaded applications: ${apps.documents.length}');
    setState(() {
      _applicationDocuments = apps;
      if (apps.documents.isNotEmpty) {
        _selectedApplication = apps.documents.first.data['application_name'];
        _applicationNames = apps.documents
            .map((doc) => doc.data['application_name'].toString())
            .toList();
        print("Application names: $_applicationNames");
        _loading = false;
        _loadPrivacyDocuments(); // Automatically load privacy documents for the first application
      }
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
          databaseId: appwriteDatabaseId, collectionId: appwritePrivacyDocumentsCollectionId, queries: [
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

  void onPrivacyDocumentChanged(String? value) {
    setState(() {
      _selectedPrivacyTitle = value!;
    });
    final selectedDoc = _docDocuments?.documents.firstWhere(
        (doc) => doc.data['title'] == _selectedPrivacyTitle);
    if (selectedDoc != null) {
      _loadPrivacyPolicy(selectedDoc);
    }
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
              MarkdownBody(data: _privacyPolicy),
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Clarium Noctis © ${DateTime.now().year}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            // 显示所有Information文档
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _informationTexts.keys.map((text) {
                return ElevatedButton(
                  onPressed: () {
                    final url = _informationTexts[text];
                    if (url != null) {
                      launchUrlString(url);
                    }
                  },
                  child: Text(text),
                );
              }).toList(),
            ),
          ],
        ),
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
            onChanged: onPrivacyDocumentChanged,
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