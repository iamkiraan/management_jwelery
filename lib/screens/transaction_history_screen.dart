import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() => _isVisible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transaction History',
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
                .collection('transactions')
                .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .where('type', isEqualTo: 'sale')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                final error = snapshot.error;
                if (error is FirebaseException) {
                  debugPrint('🔥 Firestore error [${error.code}]: ${error.message}');
                } else {
                  debugPrint('🔥 Unknown error: $error');
                }
                return const Center(child: Text('Something went wrong. Check logs.'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No transactions found'));
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
                    DataColumn(label: Text('Diamond\nPcs/Wt/Rate/Sub')),
                    DataColumn(label: Text('Stone\nPcs/Wt/Rate/Sub')),
                    DataColumn(label: Text('Making\nRate/Sub')),
                    DataColumn(label: Text('Cert')),
                    DataColumn(label: Text('Sale Amount')),
                    DataColumn(label: Text('Qty Sold')),
                    DataColumn(label: Text('Purchased Rate')),
                    DataColumn(label: Text('Profit')),
                    DataColumn(label: Text('Sold To')),
                    DataColumn(label: Text('Sold Date')),
                  ],
                  rows: snapshot.data!.docs.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final doc = entry.value;
                    final data = doc.data() as Map<String, dynamic>;
                    final Future<double> itemDoc = FirebaseFirestore.instance
                        .collection('items')
                        .where('itemNo', isEqualTo: data['itemNo'])
                        .limit(1)
                        .get()
                        .then<double>((querySnapshot) {
                      if (querySnapshot.docs.isEmpty) return 0.0;
                      final itemData = querySnapshot.docs.first.data() as Map<String, dynamic>;
                      return (itemData['purchasedRate'] as num?)?.toDouble() ?? 0.0;
                    });
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
                          '${data['diamond']['pcs'] ?? 0}/${data['diamond']['weight']?.toStringAsFixed(2) ?? '0.00'}/${data['saleRates']['diamondRate']?.toStringAsFixed(2) ?? '0.00'}/Rs${data['diamond']['subTotal']?.toStringAsFixed(2) ?? '0.00'}',
                        )),
                        DataCell(Text(
                          '${data['stone']['pcs'] ?? 0}/${data['stone']['weight']?.toStringAsFixed(2) ?? '0.00'}/${data['saleRates']['stoneRate']?.toStringAsFixed(2) ?? '0.00'}/Rs${data['stone']['subTotal']?.toStringAsFixed(2) ?? '0.00'}',
                        )),
                        DataCell(Text(
                          '${data['saleRates']['makingCharge']?.toStringAsFixed(2) ?? '0.00'}/Rs${data['making']['subTotal']?.toStringAsFixed(2) ?? '0.00'}',
                        )),
                        DataCell(Text('Rs${data['certAmount']?.toStringAsFixed(2) ?? '0.00'}')),
                        DataCell(Text('Rs${data['saleAmount']?.toStringAsFixed(2) ?? '0.00'}')),
                        DataCell(Text('${data['quantitySold'] ?? 0}')),
                        DataCell(FutureBuilder<double>(
                          future: itemDoc,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Text('Loading...');
                            }
                            return Text('Rs${snapshot.data?.toStringAsFixed(2) ?? '0.00'}');
                          },
                        )),
                        DataCell(Text('Rs${data['profit']?.toStringAsFixed(2) ?? '0.00'}')),
                        DataCell(Text(data['toWhom'] ?? '')),
                        DataCell(Text(
                          data['date'] != null
                              ? DateFormat('yyyy-MM-dd hh:mm a').format((data['date'] as Timestamp).toDate())
                              : '',
                        )),
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