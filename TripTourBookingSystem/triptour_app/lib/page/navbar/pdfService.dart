import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static String _safeText(dynamic value) {
    if (value == null) return '-';
    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  static Future<void> generateAndPrintMemberPdf(
    Map<String, dynamic> data,
  ) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.sarabunRegular();
    final fontBold = await PdfGoogleFonts.sarabunBold();

    final firstName = _safeText(data['first_name']);
    final lastName = _safeText(data['last_name']);
    final fullName = (firstName == '-' && lastName == '-')
        ? 'ไม่ระบุชื่อ'
        : '${firstName == '-' ? '' : firstName} ${lastName == '-' ? '' : lastName}'
              .trim();

    final displayName = fullName.isEmpty ? 'ไม่ระบุชื่อ' : fullName;
    final sectionTitle = pw.TextStyle(
      font: fontBold,
      fontSize: 16,
      color: PdfColors.green900,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(18),
              decoration: pw.BoxDecoration(
                color: PdfColors.green900,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(14)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'รายงานข้อมูลลูกทัวร์',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 22,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    displayName,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.green200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ข้อมูลส่วนตัว', style: sectionTitle),
                  pw.SizedBox(height: 10),
                  _buildRow('ชื่อ-นามสกุล', displayName, font, fontBold),
                  _buildRow('อีเมล', _safeText(data['email']), font, fontBold),
                  _buildRow(
                    'เบอร์โทรศัพท์',
                    _safeText(data['phone']),
                    font,
                    fontBold,
                  ),
                  _buildRow('เพศ', _safeText(data['gender']), font, fontBold),
                  _buildRow(
                    'วันเกิด',
                    _safeText(data['birthday']),
                    font,
                    fontBold,
                  ),
                  _buildRow(
                    'ที่อยู่',
                    _safeText(data['address']),
                    font,
                    fontBold,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.green200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ข้อมูลสุขภาพ & ข้อควรระวัง', style: sectionTitle),
                  pw.SizedBox(height: 10),
                  _buildRow(
                    'โรคประจำตัว',
                    _safeText(data['congenital_disease']),
                    font,
                    fontBold,
                  ),
                  _buildRow(
                    'ยาที่ต้องพกพา',
                    _safeText(data['medicine']),
                    font,
                    fontBold,
                  ),
                  _buildRow(
                    'ประวัติการแพ้',
                    _safeText(data['allergic_list']),
                    font,
                    fontBold,
                  ),
                  _buildRow(
                    'เพิ่มเติม',
                    _safeText(data['others']),
                    font,
                    fontBold,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.green200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('เอกสารประจำตัว', style: sectionTitle),
                  pw.SizedBox(height: 10),
                  _buildRow(
                    'เลขประจำตัว / พาสปอร์ต',
                    _safeText(data['number_id']),
                    font,
                    fontBold,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'วันที่พิมพ์: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Member_${data['member_id'] ?? 'Detail'}.pdf',
    );
  }

  static pw.Widget _buildRow(
    String label,
    String value,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 11,
                color: PdfColors.grey800,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: font,
                fontSize: 11,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> generateAndPrintMemberName(Map<String, dynamic> data) async {
  final pdf = pw.Document();

  // โหลดฟอนต์ภาษาไทยสำหรับ PDF
  final fontBold = await PdfGoogleFonts.sarabunBold();

  final fullName = "${data['first_name'] ?? ''} ${data['last_name'] ?? ''}"
      .trim();
  final displayName = fullName.isEmpty ? "ไม่ระบุชื่อ" : fullName;

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Text(
            displayName,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 36, // ปรับขนาดตัวอักษรให้ใหญ่ชัดเจน
            ),
            textAlign: pw.TextAlign.center,
          ),
        );
      },
    ),
  );

  // เรียกหน้าต่างพิมพ์ PDF
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
    name: 'Member_Name_${data['member_id'] ?? 'Detail'}.pdf',
  );
}

Future<void> generateAndPrintAllMembersPdf(
  List<Map<String, dynamic>> membersList,
) async {
  final pdf = pw.Document();

  final fontRegular = await PdfGoogleFonts.sarabunRegular();
  final fontBold = await PdfGoogleFonts.sarabunBold();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return [
          pw.Center(
            child: pw.Text(
              "รายชื่อและข้อมูลสมาชิกทั้งหมดในทริป",
              style: pw.TextStyle(font: fontBold, fontSize: 18),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              "จำนวนสมาชิกทั้งหมด: ${membersList.length} คน",
              style: pw.TextStyle(font: fontRegular, fontSize: 12),
            ),
          ),
          pw.SizedBox(height: 16),

          // ตารางสรุปรายชื่อ
          pw.TableHelper.fromTextArray(
            headers: [
              'ลำดับ',
              'ชื่อ-นามสกุล',
              'อีเมล',
              'เบอร์โทรศัพท์',
              'ประวัติการแพ้/โรคประจำตัว',
              'ตำแหน่ง',
            ],
            data: List.generate(membersList.length, (index) {
              final m = membersList[index];
              final fullName =
                  "${m['first_name'] ?? ''} ${m['last_name'] ?? ''}".trim();
              final email = m['email'] ?? '-';
              final phone = m['phone'] ?? '-';
              final allergy =
                  (m['allergic_list'] != null &&
                      m['allergic_list'].toString().trim().isNotEmpty)
                  ? m['allergic_list']
                  : '-';
              final role = (m['role'] == 'guide') ? 'ไกด์' : 'ลูกทัวร์';

              return [
                '${index + 1}',
                fullName.isEmpty ? 'ไม่ระบุชื่อ' : fullName,
                email,
                phone,
                allergy,
                role,
              ];
            }),
            headerStyle: pw.TextStyle(font: fontBold, fontSize: 11),
            cellStyle: pw.TextStyle(font: fontRegular, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.center,
            },
          ),
        ];
      },
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
    name: 'All_Members_List.pdf',
  );
}
