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
          logger.d("Add event");
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
                return EventItem(events[index], onTap: () {
                  navigateEventPage(events[index]);
                });
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

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Add event"),
              content: TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Event name',
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text("Add"),
                  onPressed: () async {
                    final name = nameController.text;
                    if (name.isEmpty) {
                      return;
                    }
                    await repo.create(Event(name: name));
                    setState(() {});
                    Navigator.of(context).pop();
                  },
                )
              ],
            )).then((value) => setState(() {}));
  }
}

class EventItem extends StatelessWidget {
  const EventItem(this.event, {super.key, this.onTap});

  final Event event;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final count = (event.count ?? 0) > 0 ? Text(event.count.toString()) : null;

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          title: Text(event.name),
          trailing: count,
        ),
      ),
    );
  }
}
