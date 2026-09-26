import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:caisse_dz/Services/ExportStorage.dart';

class ExcelPreviewDialog extends StatefulWidget {
  final List<List<dynamic>> data;
  final List<String> headers;
  final String title;
  final AppLocalizations l10n;
  final File? excelFile;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback onCancel;

  const ExcelPreviewDialog({
    Key? key,
    required this.data,
    required this.headers,
    required this.title,
    required this.l10n,
    this.excelFile,
    this.onSave,
    this.onShare,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<ExcelPreviewDialog> createState() => _ExcelPreviewDialogState();
}

class _ExcelPreviewDialogState extends State<ExcelPreviewDialog> {
  int _currentPage = 0;
  int _rowsPerPage = 20;
  late int _totalPages;
  TextEditingController _pageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _totalPages = (widget.data.length / _rowsPerPage).ceil();
    _pageController.text = (_currentPage + 1).toString();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page.clamp(0, _totalPages - 1);
      _pageController.text = (_currentPage + 1).toString();
    });
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _goToPage(_currentPage + 1);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _goToPage(_currentPage - 1);
    }
  }

  Future<void> _saveExcel() async {
    if (widget.excelFile != null) {
      try {
        final directory = await getExportDirectory();
        final fileName = '${widget.title}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        final newFile = File('${directory.path}/$fileName');
        await widget.excelFile!.copy(newFile.path);

        if (widget.onSave != null) {
          widget.onSave!();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.l10n.exportSuccess}: ${newFile.path}'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: widget.l10n.open,
                onPressed: () => OpenFile.open(newFile.path),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.l10n.saveError}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _shareExcel() async {
    if (widget.excelFile != null) {
      try {
        if (widget.onShare != null) {
          widget.onShare!();
        }

        await Share.shareXFiles(
          [XFile(widget.excelFile!.path)],
          text: widget.l10n.exportCompleted,
          subject: widget.title,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.l10n.shareError}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, widget.data.length);
    final pageData = widget.data.sublist(startIndex, endIndex);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 1200,
        height: 800,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.table_chart, color: Colors.green, size: 28),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: Appstyle.textLB.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    widget.onCancel();
                  },
                ),
              ],
            ),
            const Divider(),

            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.l10n.totalRecords}: ${widget.data.length} | ${widget.l10n.page} ${_currentPage + 1}/${_totalPages}',
                    style: Appstyle.textSB.copyWith(
                      color: Colors.green,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.first_page, size: 20),
                          onPressed: _currentPage > 0 ? () => _goToPage(0) : null,
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_left, size: 20),
                          onPressed: _currentPage > 0 ? _previousPage : null,
                        ),
                        SizedBox(
                          width: 50,
                          child: TextField(
                            controller: _pageController,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            onSubmitted: (value) {
                              int? page = int.tryParse(value);
                              if (page != null && page >= 1 && page <= _totalPages) {
                                _goToPage(page - 1);
                              } else {
                                _pageController.text = (_currentPage + 1).toString();
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right, size: 20),
                          onPressed: _currentPage < _totalPages - 1 ? _nextPage : null,
                        ),
                        IconButton(
                          icon: Icon(Icons.last_page, size: 20),
                          onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_totalPages - 1) : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Appstyle.grisC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: _buildDataTable(pageData),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.l10n.rowsPerPage}:',
                  style: Appstyle.textSB,
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _rowsPerPage,
                  items: [10, 20, 50, 100].map((value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _rowsPerPage = value;
                        _totalPages = (widget.data.length / _rowsPerPage).ceil();
                        _currentPage = 0;
                        _pageController.text = '1';
                      });
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MainButton(
                  text: widget.l10n.cancel,
                  color: Appstyle.gris,
                  icon: Icons.cancel,
                  onPressed: () {
                    widget.onCancel();
                  },
                ),
                const SizedBox(width: 10),
                if (widget.excelFile != null)
                  MainButton(
                    text: widget.l10n.save,
                    color: Colors.green,
                    icon: Icons.save,
                    onPressed: _saveExcel,
                  ),
                const SizedBox(width: 10),
                if (widget.excelFile != null)
                  MainButton(
                    text: widget.l10n.share,
                    color: Colors.orange,
                    icon: Icons.share,
                    onPressed: _shareExcel,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(List<List<dynamic>> data) {
    return DataTable(
      columnSpacing: 20,
      headingRowColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) => Colors.green.withOpacity(0.1),
      ),
      headingTextStyle: Appstyle.textSB.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
      dataRowColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.green.withOpacity(0.2);
          }
          return null;
        },
      ),
      columns: widget.headers.map((header) {
        return DataColumn(
          label: Container(
            width: 150,
            child: Text(
              header,
              overflow: TextOverflow.ellipsis,
              style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
      rows: data.map((row) {
        return DataRow(
          cells: List.generate(row.length, (index) {
            String value = row[index]?.toString() ?? '-';
            return DataCell(
              Container(
                width: 150,
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: Appstyle.textXSB,
                ),
              ),
            );
          }),
        );
      }).toList(),
    );
  }
}