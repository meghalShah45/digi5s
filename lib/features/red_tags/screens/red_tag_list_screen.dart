// import 'package:flutter/material.dart';
// import '../models/red_tag.dart';
// import '../services/red_tag_service.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:intl/intl.dart';
//
// class RedTagListScreen extends StatefulWidget {
//   final String orgId;
//
//   const RedTagListScreen({Key? key, required this.orgId}) : super(key: key);
//
//   @override
//   State<RedTagListScreen> createState() => _RedTagListScreenState();
// }
//
// class _RedTagListScreenState extends State<RedTagListScreen> {
//   final RedTagService _redTagService = RedTagService();
//   final _storage = const FlutterSecureStorage();
//   List<RedTag> _redTags = [];
//   bool _isLoading = true;
//   String? _error;
//   String? _userId;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUserId();
//   }
//
//   Future<void> _loadUserId() async {
//     try {
//       final userId = await _storage.read(key: 'userId');
//       setState(() {
//         _userId = userId;
//       });
//       _loadRedTags();
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _loadRedTags() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _error = null;
//       });
//
//       final redTags = await _redTagService.getRedTags(widget.orgId);
//       setState(() {
//         _redTags = redTags;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _deleteRedTag(RedTag redTag) async {
//     try {
//       await _redTagService.deleteRedTag(redTag.id);
//       await _loadRedTags();
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Red tag deleted successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error deleting red tag: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   Future<void> _showEditDialog(RedTag redTag) async {
//     final descriptionController = TextEditingController(text: redTag.description);
//     final remarksController = TextEditingController(text: redTag.remarks ?? '');
//     String selectedStatus = redTag.status;
//
//     await showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Edit Red Tag'),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: descriptionController,
//                 decoration: const InputDecoration(labelText: 'Description'),
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: remarksController,
//                 decoration: const InputDecoration(labelText: 'Remarks'),
//               ),
//               const SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 value: selectedStatus,
//                 decoration: const InputDecoration(labelText: 'Status'),
//                 items: ['PENDING', 'APPROVED', 'REJECTED'].map((status) {
//                   return DropdownMenuItem(
//                     value: status,
//                     child: Text(status),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   if (value != null) {
//                     selectedStatus = value;
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () async {
//               try {
//                 await _redTagService.updateRedTag(
//                   redTag.id,
//                   description: descriptionController.text,
//                   photo: redTag.path,
//                   date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
//                   status: selectedStatus,
//                   remarks: remarksController.text,
//                   modifiedBy: _userId ?? '',
//                 );
//                 if (mounted) {
//                   Navigator.pop(context);
//                   await _loadRedTags();
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Red tag updated successfully'),
//                       backgroundColor: Colors.green,
//                     ),
//                   );
//                 }
//               } catch (e) {
//                 if (mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('Error updating red tag: $e'),
//                       backgroundColor: Colors.red,
//                     ),
//                   );
//                 }
//               }
//             },
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _showDeleteConfirmation(RedTag redTag) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Red Tag'),
//         content: const Text('Are you sure you want to delete this red tag?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//
//     if (confirmed == true) {
//       await _deleteRedTag(redTag);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     if (_error != null) {
//       return Scaffold(
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text('Error: $_error'),
//               ElevatedButton(
//                 onPressed: _loadRedTags,
//                 child: const Text('Retry'),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Red Tags'),
//       ),
//       body: RefreshIndicator(
//         onRefresh: _loadRedTags,
//         child: ListView.builder(
//           itemCount: _redTags.length,
//           itemBuilder: (context, index) {
//             final redTag = _redTags[index];
//             return Card(
//               margin: const EdgeInsets.all(8.0),
//               child: ListTile(
//                 title: Text('Zone: ${redTag.zoneName}'),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Status: ${redTag.status}'),
//                     Text('Description: ${redTag.description}'),
//                     if (redTag.remarks != null)
//                       Text('Remarks: ${redTag.remarks}'),
//                     Text('Created by: ${redTag.email}'),
//                     Text('Created at: ${DateFormat('dd/MM/yyyy').format(redTag.createdAt)}'),
//                   ],
//                 ),
//                 trailing: PopupMenuButton<String>(
//                   onSelected: (value) {
//                     switch (value) {
//                       case 'edit':
//                         _showEditDialog(redTag);
//                         break;
//                       case 'delete':
//                         _showDeleteConfirmation(redTag);
//                         break;
//                     }
//                   },
//                   itemBuilder: (context) => [
//                     const PopupMenuItem(
//                       value: 'edit',
//                       child: Row(
//                         children: [
//                           Icon(Icons.edit),
//                           SizedBox(width: 8),
//                           Text('Edit'),
//                         ],
//                       ),
//                     ),
//                     const PopupMenuItem(
//                       value: 'delete',
//                       child: Row(
//                         children: [
//                           Icon(Icons.delete, color: Colors.red),
//                           SizedBox(width: 8),
//                           Text('Delete', style: TextStyle(color: Colors.red)),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }