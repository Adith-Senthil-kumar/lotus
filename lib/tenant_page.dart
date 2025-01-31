import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TenantPage extends StatefulWidget {
  @override
  _TenantPageState createState() => _TenantPageState();
}

class _TenantPageState extends State<TenantPage> {
  final CollectionReference tenantsCollection =
      FirebaseFirestore.instance.collection('tenants');
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tenant Management'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: TenantSearchDelegate(tenantsCollection),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: tenantsCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final tenants = snapshot.data!.docs;

          if (tenants.isEmpty) {
            return Center(
              child: Text(
                'No tenants found.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          // Filter tenants based on the search query
          final filteredTenants = tenants.where((tenant) {
            final data = tenant.data() as Map<String, dynamic>;
            final name = data['name']?.toString().toLowerCase() ?? '';
            return name.contains(_searchQuery.toLowerCase());
          }).toList();

          return ListView.builder(
            itemCount: filteredTenants.length,
            itemBuilder: (context, index) {
              final tenant = filteredTenants[index];
              final data = tenant.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 4,
                child: ListTile(
                  title: Text(data['name'] ?? 'Unknown Name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Age: ${data['age'] ?? 'N/A'}'),
                      Text('Mobile: ${data['mobileNumber'] ?? 'N/A'}'),
                      Text('Email: ${data['email'] ?? 'N/A'}'),
                      Text(
                          'Emergency Contact: ${data['emergencyContact'] ?? 'N/A'}'),
                      Text('Gov ID: ${data['govId'] ?? 'N/A'}'),
                      Text(
                          'Proof of Address: ${data['proofOfAddress'] ?? 'N/A'}'),
                      Text('Monthly Rent: ₹${data['monthlyRent'] ?? '0'}'),
                      Text('Occupation: ${data['occupation'] ?? 'N/A'}'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _showEditTenantDialog(context, tenant.id, data);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                        _showDeleteConfirmationDialog(context, tenant.id);
                      },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTenantDialog(context);
        },
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  void _showAddTenantDialog(BuildContext context) {
    final _nameController = TextEditingController();
    final _ageController = TextEditingController();
    final _mobileNumberController = TextEditingController();
    final _emailController = TextEditingController();
    final _emergencyContactController = TextEditingController();
    final _govIdController = TextEditingController();
    final _proofOfAddressController = TextEditingController();
    final _monthlyRentController = TextEditingController();
    final _occupationController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Tenant'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _ageController,
                  decoration: InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _mobileNumberController,
                  decoration: InputDecoration(labelText: 'Mobile Number'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: _emergencyContactController,
                  decoration:
                      InputDecoration(labelText: 'Emergency Contact Number'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _govIdController,
                  decoration:
                      InputDecoration(labelText: 'Government ID (Aadhar ID)'),
                ),
                TextField(
                  controller: _proofOfAddressController,
                  decoration: InputDecoration(labelText: 'Proof of Address'),
                ),
                TextField(
                  controller: _monthlyRentController,
                  decoration: InputDecoration(labelText: 'Monthly Rent'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _occupationController,
                  decoration: InputDecoration(labelText: 'Occupation'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final age = _ageController.text.trim();
                final mobileNumber = _mobileNumberController.text.trim();
                final email = _emailController.text.trim();
                final emergencyContact =
                    _emergencyContactController.text.trim();
                final govId = _govIdController.text.trim();
                final proofOfAddress = _proofOfAddressController.text.trim();
                final monthlyRent = _monthlyRentController.text.trim();
                final occupation = _occupationController.text.trim();

                if (name.isNotEmpty &&
                    age.isNotEmpty &&
                    mobileNumber.isNotEmpty &&
                    email.isNotEmpty &&
                    emergencyContact.isNotEmpty &&
                    govId.isNotEmpty &&
                    proofOfAddress.isNotEmpty &&
                    monthlyRent.isNotEmpty &&
                    occupation.isNotEmpty) {
                  await tenantsCollection.add({
                    'name': name,
                    'age': int.tryParse(age) ?? 0,
                    'mobileNumber': mobileNumber,
                    'email': email,
                    'emergencyContact': emergencyContact,
                    'govId': govId,
                    'proofOfAddress': proofOfAddress,
                    'monthlyRent': int.tryParse(monthlyRent) ?? 0,
                    'occupation': occupation,
                    'status': false,
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tenant added successfully!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('All fields are required!')),
                  );
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
  Future<void> _showDeleteConfirmationDialog(BuildContext context, String tenantId) async {
  bool confirmDelete = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete this tenant?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // User presses cancel
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true); // User presses delete
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  ) ?? false;

  if (confirmDelete) {
    // Proceed with the delete action
    await tenantsCollection.doc(tenantId).delete();
  }
}

  void _showEditTenantDialog(
      BuildContext context, String tenantId, Map<String, dynamic> tenantData) {
    final _nameController = TextEditingController(text: tenantData['name']);
    final _ageController =
        TextEditingController(text: tenantData['age']?.toString());
    final _mobileNumberController =
        TextEditingController(text: tenantData['mobileNumber']);
    final _emailController = TextEditingController(text: tenantData['email']);
    final _emergencyContactController =
        TextEditingController(text: tenantData['emergencyContact']);
    final _govIdController = TextEditingController(text: tenantData['govId']);
    final _proofOfAddressController =
        TextEditingController(text: tenantData['proofOfAddress']);
    final _monthlyRentController =
        TextEditingController(text: tenantData['monthlyRent']?.toString());
    final _occupationController =
        TextEditingController(text: tenantData['occupation']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Tenant'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _ageController,
                  decoration: InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _mobileNumberController,
                  decoration: InputDecoration(labelText: 'Mobile Number'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: _emergencyContactController,
                  decoration:
                      InputDecoration(labelText: 'Emergency Contact Number'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _govIdController,
                  decoration:
                      InputDecoration(labelText: 'Government ID (Aadhar ID)'),
                ),
                TextField(
                  controller: _proofOfAddressController,
                  decoration: InputDecoration(labelText: 'Proof of Address'),
                ),
                TextField(
                  controller: _monthlyRentController,
                  decoration: InputDecoration(labelText: 'Monthly Rent'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _occupationController,
                  decoration: InputDecoration(labelText: 'Occupation'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedData = {
                  'name': _nameController.text.trim(),
                  'age': int.tryParse(_ageController.text.trim()) ?? 0,
                  'mobileNumber': _mobileNumberController.text.trim(),
                  'email': _emailController.text.trim(),
                  'emergencyContact': _emergencyContactController.text.trim(),
                  'govId': _govIdController.text.trim(),
                  'proofOfAddress': _proofOfAddressController.text.trim(),
                  'monthlyRent':
                      int.tryParse(_monthlyRentController.text.trim()) ?? 0,
                  'occupation': _occupationController.text.trim(),
                };

                await tenantsCollection.doc(tenantId).update(updatedData);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tenant updated successfully!')),
                );
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class TenantSearchDelegate extends SearchDelegate<String> {
  final CollectionReference tenantsCollection;

  TenantSearchDelegate(this.tenantsCollection);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, ''); // Use an empty string instead of null
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: tenantsCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        final tenants = snapshot.data!.docs;

        if (tenants.isEmpty) {
          return Center(
            child: Text(
              'No tenants found.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        final filteredTenants = tenants.where((tenant) {
          final data = tenant.data() as Map<String, dynamic>;
          final name = data['name']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase());
        }).toList();

        return ListView.builder(
          itemCount: filteredTenants.length,
          itemBuilder: (context, index) {
            final tenant = filteredTenants[index];
            final data = tenant.data() as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 4,
              child: ListTile(
                title: Text(data['name'] ?? 'Unknown Name'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Age: ${data['age'] ?? 'N/A'}'),
                    Text('Mobile: ${data['mobileNumber'] ?? 'N/A'}'),
                    Text('Email: ${data['email'] ?? 'N/A'}'),
                    Text(
                        'Emergency Contact: ${data['emergencyContact'] ?? 'N/A'}'),
                    Text('Gov ID: ${data['govId'] ?? 'N/A'}'),
                    Text(
                        'Proof of Address: ${data['proofOfAddress'] ?? 'N/A'}'),
                    Text('Monthly Rent: ₹${data['monthlyRent'] ?? '0'}'),
                    Text('Occupation: ${data['occupation'] ?? 'N/A'}'),
                  ],
                ),
                isThreeLine: true,
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showEditTenantDialog(context, tenant.id, data);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        _showDeleteConfirmationDialog(context, tenant.id);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, String tenantId) async {
  bool confirmDelete = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete this tenant?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // User presses cancel
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true); // User presses delete
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  ) ?? false;

  if (confirmDelete) {
    // Proceed with the delete action
    await tenantsCollection.doc(tenantId).delete();
  }
}

  

  void _showEditTenantDialog(
      BuildContext context, String tenantId, Map<String, dynamic> tenantData) {
    final _nameController = TextEditingController(text: tenantData['name']);
    final _ageController =
        TextEditingController(text: tenantData['age']?.toString());
    final _mobileNumberController =
        TextEditingController(text: tenantData['mobileNumber']);
    final _emailController = TextEditingController(text: tenantData['email']);
    final _emergencyContactController =
        TextEditingController(text: tenantData['emergencyContact']);
    final _govIdController = TextEditingController(text: tenantData['govId']);
    final _proofOfAddressController =
        TextEditingController(text: tenantData['proofOfAddress']);
    final _monthlyRentController =
        TextEditingController(text: tenantData['monthlyRent']?.toString());
    final _occupationController =
        TextEditingController(text: tenantData['occupation']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Tenant'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _ageController,
                  decoration: InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _mobileNumberController,
                  decoration: InputDecoration(labelText: 'Mobile Number'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: _emergencyContactController,
                  decoration:
                      InputDecoration(labelText: 'Emergency Contact Number'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _govIdController,
                  decoration:
                      InputDecoration(labelText: 'Government ID (Aadhar ID)'),
                ),
                TextField(
                  controller: _proofOfAddressController,
                  decoration: InputDecoration(labelText: 'Proof of Address'),
                ),
                TextField(
                  controller: _monthlyRentController,
                  decoration: InputDecoration(labelText: 'Monthly Rent'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _occupationController,
                  decoration: InputDecoration(labelText: 'Occupation'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedData = {
                  'name': _nameController.text.trim(),
                  'age': int.tryParse(_ageController.text.trim()) ?? 0,
                  'mobileNumber': _mobileNumberController.text.trim(),
                  'email': _emailController.text.trim(),
                  'emergencyContact': _emergencyContactController.text.trim(),
                  'govId': _govIdController.text.trim(),
                  'proofOfAddress': _proofOfAddressController.text.trim(),
                  'monthlyRent':
                      int.tryParse(_monthlyRentController.text.trim()) ?? 0,
                  'occupation': _occupationController.text.trim(),
                };

                await tenantsCollection.doc(tenantId).update(updatedData);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tenant updated successfully!')),
                );
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
