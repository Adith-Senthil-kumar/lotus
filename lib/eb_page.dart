import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:csv/csv.dart'; // For CSV export
import 'package:path_provider/path_provider.dart'; // For file storage
import 'dart:io'; // For file operations
import 'package:share_plus/share_plus.dart'; // For sharing files

class EbPage extends StatefulWidget {
  @override
  _EbPageState createState() => _EbPageState();
}

class _EbPageState extends State<EbPage> {
  String? expandedRoomId; // Stores the currently expanded room ID
  String searchQuery = ""; // Stores the search query
  TextEditingController searchController =
      TextEditingController(); // Controller for search

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          onChanged: (value) {
            setState(() {
              searchQuery = value.trim(); // Update search query
            });
          },
          decoration: InputDecoration(
            hintText: 'Search Room Number...',
            border: InputBorder.none,
          ),
          style: theme.textTheme.bodyMedium,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  searchQuery = "";
                  searchController.clear();
                });
              },
            ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () {
              downloadebCollection();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('eb').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No EB data found.',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          final ebData = snapshot.data!.docs.where((doc) {
            final roomNumber = doc['roomNumber'].toString();
            return searchQuery.isEmpty || roomNumber.contains(searchQuery);
          }).toList();

          if (ebData.isEmpty) {
            return Center(
              child: Text(
                'No matching results.',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          return ListView.builder(
            itemCount: ebData.length,
            itemBuilder: (context, index) {
              final doc = ebData[index];
              final eb = doc.data() as Map<String, dynamic>;
              final roomId = doc.id;
              final List<dynamic> readings = eb['readings'] ?? [];
              final bool isExpanded = expandedRoomId == roomId;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        'Room Number: ${eb['roomNumber'] ?? 'N/A'}',
                        style: theme.textTheme.titleLarge,
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            expandedRoomId = isExpanded ? null : roomId;
                          });
                        },
                      ),
                    ),
                    if (isExpanded) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: readings.isEmpty
                              ? [
                                  Text('No readings available',
                                      style: theme.textTheme.bodyMedium)
                                ]
                              : readings.asMap().entries.map((entry) {
                                  int readingIndex = entry.key;
                                  var reading = entry.value;

                                  return ListTile(
                                    title: Text(
                                      'Reading: ${reading['value']}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    subtitle: Text(
                                      'Date: ${_formatDate(reading['date'])}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    trailing: IconButton(
                                      icon:
                                          Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        _confirmDeleteReading(
                                            roomId, readingIndex, readings);
                                      },
                                    ),
                                  );
                                }).toList(),
                        ),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showAddReadingDialog(roomId, readings);
                        },
                        icon: Icon(Icons.add),
                        label: Text('Add Reading'),
                      ),
                      SizedBox(height: 8),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddReadingDialog(String docId, List<dynamic> existingReadings) {
    TextEditingController readingController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Reading'),
          content: TextField(
            controller: readingController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Enter new reading'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String newReading = readingController.text.trim();
                if (newReading.isNotEmpty) {
                  List<dynamic> updatedReadings = List.from(existingReadings);
                  updatedReadings.add({
                    'value': newReading,
                    'date': DateTime.now().toIso8601String(),
                  });

                  await FirebaseFirestore.instance
                      .collection('eb')
                      .doc(docId)
                      .update({
                    'readings': updatedReadings,
                  });

                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteReading(String docId, int index, List<dynamic> readings) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Reading'),
          content: Text('Are you sure you want to delete this reading?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteReading(docId, index, readings);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteReading(String docId, int index, List<dynamic> readings) async {
    List<dynamic> updatedReadings = List.from(readings);
    updatedReadings.removeAt(index);

    await FirebaseFirestore.instance.collection('eb').doc(docId).update({
      'readings': updatedReadings,
    });
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'N/A';
    DateTime date = DateTime.parse(isoDate);
    return DateFormat('MMM dd, yyyy').format(date); // Example: Jan 30, 2025
  }

  Future<void> downloadebCollection() async {
    try {
      const String collectionName = 'eb';

      // Fetch documents from Firestore collection
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance.collection(collectionName).get();

      if (querySnapshot.docs.isEmpty) {
        print('No data found in the EB collection.');
        return;
      }

      // Convert documents to CSV format
      List<List<dynamic>> csvData = [];
      List<String> headers = [];

      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        data['id'] = doc.id; // Add document ID

        // Handle arrays by converting them to comma-separated values
        data.forEach((key, value) {
          if (value is List) {
            // Convert array to comma-separated string
            data[key] = value.join(', ');
          } else if (value is Timestamp) {
            data[key] = value.toDate().toIso8601String();
          }
        });

        if (headers.isEmpty) {
          headers = data.keys.toList();
          csvData.add(headers); // Add headers to CSV
        }

        List<dynamic> row = [];
        for (var header in headers) {
          var value = data[header] ?? '';
          row.add(value);
        }
        csvData.add(row);
      }

      // Convert the data to CSV format
      String csvString = const ListToCsvConverter().convert(csvData);

      // Get the downloads directory
      Directory? downloadsDir;
      if (Platform.isWindows) {
        downloadsDir =
            Directory('${Platform.environment['USERPROFILE']}\\Downloads');
      } else {
        downloadsDir = await getExternalStorageDirectory(); // Android path
      }

      if (downloadsDir == null) {
        print('Error: Could not get downloads directory.');
        return;
      }

      final file = File('${downloadsDir.path}/$collectionName.csv');
      await file.writeAsString(csvString);

      print('EB collection downloaded successfully as CSV to ${file.path}');
    } catch (e) {
      print('Error downloading EB collection: $e');
    }
  }
}
