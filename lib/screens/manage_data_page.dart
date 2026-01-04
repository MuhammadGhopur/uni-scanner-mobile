import 'package:flutter/material.dart';
import '../services/sqlite_service.dart';

class ManageDataPage extends StatefulWidget {
  const ManageDataPage({super.key});

  @override
  State<ManageDataPage> createState() => _ManageDataPageState();
}

class _ManageDataPageState extends State<ManageDataPage> {
  List<Map<String, dynamic>> _poData = [];
  bool _isLoading = true;
  late SQLiteService _sqliteService;

  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  final int _itemsPerPage = 10; // Anda bisa sesuaikan ini
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _sqliteService = SQLiteService();
    _loadPoData();
    _searchController.addListener(() {
      _currentPage = 0; // Reset ke halaman pertama saat pencarian berubah
      _loadPoData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPoData() async {
    setState(() {
      _isLoading = true;
    });
    final data = await _sqliteService.getFilteredProducts(
      searchQuery: _searchController.text,
      limit: _itemsPerPage,
      offset: _currentPage * _itemsPerPage,
    );
    final totalCount = await _sqliteService.getPoCount(); // Get total count for pagination
    setState(() {
      _poData = data;
      _totalCount = totalCount;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Menetapkan latar belakang Scaffold menjadi putih
      appBar: AppBar(
        title: const Text('Manage Data'),
        backgroundColor: const Color(0xFF3A3A3A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addEditProductDialog(context),
            tooltip: 'Create Data',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
             padding: const EdgeInsets.symmetric(horizontal: 11.0, vertical: 8.0),
             child: TextField(
               controller: _searchController,
               decoration: InputDecoration(
                 hintText: 'Search PO number...',
                 hintStyle: TextStyle(color: Colors.grey.shade600),
                 prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                 suffixIcon: IconButton(
                   icon: Icon(Icons.clear, color: Colors.grey.shade600),
                   onPressed: () {
                     _searchController.clear();
                     _currentPage = 0;
                     _loadPoData();
                   },
                 ),
                 border: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(30.0), // Sudut membulat
                   borderSide: BorderSide(color: Colors.grey.shade300), // Border elegan
                 ),
                 enabledBorder: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(30.0),
                   borderSide: BorderSide(color: Colors.grey.shade300),
                 ),
                 focusedBorder: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(30.0),
                   borderSide: BorderSide(color: Color(0xFF3A3A3A)), // Border fokus
                 ),
                 filled: true,
                 fillColor: Colors.white, // Latar belakang putih/terang
                 contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
               ),
               style: const TextStyle(color: Color(0xFF1F1F1F)),
             ),
           ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _poData.isEmpty
                   ? const Expanded(child: Center(child: Text('No data available')))
                  : Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _poData.length,
                        itemBuilder: (context, index) {
                          final po = _poData[index];
                          return Card(
                            elevation: 2.0,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            color: Colors.grey.shade50, // Latar belakang abu-abu elegan
                            child: ListTile(
                              title: Text(po['po_number']),
                              subtitle: Text(
                                  'SKU: ${po['sku']}, Cust ID: ${po['cust_id']}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blueAccent),
                                    onPressed: () =>
                                        _addEditProductDialog(context, po: po),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.redAccent),
                                    onPressed: () =>
                                        _deleteConfirmationDialog(context, po['id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _currentPage > 0
                      ? () {
                          setState(() {
                            _currentPage--;
                          });
                          _loadPoData();
                        }
                      : null,
                  child: const Text('Previous'),
                ),
                Text(
                    'Page ${_currentPage + 1} of ${(_totalCount / _itemsPerPage).ceil()}'),
                TextButton(
                  onPressed: (_currentPage + 1) * _itemsPerPage < _totalCount
                      ? () {
                          setState(() {
                            _currentPage++;
                          });
                          _loadPoData();
                        }
                      : null,
                   child: const Text('Next'),
                 ),
               ],
             ),
           ),
         ],
       ),
     );
   }

  Future<void> _addEditProductDialog(BuildContext context, {Map<String, dynamic>? po}) async {
    final isEditing = po != null;
    final poNumberController = TextEditingController(text: isEditing ? po['po_number'] : '');
    final custIdController = TextEditingController(text: isEditing ? po['cust_id'] : '');
    final skuController = TextEditingController(text: isEditing ? po['sku'] : '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Update Data' : 'Create Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: poNumberController,
              decoration: const InputDecoration(labelText: 'PO Number'),
            ),
            TextField(
              controller: custIdController,
              decoration: const InputDecoration(labelText: 'Cust ID'),
            ),
            TextField(
              controller: skuController,
              decoration: const InputDecoration(labelText: 'SKU'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (poNumberController.text.isNotEmpty &&
                  custIdController.text.isNotEmpty &&
                  skuController.text.isNotEmpty) {
                if (isEditing) {
                  await _sqliteService.updateProduct(
                    id: po['id'],
                    poNumber: poNumberController.text,
                    custId: custIdController.text,
                    sku: skuController.text,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data updated successfully!')),
                  );
                } else {
                  await _sqliteService.insertProduct(
                    poNumber: poNumberController.text,
                    custId: custIdController.text,
                    sku: skuController.text,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data added successfully!')),
                  );
                }
                Navigator.pop(context);
                _loadPoData(); // Refresh the list
              }
            },
            child: Text(isEditing ? 'Save' : 'Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteConfirmationDialog(BuildContext context, int id) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Data'),
        content: const Text('Are you sure you want to delete this PO data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _sqliteService.deleteProduct(id);
              Navigator.pop(context);
              _loadPoData(); // Refresh the list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data deleted successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), // Highlight delete action
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
