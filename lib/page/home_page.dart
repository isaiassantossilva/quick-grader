import 'package:flutter/material.dart';
import 'package:quick_grader/page/exam_list_page.dart';
import 'package:quick_grader/page/more_page.dart';
import 'package:quick_grader/page/student_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [ExamListPage(), StudentListPage(), MorePage()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 0,
        currentIndex: _selectedIndex,
        selectedFontSize: 12.0,
        unselectedFontSize: 12.0,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Provas',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Alunos'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Mais'),
        ],
      ),
    );
  }
}
