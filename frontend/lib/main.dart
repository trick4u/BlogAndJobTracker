import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(BlogAndJobTrackerApp());
}

class BlogAndJobTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blog & Job Tracker',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: HomeScreen(),
    );
  }
}

class Post {
  final int id;
  final String title;
  final String content;
  final List<dynamic> tags;
  final DateTime date;
  final List<String> comments;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.date,
    required this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      tags: json['tags'] ?? [],
      date: DateTime.parse(json['date']),
      comments: (json['comments'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

class Application {
  final int id;
  final String company;
  final String position;
  final String status;
  final DateTime applyDate;
  final DateTime? followUp;

  Application({
    required this.id,
    required this.company,
    required this.position,
    required this.status,
    required this.applyDate,
    this.followUp,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'],
      company: json['company'],
      position: json['position'],
      status: json['status'],
      applyDate: DateTime.parse(json['apply_date']),
      followUp: json['follow_up'] != null ? DateTime.parse(json['follow_up']) : null,
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Post> posts = [];
  List<Application> applications = [];
  DateTime _currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchPosts();
    fetchApplications();
    _checkReminders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchPosts() async {
    final response = await http.get(Uri.parse('http://localhost:3000/posts'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        posts = data.map((json) => Post.fromJson(json)).toList();
      });
    }
  }

  Future<void> fetchApplications() async {
    final response = await http.get(Uri.parse('http://localhost:3000/applications'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        applications = data.map((json) => Application.fromJson(json)).toList();
      });
    }
  }

  Future<void> addPost(String title, String content, List<String> tags) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/posts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'content': content, 'tags': tags}),
    );
    if (response.statusCode == 201) {
      fetchPosts();
    }
  }

  Future<void> addComment(int postId, String text) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/comments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'post_id': postId, 'text': text}),
    );
    if (response.statusCode == 201) {
      fetchPosts();
    }
  }

  Future<void> addApplication(String company, String position, String status, DateTime applyDate, DateTime? followUp) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/applications'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'company': company,
        'position': position,
        'status': status,
        'apply_date': DateFormat('yyyy-MM-dd').format(applyDate),
        'follow_up': followUp != null ? DateFormat('yyyy-MM-dd').format(followUp) : null,
      }),
    );
    if (response.statusCode == 201) {
      fetchApplications();
    }
  }

  Future<void> updateApplication(int id, String company, String position, String status, DateTime applyDate, DateTime? followUp) async {
    final response = await http.put(
      Uri.parse('http://localhost:3000/applications/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'company': company,
        'position': position,
        'status': status,
        'apply_date': DateFormat('yyyy-MM-dd').format(applyDate),
        'follow_up': followUp != null ? DateFormat('yyyy-MM-dd').format(followUp) : null,
      }),
    );
    if (response.statusCode == 200) {
      fetchApplications();
    }
  }

  Future<void> deleteApplication(int id) async {
    final response = await http.delete(Uri.parse('http://localhost:3000/applications/$id'));
    if (response.statusCode == 204) {
      fetchApplications();
    }
  }

  void _checkReminders() {
    final now = DateTime.now();
    for (var app in applications) {
      if (app.followUp != null && app.followUp!.isBefore(now.add(Duration(days: 1))) && app.followUp!.isAfter(now)) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Follow-up Reminder'),
            content: Text('Follow up with ${app.company} for ${app.position} tomorrow!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blog & Job Tracker'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Blog Platform'),
            Tab(text: 'Job Tracker'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Blog Platform Tab
          ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: Text(post.title),
                  subtitle: Text('${DateFormat('yyyy-MM-dd').format(post.date)} - Tags: ${post.tags.join(', ')}'),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.content),
                          ...post.comments.map((comment) => Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text('Comment: $comment'),
                          )),
                          TextField(
                            decoration: InputDecoration(labelText: 'Add Comment'),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) addComment(post.id, value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Job Tracker Tab
          ListView.builder(
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('${app.company} - ${app.position}'),
                  subtitle: Text('Status: ${app.status} - Applied: ${DateFormat('yyyy-MM-dd').format(app.applyDate)} - Follow-up: ${app.followUp != null ? DateFormat('yyyy-MM-dd').format(app.followUp!) : 'N/A'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showEditApplicationDialog(context, app),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => deleteApplication(app.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Builder(
        builder: (context) {
          return FloatingActionButton(
            onPressed: () {
              final tabIndex = _tabController.index;
              if (tabIndex == 0) {
                _showAddPostDialog(context);
              } else {
                _showAddApplicationDialog(context);
              }
            },
            child: Icon(Icons.add),
          );
        },
      ),
    );
  }

  void _showAddPostDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String title = '';
    String content = '';
    List<String> tags = [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Post'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Title'),
                    validator: (value) => value == null || value.isEmpty ? 'Enter a title' : null,
                    onSaved: (value) => title = value!,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Content'),
                    validator: (value) => value == null || value.isEmpty ? 'Enter content' : null,
                    onSaved: (value) => content = value!,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Tags (comma-separated)'),
                    onSaved: (value) => tags = value?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  addPost(title, content, tags);
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showAddApplicationDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String company = '';
    String position = '';
    String status = 'Applied';
    DateTime applyDate = DateTime.now();
    DateTime? followUp;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Application'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Company'),
                    validator: (value) => value == null || value.isEmpty ? 'Enter a company' : null,
                    onSaved: (value) => company = value!,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Position'),
                    validator: (value) => value == null || value.isEmpty ? 'Enter a position' : null,
                    onSaved: (value) => position = value!,
                  ),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: InputDecoration(labelText: 'Status'),
                    items: ['Applied', 'Interview', 'Offer', 'Rejected'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) => status = value!,
                  ),
                  InputDatePickerFormField(
                    firstDate: DateTime(2020, 1, 1),
                    lastDate: DateTime(2030, 12, 31),
                    initialDate: applyDate,
                    onDateSubmitted: (value) => applyDate = value,
                  ),
                  InputDatePickerFormField(
                    firstDate: DateTime(2020, 1, 1),
                    lastDate: DateTime(2030, 12, 31),
                    initialDate: followUp ?? DateTime.now().add(Duration(days: 7)),
                    onDateSubmitted: (value) => followUp = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  addApplication(company, position, status, applyDate, followUp);
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showEditApplicationDialog(BuildContext context, Application app) {
    final _formKey = GlobalKey<FormState>();
    String company = app.company;
    String position = app.position;
    String status = app.status;
    DateTime applyDate = app.applyDate;
    DateTime? followUp = app.followUp;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Application'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: company,
                    decoration: InputDecoration(labelText: 'Company'),
                    validator: (value) => value == null || value.isEmpty ? 'Enter a company' : null,
                    onSaved: (value) => company = value!,
                  ),
                  TextFormField(
                    initialValue: position,
                    decoration: InputDecoration(labelText: 'Position'),
                    validator: (value) => value == null || value.isEmpty ? 'Enter a position' : null,
                    onSaved: (value) => position = value!,
                  ),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: InputDecoration(labelText: 'Status'),
                    items: ['Applied', 'Interview', 'Offer', 'Rejected'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) => status = value!,
                  ),
                  InputDatePickerFormField(
                    firstDate: DateTime(2020, 1, 1),
                    lastDate: DateTime(2030, 12, 31),
                    initialDate: applyDate,
                    onDateSubmitted: (value) => applyDate = value,
                  ),
                  InputDatePickerFormField(
                    firstDate: DateTime(2020, 1, 1),
                    lastDate: DateTime(2030, 12, 31),
                    initialDate: followUp ?? DateTime.now().add(Duration(days: 7)),
                    onDateSubmitted: (value) => followUp = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  updateApplication(app.id, company, position, status, applyDate, followUp);
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}