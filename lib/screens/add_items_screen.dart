import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_text_field.dart';

class AddItemsScreen extends StatefulWidget {
  @override
  State<AddItemsScreen> createState() => _AddItemsScreenState();
}

class _AddItemsScreenState extends State<AddItemsScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();
  bool _isButtonPressed = false;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 100), () {
      setState(() => _isVisible = true);
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isButtonPressed = true);
      try {
        await FirebaseFirestore.instance.collection('items').add({
          'name': nameController.text.trim(),
          'price': double.parse(priceController.text.trim()),
          'quantity': int.parse(quantityController.text.trim()),
          'createdAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item added successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      setState(() => _isButtonPressed = false);
    }
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? validatePrice(String? value) {
    if (value == null || value.isEmpty) return 'Price is required';
    if (double.tryParse(value) == null || double.parse(value) <= 0) {
      return 'Enter a valid price';
    }
    return null;
  }

  String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) return 'Quantity is required';
    if (int.tryParse(value) == null || int.parse(value) <= 0) {
      return 'Enter a valid quantity';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Item',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6F73D2), Color(0xFF8E91E0)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6F73D2), Color(0xFFF9F9F9)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: AnimatedOpacity(
              opacity: _isVisible ? 1.0 : 0.0,
              duration: Duration(milliseconds: 500),
              child: Card(
                elevation: 8.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24.0),
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
                        SizedBox(height: 16.0),
                        Text(
                          'Add New Item',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 24.0),
                        CustomTextField(
                          controller: nameController,
                          labelText: 'Item Name',
                          icon: Icons.diamond,
                          validator: validateName,
                        ),
                        SizedBox(height: 16.0),
                        CustomTextField(
                          controller: priceController,
                          labelText: 'Price',
                          icon: Icons.attach_money,
                          validator: validatePrice,
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 16.0),
                        CustomTextField(
                          controller: quantityController,
                          labelText: 'Quantity',
                          icon: Icons.inventory_2,
                          validator: validateQuantity,
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 24.0),
                        LayoutBuilder(
                          builder: (context, constraints) => AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            width: constraints.maxWidth,
                            child: ElevatedButton(
                              onPressed: _addItem,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.black45,
                                elevation: _isButtonPressed ? 2.0 : 8.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF6F73D2),
                                      Color(0xFF8E91E0),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Text(
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
      ),
    );
  }
}