import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateAndPrintMemberPdf(
    Map<String, dynamic> data,
  ) async {
    final pdf = pw.Document();

    // โหลดฟอนต์ภาษาไทยรองรับการแสดงผล
    final font = await PdfGoogleFonts.sarabunRegular();
    final fontBold = await PdfGoogleFonts.sarabunBold();

    final fullName = "${data['first_name'] ?? ''} ${data['last_name'] ?? ''}"
        .trim();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // หัวข้อเอกสาร
                pw.Center(
                  child: pw.Text(
                    "รายงานข้อมูลลูกทัวร์",
                    style: pw.TextStyle(font: fontBold, fontSize: 22),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),

                // ข้อมูลส่วนตัว
                pw.Text(
                  "ข้อมูลส่วนตัว",
                  style: pw.TextStyle(font: fontBold, fontSize: 16),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  "ชื่อ-นามสกุล: ${fullName.isEmpty ? '-' : fullName}",
                  style: pw.TextStyle(font: font),
                ),
                pw.Text(
                  "อีเมล: ${data['email'] ?? '-'}",
                  style: pw.TextStyle(font: font),
                ),
                pw.Text(
                  "เบอร์โทรศัพท์: ${data['phone'] ?? '-'}",
                  style: pw.TextStyle(font: font),
                ),
                pw.Text(
                  "เพศ: ${data['gender'] ?? '-'} | วันเกิด: ${data['birthday'] ?? '-'}",
                  style: pw.TextStyle(font: font),
                ),
                pw.Text(
                  "ที่อยู่: ${data['address'] ?? '-'}",
                  style: pw.TextStyle(font: font),
                ),

                pw.SizedBox(height: 16),
                pw.Divider(),

                // ข้อมูลสุขภาพ
                pw.Text(
                  "ข้อมูลสุขภาพ & ข้อควรระวัง",
                  style: pw.TextStyle(font: fontBold, fontSize: 16),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  "โรคประจำตัว: ${data['congenital_disease'] ?? '-'}",
                  style: pw.TextStyle(font: font),
                ),
                pw.Text(
                  "ยาที่ต้องพกพา: ${data['medicine'] ?? '-'}",
                  style: pw.TextStyle(font: font),
                ),
                pw.Text(
                  "ประวัติการแพ้: ${data['allergic_list'] ?? '-'}",
                  style: pw.TextStyle(font: font),
                ),
                pw.Text(
                  "เพิ่มเติม: ${data['others'] ?? '-'}",
                  style: pw.TextStyle(font: font),
                ),

                pw.SizedBox(height: 16),
                pw.Divider(),

                // เอกสารประจำตัว
                pw.Text(
                  "เอกสารประจำตัว",
                  style: pw.TextStyle(font: fontBold, fontSize: 16),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  "เลขประจำตัว / พาสปอร์ต: ${data['number_id'] ?? '-'}",
                  style: pw.TextStyle(font: font),
                ),
              ],
            ),
          );
        },
      ),
    );

    // เปิดหน้า Preview สำหรับสั่งพิมพ์ หรือบันทึกเป็น PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Member_${data['member_id'] ?? 'Detail'}.pdf',
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
              'เบอร์โทรศัพท์',
              'ประวัติการแพ้/โรคประจำตัว',
              'ตำแหน่ง',
            ],
            data: List.generate(membersList.length, (index) {
              final m = membersList[index];
              final fullName =
                  "${m['first_name'] ?? ''} ${m['last_name'] ?? ''}".trim();
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
