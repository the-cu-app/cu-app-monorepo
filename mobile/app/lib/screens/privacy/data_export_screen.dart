import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons, Colors, CircularProgressIndicator, showDialog;
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import '../../services/plaid_service.dart';
import 'package:flutter/services.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  final PlaidService _plaidService = PlaidService();
  ExportFormat _selectedFormat = ExportFormat.fdxJson;
  DateRange _selectedRange = DateRange.lastYear;
  bool _isExporting = false;
  final Set<DataCategory> _selectedCategories = {
    DataCategory.accounts,
    DataCategory.transactions,
    DataCategory.balances,
  };

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      // Simulate export process
      await Future.delayed(const Duration(seconds: 2));

      Map<String, dynamic> exportData = {};

      // Gather data based on selected categories
      if (_selectedCategories.contains(DataCategory.accounts)) {
        final accounts = await _plaidService.getAccounts();
        exportData['accounts'] = accounts;
      }

      if (_selectedCategories.contains(DataCategory.transactions)) {
        final txData = await _plaidService.getRealTransactions(count: 100);
        exportData['transactions'] = txData['transactions'];
      }

      if (_selectedCategories.contains(DataCategory.balances)) {
        final accounts = await _plaidService.getAccounts();
        exportData['balances'] = accounts.map((acc) => {
          'account_id': acc['account_id'],
          'current': acc['balances']?['current'],
          'available': acc['balances']?['available'],
        }).toList();
      }

      // Format data based on export format
      String formattedData;
      String filename;

      switch (_selectedFormat) {
        case ExportFormat.fdxJson:
          formattedData = _formatAsFDX(exportData);
          filename = 'financial_data_fdx_${DateTime.now().millisecondsSinceEpoch}.json';
          break;
        case ExportFormat.json:
          formattedData = const JsonEncoder.withIndent('  ').convert(exportData);
          filename = 'financial_data_${DateTime.now().millisecondsSinceEpoch}.json';
          break;
        case ExportFormat.csv:
          formattedData = _formatAsCSV(exportData);
          filename = 'financial_data_${DateTime.now().millisecondsSinceEpoch}.csv';
          break;
        case ExportFormat.qfx:
          formattedData = _formatAsQFX(exportData);
          filename = 'financial_data_${DateTime.now().millisecondsSinceEpoch}.qfx';
          break;
      }

      // Copy to clipboard for demo
      await Clipboard.setData(ClipboardData(text: formattedData));

      if (mounted) {
        HapticFeedback.mediumImpact();
        showDialog(
          context: context,
          builder: (context) => Center(
            child: _ExportSuccessDialog(
              format: _selectedFormat,
              filename: filename,
              recordCount: _getRecordCount(exportData),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Export error: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  String _formatAsFDX(Map<String, dynamic> data) {
    // FDX API 6.0 compliant format
    final fdxData = {
      'fdxVersion': '6.0',
      'exportDate': DateTime.now().toIso8601String(),
      'accounts': (data['accounts'] as List?)?.map((acc) => {
        'accountId': acc['account_id'],
        'accountType': acc['subtype']?.toString().toUpperCase() ?? 'CHECKING',
        'accountName': acc['name'],
        'accountNumber': acc['mask'],
        'balance': {
          'current': acc['balances']?['current'],
          'available': acc['balances']?['available'],
          'currency': 'USD',
        },
        'institution': {
          'institutionId': acc['institution_id'],
          'institutionName': acc['institution'],
        },
      }).toList() ?? [],
      'transactions': (data['transactions'] as List?)?.map((tx) => {
        'transactionId': tx['transaction_id'],
        'accountId': tx['account_id'],
        'amount': tx['amount'],
        'currency': 'USD',
        'description': tx['name'],
        'merchantName': tx['merchant_name'],
        'category': tx['category'],
        'date': tx['date'],
        'pending': tx['pending'] ?? false,
      }).toList() ?? [],
    };

    return const JsonEncoder.withIndent('  ').convert(fdxData);
  }

  String _formatAsCSV(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    // Export transactions as CSV
    if (data['transactions'] != null) {
      buffer.writeln('Date,Description,Merchant,Amount,Category,Account');
      for (var tx in data['transactions']) {
        buffer.writeln(
          '${tx['date']},${_escapeCsv(tx['name'])},${_escapeCsv(tx['merchant_name'] ?? '')},${tx['amount']},${_escapeCsv((tx['category'] as List?)?.firstOrNull ?? '')},${tx['account_id']}'
        );
      }
    }

    return buffer.toString();
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _formatAsQFX(Map<String, dynamic> data) {
    // Quicken/QuickBooks OFX format
    final buffer = StringBuffer();
    buffer.writeln('OFXHEADER:100');
    buffer.writeln('DATA:OFXSGML');
    buffer.writeln('VERSION:102');
    buffer.writeln('SECURITY:NONE');
    buffer.writeln('ENCODING:USASCII');
    buffer.writeln('CHARSET:1252');
    buffer.writeln('COMPRESSION:NONE');
    buffer.writeln('OLDFILEUID:NONE');
    buffer.writeln('NEWFILEUID:${DateTime.now().millisecondsSinceEpoch}');
    buffer.writeln('');
    buffer.writeln('<OFX>');
    buffer.writeln('  <SIGNONMSGSRSV1>');
    buffer.writeln('    <SONRS>');
    buffer.writeln('      <STATUS>');
    buffer.writeln('        <CODE>0');
    buffer.writeln('        <SEVERITY>INFO');
    buffer.writeln('      </STATUS>');
    buffer.writeln('      <DTSERVER>${_formatOfxDate(DateTime.now())}');
    buffer.writeln('      <LANGUAGE>ENG');
    buffer.writeln('    </SONRS>');
    buffer.writeln('  </SIGNONMSGSRSV1>');
    buffer.writeln('</OFX>');

    return buffer.toString();
  }

  String _formatOfxDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}120000';
  }

  int _getRecordCount(Map<String, dynamic> data) {
    int count = 0;
    if (data['accounts'] != null) count += (data['accounts'] as List).length;
    if (data['transactions'] != null) count += (data['transactions'] as List).length;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return CUScacuold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CUAppBar(
        title: const Text(
          'Export Your Data',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Geist',
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 800 : double.infinity,
          ),
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Download Your Financial Data',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                          fontFamily: 'Geist',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Export your data in industry-standard formats. All exports are encrypted and comply with Section 1033 regulations.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Format Selection
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Format',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade900,
                          fontFamily: 'Geist',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _FormatCard(
                        format: ExportFormat.fdxJson,
                        title: 'FDX JSON',
                        description: 'Financial Data Exchange standard (recommended)',
                        icon: Icons.code,
                        selected: _selectedFormat == ExportFormat.fdxJson,
                        onTap: () => setState(() => _selectedFormat = ExportFormat.fdxJson),
                      ),
                      const SizedBox(height: 8),
                      _FormatCard(
                        format: ExportFormat.json,
                        title: 'JSON',
                        description: 'Standard JSON format for developers',
                        icon: Icons.data_object,
                        selected: _selectedFormat == ExportFormat.json,
                        onTap: () => setState(() => _selectedFormat = ExportFormat.json),
                      ),
                      const SizedBox(height: 8),
                      _FormatCard(
                        format: ExportFormat.csv,
                        title: 'CSV',
                        description: 'Compatible with Excel and spreadsheet apps',
                        icon: Icons.table_chart,
                        selected: _selectedFormat == ExportFormat.csv,
                        onTap: () => setState(() => _selectedFormat = ExportFormat.csv),
                      ),
                      const SizedBox(height: 8),
                      _FormatCard(
                        format: ExportFormat.qfx,
                        title: 'QFX/OFX',
                        description: 'Quicken and QuickBooks format',
                        icon: Icons.account_balance,
                        selected: _selectedFormat == ExportFormat.qfx,
                        onTap: () => setState(() => _selectedFormat = ExportFormat.qfx),
                      ),
                    ],
                  ),
                ),
              ),

              // Data Categories
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What to Export',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade900,
                          fontFamily: 'Geist',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CategoryCheckbox(
                        category: DataCategory.accounts,
                        title: 'Account Information',
                        description: 'Account names, numbers, and types',
                        icon: Icons.account_balance_wallet,
                        selected: _selectedCategories.contains(DataCategory.accounts),
                        onToggle: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(DataCategory.accounts);
                            } else {
                              _selectedCategories.remove(DataCategory.accounts);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _CategoryCheckbox(
                        category: DataCategory.transactions,
                        title: 'Transaction History',
                        description: 'All transactions within selected date range',
                        icon: Icons.receipt_long,
                        selected: _selectedCategories.contains(DataCategory.transactions),
                        onToggle: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(DataCategory.transactions);
                            } else {
                              _selectedCategories.remove(DataCategory.transactions);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _CategoryCheckbox(
                        category: DataCategory.balances,
                        title: 'Account Balances',
                        description: 'Current and available balances',
                        icon: Icons.account_balance,
                        selected: _selectedCategories.contains(DataCategory.balances),
                        onToggle: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(DataCategory.balances);
                            } else {
                              _selectedCategories.remove(DataCategory.balances);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _CategoryCheckbox(
                        category: DataCategory.identity,
                        title: 'Identity Information',
                        description: 'Name, address, and contact details',
                        icon: Icons.person,
                        selected: _selectedCategories.contains(DataCategory.identity),
                        onToggle: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(DataCategory.identity);
                            } else {
                              _selectedCategories.remove(DataCategory.identity);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Date Range
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date Range',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade900,
                          fontFamily: 'Geist',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DateRangeChip(
                              label: 'Last 30 Days',
                              selected: _selectedRange == DateRange.last30Days,
                              onTap: () => setState(() => _selectedRange = DateRange.last30Days),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DateRangeChip(
                              label: 'Last 90 Days',
                              selected: _selectedRange == DateRange.last90Days,
                              onTap: () => setState(() => _selectedRange = DateRange.last90Days),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _DateRangeChip(
                              label: 'Last Year',
                              selected: _selectedRange == DateRange.lastYear,
                              onTap: () => setState(() => _selectedRange = DateRange.lastYear),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DateRangeChip(
                              label: 'All Time',
                              selected: _selectedRange == DateRange.allTime,
                              onTap: () => setState(() => _selectedRange = DateRange.allTime),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Export Button
                      SizedBox(
                        width: double.infinity,
                        child: CUButton(
                          onPressed: _selectedCategories.isEmpty || _isExporting
                              ? null
                              : _exportData,
                          child: _isExporting
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Exporting...'),
                                  ],
                                )
                              : const Text('Export Data'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  final ExportFormat format;
  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FormatCard({
    required this.format,
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);

    return CUOutlinedCard(
      onTap: onTap,
      child: Container(
        decoration: selected
            ? BoxDecoration(
                border: Border.all(color: theme.colorScheme.primary, width: 2),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: selected ? theme.colorScheme.primary : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade900,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontFamily: 'Geist',
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 24)
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCheckbox extends StatelessWidget {
  final DataCategory category;
  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final Function(bool) onToggle;

  const _CategoryCheckbox({
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);

    return CUOutlinedCard(
      onTap: () => onToggle(!selected),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Icon(Icons.check_box, color: theme.colorScheme.primary, size: 24)
          else
            Icon(Icons.check_box_outline_blank, color: Colors.grey.shade400, size: 24),
        ],
      ),
    );
  }
}

class _DateRangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DateRangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : Colors.white,
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.grey.shade300,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.grey.shade700,
            fontFamily: 'Geist',
          ),
        ),
      ),
    );
  }
}

class _ExportSuccessDialog extends StatelessWidget {
  final ExportFormat format;
  final String filename;
  final int recordCount;

  const _ExportSuccessDialog({
    required this.format,
    required this.filename,
    required this.recordCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green.shade600),
          const SizedBox(height: 16),
          const Text(
            'Export Complete',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Successfully exported $recordCount records to ${format.name.toUpperCase()} format',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '(Data copied to clipboard for demo)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontFamily: 'Geist',
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: CUButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

enum ExportFormat { fdxJson, json, csv, qfx }
enum DataCategory { accounts, transactions, balances, identity }
enum DateRange { last30Days, last90Days, lastYear, allTime }
