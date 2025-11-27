import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final file = File('assets/data/questions.json');
  if (!file.existsSync()) {
    print('File not found');
    return;
  }

  final content = await file.readAsString();
  final List<dynamic> data = json.decode(content);

  final historyQuestions = <String>[];
  final religionQuestions = <String>[];

  final religionKeywords = [
    'نبي', 'رسول', 'الله', 'قرآن', 'سورة', 'آية', 'إسلام', 'صلاة', 'زكاة', 'حج', 'صوم',
    'كعبة', 'مكة', 'صحابي', 'إنجيل', 'توراة', 'مسيح', 'موسى', 'عيسى', 'محمد', 'إبراهيم',
    'نوح', 'يوسف', 'يونس', 'آدم', 'حواء', 'جنة', 'نار', 'يوم القيامة', 'ملائكة', 'جن',
    'شيطان', 'مسجد', 'كنيسة', 'غزوة', 'خديجة', 'عائشة', 'أبو بكر', 'عمر بن الخطاب',
    'عثمان بن عفان', 'علي بن أبي طالب', 'خلق', 'سفر', 'خلفاء', 'راشدين'
  ];

  for (var item in data) {
    if (item['category'] == 'history_religion') {
      final question = item['question'] as String;
      bool isReligion = false;
      for (var keyword in religionKeywords) {
        if (question.contains(keyword)) {
          isReligion = true;
          break;
        }
      }

      if (isReligion) {
        religionQuestions.add(question);
      } else {
        historyQuestions.add(question);
      }
    }
  }

  final output = {
    'history': historyQuestions,
    'religion': religionQuestions,
  };

  final outputFile = File('split_questions_export.json');
  await outputFile.writeAsString(json.encode(output));
  
  print('✅ Exported split questions to ${outputFile.absolute.path}');
  print('   History: ${historyQuestions.length}');
  print('   Religion: ${religionQuestions.length}');
}
