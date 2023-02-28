import 'package:ahmed/modules/archive_tasks/archive_tasks_screen.dart';
import 'package:ahmed/modules/done_tasks/done_tasks_screen.dart';
import 'package:ahmed/modules/new_tasks/new_tasks_screen.dart';
import 'package:ahmed/shared/cubit/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';

class AppCubit extends Cubit<AppStates>
{
  AppCubit() : super(AppInitalStates());

  static AppCubit get(context) => BlocProvider.of(context);

  int currentIndex = 0;
  List<Widget> screens =
  [
    NewTasksScreen(),
    DoneTasksScreen(),
    ArchivedTasksScreen(),
  ];
  List<String> titles =
  [
    'New Tasks',
    'Done Tasks',
    'Archived Tasks'
  ];

  void changeIndex(int index)
  {
    currentIndex = index;
    emit(AppChangeBottomNavBarStates());
  }

  late Database database;
  List<Map> newTasks= [];
  List<Map> doneTasks= [];
  List<Map> archivedTasks= [];


  void createDatabase()
  {
    openDatabase(
      'todo.db',
      version: 1,
      onCreate: (database, version) async
      {
        print('database created');
        await database.execute(
            'CREATE TABLE tasks (id INTEGER PRIMARY KEY, title TEXT, date TEXT,time TEXT,status TEXT)');
      },
      onOpen: (database) {

        getDataFromDatabase(database);

        print('database opened');
      },
    ).then((value)
    {
      database = value;
      emit(AppCreateDatabaseStates());
    });
  }

   insertToDatabase({
    required String title,
    required String time,
    required String date,
  }) async
   {
     await  database.transaction((txn)
    async {
      txn.rawInsert('INSERT INTO tasks(title, date, time, status) values("$title","$date","$time","new")',
      ).then((value)
      {
        print('$value inserted successfully');
        emit(AppInsertDatabaseStates());

        getDataFromDatabase(database);
      }).catchError((error) {
        print('Error When Inserting New Record ${error.toString()}');
      });
      return database;
    });
  }

  void getDataFromDatabase(database)
  {
    newTasks = [];
    doneTasks = [];
    archivedTasks = [];
    emit(AppGetDataDatabaseLoadingStates());

    database.rawQuery('SELECT * FROM tasks').then((value)
    {
      value.forEach((element)
      {
        if(element['status'] == 'new')
          newTasks.add(element);
        else if(element['status'] == 'done')
          doneTasks.add(element);
        else if(element['status'] == 'archived')
          archivedTasks.add(element);
      });
      emit(AppGetDataDatabaseStates());
    });
  }
  void  updateData({
    required String status,
    required int id,
  }) async
  {
     database.rawUpdate(
      'UPDATE tasks SET status = ? WHERE id = ?',
      ['$status',id],
    ).then((value)
     {
       getDataFromDatabase(database);
       emit(AppUpdateDatabaseStates());
     });
  }

  void  deleteData({
    required int id,
  }) async
  {
    database.rawDelete('DELETE FROM tasks WHERE id = ?',[id],)
        .then((value)
    {
      getDataFromDatabase(database);
      emit(AppDeleteDatabaseStates());
    });
  }


  bool isBottomSheetShown = false;
  IconData fabIcon = Icons.edit;

  void changeBottomSheetState({
    required bool isShow,
    required IconData icon,
})
  {
    isBottomSheetShown = isShow;
    fabIcon = icon;

    emit(AppChangeBottomSheetStates());
  }
}