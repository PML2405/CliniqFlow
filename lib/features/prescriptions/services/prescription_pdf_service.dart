import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/prescription.dart';

/// Service for generating PDF documents from prescriptions
class PrescriptionPdfService {
  /// Generate a PDF document for a prescription
  Future<Uint8List> generatePrescriptionPdf(Prescription prescription) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              pw.SizedBox(height: 30),
              _buildPatientInfo(prescription),
              pw.SizedBox(height: 20),
              _buildPrescriptionDetails(prescription),
              pw.SizedBox(height: 30),
              _buildMedicationTable(prescription.items),
              pw.Spacer(),
              _buildFooter(prescription),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'CliniqFlow Dental Clinic',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Medical Prescription',
          style: pw.TextStyle(
            fontSize: 16,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Divider(thickness: 2),
      ],
    );
  }

  pw.Widget _buildPatientInfo(Prescription prescription) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Patient Information',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Name:', prescription.patientName),
                  pw.SizedBox(height: 4),
                  _buildInfoRow('Patient UID:', prescription.patientUid),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    'Date:',
                    DateFormat.yMMMd().format(prescription.prescriptionDate),
                  ),
                  pw.SizedBox(height: 4),
                  if (prescription.caseSheetId != null)
                    _buildInfoRow('Case Sheet:', prescription.caseSheetId!),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPrescriptionDetails(Prescription prescription) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildInfoRow('Prescribed by:', prescription.doctorName),
        _buildInfoRow(
          'Prescription Date:',
          DateFormat.yMMMd().format(prescription.prescriptionDate),
        ),
      ],
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          value,
          style: const pw.TextStyle(
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildMedicationTable(List<PrescriptionItem> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Medications',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: {
            0: const pw.FixedColumnWidth(30),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              children: [
                _buildTableCell('#', isHeader: true),
                _buildTableCell('Drug Name', isHeader: true),
                _buildTableCell('Dosage', isHeader: true),
                _buildTableCell('Frequency', isHeader: true),
                _buildTableCell('Duration', isHeader: true),
              ],
            ),
            // Data rows
            ...items.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final item = entry.value;
              return pw.TableRow(
                children: [
                  _buildTableCell('$index'),
                  _buildTableCell(item.drugName),
                  _buildTableCell(item.dosage),
                  _buildTableCell(item.frequency),
                  _buildTableCell(item.duration),
                ],
              );
            }),
          ],
        ),
        // Notes section
        ...items.where((item) => item.notes != null && item.notes!.isNotEmpty).map(
          (item) {
            final index = items.indexOf(item) + 1;
            return pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '[$index] Notes: ',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      item.notes!,
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildFooter(Prescription prescription) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Doctor\'s Signature',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Container(
                  width: 150,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.grey700),
                    ),
                  ),
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text(
                      prescription.doctorName,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Generated by CliniqFlow',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Date: ${DateFormat.yMMMd().add_jm().format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
