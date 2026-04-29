import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class TaskPage extends StatefulWidget {
  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  List<ParseObject> tasks = [];
  List<ParseObject> filteredTasks = [];
  Set<String> expandedTasks = {};

  bool isLoading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<ParseUser?> getCurrentUser() async {
    return await ParseUser.currentUser() as ParseUser?;
  }

  Future<void> logout() async {
    final user = await getCurrentUser();
    await user?.logout();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/', //
          (route) => false,
    );
  }

  Future<bool> confirmLogout() async {
    return await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Logout"),
        content: Text("Do you want to logout?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Logout")),
        ],
      ),
    ) ??
        false;
  }

  Color getCardColor(String status) {
    switch (status) {
      case "Pending":
        return Colors.red.shade100;
      case "InProgress":
        return Colors.yellow.shade100;
      case "Done":
        return Colors.green.shade100;
      default:
        return Colors.white;
    }
  }

  void applyFilters() {
    List<ParseObject> temp = [...tasks];

    if (searchQuery.isNotEmpty) {
      temp = temp.where((task) {
        final name = task.get<String>('TaskName')?.toLowerCase() ?? "";
        return name.contains(searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      filteredTasks = temp;
    });
  }

  Future<void> fetchTasks() async {
    setState(() => isLoading = true);

    final user = await getCurrentUser();

    final query = QueryBuilder<ParseObject>(ParseObject('Task'))
      ..whereEqualTo('user', user);

    final response = await query.query();

    if (response.success && response.results != null) {
      tasks = response.results as List<ParseObject>;
      applyFilters();
    } else {

      if (response.error?.code == 209) {
        await logout();
        return;
      }

      showMessage("Failed to fetch tasks");
    }

    setState(() => isLoading = false);
  }

  Future<void> updateStatus(ParseObject task, String status) async {
    task.set('Status', status);
    await task.save();
    fetchTasks();
    showMessage("Marked as $status");
  }

  Future<void> deleteTask(ParseObject task) async {
    await task.delete();
    setState(() {
      tasks.remove(task);
      filteredTasks.remove(task);
    });
    showMessage("Task deleted");
  }

  Future<bool> confirmDelete(ParseObject task) async {
    return await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete Task?"),
        content: Text("Are you sure?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("No")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Yes")),
        ],
      ),
    ) ??
        false;
  }

  void showEditDialog(ParseObject task) {
    final nameController =
    TextEditingController(text: task.get<String>('TaskName'));
    final descController =
    TextEditingController(text: task.get<String>('Description'));
    String status = task.get<String>('Status') ?? "Pending";

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text("Edit Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Task Name"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(labelText: "Description"),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: status,
                decoration: InputDecoration(labelText: "Status"),
                items: ["Pending", "InProgress", "Done"]
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ))
                    .toList(),
                onChanged: (val) {
                  setStateDialog(() => status = val!);
                },
              )
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                task
                  ..set('TaskName', nameController.text.trim())
                  ..set('Description', descController.text.trim())
                  ..set('Status', status);

                await task.save();
                Navigator.pop(context);
                fetchTasks();
              },
              child: Text("Update"),
            )
          ],
        ),
      ),
    );
  }

  void showCreateDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String status = "Pending";

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text("Create Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Task Name"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(labelText: "Description"),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: status,
                decoration: InputDecoration(labelText: "Status"),
                items: ["Pending", "InProgress", "Done"]
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ))
                    .toList(),
                onChanged: (val) {
                  setStateDialog(() => status = val!);
                },
              )
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final user = await getCurrentUser();

                final task = ParseObject('Task')
                  ..set('TaskName', nameController.text.trim())
                  ..set('Description', descController.text.trim())
                  ..set('Status', status)
                  ..set('user', user);

                await task.save();
                Navigator.pop(context);
                fetchTasks();
              },
              child: Text("Create"),
            )
          ],
        ),
      ),
    );
  }

  Widget swipeRightBackground() {
    return Container(
      color: Colors.green,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(Icons.check, color: Colors.white),
          SizedBox(width: 10),
          Text("DONE", style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget swipeLeftBackground() {
    return Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text("DELETE", style: TextStyle(color: Colors.white)),
          SizedBox(width: 10),
          Icon(Icons.delete, color: Colors.white),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await confirmLogout()) {
          await logout();
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Tasks"),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                if (await confirmLogout()) {
                  await logout();
                }
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(50),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: TextField(
                onChanged: (val) {
                  searchQuery = val;
                  applyFilters();
                },
                decoration: InputDecoration(
                  hintText: "Search tasks...",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ),

        body: RefreshIndicator(
          onRefresh: fetchTasks,
          child: isLoading
              ? ListView(
            children: [
              SizedBox(height: 300),
              Center(child: CircularProgressIndicator()),
            ],
          )
              : filteredTasks.isEmpty
              ? ListView(
            children: [
              SizedBox(height: 300),
              Center(child: Text("No tasks found")),
            ],
          )
              : ListView.builder(
            itemCount: filteredTasks.length,
            itemBuilder: (_, index) {
              final task = filteredTasks[index];
              final id = task.objectId!;
              final isExpanded = expandedTasks.contains(id);
              final status =
                  task.get<String>('Status') ?? "Pending";

              return Dismissible(
                key: Key(id),
                background: swipeRightBackground(),
                secondaryBackground: swipeLeftBackground(),
                confirmDismiss: (direction) async {
                  if (direction ==
                      DismissDirection.startToEnd) {
                    await updateStatus(task, "Done");
                    return false;
                  } else {
                    return await confirmDelete(task);
                  }
                },
                onDismissed: (direction) async {
                  if (direction ==
                      DismissDirection.endToStart) {
                    await deleteTask(task);
                  }
                },
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isExpanded
                          ? expandedTasks.remove(id)
                          : expandedTasks.add(id);
                    });
                  },
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    showEditDialog(task);
                  },
                  child: Card(
                    color: getCardColor(status),
                    margin: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  task.get<String>('TaskName') ?? "",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                      FontWeight.bold),
                                ),
                              ),
                              DropdownButton<String>(
                                value: status,
                                underline: SizedBox(),
                                items: [
                                  "Pending",
                                  "InProgress",
                                  "Done"
                                ]
                                    .map((e) =>
                                    DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ))
                                    .toList(),
                                onChanged: (val) {
                                  updateStatus(task, val!);
                                },
                              ),
                            ],
                          ),
                          AnimatedCrossFade(
                            duration:
                            Duration(milliseconds: 300),
                            crossFadeState: isExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            firstChild: SizedBox(),
                            secondChild: Padding(
                              padding:
                              EdgeInsets.only(top: 10),
                              child: Text(task.get<String>(
                                  'Description') ??
                                  ""),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        floatingActionButton: FloatingActionButton(
          onPressed: showCreateDialog,
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}