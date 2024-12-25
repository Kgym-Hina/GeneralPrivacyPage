import 'dart:collection';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:privacy/appwrite_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoveAccountPage extends StatefulWidget {
  const RemoveAccountPage({super.key});

  @override
  State<RemoveAccountPage> createState() => _RemoveAccountPageState();
}

class _RemoveAccountPageState extends State<RemoveAccountPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedApplication = '';
  String _username = '';
  String _password = '';
  late List<Document> _applicationNames;
  bool isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }


  Future<void> _fetchApplications() async {
    Client client = Client();
    Databases databases = Databases(client);

    client
        .setEndpoint(appwriteEndpoint)
        .setProject(appwriteProjectId);

    try {
      final response = await databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteApplicationsCollectionId,
      );

      print(response.toMap());

      setState(() {
        _selectedApplication = response.documents.first.$id;
        _applicationNames = response.documents;

        print('Default application: ${response.documents.first.$id}');

        if (_applicationNames.isNotEmpty) {
          _selectedApplication = _applicationNames.first.data['application_name'];
        }
      });

    } catch (e) {
      print('Error fetching applications: $e');
    }
    finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remove Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isLoading ? const CircularProgressIndicator() : DropdownButtonFormField<String>(
                value: _selectedApplication.isNotEmpty ? _selectedApplication : null,
                items: _applicationNames.map((Document document) {
                  return DropdownMenuItem<String>(
                    value: document.data['application_name'],
                    child: Text(document.data['application_name']),
                  );
                }).toList(),
                onChanged: _isProcessing ? null : (newValue) {
                  setState(() {
                    _selectedApplication = newValue!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Select Application',
                ),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email or Username'),
                onChanged: (value) {
                  setState(() {
                    _username = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
                enabled: !_isProcessing,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (value) {
                  setState(() {
                    _password = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                enabled: !_isProcessing,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isProcessing ? null : () {
                  if (_formKey.currentState!.validate()) {
                    if (_selectedApplication.isNotEmpty && _username.isNotEmpty && _password.isNotEmpty) {
                      _removeAccount();
                    }
                    else{
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Error'),
                            content: const Text('Please fill in all fields.'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  }
                },
                child: _isProcessing ? const CircularProgressIndicator() : const Text('Remove Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeAccount() async {
    setState(() {
      _isProcessing = true;
    });

    print('Removing account for $_selectedApplication with username $_username');

    Client client = Client();
    Databases databases = Databases(client);

    client
        .setEndpoint(appwriteEndpoint)
        .setProject(appwriteProjectId);

    final application = _applicationNames.firstWhere((element) => element.data['application_name'] == _selectedApplication);

    try {
      final response = await databases.createDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteAccountRemoveCollectionId,
        documentId: ID.unique(),
        data: {
          'Application': application.$id,
          'Email': _username,
          'Password': _password,
        },
      );

      print('Account removal request created: ${response.data}');

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Account Removal Request'),
            content: const Text('Your account removal request has been submitted. You will receive an email with further instructions if applicable.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

    } catch (e) {
      print('Error creating account removal request: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}