import 'package:flutter/material.dart';
import 'package:quick_grader/utils/camera_processing.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mais')),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: ListView(
          children: [
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
              title: Text("Instruções"),
              trailing: Icon(Icons.keyboard_arrow_right),
              onTap: () {},
            ),

            Divider(height: 1, color: Colors.grey.shade300),

            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
              title: Text("Sobre"),
              trailing: Icon(Icons.keyboard_arrow_right),
              onTap: () async {
                // await DB.instance.delete();
              },
            ),

            /*
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
              title: Text("Deletar banco"),
              trailing: Icon(Icons.keyboard_arrow_right),
              onTap: () async {
                // await DB.instance.delete();
              },
            ),

            Divider(height: 1, color: Colors.grey.shade300),

            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
              title: Text("Camera"),
              trailing: Icon(Icons.keyboard_arrow_right),
              onTap: () async {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => CameraProcessing()));
              },
            ),
            */
          ],
        ),
      ),
    );
  }
}
