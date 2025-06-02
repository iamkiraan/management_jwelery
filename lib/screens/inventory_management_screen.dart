import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() => _isVisible = true);
    });
  }

  Future<void> _deleteItem(String docId) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this item? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance.collection('items').doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _sellItem(String docId, Map<String, dynamic> data) async {
    final qtyController = TextEditingController(text: '1');
    final toWhomController = TextEditingController();
    final goldRateController = TextEditingController();
    final diamondRateController = TextEditingController();
    final stoneRateController = TextEditingController();
    final makingChargeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sell Item: ${data['itemNo']} ${data['design'] ?? ''}'),
        content: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter Sale Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16.0),
                CustomTextField(
                  controller: qtyController,
                  labelText: 'Quantity to Sell',
                  icon: Icons.sell,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final qty = int.tryParse(value ?? '0');
                    if (qty == null || qty <= 0) return 'Enter a valid quantity';
                    if (qty > (data['quantityAvailable'] ?? 1)) {
                      return 'Cannot sell more than ${data['quantityAvailable']}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                CustomTextField(
                  controller: toWhomController,
                  labelText: 'To Whom',
                  icon: Icons.person,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Enter the buyer\'s name';
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                CustomTextField(
                  controller: goldRateController,
                  labelText: 'Gold Rate (per gm)',
                  icon: Icons.monetization_on,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return null;
                    final rate = double.tryParse(value!);
                    if (rate == null || rate <= 0) return 'Enter a valid rate';
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                CustomTextField(
                  controller: diamondRateController,
                  labelText: 'Diamond Rate (per carat)',
                  icon: Icons.diamond,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return null;
                    final rate = double.tryParse(value!);
                    if (rate == null || rate <= 0) return 'Enter a valid rate';
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                CustomTextField(
                  controller: stoneRateController,
                  labelText: 'Stone Rate (per carat)',
                  icon: Icons.circle,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return null;
                    final rate = double.tryParse(value!);
                    if (rate == null || rate <= 0) return 'Enter a valid rate';
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                CustomTextField(
                  controller: makingChargeController,
                  labelText: 'Making Charge',
                  icon: Icons.build,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return null;
                    final charge = double.tryParse(value!);
                    if (charge == null || charge < 0) return 'Enter a valid charge';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final qty = int.parse(qtyController.text);
                final toWhom = toWhomController.text.trim();
                final goldRate = double.tryParse(goldRateController.text) ?? 0.0;
                final diamondRate = double.tryParse(diamondRateController.text) ?? 0.0;
                final stoneRate = double.tryParse(stoneRateController.text) ?? 0.0;
                final makingCharge = double.tryParse(makingChargeController.text) ?? 0.0;

                final saleGold = (data['fineWeight'] ?? 0.0) * goldRate * qty;
                final saleDiamond = (data['diamond']['weight'] ?? 0.0) * diamondRate * qty;
                final saleStone = (data['stone']['weight'] ?? 0.0) * stoneRate * qty;
                final saleMaking = makingCharge * qty;
                final saleAmount = saleGold + saleDiamond + saleStone + saleMaking;
                final cost = (data['purchasedRate'] ?? 0.0) * qty;
                final profit = saleAmount - cost;

                try {
                  final newQuantity = (data['quantityAvailable'] ?? 0) - qty;
                  await FirebaseFirestore.instance.collection('items').doc(docId).update({
                    'quantityAvailable': newQuantity,
                  });
                  if (newQuantity <= 0) {
                    await FirebaseFirestore.instance.collection('items').doc(docId).delete();
                  }
                  await FirebaseFirestore.instance.collection('transactions').add({
                    'itemNo': data['itemNo'],
                    'design': data['design'] ?? '',
                    'purity': data['purity'] ?? '',
                    'grossWeight': data['grossWeight'] ?? 0.0,
                    'netWeight': data['netWeight'] ?? 0.0,
                    'fineWeight': data['fineWeight'] ?? 0.0,
                    'diamond': data['diamond'],
                    'stone': data['stone'],
                    'making': {'rate': makingCharge, 'subTotal': saleMaking},
                    'certAmount': data['certAmount'] ?? 0.0,
                    'saleAmount': saleAmount,
                    'cost': cost,
                    'profit': profit,
                    'quantitySold': qty,
                    'saleRates': {
                      'goldRate': goldRate,
                      'diamondRate': diamondRate,
                      'stoneRate': stoneRate,
                      'makingCharge': makingCharge,
                    },
                    'toWhom': toWhom,
                    'type': 'sale',
                    'date': FieldValue.serverTimestamp(),
                    'userId': FirebaseAuth.instance.currentUser?.uid,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sale recorded successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Sell'),
          ),
        ],
      ),
    );
  }

  Future<void> _editItem(String docId, Map<String, dynamic> data) async {
    final itemNoController = TextEditingController(text: data['itemNo']);
    final designController = TextEditingController(text: data['design']);
    final purityController = TextEditingController(text: data['purity']);
    final grossWeightController = TextEditingController(text: data['grossWeight']?.toString());
    final netWeightController = TextEditingController(text: data['netWeight']?.toString());
    final diamondPcsController = TextEditingController(text: data['diamond']['pcs']?.toString());
    final diamondWeightController = TextEditingController(text: data['diamond']['weight']?.toString());
    final diamondRateController = TextEditingController(text: data['diamond']['rate']?.toString());
    final stonePcsController = TextEditingController(text: data['stone']['pcs']?.toString());
    final stoneWeightController = TextEditingController(text: data['stone']['weight']?.toString());
    final stoneRateController = TextEditingController(text: data['stone']['rate']?.toString());
    final makingRateController = TextEditingController(text: data['making']['rate']?.toString());
    final certAmountController = TextEditingController(text: data['certAmount']?.toString());
    final qtyController = TextEditingController(text: data['quantityAvailable']?.toString() ?? '1');
    final purchasedRateController = TextEditingController(text: data['purchasedRate']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: itemNoController,
                  labelText: 'Item No',
                  icon: Icons.tag,
                ),
                CustomTextField(
                  controller: designController,
                  labelText: 'Design',
                  icon: Icons.design_services,
                ),
                CustomTextField(
                  controller: purityController,
                  labelText: 'Purity (e.g., 14K)',
                  icon: Icons.verified,
                ),
                CustomTextField(
                  controller: grossWeightController,
                  labelText: 'Gross Weight (gm)',
                  icon: Icons.scale,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return null;
                    final wt = double.tryParse(value!);
                    if (wt == null || wt <= 0) return 'Invalid weight';
                    return null;
                  },
                ),
                CustomTextField(
                  controller: netWeightController,
                  labelText: 'Net Weight (gm)',
                  icon: Icons.scale,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return null;
                    final wt = double.tryParse(value!);
                    if (wt == null || wt <= 0) return 'Invalid weight';
                    return null;
                  },
                ),
                CustomTextField(
                  controller: diamondPcsController,
                  labelText: 'Diamond Pieces',
                  icon: Icons.diamond,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return null;
                    final pcs = int.tryParse(value!);
                    if (pcs == null || pcs < 0) return 'Invalid pieces';
                    return null;
                  },
                ),
                CustomTextField(
                  controller: diamondWeightController,
                  labelText: 'Diamond Weight (carat)',
                  icon: Icons.diamond,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return null;
                    final wt = double.tryParse(value!);
                    if (wt == null || wt < 0) return 'Invalid weight';
                    return null;
                  },
                ),
                CustomTextField(
                  controller: diamondRateController,
                  labelText: 'Diamond Rate',
                  icon: Icons.monetization_on,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return null;
                    final rate = double.tryParse(value!);
                    if (rate == null || rate < 0) return 'Invalid rate';
                    return null;
                  },
                ),
                CustomTextField(
                  controller: stonePcsController,
                  labelText: 'Stone Pieces',
                  icon: Icons.circle,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return null;
                    final pcs = int.tryParse(value!);
                    if (pcs == null || pcs < 0) return 'Invalid pieces';
                    return null;
                  },
                ),
                CustomTextField(
                  controller: stoneWeightController,
                  labelText: 'Stone Weight (carat)',
                  icon: Icons.circle,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return null;
                    final wt = double.tryParse(value!);
                    if (wt == null || wt < 0) return 'Invalid weight';
                    return null;
                  },
                ),
                CustomTextField(
                  controller: stoneRateController,
                  labelText: 'Stone Rate',
                  icon: Icons.monetization_on,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return null;
                    final rate = double.tryParse(value!);
                    if (rate == null || rate < 0) return 'Invalid rate';
                    return null;
                  },
                ),
                CustomTextField(
                  controller: makingRateController,
                  labelText: 'Making Rate',
                  icon: Icons.build,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return null;
                    final rate = double.tryParse(value!);
                    if (rate == null || rate < 0) return 'Invalid rate';
                    return null;
                  },
                ),
                CustomTextField(
                  controller: certAmountController,
                  labelText: 'Certification Amount',
                  icon: Icons.verified_user,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return null;
                    final amt = double.tryParse(value!);
                    if (amt == null || amt < 0) return 'Invalid amount';
                    return null;
                  },
                ),
                CustomTextField(
                  controller: qtyController,
                  labelText: 'Quantity Available',
                  icon: Icons.inventory,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Enter quantity';
                    final qty = int.tryParse(value!);
                    if (qty == null || qty <= 0) return 'Invalid quantity';
                    return null;
                  },
                ),
                CustomTextField(
                  controller: purchasedRateController,
                  labelText: 'Purchased Rate (per unit)',
                  icon: Icons.monetization_on,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return null;
                    final rate = double.tryParse(value!);
                    if (rate == null || rate < 0) return 'Invalid rate';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final grossWeight = double.tryParse(grossWeightController.text) ?? 0.0;
                final netWeight = double.tryParse(netWeightController.text) ?? 0.0;
                final purityValue = purityController.text.isEmpty
                    ? 0.0
                    : (double.tryParse(purityController.text.replaceAll('K', '')) ?? 0.0);
                final fineWeight = netWeight * (purityValue / 24);
                final diamondPcs = int.tryParse(diamondPcsController.text) ?? 0;
                final diamondWeight = double.tryParse(diamondWeightController.text) ?? 0.0;
                final diamondRate = double.tryParse(diamondRateController.text) ?? 0.0;
                final diamondSubTotal = diamondPcs * diamondWeight * diamondRate;
                final stonePcs = int.tryParse(stonePcsController.text) ?? 0;
                final stoneWeight = double.tryParse(stoneWeightController.text) ?? 0.0;
                final stoneRate = double.tryParse(stoneRateController.text) ?? 0.0;
                final stoneSubTotal = stonePcs * stoneWeight * stoneRate;
                final makingRate = double.tryParse(makingRateController.text) ?? 0.0;
                final makingSubTotal = makingRate;
                final certAmount = double.tryParse(certAmountController.text) ?? 0.0;
                final totalAmount = diamondSubTotal + stoneSubTotal + makingSubTotal + certAmount;
                final qty = int.parse(qtyController.text);
                final purchasedRate = double.tryParse(purchasedRateController.text) ?? (totalAmount / qty);

                try {
                  await FirebaseFirestore.instance.collection('items').doc(docId).update({
                    'itemNo': itemNoController.text.trim(),
                    'design': designController.text.trim(),
                    'purity': purityController.text.trim(),
                    'grossWeight': grossWeight,
                    'netWeight': netWeight,
                    'fineWeight': fineWeight,
                    'diamond': {
                      'pcs': diamondPcs,
                      'weight': diamondWeight,
                      'rate': diamondRate,
                      'subTotal': diamondSubTotal,
                    },
                    'stone': {
                      'pcs': stonePcs,
                      'weight': stoneWeight,
                      'rate': stoneRate,
                      'subTotal': stoneSubTotal,
                    },
                    'making': {
                      'rate': makingRate,
                      'subTotal': makingSubTotal,
                    },
                    'certAmount': certAmount,
                    'totalAmount': totalAmount,
                    'quantityAvailable': qty,
                    'purchasedRate': purchasedRate,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Item updated successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inventory Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6F73D2), Color(0xFF8E91E0)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6F73D2), Color(0xFFF9F9F9)],
          ),
        ),
        child: AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('items')
                .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No items in inventory'));
              }
              return InteractiveViewer(
                constrained: false,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Theme.of(context).primaryColor.withOpacity(0.1)),
                  dataRowHeight: 60,
                  columns: const [
                    DataColumn(label: Text('Sno.')),
                    DataColumn(label: Text('Item No')),
                    DataColumn(label: Text('Design')),
                    DataColumn(label: Text('Purity')),
                    DataColumn(label: Text('G.Wt (g)')),
                    DataColumn(label: Text('N.Wt (g)')),
                    DataColumn(label: Text('Fine (g)')),
                    DataColumn(label: Text('Diamond\nPcs/Wts/Rate/Sub')),
                    DataColumn(label: Text('Stone\nPcs/Wt/Rate/Sub')),
                    DataColumn(label: Text('Making\nRate/Sub')),
                    DataColumn(label: Text('Cert')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Qty')),
                    DataColumn(label: Text('Purchased Rate')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: snapshot.data!.docs.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final doc = entry.value;
                    final data = doc.data() as Map<String, dynamic>;
                    return DataRow(
                      cells: [
                        DataCell(Text('$index')),
                        DataCell(Text(data['itemNo'] ?? '')),
                        DataCell(Text(data['design'] ?? '')),
                        DataCell(Text(data['purity'] ?? '')),
                        DataCell(Text(data['grossWeight']?.toStringAsFixed(3) ?? '')),
                        DataCell(Text(data['netWeight']?.toStringAsFixed(3) ?? '')),
                        DataCell(Text(data['fineWeight']?.toStringAsFixed(3) ?? '')),
                        DataCell(Text(
                          '${data['diamond']['pcs'] ?? 0}/${data['diamond']['weight']?.toStringAsFixed(2) ?? '0.00'}/${data['diamond']['rate']?.toStringAsFixed(2) ?? '0.00'}/Rs${data['diamond']['subTotal']?.toStringAsFixed(2) ?? '0.00'}',
                        )),
                        DataCell(Text(
                          '${data['stone']['pcs'] ?? 0}/${data['stone']['weight']?.toStringAsFixed(2) ?? '0.00'}/${data['stone']['rate']?.toStringAsFixed(2) ?? '0.00'}/Rs${data['stone']['subTotal']?.toStringAsFixed(2) ?? '0.00'}',
                        )),
                        DataCell(Text(
                          '${data['making']['rate']?.toStringAsFixed(2) ?? '0.00'}/Rs${data['making']['subTotal']?.toStringAsFixed(2) ?? '0.00'}',
                        )),
                        DataCell(Text('Rs${data['certAmount']?.toStringAsFixed(2) ?? '0.00'}')),
                        DataCell(Text('Rs${data['totalAmount']?.toStringAsFixed(2) ?? '0.00'}')),
                        DataCell(Text('${data['quantityAvailable'] ?? 1}')),
                        DataCell(Text('Rs${data['purchasedRate']?.toStringAsFixed(2) ?? '0.00'}')),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                                onPressed: () => _editItem(doc.id, data),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteItem(doc.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.sell, color: Colors.green),
                                onPressed: () => _sellItem(doc.id, data),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}