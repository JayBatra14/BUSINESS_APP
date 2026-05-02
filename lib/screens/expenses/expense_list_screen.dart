// lib/screens/expenses/expense_list_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final _svc = ExpenseService();
  List<ExpenseModel> _expenses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _expenses = _svc.getAllExpenses());

  @override
  Widget build(BuildContext context) {
    final catTotals = _svc.getExpensesByCategory();
    final totalAll = _expenses.fold(0.0, (s, e) => s + e.amount);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(AppStrings.tx(context, 'Expenses')),
        backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white,
      ),
      body: Column(children: [
        // Summary
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppStrings.tx(context, 'Total Expenses'), style: TextStyle(color: Colors.red.shade300, fontSize: 12)),
              Text('₹${totalAll.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(AppStrings.tx(context, 'Today'), style: TextStyle(color: Colors.red.shade300, fontSize: 12)),
              Text('₹${_svc.getTodayExpenses().toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
            ]),
          ]),
        ),
        // Category breakdown
        if (catTotals.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: catTotals.entries.map((e) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text('${e.key}: ₹${e.value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.grey.shade100,
                ),
              )).toList(),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: _expenses.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.receipt_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(AppStrings.tx(context, 'No expenses recorded'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _expenses.length,
                  itemBuilder: (_, i) {
                    final e = _expenses[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade50,
                          child: Icon(_catIcon(e.category), color: Colors.red.shade700, size: 20),
                        ),
                        title: Text(e.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${e.category} • ${e.paymentMethod}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('₹${e.amount.toStringAsFixed(0)}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                          Text('${e.date.day}/${e.date.month}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ]),
                        onLongPress: () {
                          showDialog(context: context, builder: (ctx) => AlertDialog(
                            title: Text(AppStrings.tx(context, 'Delete Expense?')),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.tx(context, 'Cancel'))),
                              TextButton(onPressed: () {
                                _svc.deleteExpense(e.id!);
                                Navigator.pop(ctx);
                                _load();
                              }, child: Text(AppStrings.tx(context, 'Delete'), style: TextStyle(color: Colors.red.shade700))),
                            ],
                          ));
                        },
                      ),
                    );
                  },
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpense(),
        backgroundColor: Colors.red.shade700, foregroundColor: Colors.white,
        icon: const Icon(Icons.add), label: Text(AppStrings.tx(context, 'Add Expense')),
      ),
    );
  }

  void _showAddExpense() {
    final descCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String cat = 'General';
    String method = 'cash';

    final cats = ['General', 'Rent', 'Salary', 'Transport', 'Utilities', 'Supplies', 'Food', 'Maintenance', 'Marketing', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setBS) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(AppStrings.tx(context, 'Add Expense'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: descCtrl, decoration: InputDecoration(
            labelText: AppStrings.tx(context, 'Description *'), hintText: AppStrings.tx(context, 'e.g. Electricity bill'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true, fillColor: Colors.grey.shade50,
          )),
          const SizedBox(height: 12),
          TextField(controller: amtCtrl, keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: AppStrings.tx(context, 'Amount *'), hintText: '0', prefixText: '₹ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true, fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              initialValue: cat,
              decoration: InputDecoration(labelText: AppStrings.tx(context, 'Category'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true, fillColor: Colors.grey.shade50),
              items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setBS(() => cat = v!),
            )),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<String>(
              initialValue: method,
              decoration: InputDecoration(labelText: AppStrings.tx(context, 'Method'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true, fillColor: Colors.grey.shade50),
              items: [
                DropdownMenuItem(value: 'cash', child: Text(AppStrings.tx(context, 'Cash'))),
                DropdownMenuItem(value: 'upi', child: Text('UPI')),
                DropdownMenuItem(value: 'bank_transfer', child: Text(AppStrings.tx(context, 'Bank'))),
              ],
              onChanged: (v) => setBS(() => method = v!),
            )),
          ]),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
            onPressed: () async {
              if (descCtrl.text.isEmpty || amtCtrl.text.isEmpty) return;
              await _svc.addExpense(ExpenseModel(
                category: cat,
                amount: double.tryParse(amtCtrl.text) ?? 0,
                description: descCtrl.text.trim(),
                paymentMethod: method,
                date: DateTime.now(),
                createdAt: DateTime.now(),
              ));
              Navigator.pop(ctx);
              _load();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppStrings.tx(context, 'Save Expense'), style: const TextStyle(fontWeight: FontWeight.bold)),
          )),
        ]),
      )),
    );
  }

  IconData _catIcon(String c) {
    switch (c) {
      case 'Rent': return Icons.home;
      case 'Salary': return Icons.people;
      case 'Transport': return Icons.directions_car;
      case 'Utilities': return Icons.bolt;
      case 'Supplies': return Icons.shopping_bag;
      case 'Food': return Icons.restaurant;
      case 'Maintenance': return Icons.build;
      case 'Marketing': return Icons.campaign;
      default: return Icons.receipt;
    }
  }
}
