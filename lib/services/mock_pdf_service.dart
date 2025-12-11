import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class MockPdfService {
  /// Generates a mock contract PDF based on template type and form data
  ///
  /// [templateType] - One of: FRIENDLY_LOAN, BILL_SPLIT, ITEM_BORROW,
  ///                   VEHICLE_USE, FREELANCE_JOB, SALE_DEPOSIT
  /// [formData] - Map containing form field values (varies by template)
  ///
  /// Returns PDF as Uint8List bytes
  /// [includeSignatures] - If false, shows preview mode without signatures
  /// [creatorSignature] - Optional Uint8List of creator's signature image (PNG bytes)
  /// [accepteeSignature] - Optional Uint8List of acceptee's signature image (PNG bytes)
  /// [contractId] - Optional contract ID to display in PDF (if not provided, generates one)
  /// [creatorSignatureTimestamp] - Optional timestamp for creator signature
  /// [accepteeSignatureTimestamp] - Optional timestamp for acceptee signature
  /// [accepteeName] - Optional name of the acceptee (borrower/buyer/provider)
  /// [accepteeIc] - Optional IC number of the acceptee
  static Future<Uint8List> generateMockContractPdf(
    String templateType,
    Map<String, dynamic> formData, {
    bool includeSignatures = true,
    Uint8List? creatorSignature,
    Uint8List? accepteeSignature,
    String? contractId,
    DateTime? creatorSignatureTimestamp,
    DateTime? accepteeSignatureTimestamp,
    String? accepteeName,
    String? accepteeIc,
  }) async {
    // Create a copy of formData to avoid modifying the original
    Map<String, dynamic> processedFormData =
        Map<String, dynamic>.from(formData);

    // For ITEM_BORROW, map contractDueDate to returnDate if returnDate is not present
    if (templateType.toUpperCase() == 'ITEM_BORROW') {
      if (!processedFormData.containsKey('returnDate') ||
          processedFormData['returnDate'] == null ||
          processedFormData['returnDate'].toString().isEmpty) {
        // Use contractDueDate as returnDate
        if (processedFormData.containsKey('contractDueDate') &&
            processedFormData['contractDueDate'] != null &&
            processedFormData['contractDueDate'].toString().isNotEmpty) {
          processedFormData['returnDate'] =
              processedFormData['contractDueDate'];
        }
      }
    }

    // Initialize terms and breach text variables
    String termsText = '';
    String breachText = '';

    // Switch logic based on template type
    switch (templateType.toUpperCase()) {
      case 'FRIENDLY_LOAN':
        termsText = _replacePlaceholders(
          "The Lender agrees to provide a principal sum of RM{{amount}} to the Borrower for the purpose of {{purpose}}. The Borrower agrees to repay this sum in full on or before {{date}}. This loan is provided without interest based on mutual trust.",
          processedFormData,
        );
        breachText = _replacePlaceholders(
          "If the Borrower fails to repay the full outstanding amount by the deadline, the Borrower shall be liable to pay a one-time late penalty of RM50 in addition to the principal sum. The Lender reserves the right to use this signed digital record to pursue debt recovery.",
          processedFormData,
        );
        break;

      case 'BILL_SPLIT':
        termsText = _replacePlaceholders(
          "The Borrower acknowledges a debt of RM{{share}} owed to the Lender, representing their share of the total expense for {{description}} (Total: RM{{total}}) which was paid in advance by the Lender. The Borrower agrees to settle this debt by {{date}}.",
          processedFormData,
        );
        breachText = _replacePlaceholders(
          "Failure by the Borrower to settle this acknowledged debt by the Due Date constitutes a breach of promise. This digital record serves as formal proof of debt for any subsequent recovery action.",
          processedFormData,
        );
        break;

      case 'ITEM_BORROW':
        termsText = _replacePlaceholders(
          "The Lender temporarily hands over possession of {{item}} (Condition: {{condition}}) to the Borrower. The Borrower agrees to return the item in the same condition on or before {{returnDate}}.",
          processedFormData,
        );
        breachText = _replacePlaceholders(
          "Late Return: A penalty of RM20 per day will be charged. Damage/Loss: If the item is lost or damaged, the Borrower agrees to pay the Lender the full Replacement Value of RM{{value}} within 7 days.",
          processedFormData,
        );
        break;

      case 'VEHICLE_USE':
        termsText = _replacePlaceholders(
          "The Owner grants temporary use of vehicle {{model}}, plate number {{plate}}, to the Borrower from {{startDate}} until {{endDate}}.",
          processedFormData,
        );
        breachText = _replacePlaceholders(
          "The Borrower accepts full financial responsibility for traffic summons (SAMAN), fuel costs as per the '{{fuel}}' agreement, and any damages or insurance excesses incurred due to negligence.",
          processedFormData,
        );
        break;

      case 'FREELANCE_JOB':
        termsText = _replacePlaceholders(
          "The Client engages the Provider to complete: {{task}}, by {{deadline}}. Total price: RM{{price}}. Deposit received: RM{{deposit}}.",
          processedFormData,
        );
        breachText = _replacePlaceholders(
          "Provider Breach: Failure to deliver allows Client to demand full refund. Client Breach: Failure to pay balance after delivery constitutes a formal debt.",
          processedFormData,
        );
        break;

      case 'SALE_DEPOSIT':
        termsText = _replacePlaceholders(
          "Seller acknowledges receipt of RM{{deposit}} deposit from Buyer to secure purchase of {{item}} (Total Price: RM{{price}}). Balance due by {{dueDate}}.",
          processedFormData,
        );
        breachText = _replacePlaceholders(
          "Buyer Breach: Failure to pay balance results in forfeiture of deposit. Seller Breach: Selling to another party requires full refund of deposit plus RM50 penalty.",
          processedFormData,
        );
        break;

      default:
        termsText = "Invalid template type specified.";
        breachText = "Please contact support.";
    }

    // Generate PDF with standard legal layout
    return _buildPdfDocument(
      termsText,
      breachText,
      includeSignatures,
      creatorSignature,
      accepteeSignature,
      contractId: contractId,
      creatorSignatureTimestamp: creatorSignatureTimestamp,
      accepteeSignatureTimestamp: accepteeSignatureTimestamp,
      accepteeName: accepteeName,
      accepteeIc: accepteeIc,
    );
  }

  /// Replaces placeholders in text with form data values
  static String _replacePlaceholders(
      String text, Map<String, dynamic> formData) {
    String result = text;
    formData.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value.toString());
    });
    return result;
  }

  /// Builds the PDF document with standard legal layout
  static Future<Uint8List> _buildPdfDocument(
    String termsText,
    String breachText,
    bool includeSignatures,
    Uint8List? creatorSignature,
    Uint8List? accepteeSignature, {
    String? contractId,
    DateTime? creatorSignatureTimestamp,
    DateTime? accepteeSignatureTimestamp,
    String? accepteeName,
    String? accepteeIc,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    // Generate contract ID if not provided
    final displayContractId = contractId ??
        'CNT-${now.millisecondsSinceEpoch.toString().substring(7)}';

    // Use provided timestamps or current time as fallback
    final creatorTimestamp = creatorSignatureTimestamp ?? now;
    final accepteeTimestamp =
        accepteeSignatureTimestamp ?? (accepteeSignature != null ? now : null);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(50),
        build: (pw.Context context) {
          return [
            // Header: PERJANJIAN DIGITAL
            pw.Header(
              level: 0,
              child: pw.Center(
                child: pw.Text(
                  'PERJANJIAN DIGITAL',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ),
            ),
            pw.SizedBox(height: 30),

            // Part A: Hardcoded Identities
            pw.Text(
              'PARTIES TO THIS AGREEMENT',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'LENDER/OWNER/SELLER/CLIENT:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Name: SpongeBob bin Squarepants',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.Text(
                        'IC: 123456-12-1234',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Always show borrower/buyer section (with values if signed, blank if not)
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BORROWER/BUYER/PROVIDER:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        accepteeName != null && accepteeName.isNotEmpty
                            ? 'Name: $accepteeName'
                            : 'Name:',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.Text(
                        accepteeIc != null && accepteeIc.isNotEmpty
                            ? 'IC: $accepteeIc'
                            : 'IC:',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Part B: Terms Text
            pw.Text(
              'TERMS AND CONDITIONS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              termsText,
              style: const pw.TextStyle(fontSize: 11),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 20),

            // Part C: Breach Text
            pw.Text(
              'BREACH OF AGREEMENT',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              breachText,
              style: const pw.TextStyle(fontSize: 11),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 30),

            // Part D: Electronic Commerce Act Legal Notice
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey700, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'LEGAL NOTICE',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'This digital contract is executed in accordance with the Electronic Commerce Act 2006 (Act 658) of Malaysia. '
                    'The digital signatures affixed to this document are legally binding and equivalent to handwritten signatures. '
                    'This document has been timestamped and cryptographically secured. Any tampering with this document will be '
                    'detectable and may result in legal consequences.',
                    style: const pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.justify,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Footer: Execution Record with Timestamps
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Text(
              'EXECUTION RECORD',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            if (includeSignatures) ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Lender Signature:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      if (creatorSignature != null)
                        pw.Image(
                          pw.MemoryImage(creatorSignature),
                          width: 100,
                          height: 40,
                        )
                      else
                        pw.Container(
                          width: 100,
                          height: 40,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey400),
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              '[Signature]',
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ),
                        ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'SpongeBob bin Squarepants',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'IC: 123456-12-1234',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      if (creatorSignature != null)
                        pw.Text(
                          'Signed: ${_formatDateTime(creatorTimestamp)}',
                          style: const pw.TextStyle(fontSize: 9),
                        )
                      else
                        pw.Text(
                          'Signed: [Pending]',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  // Always show borrower signature section (blank if not signed)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Borrower Signature:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      if (accepteeSignature != null)
                        pw.Image(
                          pw.MemoryImage(accepteeSignature),
                          width: 100,
                          height: 40,
                        )
                      else
                        pw.Container(
                          width: 100,
                          height: 40,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey400),
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              '[Pending Signature]',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.grey600,
                                fontStyle: pw.FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      pw.SizedBox(height: 5),
                      if (accepteeSignature != null) ...[
                        pw.Text(
                          accepteeName ?? 'Siti Sarah binti Ahmad',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          accepteeIc != null && accepteeIc.isNotEmpty
                              ? 'IC: $accepteeIc'
                              : 'IC: 950505-08-5678',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        if (accepteeTimestamp != null)
                          pw.Text(
                            'Signed: ${_formatDateTime(accepteeTimestamp)}',
                            style: const pw.TextStyle(fontSize: 9),
                          )
                        else
                          pw.Text(
                            'Signed: [Pending]',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey600,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                      ] else ...[
                        pw.Text(
                          accepteeName != null && accepteeName.isNotEmpty
                              ? accepteeName
                              : 'Name:',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          accepteeIc != null && accepteeIc.isNotEmpty
                              ? 'IC: $accepteeIc'
                              : 'IC:',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          'Signed: [Pending]',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ] else ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Lender Signature:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        '[Pending Signature]',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Borrower Signature:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        '[Pending Signature]',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                'Contract ID: $displayContractId',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Formats DateTime to readable string
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
