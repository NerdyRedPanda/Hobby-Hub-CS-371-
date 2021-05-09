import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_calendar_carousel/classes/event.dart';
import 'package:flutter_calendar_carousel/classes/event_list.dart';
import 'package:hobby_hub/models/user.dart';
import 'package:provider/provider.dart';

import 'package:hobby_hub/widgets/database.dart';

class DatabaseEvent {
  int month;
  int day;
  int year;
  double hours;
  String name;
  int id;

  DatabaseEvent(int newMonth, int newDay, int newYear, double newHours,
      String newName, int newID) {
    month = newMonth;
    day = newDay;
    year = newYear;
    hours = newHours;
    name = newName;
    id = newID;
  }

  Map toJson() => {
        'month': month,
        'day': day,
        'year': year,
        'hours': hours,
        'name': name,
        'id': id
      };
}

class HobbyInfo extends ChangeNotifier {
  //String for the current hobby user has selected.
  String _currentHobby = "";
  //List of all avaliable hobbies to select from
  List<String> _allHobbies = [];

  List<DatabaseEvent> _allEvents = [];
  String uid;
  DatabaseService dbService = DatabaseService();
  EventList<Event> _calendarEvents = new EventList<Event>();
  Map<int, double> _eventTimes;

  String get getHobby {
    return _currentHobby;
  }

  List<String> get getAllHobbies {
    return _allHobbies;
  }

  EventList<Event> get calendarEvents {
    return _calendarEvents;
  }

  Map<int, double> get eventTimes {
    return _eventTimes;
  }

  HobbyInfo() {
    //Pull JSON array of hobbies
    //Mock data for now
    String _databaseHobbies = "[\"Hobby1\"]";
    List _databaseList = jsonDecode(_databaseHobbies);

    _databaseList.forEach((element) {
      _allHobbies.add(element);
    });

    _currentHobby = _allHobbies.length == 0 ? "None" : _allHobbies[0];

    //Load all events from database matching _currentHobby and store them in _allEvents
    _loadEvents('uwu');
  }

  void _loadEvents(String hobby) async {
    List dbCall = await dbService.getUserData(hobby);
    if (dbCall.length != 0) {
      dbCall.forEach((element) {
        _allEvents.add(new DatabaseEvent((element['month']), element['day'],
            element['year'], element['hours'], element['name'], element['id']));
      });
    }
    _createCalendarEvents();
  }

  void createEvent(DateTime date, double hours) {
    DatabaseEvent _newEvent = new DatabaseEvent(date.month, date.day, date.year,
        hours, _currentHobby, _allEvents.length + 1);
    _allEvents.add(_newEvent);

    _saveEvents();
    _createCalendarEvents();
  }

  void updateEvent(int id, double newTime) {
    _allEvents.forEach((element) {
      if (element.id == id) {
        element.hours = newTime;
        return;
      }
    });

    _saveEvents();
    _createCalendarEvents();
  }

  void deleteEvent(int id) {
    _allEvents.forEach((element) {
      if (element.id == id) {
        _allEvents.remove(element);
      }
    });

    _saveEvents();
    _createCalendarEvents();
  }

  void updateHobby(String newHobby) {
    _currentHobby = newHobby;
    _loadEvents(newHobby);
    notifyListeners();
  }

  DatabaseEvent getEvent(DateTime date) {
    DatabaseEvent _findEvent;
    _allEvents.forEach((element) {
      if (element.year == date.year &&
          element.month == date.month &&
          element.day == date.day) {
        _findEvent = element;
      }
    });
    return _findEvent;
  }

  void _createCalendarEvents() {
    _calendarEvents = new EventList<Event>();
    _allEvents.forEach((element) {
      DateTime _tempDate =
          new DateTime(element.year, element.month, element.day);
      _calendarEvents.add(_tempDate,
          new Event(date: _tempDate, title: element.name, id: element.id));
    });
    notifyListeners();
  }

  void _saveEvents() {
    //Save the list _allEvents back to the databse
    List json = [];
    _allEvents.forEach((element) {
      json.add(element.toJson());
    });
    dbService.updateUserData("NAME", "EMAIL",
        json); // hardcoded data that will be overwritten--cannot implement properly at this time due to not knowing firebase query syntax and shortage of time
  }
}
