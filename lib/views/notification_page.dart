import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ybs/data/app_data.dart';
import 'package:ybs/models/message.dart';
import 'package:ybs/views/read_message.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  Set<String> categories = {};
  int selectedIndex = 0;

  List<Message> messages = [];
  List<Message> filterMessages = [];

  filterMessage() {
    filterMessages.clear();
    if (selectedIndex == 0) {
      filterMessages = List.generate(
        messages.length,
        (index) => messages[index],
      );
    } else {
      filterMessages = messages
          .where((e) => e.category == categories.elementAt(selectedIndex))
          .toList();
    }
    setState(() {});
  }

  deleteMessage(int id) {
    messages.removeWhere((e) => e.id == id);
    loadCategory();
    filterMessage();
  }

  loadCategory() {
    categories.clear();
    selectedIndex = 0;
    categories.add("All");
    for (var i in messages) {
      categories.add(i.category);
    }
    if (categories.length == 1) {
      categories.clear();
    }
  }

  loadMessage() {
    categories.clear();
    messages = AppData.testMessages;
    filterMessages = List.generate(messages.length, (index) => messages[index]);
    loadCategory();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          "Notification",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SizedBox(
        width: double.infinity,
        child: messages.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 20,
                children: [
                  Icon(Icons.notifications_none, size: 90, color: Colors.grey),
                  SizedBox(
                    width: 300,
                    child: Text(
                      "Notification will appear here. Get Notified about bus route changes, delays, or important updates.",
                      textAlign: TextAlign.center,
                      style: TextStyle(height: 1.5, color: Colors.grey),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 40,
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () {
                          selectedIndex = index;
                          filterMessage();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          margin: EdgeInsets.only(right: 5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: index == selectedIndex
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(categories.elementAt(index)),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filterMessages.length,
                      itemBuilder: (context, index) => Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Icon(
                                    Icons.notifications_none,
                                    size: 40,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: Row(
                                          spacing: 5,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                filterMessages[index].title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              DateFormat("dd.MM.yy").format(
                                                filterMessages[index].dateTime,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: double.infinity,
                                        child: Text(
                                          filterMessages[index].text,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              spacing: 10,
                              children: [
                                Expanded(
                                  child: MaterialButton(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                      side: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                    onPressed: () {
                                      deleteMessage(filterMessages[index].id);
                                    },
                                    child: Text("Delete"),
                                  ),
                                ),
                                Expanded(
                                  child: MaterialButton(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                      side: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ReadMessage(
                                            message: filterMessages[index],
                                          ),
                                        ),
                                      ).then((value) {
                                        if (value == true) {
                                          deleteMessage(
                                            filterMessages[index].id,
                                          );
                                        }
                                      });
                                    },
                                    child: Text("Read"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
