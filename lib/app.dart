import 'package:flutter/material.dart';
import 'package:quick_grader/config/app_routes.dart';
import 'package:quick_grader/page/answer_sheet_generation_page.dart';
import 'package:quick_grader/page/edit_answer_key_page.dart';
import 'package:quick_grader/page/exam_scanned_page.dart';
import 'package:quick_grader/page/extracted_answer_keys_page.dart';
import 'package:quick_grader/page/grade_list_page.dart';
import 'package:quick_grader/page/student_selection_page.dart';
import 'package:quick_grader/page/exam_scan_page.dart';
import 'package:quick_grader/page/exam_details_page.dart';
import 'package:quick_grader/page/exam_form_page.dart';
import 'package:quick_grader/page/home_page.dart';
import 'package:quick_grader/page/student_form_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: "Roboto",
          useMaterial3: true,
          primaryColor: Color.fromRGBO(55, 152, 55, 1),
          primarySwatch: Colors.green,
          scaffoldBackgroundColor: Color.fromRGBO(247, 251, 241, 1),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color.fromRGBO(55, 152, 55, 1),
            error: Colors.red,
          ),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            backgroundColor: Color.fromRGBO(55, 152, 55, 1),
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: Color.fromRGBO(55, 152, 55, 1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ),
          textTheme: TextTheme(
            bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            headlineLarge: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        routes: {
          AppRoutes.home: (_) => HomePage(),
          AppRoutes.examForm: (_) => ExamFormPage(),
          AppRoutes.examDetails: (_) => ExamDetailsPage(),
          AppRoutes.editAnswerKeys: (_) => EditAnswerKeyPage(),
          AppRoutes.answerSheetGeneration: (_) => AnswerSheetGenerationPage(),
          AppRoutes.examScan: (_) => ExamScanPage(),
          AppRoutes.examScanned: (_) => ExamScannedPage(),
          AppRoutes.extractedAnswerKeys: (_) => ExamExtractedAnswerKeysPage(),
          AppRoutes.studentForm: (_) => StudentFormPage(),
          AppRoutes.gradeList: (_) => GradeListPage(),
          AppRoutes.studentSelection: (_) => StudentSelectionPage(),
        },
      ),
    );
  }
}
