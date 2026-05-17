import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CertificateService {
  static Future<void> generateAndDownload({
    required BuildContext context,
    required String courseTitle,
    required String courseCategory,
  }) async {
    try {
      // Get student name from Firestore
      final uid = FirebaseAuth.instance.currentUser?.uid;
      String studentName = 'Student';
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        studentName = doc.data()?['name']?.toString() ?? 'Student';
      }

      final completionDate = DateTime.now();
      final dateStr =
          '${completionDate.day}/${completionDate.month}/${completionDate.year}';

      // Build PDF
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (pw.Context ctx) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColor.fromHex('#0E7C86'),
                  width: 8,
                ),
              ),
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'CERTIFICATE OF COMPLETION',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#0E7C86'),
                    ),
                  ),
                  pw.SizedBox(height: 24),
                  pw.Text(
                    'This is to certify that',
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    studentName,
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'has successfully completed the course',
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    courseTitle,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#0E7C86'),
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Category: $courseCategory',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 32),
                  pw.Text(
                    'Date of Completion: $dateStr',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Divider(color: PdfColor.fromHex('#0E7C86')),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Online Learning Hub',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#0E7C86'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Show print/save dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Certificate_${courseTitle.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate certificate: $e')),
        );
      }
    }
  }
}
