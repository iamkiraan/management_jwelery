import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';

class AddItemsScreen extends StatefulWidget {
  const AddItemsScreen({Key? key}) : super(key: key);

  @override
  State<AddItemsScreen> createState() => _AddItemsScreenState();
}

class _AddItemsScreenState extends State<AddItemsScreen> {
  final _formKey = GlobalKey<FormState>();
  final itemNoController = TextEditingController();
  final designController = TextEditingController();
  final purityController = TextEditingController();
  final grossWeightController = TextEditingController();
  final netWeightController = TextEditingController();
  final diamondPcsController = TextEditingController();
  final diamondWeightController = TextEditingController();
  final diamondRateController = TextEditingController();
  final stonePcsController = TextEditingController();
  final stoneWeightController = TextEditingController();
  final stoneRateController = TextEditingController();
  final makingRateController = TextEditingController();
  final certAmountController = TextEditingController();
  final qtyController = TextEditingController(text: '1');
  final goldRateController = TextEditingController();
  bool _isButtonPressed = false;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() => _isVisible = true);
    });
  }

  @override
  void dispose() {
    itemNoController.dispose();
    designController.dispose();
    purityController.dispose();
    grossWeightController.dispose();
    netWeightController.dispose();
    diamondPcsController.dispose();
    diamondWeightController.dispose();
    diamondRateController.dispose();
    stonePcsController.dispose();
    stoneWeightController.dispose();
    stoneRateController.dispose();
    makingRateController.dispose();
    certAmountController.dispose();
    qtyController.dispose();
    goldRateController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isButtonPressed = true);
      try {
        final grossWeight = double.tryParse(grossWeightController.text) ?? 0.0;
        final netWeight = double.tryParse(netWeightController.text) ?? 0.0;
        // Use net weight if provided; otherwise, use gross weight
        final goldWeight = netWeight > 0 ? netWeight : grossWeight;
        final goldRate = double.tryParse(goldRateController.text) ?? 0.0;
        final purityValue = purityController.text.isEmpty
            ? 0.0
            : (double.tryParse(purityController.text.replaceAll('K', '')) ?? 0.0);
        final fineWeight = goldWeight * (purityValue / 24);
        final goldCost = goldWeight * goldRate;

        final diamondPcs = int.tryParse(diamondPcsController.text) ?? 0;
        final diamondWeightCarat = double.tryParse(diamondWeightController.text) ?? 0.0;
        final diamondWeightGram = diamondWeightCarat * 0.2; // Convert carats to grams
        final diamondRate = double.tryParse(diamondRateController.text) ?? 0.0;
        final diamondCost = diamondWeightGram * diamondRate;

        final stonePcs = int.tryParse(stonePcsController.text) ?? 0;
        final stoneWeightCarat = double.tryParse(stoneWeightController.text) ?? 0.0;
        final stoneWeightGram = stoneWeightCarat * 0.2; // Convert carats to grams
        final stoneRate = double.tryParse(stoneRateController.text) ?? 0.0;
        final stoneCost = stoneWeightGram * stoneRate;

        final makingRate = double.tryParse(makingRateController.text) ?? 0.0;
        final certAmount = double.tryParse(certAmountController.text) ?? 0.0;
        final qty = int.parse(qtyController.text);

        // Calculate total purchase amount
        final totalAmount = goldCost + diamondCost + stoneCost + makingRate + certAmount;
        final purchasedRate = totalAmount / qty;

        await FirebaseFirestore.instance.collection('items').add({
          'itemNo': itemNoController.text.trim(),
          'design': designController.text.trim(),
          'purity': purityController.text.trim(),
          'grossWeight': grossWeight,
          'netWeight': netWeight,
          'fineWeight': fineWeight,
          'diamond': {
            'pcs': diamondPcs,
            'weight': diamondWeightCarat,
            'weightGram': diamondWeightGram,
            'rate': diamondRate,
            'subTotal': diamondCost,
          },
          'stone': {
            'pcs': stonePcs,
            'weight': stoneWeightCarat,
            'weightGram': stoneWeightGram,
            'rate': stoneRate,
            'subTotal': stoneCost,
          },
          'making': {
            'rate': makingRate,
            'subTotal': makingRate,
          },
          'certAmount': certAmount,
          'totalAmount': totalAmount,
          'quantityAvailable': qty,
          'purchasedRate': purchasedRate,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': FirebaseAuth.instance.currentUser?.uid,
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item added successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
      setState(() => _isButtonPressed = false);
    }
  }

  String? _validateNumber(String? value, String field, {bool isInt = false}) {
    if (value?.isEmpty ?? true) return null;
    final number = isInt ? int.tryParse(value!) : double.tryParse(value!);
    if (number == null || number < 0) return 'Enter a valid $field';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Item',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedOpacity(
            opacity: _isVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: Card(
              elevation: 8.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 80.0,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.diamond,
                          size: 80.0,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'Add New Item',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      CustomTextField(
                        controller: itemNoController,
                        labelText: 'Item No',
                        icon: Icons.tag,
                      ),
                      const SizedBox(height: 16.0),
                      CustomTextField(
                        controller: designController,
                        labelText: 'Design',
                        icon: Icons.design_services,
                      ),
                      const SizedBox(height: 16.0),
                      CustomTextField(
                        controller: purityController,
                        labelText: 'Purity (e.g., 14K)',
                        icon: Icons.verified,
                      ),
                      const SizedBox(height: 16.0),
                      CustomTextField(
                        controller: grossWeightController,
                        labelText: 'Gross Weight (gm)',
                        icon: Icons.scale,
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'weight'),
                      ),
                      const SizedBox(height: 16.0),
                      CustomTextField(
                        controller: netWeightController,
                        labelText: 'Net Weight (gm)',
                        icon: Icons.scale,
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'weight'),
                      ),
                      const SizedBox(height: 16.0),
                      CustomTextField(
                        controller: goldRateController,
                        labelText: 'Gold Rate (per gm)',
                        icon: Icons.monetization_on,
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'rate'),
                      ),
                      const SizedBox(height: 16.0),
                      CustomTextField(
                        controller: diamondPcsController,
                        labelText: 'Diamond Pieces',
                        icon: Icons.diamond,
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'pieces', isInt: true),
                      ),
                      const SizedBox(height: 16.0),
                      CustomTextField(
                        controller: diamondWeightController,
                        labelText: 'Diamond Weight (carat)',
                        icon: Icons.diamond,
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'weight'),
                      ),
                      const SizedBox(height: 16.0),
                      CustomTextField(
                        controller: diamondRateController,
                        labelText: 'Diamond Rate (per gm)',
                        icon: Icons.monetization_on,
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'rate'),
                      ),
                      const SizedBox(height: 16.0),
                      CustomTextField(
                        controller: stonePcsController,
                        labelText: 'Stone Pieces',
                        icon: Icons.circle,
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'pieces', isInt: true),
                      ),
                      const SizedBox(height: 16.0),
                      CustomTextField(
                        controller: stoneWeightController,
                        labelText: 'Stone Weight (carat)',
                        icon: Icons.circle,
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'weight'),
                      ),
                      const SizedBox(height: 16.0),
                      CustomTextField(
                        controller: stoneRateController,
                        labelText: 'Stone Rate (per gm)',
                        icon: Icons.monetization_on,
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'rate'),
                      ),
                      const SizedBox(height: 16.0),
                      CustomTextField(
                        controller: makingRateController,
                        labelText: 'Making Rate',
                        icon: Icons.build,
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'rate'),
                      ),
                      const SizedBox(height: 16.0),
                      CustomTextField(
                        controller: certAmountController,
                        labelText: 'Certification Amount',
                        icon: Icons.verified_user,
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'amount'),
                      ),
                      const SizedBox(height: 16.0),
                      CustomTextField(
                        controller: qtyController,
                        labelText: 'Quantity',
                        icon: Icons.inventory,
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateNumber(value, 'quantity', isInt: true),
                      ),
                      const SizedBox(height: 24.0),
                      LayoutBuilder(
                        builder: (context, constraints) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: constraints.maxWidth,
                          child: ElevatedButton(
                            onPressed: _addItem,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.black45,
                              elevation: _isButtonPressed ? 2.0 : 8.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6F73D2),
                                    Color(0xFF8E91E0),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: const Text(
                                'Add Item',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}