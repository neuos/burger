import 'package:burger/data/repository/event_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../data/model/event.dart';
import 'event_page.dart';

class EventList extends StatefulWidget {
  const EventList({super.key});

  @override
  State<StatefulWidget> createState() => _EventListState();
}

class _EventListState extends State<EventList> {
  final repo = GetIt.I.get<IEventRepository>();
  final logger = Logger();

  List<Event> events = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _addEvent();
        },
        label: const Text('Add event'),
        icon: const Icon(Icons.add),
      ),
      body: FutureBuilder(
        future: repo.getEvents(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            events = snapshot.data as List<Event>;
            return ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                return EventItem(
                  events[index],
                  onTap: () {
                    navigateEventPage(events[index]);
                  },
                  onLongPress: () {
                    _deleteEvent(events[index]);
                  },
                );
              },
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  void navigateEventPage(Event event) {
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (context) => EventPage(
                  title: event.name,
                  event: event,
                )))
        .then((value) => setState(() {}));
  }

  void _addEvent() {
    final nameController = TextEditingController();

    onSubmit(String name) async {
      if (name.isEmpty) {
        return;
      }
      await repo.create(Event(name: name));
      Navigator.of(context).pop();
    }

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Add event"),
              content: TextField(
                controller: nameController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: onSubmit,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Event name',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: nameController,
                  builder: (context, value, child) {
                    var name = value.text;
                    return FilledButton(
                    onPressed: name.isNotEmpty ? (){
                      onSubmit(name);
                    } : null,
                    child: const Text("Add"),
                  );
                  },
                )
              ],
            )).then((value) => setState(() {}));
  }

  void _deleteEvent(Event event) {
    final themeData = GetIt.I.get<ThemeData>();

    //
    // final buttonStyle = ButtonStyle(
    //   backgroundColor: themeData.colorScheme.error,
    // );

    final container = themeData.colorScheme.errorContainer;
    final text = themeData.colorScheme.onErrorContainer;
    final textStyle = TextStyle(color: text);

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: container,
            icon: Icon(Icons.delete, color: text),
            title: Text(
              "Delete '${event.name}'?",
              style: textStyle,
            ),
            content: Text(
                "Do you want to delete the event with ${event.count} scans?"),
            actions: [
              TextButton(
                child: Text("Cancel", style: textStyle),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FilledButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.red),
                ),
                child: const Text("Delete"),
                onPressed: () async {
                  await repo.delete(event);
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        }).then((value) => setState(() {}));
  }
}

class EventItem extends StatelessWidget {
  const EventItem(this.event,
      {super.key, this.onTap, required this.onLongPress});

  final Event event;
  final GestureTapCallback? onTap;
  final GestureTapCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final count = (event.count ?? 0) > 0 ? Text(event.count.toString()) : null;

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: ListTile(
          title: Text(event.name),
          trailing: count,
        ),
      ),
    );
  }
}
