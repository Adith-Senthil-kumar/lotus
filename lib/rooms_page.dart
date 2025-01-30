import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomsPage extends StatefulWidget {
  @override
  _RoomsPageState createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  final CollectionReference roomsCollection =
      FirebaseFirestore.instance.collection('rooms');
  final CollectionReference tenantsCollection =
      FirebaseFirestore.instance.collection('tenants');

  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: TextField(
          decoration: InputDecoration(
            hintText: 'Search by Room Number...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: Theme.of(context).hintColor,
            ),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        searchQuery = "";
                      });
                    },
                  )
                : null,
          ),
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
          onChanged: (value) {
            setState(() {
              searchQuery = value.trim();
            });
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: roomsCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final allRooms = snapshot.data!.docs;
          final filteredRooms = allRooms.where((room) {
            final roomData = room.data() as Map<String, dynamic>;
            return searchQuery.isEmpty ||
                roomData['roomNumber']
                    .toString()
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase());
          }).toList();

          if (filteredRooms.isEmpty) {
            return Center(child: Text('No rooms found.'));
          }

          return ListView.builder(
            itemCount: filteredRooms.length,
            itemBuilder: (context, index) {
              final room = filteredRooms[index];
              final data = room.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 4,
                child: ListTile(
                  title: Text('Room ${data['roomNumber']}'),
                  subtitle: _buildRoomSpots(room.id, data['maxCapacity']),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteRoom(room.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddRoomDialog();
        },
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildRoomSpots(String roomId, int maxCapacity) {
    return StreamBuilder<QuerySnapshot>(
      stream: tenantsCollection.where('roomId', isEqualTo: roomId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text('Loading...');
        }

        final tenants = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(maxCapacity, (index) {
            if (index < tenants.length) {
              final tenant = tenants[index];
              final tenantData = tenant.data() as Map<String, dynamic>;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Spot ${index + 1}: Occupied (${tenantData['name']})'),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () => _unassignTenant(tenant.id),
                  ),
                ],
              );
            } else {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Spot ${index + 1}: Vacant'),
                  IconButton(
                    icon: Icon(Icons.person_add, color: Colors.green),
                    onPressed: () => _assignTenant(roomId),
                  ),
                ],
              );
            }
          }),
        );
      },
    );
  }

  void _assignTenant(String roomId) async {
    QuerySnapshot availableTenants = await tenantsCollection
        .where('status', isEqualTo: false)
        .get();

    if (availableTenants.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No available tenants to assign!')),
      );
      return;
    }

    String? selectedTenantId;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Assign Tenant'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return DropdownButton<String>(
                value: selectedTenantId,
                hint: Text('Select Tenant'),
                onChanged: (String? newValue) {
                  setDialogState(() {
                    selectedTenantId = newValue;
                  });
                },
                items: availableTenants.docs.map((tenant) {
                  final tenantData = tenant.data() as Map<String, dynamic>;
                  return DropdownMenuItem<String>(
                    value: tenant.id,
                    child: Text(tenantData['name']),
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedTenantId != null) {
                  try {
                    await tenantsCollection.doc(selectedTenantId).update({
                      'roomId': roomId,
                      'status': true,
                    });

                    setState(() {});
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tenant assigned successfully!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to assign tenant: $e')),
                    );
                  }
                }
              },
              child: Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  void _unassignTenant(String tenantId) async {
    try {
      await tenantsCollection.doc(tenantId).update({
        'roomId': null,
        'status': false,
      });

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tenant unassigned successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unassign tenant: $e')),
      );
    }
  }

  void _deleteRoom(String roomId) async {
    try {
      await roomsCollection.doc(roomId).delete();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete room: $e')),
      );
    }
  }

  void _showAddRoomDialog() {
    final TextEditingController _roomNumberController = TextEditingController();
    final TextEditingController _maxCapacityController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Room'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _roomNumberController,
                decoration: InputDecoration(labelText: 'Room Number'),
              ),
              TextField(
                controller: _maxCapacityController,
                decoration: InputDecoration(labelText: 'Max Capacity'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final roomNumber = _roomNumberController.text.trim();
                final maxCapacity =
                    int.tryParse(_maxCapacityController.text.trim()) ?? 0;

                if (roomNumber.isNotEmpty && maxCapacity > 0) {
                  try {
                    await roomsCollection.add({
                      'roomNumber': roomNumber,
                      'maxCapacity': maxCapacity,
                    });

                    setState(() {});
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Room added successfully!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add room: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter valid details!')),
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
}