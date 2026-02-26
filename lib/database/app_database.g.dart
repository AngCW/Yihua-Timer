// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class Event extends Table with TableInfo<Event, EventData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Event(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  static const VerificationMeta _eventNameMeta =
      const VerificationMeta('eventName');
  late final GeneratedColumn<String> eventName = GeneratedColumn<String>(
      'event_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _eventDescMeta =
      const VerificationMeta('eventDesc');
  late final GeneratedColumn<String> eventDesc = GeneratedColumn<String>(
      'event_desc', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, true,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _teamNumMeta =
      const VerificationMeta('teamNum');
  late final GeneratedColumn<int> teamNum = GeneratedColumn<int>(
      'team_num', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _remarkMeta = const VerificationMeta('remark');
  late final GeneratedColumn<String> remark = GeneratedColumn<String>(
      'remark', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns =>
      [id, eventName, eventDesc, startDate, endDate, teamNum, remark];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event';
  @override
  VerificationContext validateIntegrity(Insertable<EventData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('event_name')) {
      context.handle(_eventNameMeta,
          eventName.isAcceptableOrUnknown(data['event_name']!, _eventNameMeta));
    } else if (isInserting) {
      context.missing(_eventNameMeta);
    }
    if (data.containsKey('event_desc')) {
      context.handle(_eventDescMeta,
          eventDesc.isAcceptableOrUnknown(data['event_desc']!, _eventDescMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('team_num')) {
      context.handle(_teamNumMeta,
          teamNum.isAcceptableOrUnknown(data['team_num']!, _teamNumMeta));
    }
    if (data.containsKey('remark')) {
      context.handle(_remarkMeta,
          remark.isAcceptableOrUnknown(data['remark']!, _remarkMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      eventName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_name'])!,
      eventDesc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_desc']),
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date']),
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      teamNum: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}team_num']),
      remark: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remark']),
    );
  }

  @override
  Event createAlias(String alias) {
    return Event(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class EventData extends DataClass implements Insertable<EventData> {
  final int id;
  final String eventName;
  final String? eventDesc;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? teamNum;
  final String? remark;
  const EventData(
      {required this.id,
      required this.eventName,
      this.eventDesc,
      this.startDate,
      this.endDate,
      this.teamNum,
      this.remark});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_name'] = Variable<String>(eventName);
    if (!nullToAbsent || eventDesc != null) {
      map['event_desc'] = Variable<String>(eventDesc);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    if (!nullToAbsent || teamNum != null) {
      map['team_num'] = Variable<int>(teamNum);
    }
    if (!nullToAbsent || remark != null) {
      map['remark'] = Variable<String>(remark);
    }
    return map;
  }

  EventCompanion toCompanion(bool nullToAbsent) {
    return EventCompanion(
      id: Value(id),
      eventName: Value(eventName),
      eventDesc: eventDesc == null && nullToAbsent
          ? const Value.absent()
          : Value(eventDesc),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      teamNum: teamNum == null && nullToAbsent
          ? const Value.absent()
          : Value(teamNum),
      remark:
          remark == null && nullToAbsent ? const Value.absent() : Value(remark),
    );
  }

  factory EventData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventData(
      id: serializer.fromJson<int>(json['id']),
      eventName: serializer.fromJson<String>(json['event_name']),
      eventDesc: serializer.fromJson<String?>(json['event_desc']),
      startDate: serializer.fromJson<DateTime?>(json['start_date']),
      endDate: serializer.fromJson<DateTime?>(json['end_date']),
      teamNum: serializer.fromJson<int?>(json['team_num']),
      remark: serializer.fromJson<String?>(json['remark']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'event_name': serializer.toJson<String>(eventName),
      'event_desc': serializer.toJson<String?>(eventDesc),
      'start_date': serializer.toJson<DateTime?>(startDate),
      'end_date': serializer.toJson<DateTime?>(endDate),
      'team_num': serializer.toJson<int?>(teamNum),
      'remark': serializer.toJson<String?>(remark),
    };
  }

  EventData copyWith(
          {int? id,
          String? eventName,
          Value<String?> eventDesc = const Value.absent(),
          Value<DateTime?> startDate = const Value.absent(),
          Value<DateTime?> endDate = const Value.absent(),
          Value<int?> teamNum = const Value.absent(),
          Value<String?> remark = const Value.absent()}) =>
      EventData(
        id: id ?? this.id,
        eventName: eventName ?? this.eventName,
        eventDesc: eventDesc.present ? eventDesc.value : this.eventDesc,
        startDate: startDate.present ? startDate.value : this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        teamNum: teamNum.present ? teamNum.value : this.teamNum,
        remark: remark.present ? remark.value : this.remark,
      );
  EventData copyWithCompanion(EventCompanion data) {
    return EventData(
      id: data.id.present ? data.id.value : this.id,
      eventName: data.eventName.present ? data.eventName.value : this.eventName,
      eventDesc: data.eventDesc.present ? data.eventDesc.value : this.eventDesc,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      teamNum: data.teamNum.present ? data.teamNum.value : this.teamNum,
      remark: data.remark.present ? data.remark.value : this.remark,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventData(')
          ..write('id: $id, ')
          ..write('eventName: $eventName, ')
          ..write('eventDesc: $eventDesc, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('teamNum: $teamNum, ')
          ..write('remark: $remark')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, eventName, eventDesc, startDate, endDate, teamNum, remark);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventData &&
          other.id == this.id &&
          other.eventName == this.eventName &&
          other.eventDesc == this.eventDesc &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.teamNum == this.teamNum &&
          other.remark == this.remark);
}

class EventCompanion extends UpdateCompanion<EventData> {
  final Value<int> id;
  final Value<String> eventName;
  final Value<String?> eventDesc;
  final Value<DateTime?> startDate;
  final Value<DateTime?> endDate;
  final Value<int?> teamNum;
  final Value<String?> remark;
  const EventCompanion({
    this.id = const Value.absent(),
    this.eventName = const Value.absent(),
    this.eventDesc = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.teamNum = const Value.absent(),
    this.remark = const Value.absent(),
  });
  EventCompanion.insert({
    this.id = const Value.absent(),
    required String eventName,
    this.eventDesc = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.teamNum = const Value.absent(),
    this.remark = const Value.absent(),
  }) : eventName = Value(eventName);
  static Insertable<EventData> custom({
    Expression<int>? id,
    Expression<String>? eventName,
    Expression<String>? eventDesc,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<int>? teamNum,
    Expression<String>? remark,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventName != null) 'event_name': eventName,
      if (eventDesc != null) 'event_desc': eventDesc,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (teamNum != null) 'team_num': teamNum,
      if (remark != null) 'remark': remark,
    });
  }

  EventCompanion copyWith(
      {Value<int>? id,
      Value<String>? eventName,
      Value<String?>? eventDesc,
      Value<DateTime?>? startDate,
      Value<DateTime?>? endDate,
      Value<int?>? teamNum,
      Value<String?>? remark}) {
    return EventCompanion(
      id: id ?? this.id,
      eventName: eventName ?? this.eventName,
      eventDesc: eventDesc ?? this.eventDesc,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      teamNum: teamNum ?? this.teamNum,
      remark: remark ?? this.remark,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eventName.present) {
      map['event_name'] = Variable<String>(eventName.value);
    }
    if (eventDesc.present) {
      map['event_desc'] = Variable<String>(eventDesc.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (teamNum.present) {
      map['team_num'] = Variable<int>(teamNum.value);
    }
    if (remark.present) {
      map['remark'] = Variable<String>(remark.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventCompanion(')
          ..write('id: $id, ')
          ..write('eventName: $eventName, ')
          ..write('eventDesc: $eventDesc, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('teamNum: $teamNum, ')
          ..write('remark: $remark')
          ..write(')'))
        .toString();
  }
}

class TimerTemplate extends Table
    with TableInfo<TimerTemplate, TimerTemplateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  TimerTemplate(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      $customConstraints: 'DEFAULT CURRENT_TIMESTAMP',
      defaultValue: const CustomExpression('CURRENT_TIMESTAMP'));
  @override
  List<GeneratedColumn> get $columns => [id, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timer_template';
  @override
  VerificationContext validateIntegrity(Insertable<TimerTemplateData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimerTemplateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimerTemplateData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
    );
  }

  @override
  TimerTemplate createAlias(String alias) {
    return TimerTemplate(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class TimerTemplateData extends DataClass
    implements Insertable<TimerTemplateData> {
  final int id;
  final DateTime? createdAt;
  const TimerTemplateData({required this.id, this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  TimerTemplateCompanion toCompanion(bool nullToAbsent) {
    return TimerTemplateCompanion(
      id: Value(id),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory TimerTemplateData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimerTemplateData(
      id: serializer.fromJson<int>(json['id']),
      createdAt: serializer.fromJson<DateTime?>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'created_at': serializer.toJson<DateTime?>(createdAt),
    };
  }

  TimerTemplateData copyWith(
          {int? id, Value<DateTime?> createdAt = const Value.absent()}) =>
      TimerTemplateData(
        id: id ?? this.id,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  TimerTemplateData copyWithCompanion(TimerTemplateCompanion data) {
    return TimerTemplateData(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimerTemplateData(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimerTemplateData &&
          other.id == this.id &&
          other.createdAt == this.createdAt);
}

class TimerTemplateCompanion extends UpdateCompanion<TimerTemplateData> {
  final Value<int> id;
  final Value<DateTime?> createdAt;
  const TimerTemplateCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TimerTemplateCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  static Insertable<TimerTemplateData> custom({
    Expression<int>? id,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TimerTemplateCompanion copyWith(
      {Value<int>? id, Value<DateTime?>? createdAt}) {
    return TimerTemplateCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimerTemplateCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class DingValue extends Table with TableInfo<DingValue, DingValueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DingValue(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  static const VerificationMeta _dingTimeMeta =
      const VerificationMeta('dingTime');
  late final GeneratedColumn<String> dingTime = GeneratedColumn<String>(
      'ding_time', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _dingAmountMeta =
      const VerificationMeta('dingAmount');
  late final GeneratedColumn<int> dingAmount = GeneratedColumn<int>(
      'ding_amount', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _timerTemplateIdMeta =
      const VerificationMeta('timerTemplateId');
  late final GeneratedColumn<int> timerTemplateId = GeneratedColumn<int>(
      'timer_template_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns =>
      [id, dingTime, dingAmount, timerTemplateId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ding_value';
  @override
  VerificationContext validateIntegrity(Insertable<DingValueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ding_time')) {
      context.handle(_dingTimeMeta,
          dingTime.isAcceptableOrUnknown(data['ding_time']!, _dingTimeMeta));
    }
    if (data.containsKey('ding_amount')) {
      context.handle(
          _dingAmountMeta,
          dingAmount.isAcceptableOrUnknown(
              data['ding_amount']!, _dingAmountMeta));
    }
    if (data.containsKey('timer_template_id')) {
      context.handle(
          _timerTemplateIdMeta,
          timerTemplateId.isAcceptableOrUnknown(
              data['timer_template_id']!, _timerTemplateIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DingValueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DingValueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      dingTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ding_time']),
      dingAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ding_amount']),
      timerTemplateId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timer_template_id']),
    );
  }

  @override
  DingValue createAlias(String alias) {
    return DingValue(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class DingValueData extends DataClass implements Insertable<DingValueData> {
  final int id;
  final String? dingTime;
  final int? dingAmount;
  final int? timerTemplateId;
  const DingValueData(
      {required this.id, this.dingTime, this.dingAmount, this.timerTemplateId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || dingTime != null) {
      map['ding_time'] = Variable<String>(dingTime);
    }
    if (!nullToAbsent || dingAmount != null) {
      map['ding_amount'] = Variable<int>(dingAmount);
    }
    if (!nullToAbsent || timerTemplateId != null) {
      map['timer_template_id'] = Variable<int>(timerTemplateId);
    }
    return map;
  }

  DingValueCompanion toCompanion(bool nullToAbsent) {
    return DingValueCompanion(
      id: Value(id),
      dingTime: dingTime == null && nullToAbsent
          ? const Value.absent()
          : Value(dingTime),
      dingAmount: dingAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(dingAmount),
      timerTemplateId: timerTemplateId == null && nullToAbsent
          ? const Value.absent()
          : Value(timerTemplateId),
    );
  }

  factory DingValueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DingValueData(
      id: serializer.fromJson<int>(json['id']),
      dingTime: serializer.fromJson<String?>(json['ding_time']),
      dingAmount: serializer.fromJson<int?>(json['ding_amount']),
      timerTemplateId: serializer.fromJson<int?>(json['timer_template_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ding_time': serializer.toJson<String?>(dingTime),
      'ding_amount': serializer.toJson<int?>(dingAmount),
      'timer_template_id': serializer.toJson<int?>(timerTemplateId),
    };
  }

  DingValueData copyWith(
          {int? id,
          Value<String?> dingTime = const Value.absent(),
          Value<int?> dingAmount = const Value.absent(),
          Value<int?> timerTemplateId = const Value.absent()}) =>
      DingValueData(
        id: id ?? this.id,
        dingTime: dingTime.present ? dingTime.value : this.dingTime,
        dingAmount: dingAmount.present ? dingAmount.value : this.dingAmount,
        timerTemplateId: timerTemplateId.present
            ? timerTemplateId.value
            : this.timerTemplateId,
      );
  DingValueData copyWithCompanion(DingValueCompanion data) {
    return DingValueData(
      id: data.id.present ? data.id.value : this.id,
      dingTime: data.dingTime.present ? data.dingTime.value : this.dingTime,
      dingAmount:
          data.dingAmount.present ? data.dingAmount.value : this.dingAmount,
      timerTemplateId: data.timerTemplateId.present
          ? data.timerTemplateId.value
          : this.timerTemplateId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DingValueData(')
          ..write('id: $id, ')
          ..write('dingTime: $dingTime, ')
          ..write('dingAmount: $dingAmount, ')
          ..write('timerTemplateId: $timerTemplateId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dingTime, dingAmount, timerTemplateId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DingValueData &&
          other.id == this.id &&
          other.dingTime == this.dingTime &&
          other.dingAmount == this.dingAmount &&
          other.timerTemplateId == this.timerTemplateId);
}

class DingValueCompanion extends UpdateCompanion<DingValueData> {
  final Value<int> id;
  final Value<String?> dingTime;
  final Value<int?> dingAmount;
  final Value<int?> timerTemplateId;
  const DingValueCompanion({
    this.id = const Value.absent(),
    this.dingTime = const Value.absent(),
    this.dingAmount = const Value.absent(),
    this.timerTemplateId = const Value.absent(),
  });
  DingValueCompanion.insert({
    this.id = const Value.absent(),
    this.dingTime = const Value.absent(),
    this.dingAmount = const Value.absent(),
    this.timerTemplateId = const Value.absent(),
  });
  static Insertable<DingValueData> custom({
    Expression<int>? id,
    Expression<String>? dingTime,
    Expression<int>? dingAmount,
    Expression<int>? timerTemplateId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dingTime != null) 'ding_time': dingTime,
      if (dingAmount != null) 'ding_amount': dingAmount,
      if (timerTemplateId != null) 'timer_template_id': timerTemplateId,
    });
  }

  DingValueCompanion copyWith(
      {Value<int>? id,
      Value<String?>? dingTime,
      Value<int?>? dingAmount,
      Value<int?>? timerTemplateId}) {
    return DingValueCompanion(
      id: id ?? this.id,
      dingTime: dingTime ?? this.dingTime,
      dingAmount: dingAmount ?? this.dingAmount,
      timerTemplateId: timerTemplateId ?? this.timerTemplateId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dingTime.present) {
      map['ding_time'] = Variable<String>(dingTime.value);
    }
    if (dingAmount.present) {
      map['ding_amount'] = Variable<int>(dingAmount.value);
    }
    if (timerTemplateId.present) {
      map['timer_template_id'] = Variable<int>(timerTemplateId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DingValueCompanion(')
          ..write('id: $id, ')
          ..write('dingTime: $dingTime, ')
          ..write('dingAmount: $dingAmount, ')
          ..write('timerTemplateId: $timerTemplateId')
          ..write(')'))
        .toString();
  }
}

class Flow extends Table with TableInfo<Flow, FlowData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Flow(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  static const VerificationMeta _flowNameMeta =
      const VerificationMeta('flowName');
  late final GeneratedColumn<String> flowName = GeneratedColumn<String>(
      'flow_name', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  late final GeneratedColumn<int> eventId = GeneratedColumn<int>(
      'event_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns => [id, flowName, eventId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flow';
  @override
  VerificationContext validateIntegrity(Insertable<FlowData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('flow_name')) {
      context.handle(_flowNameMeta,
          flowName.isAcceptableOrUnknown(data['flow_name']!, _flowNameMeta));
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FlowData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FlowData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      flowName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}flow_name']),
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}event_id']),
    );
  }

  @override
  Flow createAlias(String alias) {
    return Flow(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class FlowData extends DataClass implements Insertable<FlowData> {
  final int id;
  final String? flowName;
  final int? eventId;
  const FlowData({required this.id, this.flowName, this.eventId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || flowName != null) {
      map['flow_name'] = Variable<String>(flowName);
    }
    if (!nullToAbsent || eventId != null) {
      map['event_id'] = Variable<int>(eventId);
    }
    return map;
  }

  FlowCompanion toCompanion(bool nullToAbsent) {
    return FlowCompanion(
      id: Value(id),
      flowName: flowName == null && nullToAbsent
          ? const Value.absent()
          : Value(flowName),
      eventId: eventId == null && nullToAbsent
          ? const Value.absent()
          : Value(eventId),
    );
  }

  factory FlowData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FlowData(
      id: serializer.fromJson<int>(json['id']),
      flowName: serializer.fromJson<String?>(json['flow_name']),
      eventId: serializer.fromJson<int?>(json['event_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'flow_name': serializer.toJson<String?>(flowName),
      'event_id': serializer.toJson<int?>(eventId),
    };
  }

  FlowData copyWith(
          {int? id,
          Value<String?> flowName = const Value.absent(),
          Value<int?> eventId = const Value.absent()}) =>
      FlowData(
        id: id ?? this.id,
        flowName: flowName.present ? flowName.value : this.flowName,
        eventId: eventId.present ? eventId.value : this.eventId,
      );
  FlowData copyWithCompanion(FlowCompanion data) {
    return FlowData(
      id: data.id.present ? data.id.value : this.id,
      flowName: data.flowName.present ? data.flowName.value : this.flowName,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FlowData(')
          ..write('id: $id, ')
          ..write('flowName: $flowName, ')
          ..write('eventId: $eventId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, flowName, eventId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlowData &&
          other.id == this.id &&
          other.flowName == this.flowName &&
          other.eventId == this.eventId);
}

class FlowCompanion extends UpdateCompanion<FlowData> {
  final Value<int> id;
  final Value<String?> flowName;
  final Value<int?> eventId;
  const FlowCompanion({
    this.id = const Value.absent(),
    this.flowName = const Value.absent(),
    this.eventId = const Value.absent(),
  });
  FlowCompanion.insert({
    this.id = const Value.absent(),
    this.flowName = const Value.absent(),
    this.eventId = const Value.absent(),
  });
  static Insertable<FlowData> custom({
    Expression<int>? id,
    Expression<String>? flowName,
    Expression<int>? eventId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (flowName != null) 'flow_name': flowName,
      if (eventId != null) 'event_id': eventId,
    });
  }

  FlowCompanion copyWith(
      {Value<int>? id, Value<String?>? flowName, Value<int?>? eventId}) {
    return FlowCompanion(
      id: id ?? this.id,
      flowName: flowName ?? this.flowName,
      eventId: eventId ?? this.eventId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (flowName.present) {
      map['flow_name'] = Variable<String>(flowName.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<int>(eventId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlowCompanion(')
          ..write('id: $id, ')
          ..write('flowName: $flowName, ')
          ..write('eventId: $eventId')
          ..write(')'))
        .toString();
  }
}

class Images extends Table with TableInfo<Images, ImagesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Images(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  static const VerificationMeta _imageNameMeta =
      const VerificationMeta('imageName');
  late final GeneratedColumn<String> imageName = GeneratedColumn<String>(
      'image_name', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _imageTypeMeta =
      const VerificationMeta('imageType');
  late final GeneratedColumn<String> imageType = GeneratedColumn<String>(
      'image_type', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  late final GeneratedColumn<int> pageId = GeneratedColumn<int>(
      'page_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _xposMeta = const VerificationMeta('xpos');
  late final GeneratedColumn<double> xpos = GeneratedColumn<double>(
      'xpos', aliasedName, true,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _yposMeta = const VerificationMeta('ypos');
  late final GeneratedColumn<double> ypos = GeneratedColumn<double>(
      'ypos', aliasedName, true,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns =>
      [id, imageName, imageType, pageId, xpos, ypos];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'images';
  @override
  VerificationContext validateIntegrity(Insertable<ImagesData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('image_name')) {
      context.handle(_imageNameMeta,
          imageName.isAcceptableOrUnknown(data['image_name']!, _imageNameMeta));
    }
    if (data.containsKey('image_type')) {
      context.handle(_imageTypeMeta,
          imageType.isAcceptableOrUnknown(data['image_type']!, _imageTypeMeta));
    }
    if (data.containsKey('page_id')) {
      context.handle(_pageIdMeta,
          pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta));
    }
    if (data.containsKey('xpos')) {
      context.handle(
          _xposMeta, xpos.isAcceptableOrUnknown(data['xpos']!, _xposMeta));
    }
    if (data.containsKey('ypos')) {
      context.handle(
          _yposMeta, ypos.isAcceptableOrUnknown(data['ypos']!, _yposMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImagesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImagesData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      imageName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_name']),
      imageType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_type']),
      pageId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_id']),
      xpos: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}xpos']),
      ypos: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}ypos']),
    );
  }

  @override
  Images createAlias(String alias) {
    return Images(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ImagesData extends DataClass implements Insertable<ImagesData> {
  final int id;
  final String? imageName;
  final String? imageType;

  /// schoolA, schoolB or background
  final int? pageId;
  final double? xpos;
  final double? ypos;
  const ImagesData(
      {required this.id,
      this.imageName,
      this.imageType,
      this.pageId,
      this.xpos,
      this.ypos});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || imageName != null) {
      map['image_name'] = Variable<String>(imageName);
    }
    if (!nullToAbsent || imageType != null) {
      map['image_type'] = Variable<String>(imageType);
    }
    if (!nullToAbsent || pageId != null) {
      map['page_id'] = Variable<int>(pageId);
    }
    if (!nullToAbsent || xpos != null) {
      map['xpos'] = Variable<double>(xpos);
    }
    if (!nullToAbsent || ypos != null) {
      map['ypos'] = Variable<double>(ypos);
    }
    return map;
  }

  ImagesCompanion toCompanion(bool nullToAbsent) {
    return ImagesCompanion(
      id: Value(id),
      imageName: imageName == null && nullToAbsent
          ? const Value.absent()
          : Value(imageName),
      imageType: imageType == null && nullToAbsent
          ? const Value.absent()
          : Value(imageType),
      pageId:
          pageId == null && nullToAbsent ? const Value.absent() : Value(pageId),
      xpos: xpos == null && nullToAbsent ? const Value.absent() : Value(xpos),
      ypos: ypos == null && nullToAbsent ? const Value.absent() : Value(ypos),
    );
  }

  factory ImagesData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImagesData(
      id: serializer.fromJson<int>(json['id']),
      imageName: serializer.fromJson<String?>(json['image_name']),
      imageType: serializer.fromJson<String?>(json['image_type']),
      pageId: serializer.fromJson<int?>(json['page_id']),
      xpos: serializer.fromJson<double?>(json['xpos']),
      ypos: serializer.fromJson<double?>(json['ypos']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'image_name': serializer.toJson<String?>(imageName),
      'image_type': serializer.toJson<String?>(imageType),
      'page_id': serializer.toJson<int?>(pageId),
      'xpos': serializer.toJson<double?>(xpos),
      'ypos': serializer.toJson<double?>(ypos),
    };
  }

  ImagesData copyWith(
          {int? id,
          Value<String?> imageName = const Value.absent(),
          Value<String?> imageType = const Value.absent(),
          Value<int?> pageId = const Value.absent(),
          Value<double?> xpos = const Value.absent(),
          Value<double?> ypos = const Value.absent()}) =>
      ImagesData(
        id: id ?? this.id,
        imageName: imageName.present ? imageName.value : this.imageName,
        imageType: imageType.present ? imageType.value : this.imageType,
        pageId: pageId.present ? pageId.value : this.pageId,
        xpos: xpos.present ? xpos.value : this.xpos,
        ypos: ypos.present ? ypos.value : this.ypos,
      );
  ImagesData copyWithCompanion(ImagesCompanion data) {
    return ImagesData(
      id: data.id.present ? data.id.value : this.id,
      imageName: data.imageName.present ? data.imageName.value : this.imageName,
      imageType: data.imageType.present ? data.imageType.value : this.imageType,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      xpos: data.xpos.present ? data.xpos.value : this.xpos,
      ypos: data.ypos.present ? data.ypos.value : this.ypos,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImagesData(')
          ..write('id: $id, ')
          ..write('imageName: $imageName, ')
          ..write('imageType: $imageType, ')
          ..write('pageId: $pageId, ')
          ..write('xpos: $xpos, ')
          ..write('ypos: $ypos')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, imageName, imageType, pageId, xpos, ypos);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImagesData &&
          other.id == this.id &&
          other.imageName == this.imageName &&
          other.imageType == this.imageType &&
          other.pageId == this.pageId &&
          other.xpos == this.xpos &&
          other.ypos == this.ypos);
}

class ImagesCompanion extends UpdateCompanion<ImagesData> {
  final Value<int> id;
  final Value<String?> imageName;
  final Value<String?> imageType;
  final Value<int?> pageId;
  final Value<double?> xpos;
  final Value<double?> ypos;
  const ImagesCompanion({
    this.id = const Value.absent(),
    this.imageName = const Value.absent(),
    this.imageType = const Value.absent(),
    this.pageId = const Value.absent(),
    this.xpos = const Value.absent(),
    this.ypos = const Value.absent(),
  });
  ImagesCompanion.insert({
    this.id = const Value.absent(),
    this.imageName = const Value.absent(),
    this.imageType = const Value.absent(),
    this.pageId = const Value.absent(),
    this.xpos = const Value.absent(),
    this.ypos = const Value.absent(),
  });
  static Insertable<ImagesData> custom({
    Expression<int>? id,
    Expression<String>? imageName,
    Expression<String>? imageType,
    Expression<int>? pageId,
    Expression<double>? xpos,
    Expression<double>? ypos,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (imageName != null) 'image_name': imageName,
      if (imageType != null) 'image_type': imageType,
      if (pageId != null) 'page_id': pageId,
      if (xpos != null) 'xpos': xpos,
      if (ypos != null) 'ypos': ypos,
    });
  }

  ImagesCompanion copyWith(
      {Value<int>? id,
      Value<String?>? imageName,
      Value<String?>? imageType,
      Value<int?>? pageId,
      Value<double?>? xpos,
      Value<double?>? ypos}) {
    return ImagesCompanion(
      id: id ?? this.id,
      imageName: imageName ?? this.imageName,
      imageType: imageType ?? this.imageType,
      pageId: pageId ?? this.pageId,
      xpos: xpos ?? this.xpos,
      ypos: ypos ?? this.ypos,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (imageName.present) {
      map['image_name'] = Variable<String>(imageName.value);
    }
    if (imageType.present) {
      map['image_type'] = Variable<String>(imageType.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<int>(pageId.value);
    }
    if (xpos.present) {
      map['xpos'] = Variable<double>(xpos.value);
    }
    if (ypos.present) {
      map['ypos'] = Variable<double>(ypos.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImagesCompanion(')
          ..write('id: $id, ')
          ..write('imageName: $imageName, ')
          ..write('imageType: $imageType, ')
          ..write('pageId: $pageId, ')
          ..write('xpos: $xpos, ')
          ..write('ypos: $ypos')
          ..write(')'))
        .toString();
  }
}

class Timer extends Table with TableInfo<Timer, TimerData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Timer(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  static const VerificationMeta _timerTemplateIdMeta =
      const VerificationMeta('timerTemplateId');
  late final GeneratedColumn<int> timerTemplateId = GeneratedColumn<int>(
      'timer_template_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
      'start_time', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  late final GeneratedColumn<int> pageId = GeneratedColumn<int>(
      'page_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns =>
      [id, timerTemplateId, startTime, pageId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timer';
  @override
  VerificationContext validateIntegrity(Insertable<TimerData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timer_template_id')) {
      context.handle(
          _timerTemplateIdMeta,
          timerTemplateId.isAcceptableOrUnknown(
              data['timer_template_id']!, _timerTemplateIdMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    }
    if (data.containsKey('page_id')) {
      context.handle(_pageIdMeta,
          pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimerData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimerData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      timerTemplateId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timer_template_id']),
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}start_time']),
      pageId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_id']),
    );
  }

  @override
  Timer createAlias(String alias) {
    return Timer(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class TimerData extends DataClass implements Insertable<TimerData> {
  final int id;
  final int? timerTemplateId;
  final String? startTime;
  final int? pageId;
  const TimerData(
      {required this.id, this.timerTemplateId, this.startTime, this.pageId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || timerTemplateId != null) {
      map['timer_template_id'] = Variable<int>(timerTemplateId);
    }
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<String>(startTime);
    }
    if (!nullToAbsent || pageId != null) {
      map['page_id'] = Variable<int>(pageId);
    }
    return map;
  }

  TimerCompanion toCompanion(bool nullToAbsent) {
    return TimerCompanion(
      id: Value(id),
      timerTemplateId: timerTemplateId == null && nullToAbsent
          ? const Value.absent()
          : Value(timerTemplateId),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      pageId:
          pageId == null && nullToAbsent ? const Value.absent() : Value(pageId),
    );
  }

  factory TimerData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimerData(
      id: serializer.fromJson<int>(json['id']),
      timerTemplateId: serializer.fromJson<int?>(json['timer_template_id']),
      startTime: serializer.fromJson<String?>(json['start_time']),
      pageId: serializer.fromJson<int?>(json['page_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timer_template_id': serializer.toJson<int?>(timerTemplateId),
      'start_time': serializer.toJson<String?>(startTime),
      'page_id': serializer.toJson<int?>(pageId),
    };
  }

  TimerData copyWith(
          {int? id,
          Value<int?> timerTemplateId = const Value.absent(),
          Value<String?> startTime = const Value.absent(),
          Value<int?> pageId = const Value.absent()}) =>
      TimerData(
        id: id ?? this.id,
        timerTemplateId: timerTemplateId.present
            ? timerTemplateId.value
            : this.timerTemplateId,
        startTime: startTime.present ? startTime.value : this.startTime,
        pageId: pageId.present ? pageId.value : this.pageId,
      );
  TimerData copyWithCompanion(TimerCompanion data) {
    return TimerData(
      id: data.id.present ? data.id.value : this.id,
      timerTemplateId: data.timerTemplateId.present
          ? data.timerTemplateId.value
          : this.timerTemplateId,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimerData(')
          ..write('id: $id, ')
          ..write('timerTemplateId: $timerTemplateId, ')
          ..write('startTime: $startTime, ')
          ..write('pageId: $pageId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, timerTemplateId, startTime, pageId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimerData &&
          other.id == this.id &&
          other.timerTemplateId == this.timerTemplateId &&
          other.startTime == this.startTime &&
          other.pageId == this.pageId);
}

class TimerCompanion extends UpdateCompanion<TimerData> {
  final Value<int> id;
  final Value<int?> timerTemplateId;
  final Value<String?> startTime;
  final Value<int?> pageId;
  const TimerCompanion({
    this.id = const Value.absent(),
    this.timerTemplateId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.pageId = const Value.absent(),
  });
  TimerCompanion.insert({
    this.id = const Value.absent(),
    this.timerTemplateId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.pageId = const Value.absent(),
  });
  static Insertable<TimerData> custom({
    Expression<int>? id,
    Expression<int>? timerTemplateId,
    Expression<String>? startTime,
    Expression<int>? pageId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timerTemplateId != null) 'timer_template_id': timerTemplateId,
      if (startTime != null) 'start_time': startTime,
      if (pageId != null) 'page_id': pageId,
    });
  }

  TimerCompanion copyWith(
      {Value<int>? id,
      Value<int?>? timerTemplateId,
      Value<String?>? startTime,
      Value<int?>? pageId}) {
    return TimerCompanion(
      id: id ?? this.id,
      timerTemplateId: timerTemplateId ?? this.timerTemplateId,
      startTime: startTime ?? this.startTime,
      pageId: pageId ?? this.pageId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timerTemplateId.present) {
      map['timer_template_id'] = Variable<int>(timerTemplateId.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<int>(pageId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimerCompanion(')
          ..write('id: $id, ')
          ..write('timerTemplateId: $timerTemplateId, ')
          ..write('startTime: $startTime, ')
          ..write('pageId: $pageId')
          ..write(')'))
        .toString();
  }
}

class Page extends Table with TableInfo<Page, PageData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Page(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  static const VerificationMeta _pageNameMeta =
      const VerificationMeta('pageName');
  late final GeneratedColumn<String> pageName = GeneratedColumn<String>(
      'page_name', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _sectionNameMeta =
      const VerificationMeta('sectionName');
  late final GeneratedColumn<String> sectionName = GeneratedColumn<String>(
      'section_name', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _fontNameMeta =
      const VerificationMeta('fontName');
  late final GeneratedColumn<String> fontName = GeneratedColumn<String>(
      'font_name', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _bgmNameMeta =
      const VerificationMeta('bgmName');
  late final GeneratedColumn<String> bgmName = GeneratedColumn<String>(
      'bgm_name', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _pageTypeIdMeta =
      const VerificationMeta('pageTypeId');
  late final GeneratedColumn<String> pageTypeId = GeneratedColumn<String>(
      'page_type_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _hotkeyValueMeta =
      const VerificationMeta('hotkeyValue');
  late final GeneratedColumn<String> hotkeyValue = GeneratedColumn<String>(
      'hotkey_value', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _flowIdMeta = const VerificationMeta('flowId');
  late final GeneratedColumn<int> flowId = GeneratedColumn<int>(
      'flow_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _pagePositionMeta =
      const VerificationMeta('pagePosition');
  late final GeneratedColumn<int> pagePosition = GeneratedColumn<int>(
      'page_position', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns => [
        id,
        pageName,
        sectionName,
        fontName,
        bgmName,
        pageTypeId,
        hotkeyValue,
        flowId,
        pagePosition
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'page';
  @override
  VerificationContext validateIntegrity(Insertable<PageData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('page_name')) {
      context.handle(_pageNameMeta,
          pageName.isAcceptableOrUnknown(data['page_name']!, _pageNameMeta));
    }
    if (data.containsKey('section_name')) {
      context.handle(
          _sectionNameMeta,
          sectionName.isAcceptableOrUnknown(
              data['section_name']!, _sectionNameMeta));
    }
    if (data.containsKey('font_name')) {
      context.handle(_fontNameMeta,
          fontName.isAcceptableOrUnknown(data['font_name']!, _fontNameMeta));
    }
    if (data.containsKey('bgm_name')) {
      context.handle(_bgmNameMeta,
          bgmName.isAcceptableOrUnknown(data['bgm_name']!, _bgmNameMeta));
    }
    if (data.containsKey('page_type_id')) {
      context.handle(
          _pageTypeIdMeta,
          pageTypeId.isAcceptableOrUnknown(
              data['page_type_id']!, _pageTypeIdMeta));
    }
    if (data.containsKey('hotkey_value')) {
      context.handle(
          _hotkeyValueMeta,
          hotkeyValue.isAcceptableOrUnknown(
              data['hotkey_value']!, _hotkeyValueMeta));
    }
    if (data.containsKey('flow_id')) {
      context.handle(_flowIdMeta,
          flowId.isAcceptableOrUnknown(data['flow_id']!, _flowIdMeta));
    }
    if (data.containsKey('page_position')) {
      context.handle(
          _pagePositionMeta,
          pagePosition.isAcceptableOrUnknown(
              data['page_position']!, _pagePositionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PageData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PageData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      pageName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}page_name']),
      sectionName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}section_name']),
      fontName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}font_name']),
      bgmName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bgm_name']),
      pageTypeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}page_type_id']),
      hotkeyValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hotkey_value']),
      flowId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}flow_id']),
      pagePosition: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_position']),
    );
  }

  @override
  Page createAlias(String alias) {
    return Page(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PageData extends DataClass implements Insertable<PageData> {
  final int id;
  final String? pageName;
  final String? sectionName;
  final String? fontName;
  final String? bgmName;
  final String? pageTypeId;
  final String? hotkeyValue;

  /// only available for bonuses pages
  final int? flowId;
  final int? pagePosition;
  const PageData(
      {required this.id,
      this.pageName,
      this.sectionName,
      this.fontName,
      this.bgmName,
      this.pageTypeId,
      this.hotkeyValue,
      this.flowId,
      this.pagePosition});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || pageName != null) {
      map['page_name'] = Variable<String>(pageName);
    }
    if (!nullToAbsent || sectionName != null) {
      map['section_name'] = Variable<String>(sectionName);
    }
    if (!nullToAbsent || fontName != null) {
      map['font_name'] = Variable<String>(fontName);
    }
    if (!nullToAbsent || bgmName != null) {
      map['bgm_name'] = Variable<String>(bgmName);
    }
    if (!nullToAbsent || pageTypeId != null) {
      map['page_type_id'] = Variable<String>(pageTypeId);
    }
    if (!nullToAbsent || hotkeyValue != null) {
      map['hotkey_value'] = Variable<String>(hotkeyValue);
    }
    if (!nullToAbsent || flowId != null) {
      map['flow_id'] = Variable<int>(flowId);
    }
    if (!nullToAbsent || pagePosition != null) {
      map['page_position'] = Variable<int>(pagePosition);
    }
    return map;
  }

  PageCompanion toCompanion(bool nullToAbsent) {
    return PageCompanion(
      id: Value(id),
      pageName: pageName == null && nullToAbsent
          ? const Value.absent()
          : Value(pageName),
      sectionName: sectionName == null && nullToAbsent
          ? const Value.absent()
          : Value(sectionName),
      fontName: fontName == null && nullToAbsent
          ? const Value.absent()
          : Value(fontName),
      bgmName: bgmName == null && nullToAbsent
          ? const Value.absent()
          : Value(bgmName),
      pageTypeId: pageTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(pageTypeId),
      hotkeyValue: hotkeyValue == null && nullToAbsent
          ? const Value.absent()
          : Value(hotkeyValue),
      flowId:
          flowId == null && nullToAbsent ? const Value.absent() : Value(flowId),
      pagePosition: pagePosition == null && nullToAbsent
          ? const Value.absent()
          : Value(pagePosition),
    );
  }

  factory PageData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PageData(
      id: serializer.fromJson<int>(json['id']),
      pageName: serializer.fromJson<String?>(json['page_name']),
      sectionName: serializer.fromJson<String?>(json['section_name']),
      fontName: serializer.fromJson<String?>(json['font_name']),
      bgmName: serializer.fromJson<String?>(json['bgm_name']),
      pageTypeId: serializer.fromJson<String?>(json['page_type_id']),
      hotkeyValue: serializer.fromJson<String?>(json['hotkey_value']),
      flowId: serializer.fromJson<int?>(json['flow_id']),
      pagePosition: serializer.fromJson<int?>(json['page_position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'page_name': serializer.toJson<String?>(pageName),
      'section_name': serializer.toJson<String?>(sectionName),
      'font_name': serializer.toJson<String?>(fontName),
      'bgm_name': serializer.toJson<String?>(bgmName),
      'page_type_id': serializer.toJson<String?>(pageTypeId),
      'hotkey_value': serializer.toJson<String?>(hotkeyValue),
      'flow_id': serializer.toJson<int?>(flowId),
      'page_position': serializer.toJson<int?>(pagePosition),
    };
  }

  PageData copyWith(
          {int? id,
          Value<String?> pageName = const Value.absent(),
          Value<String?> sectionName = const Value.absent(),
          Value<String?> fontName = const Value.absent(),
          Value<String?> bgmName = const Value.absent(),
          Value<String?> pageTypeId = const Value.absent(),
          Value<String?> hotkeyValue = const Value.absent(),
          Value<int?> flowId = const Value.absent(),
          Value<int?> pagePosition = const Value.absent()}) =>
      PageData(
        id: id ?? this.id,
        pageName: pageName.present ? pageName.value : this.pageName,
        sectionName: sectionName.present ? sectionName.value : this.sectionName,
        fontName: fontName.present ? fontName.value : this.fontName,
        bgmName: bgmName.present ? bgmName.value : this.bgmName,
        pageTypeId: pageTypeId.present ? pageTypeId.value : this.pageTypeId,
        hotkeyValue: hotkeyValue.present ? hotkeyValue.value : this.hotkeyValue,
        flowId: flowId.present ? flowId.value : this.flowId,
        pagePosition:
            pagePosition.present ? pagePosition.value : this.pagePosition,
      );
  PageData copyWithCompanion(PageCompanion data) {
    return PageData(
      id: data.id.present ? data.id.value : this.id,
      pageName: data.pageName.present ? data.pageName.value : this.pageName,
      sectionName:
          data.sectionName.present ? data.sectionName.value : this.sectionName,
      fontName: data.fontName.present ? data.fontName.value : this.fontName,
      bgmName: data.bgmName.present ? data.bgmName.value : this.bgmName,
      pageTypeId:
          data.pageTypeId.present ? data.pageTypeId.value : this.pageTypeId,
      hotkeyValue:
          data.hotkeyValue.present ? data.hotkeyValue.value : this.hotkeyValue,
      flowId: data.flowId.present ? data.flowId.value : this.flowId,
      pagePosition: data.pagePosition.present
          ? data.pagePosition.value
          : this.pagePosition,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PageData(')
          ..write('id: $id, ')
          ..write('pageName: $pageName, ')
          ..write('sectionName: $sectionName, ')
          ..write('fontName: $fontName, ')
          ..write('bgmName: $bgmName, ')
          ..write('pageTypeId: $pageTypeId, ')
          ..write('hotkeyValue: $hotkeyValue, ')
          ..write('flowId: $flowId, ')
          ..write('pagePosition: $pagePosition')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pageName, sectionName, fontName, bgmName,
      pageTypeId, hotkeyValue, flowId, pagePosition);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PageData &&
          other.id == this.id &&
          other.pageName == this.pageName &&
          other.sectionName == this.sectionName &&
          other.fontName == this.fontName &&
          other.bgmName == this.bgmName &&
          other.pageTypeId == this.pageTypeId &&
          other.hotkeyValue == this.hotkeyValue &&
          other.flowId == this.flowId &&
          other.pagePosition == this.pagePosition);
}

class PageCompanion extends UpdateCompanion<PageData> {
  final Value<int> id;
  final Value<String?> pageName;
  final Value<String?> sectionName;
  final Value<String?> fontName;
  final Value<String?> bgmName;
  final Value<String?> pageTypeId;
  final Value<String?> hotkeyValue;
  final Value<int?> flowId;
  final Value<int?> pagePosition;
  const PageCompanion({
    this.id = const Value.absent(),
    this.pageName = const Value.absent(),
    this.sectionName = const Value.absent(),
    this.fontName = const Value.absent(),
    this.bgmName = const Value.absent(),
    this.pageTypeId = const Value.absent(),
    this.hotkeyValue = const Value.absent(),
    this.flowId = const Value.absent(),
    this.pagePosition = const Value.absent(),
  });
  PageCompanion.insert({
    this.id = const Value.absent(),
    this.pageName = const Value.absent(),
    this.sectionName = const Value.absent(),
    this.fontName = const Value.absent(),
    this.bgmName = const Value.absent(),
    this.pageTypeId = const Value.absent(),
    this.hotkeyValue = const Value.absent(),
    this.flowId = const Value.absent(),
    this.pagePosition = const Value.absent(),
  });
  static Insertable<PageData> custom({
    Expression<int>? id,
    Expression<String>? pageName,
    Expression<String>? sectionName,
    Expression<String>? fontName,
    Expression<String>? bgmName,
    Expression<String>? pageTypeId,
    Expression<String>? hotkeyValue,
    Expression<int>? flowId,
    Expression<int>? pagePosition,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pageName != null) 'page_name': pageName,
      if (sectionName != null) 'section_name': sectionName,
      if (fontName != null) 'font_name': fontName,
      if (bgmName != null) 'bgm_name': bgmName,
      if (pageTypeId != null) 'page_type_id': pageTypeId,
      if (hotkeyValue != null) 'hotkey_value': hotkeyValue,
      if (flowId != null) 'flow_id': flowId,
      if (pagePosition != null) 'page_position': pagePosition,
    });
  }

  PageCompanion copyWith(
      {Value<int>? id,
      Value<String?>? pageName,
      Value<String?>? sectionName,
      Value<String?>? fontName,
      Value<String?>? bgmName,
      Value<String?>? pageTypeId,
      Value<String?>? hotkeyValue,
      Value<int?>? flowId,
      Value<int?>? pagePosition}) {
    return PageCompanion(
      id: id ?? this.id,
      pageName: pageName ?? this.pageName,
      sectionName: sectionName ?? this.sectionName,
      fontName: fontName ?? this.fontName,
      bgmName: bgmName ?? this.bgmName,
      pageTypeId: pageTypeId ?? this.pageTypeId,
      hotkeyValue: hotkeyValue ?? this.hotkeyValue,
      flowId: flowId ?? this.flowId,
      pagePosition: pagePosition ?? this.pagePosition,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pageName.present) {
      map['page_name'] = Variable<String>(pageName.value);
    }
    if (sectionName.present) {
      map['section_name'] = Variable<String>(sectionName.value);
    }
    if (fontName.present) {
      map['font_name'] = Variable<String>(fontName.value);
    }
    if (bgmName.present) {
      map['bgm_name'] = Variable<String>(bgmName.value);
    }
    if (pageTypeId.present) {
      map['page_type_id'] = Variable<String>(pageTypeId.value);
    }
    if (hotkeyValue.present) {
      map['hotkey_value'] = Variable<String>(hotkeyValue.value);
    }
    if (flowId.present) {
      map['flow_id'] = Variable<int>(flowId.value);
    }
    if (pagePosition.present) {
      map['page_position'] = Variable<int>(pagePosition.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PageCompanion(')
          ..write('id: $id, ')
          ..write('pageName: $pageName, ')
          ..write('sectionName: $sectionName, ')
          ..write('fontName: $fontName, ')
          ..write('bgmName: $bgmName, ')
          ..write('pageTypeId: $pageTypeId, ')
          ..write('hotkeyValue: $hotkeyValue, ')
          ..write('flowId: $flowId, ')
          ..write('pagePosition: $pagePosition')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final Event event = Event(this);
  late final TimerTemplate timerTemplate = TimerTemplate(this);
  late final DingValue dingValue = DingValue(this);
  late final Flow flow = Flow(this);
  late final Images images = Images(this);
  late final Timer timer = Timer(this);
  late final Page page = Page(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [event, timerTemplate, dingValue, flow, images, timer, page];
}

typedef $EventCreateCompanionBuilder = EventCompanion Function({
  Value<int> id,
  required String eventName,
  Value<String?> eventDesc,
  Value<DateTime?> startDate,
  Value<DateTime?> endDate,
  Value<int?> teamNum,
  Value<String?> remark,
});
typedef $EventUpdateCompanionBuilder = EventCompanion Function({
  Value<int> id,
  Value<String> eventName,
  Value<String?> eventDesc,
  Value<DateTime?> startDate,
  Value<DateTime?> endDate,
  Value<int?> teamNum,
  Value<String?> remark,
});

class $EventFilterComposer extends Composer<_$AppDatabase, Event> {
  $EventFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventName => $composableBuilder(
      column: $table.eventName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventDesc => $composableBuilder(
      column: $table.eventDesc, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get teamNum => $composableBuilder(
      column: $table.teamNum, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remark => $composableBuilder(
      column: $table.remark, builder: (column) => ColumnFilters(column));
}

class $EventOrderingComposer extends Composer<_$AppDatabase, Event> {
  $EventOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventName => $composableBuilder(
      column: $table.eventName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventDesc => $composableBuilder(
      column: $table.eventDesc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get teamNum => $composableBuilder(
      column: $table.teamNum, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remark => $composableBuilder(
      column: $table.remark, builder: (column) => ColumnOrderings(column));
}

class $EventAnnotationComposer extends Composer<_$AppDatabase, Event> {
  $EventAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventName =>
      $composableBuilder(column: $table.eventName, builder: (column) => column);

  GeneratedColumn<String> get eventDesc =>
      $composableBuilder(column: $table.eventDesc, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get teamNum =>
      $composableBuilder(column: $table.teamNum, builder: (column) => column);

  GeneratedColumn<String> get remark =>
      $composableBuilder(column: $table.remark, builder: (column) => column);
}

class $EventTableManager extends RootTableManager<
    _$AppDatabase,
    Event,
    EventData,
    $EventFilterComposer,
    $EventOrderingComposer,
    $EventAnnotationComposer,
    $EventCreateCompanionBuilder,
    $EventUpdateCompanionBuilder,
    (EventData, BaseReferences<_$AppDatabase, Event, EventData>),
    EventData,
    PrefetchHooks Function()> {
  $EventTableManager(_$AppDatabase db, Event table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $EventFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $EventOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $EventAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> eventName = const Value.absent(),
            Value<String?> eventDesc = const Value.absent(),
            Value<DateTime?> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<int?> teamNum = const Value.absent(),
            Value<String?> remark = const Value.absent(),
          }) =>
              EventCompanion(
            id: id,
            eventName: eventName,
            eventDesc: eventDesc,
            startDate: startDate,
            endDate: endDate,
            teamNum: teamNum,
            remark: remark,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String eventName,
            Value<String?> eventDesc = const Value.absent(),
            Value<DateTime?> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<int?> teamNum = const Value.absent(),
            Value<String?> remark = const Value.absent(),
          }) =>
              EventCompanion.insert(
            id: id,
            eventName: eventName,
            eventDesc: eventDesc,
            startDate: startDate,
            endDate: endDate,
            teamNum: teamNum,
            remark: remark,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $EventProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    Event,
    EventData,
    $EventFilterComposer,
    $EventOrderingComposer,
    $EventAnnotationComposer,
    $EventCreateCompanionBuilder,
    $EventUpdateCompanionBuilder,
    (EventData, BaseReferences<_$AppDatabase, Event, EventData>),
    EventData,
    PrefetchHooks Function()>;
typedef $TimerTemplateCreateCompanionBuilder = TimerTemplateCompanion Function({
  Value<int> id,
  Value<DateTime?> createdAt,
});
typedef $TimerTemplateUpdateCompanionBuilder = TimerTemplateCompanion Function({
  Value<int> id,
  Value<DateTime?> createdAt,
});

class $TimerTemplateFilterComposer
    extends Composer<_$AppDatabase, TimerTemplate> {
  $TimerTemplateFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $TimerTemplateOrderingComposer
    extends Composer<_$AppDatabase, TimerTemplate> {
  $TimerTemplateOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $TimerTemplateAnnotationComposer
    extends Composer<_$AppDatabase, TimerTemplate> {
  $TimerTemplateAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $TimerTemplateTableManager extends RootTableManager<
    _$AppDatabase,
    TimerTemplate,
    TimerTemplateData,
    $TimerTemplateFilterComposer,
    $TimerTemplateOrderingComposer,
    $TimerTemplateAnnotationComposer,
    $TimerTemplateCreateCompanionBuilder,
    $TimerTemplateUpdateCompanionBuilder,
    (
      TimerTemplateData,
      BaseReferences<_$AppDatabase, TimerTemplate, TimerTemplateData>
    ),
    TimerTemplateData,
    PrefetchHooks Function()> {
  $TimerTemplateTableManager(_$AppDatabase db, TimerTemplate table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TimerTemplateFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TimerTemplateOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TimerTemplateAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
          }) =>
              TimerTemplateCompanion(
            id: id,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
          }) =>
              TimerTemplateCompanion.insert(
            id: id,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $TimerTemplateProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    TimerTemplate,
    TimerTemplateData,
    $TimerTemplateFilterComposer,
    $TimerTemplateOrderingComposer,
    $TimerTemplateAnnotationComposer,
    $TimerTemplateCreateCompanionBuilder,
    $TimerTemplateUpdateCompanionBuilder,
    (
      TimerTemplateData,
      BaseReferences<_$AppDatabase, TimerTemplate, TimerTemplateData>
    ),
    TimerTemplateData,
    PrefetchHooks Function()>;
typedef $DingValueCreateCompanionBuilder = DingValueCompanion Function({
  Value<int> id,
  Value<String?> dingTime,
  Value<int?> dingAmount,
  Value<int?> timerTemplateId,
});
typedef $DingValueUpdateCompanionBuilder = DingValueCompanion Function({
  Value<int> id,
  Value<String?> dingTime,
  Value<int?> dingAmount,
  Value<int?> timerTemplateId,
});

class $DingValueFilterComposer extends Composer<_$AppDatabase, DingValue> {
  $DingValueFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dingTime => $composableBuilder(
      column: $table.dingTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dingAmount => $composableBuilder(
      column: $table.dingAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timerTemplateId => $composableBuilder(
      column: $table.timerTemplateId,
      builder: (column) => ColumnFilters(column));
}

class $DingValueOrderingComposer extends Composer<_$AppDatabase, DingValue> {
  $DingValueOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dingTime => $composableBuilder(
      column: $table.dingTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dingAmount => $composableBuilder(
      column: $table.dingAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timerTemplateId => $composableBuilder(
      column: $table.timerTemplateId,
      builder: (column) => ColumnOrderings(column));
}

class $DingValueAnnotationComposer extends Composer<_$AppDatabase, DingValue> {
  $DingValueAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dingTime =>
      $composableBuilder(column: $table.dingTime, builder: (column) => column);

  GeneratedColumn<int> get dingAmount => $composableBuilder(
      column: $table.dingAmount, builder: (column) => column);

  GeneratedColumn<int> get timerTemplateId => $composableBuilder(
      column: $table.timerTemplateId, builder: (column) => column);
}

class $DingValueTableManager extends RootTableManager<
    _$AppDatabase,
    DingValue,
    DingValueData,
    $DingValueFilterComposer,
    $DingValueOrderingComposer,
    $DingValueAnnotationComposer,
    $DingValueCreateCompanionBuilder,
    $DingValueUpdateCompanionBuilder,
    (DingValueData, BaseReferences<_$AppDatabase, DingValue, DingValueData>),
    DingValueData,
    PrefetchHooks Function()> {
  $DingValueTableManager(_$AppDatabase db, DingValue table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DingValueFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DingValueOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DingValueAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> dingTime = const Value.absent(),
            Value<int?> dingAmount = const Value.absent(),
            Value<int?> timerTemplateId = const Value.absent(),
          }) =>
              DingValueCompanion(
            id: id,
            dingTime: dingTime,
            dingAmount: dingAmount,
            timerTemplateId: timerTemplateId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> dingTime = const Value.absent(),
            Value<int?> dingAmount = const Value.absent(),
            Value<int?> timerTemplateId = const Value.absent(),
          }) =>
              DingValueCompanion.insert(
            id: id,
            dingTime: dingTime,
            dingAmount: dingAmount,
            timerTemplateId: timerTemplateId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $DingValueProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    DingValue,
    DingValueData,
    $DingValueFilterComposer,
    $DingValueOrderingComposer,
    $DingValueAnnotationComposer,
    $DingValueCreateCompanionBuilder,
    $DingValueUpdateCompanionBuilder,
    (DingValueData, BaseReferences<_$AppDatabase, DingValue, DingValueData>),
    DingValueData,
    PrefetchHooks Function()>;
typedef $FlowCreateCompanionBuilder = FlowCompanion Function({
  Value<int> id,
  Value<String?> flowName,
  Value<int?> eventId,
});
typedef $FlowUpdateCompanionBuilder = FlowCompanion Function({
  Value<int> id,
  Value<String?> flowName,
  Value<int?> eventId,
});

class $FlowFilterComposer extends Composer<_$AppDatabase, Flow> {
  $FlowFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get flowName => $composableBuilder(
      column: $table.flowName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnFilters(column));
}

class $FlowOrderingComposer extends Composer<_$AppDatabase, Flow> {
  $FlowOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get flowName => $composableBuilder(
      column: $table.flowName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnOrderings(column));
}

class $FlowAnnotationComposer extends Composer<_$AppDatabase, Flow> {
  $FlowAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get flowName =>
      $composableBuilder(column: $table.flowName, builder: (column) => column);

  GeneratedColumn<int> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);
}

class $FlowTableManager extends RootTableManager<
    _$AppDatabase,
    Flow,
    FlowData,
    $FlowFilterComposer,
    $FlowOrderingComposer,
    $FlowAnnotationComposer,
    $FlowCreateCompanionBuilder,
    $FlowUpdateCompanionBuilder,
    (FlowData, BaseReferences<_$AppDatabase, Flow, FlowData>),
    FlowData,
    PrefetchHooks Function()> {
  $FlowTableManager(_$AppDatabase db, Flow table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $FlowFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $FlowOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $FlowAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> flowName = const Value.absent(),
            Value<int?> eventId = const Value.absent(),
          }) =>
              FlowCompanion(
            id: id,
            flowName: flowName,
            eventId: eventId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> flowName = const Value.absent(),
            Value<int?> eventId = const Value.absent(),
          }) =>
              FlowCompanion.insert(
            id: id,
            flowName: flowName,
            eventId: eventId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $FlowProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    Flow,
    FlowData,
    $FlowFilterComposer,
    $FlowOrderingComposer,
    $FlowAnnotationComposer,
    $FlowCreateCompanionBuilder,
    $FlowUpdateCompanionBuilder,
    (FlowData, BaseReferences<_$AppDatabase, Flow, FlowData>),
    FlowData,
    PrefetchHooks Function()>;
typedef $ImagesCreateCompanionBuilder = ImagesCompanion Function({
  Value<int> id,
  Value<String?> imageName,
  Value<String?> imageType,
  Value<int?> pageId,
  Value<double?> xpos,
  Value<double?> ypos,
});
typedef $ImagesUpdateCompanionBuilder = ImagesCompanion Function({
  Value<int> id,
  Value<String?> imageName,
  Value<String?> imageType,
  Value<int?> pageId,
  Value<double?> xpos,
  Value<double?> ypos,
});

class $ImagesFilterComposer extends Composer<_$AppDatabase, Images> {
  $ImagesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageName => $composableBuilder(
      column: $table.imageName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageType => $composableBuilder(
      column: $table.imageType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pageId => $composableBuilder(
      column: $table.pageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get xpos => $composableBuilder(
      column: $table.xpos, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get ypos => $composableBuilder(
      column: $table.ypos, builder: (column) => ColumnFilters(column));
}

class $ImagesOrderingComposer extends Composer<_$AppDatabase, Images> {
  $ImagesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageName => $composableBuilder(
      column: $table.imageName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageType => $composableBuilder(
      column: $table.imageType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pageId => $composableBuilder(
      column: $table.pageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get xpos => $composableBuilder(
      column: $table.xpos, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get ypos => $composableBuilder(
      column: $table.ypos, builder: (column) => ColumnOrderings(column));
}

class $ImagesAnnotationComposer extends Composer<_$AppDatabase, Images> {
  $ImagesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get imageName =>
      $composableBuilder(column: $table.imageName, builder: (column) => column);

  GeneratedColumn<String> get imageType =>
      $composableBuilder(column: $table.imageType, builder: (column) => column);

  GeneratedColumn<int> get pageId =>
      $composableBuilder(column: $table.pageId, builder: (column) => column);

  GeneratedColumn<double> get xpos =>
      $composableBuilder(column: $table.xpos, builder: (column) => column);

  GeneratedColumn<double> get ypos =>
      $composableBuilder(column: $table.ypos, builder: (column) => column);
}

class $ImagesTableManager extends RootTableManager<
    _$AppDatabase,
    Images,
    ImagesData,
    $ImagesFilterComposer,
    $ImagesOrderingComposer,
    $ImagesAnnotationComposer,
    $ImagesCreateCompanionBuilder,
    $ImagesUpdateCompanionBuilder,
    (ImagesData, BaseReferences<_$AppDatabase, Images, ImagesData>),
    ImagesData,
    PrefetchHooks Function()> {
  $ImagesTableManager(_$AppDatabase db, Images table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ImagesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ImagesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ImagesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> imageName = const Value.absent(),
            Value<String?> imageType = const Value.absent(),
            Value<int?> pageId = const Value.absent(),
            Value<double?> xpos = const Value.absent(),
            Value<double?> ypos = const Value.absent(),
          }) =>
              ImagesCompanion(
            id: id,
            imageName: imageName,
            imageType: imageType,
            pageId: pageId,
            xpos: xpos,
            ypos: ypos,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> imageName = const Value.absent(),
            Value<String?> imageType = const Value.absent(),
            Value<int?> pageId = const Value.absent(),
            Value<double?> xpos = const Value.absent(),
            Value<double?> ypos = const Value.absent(),
          }) =>
              ImagesCompanion.insert(
            id: id,
            imageName: imageName,
            imageType: imageType,
            pageId: pageId,
            xpos: xpos,
            ypos: ypos,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $ImagesProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    Images,
    ImagesData,
    $ImagesFilterComposer,
    $ImagesOrderingComposer,
    $ImagesAnnotationComposer,
    $ImagesCreateCompanionBuilder,
    $ImagesUpdateCompanionBuilder,
    (ImagesData, BaseReferences<_$AppDatabase, Images, ImagesData>),
    ImagesData,
    PrefetchHooks Function()>;
typedef $TimerCreateCompanionBuilder = TimerCompanion Function({
  Value<int> id,
  Value<int?> timerTemplateId,
  Value<String?> startTime,
  Value<int?> pageId,
});
typedef $TimerUpdateCompanionBuilder = TimerCompanion Function({
  Value<int> id,
  Value<int?> timerTemplateId,
  Value<String?> startTime,
  Value<int?> pageId,
});

class $TimerFilterComposer extends Composer<_$AppDatabase, Timer> {
  $TimerFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timerTemplateId => $composableBuilder(
      column: $table.timerTemplateId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pageId => $composableBuilder(
      column: $table.pageId, builder: (column) => ColumnFilters(column));
}

class $TimerOrderingComposer extends Composer<_$AppDatabase, Timer> {
  $TimerOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timerTemplateId => $composableBuilder(
      column: $table.timerTemplateId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pageId => $composableBuilder(
      column: $table.pageId, builder: (column) => ColumnOrderings(column));
}

class $TimerAnnotationComposer extends Composer<_$AppDatabase, Timer> {
  $TimerAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get timerTemplateId => $composableBuilder(
      column: $table.timerTemplateId, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get pageId =>
      $composableBuilder(column: $table.pageId, builder: (column) => column);
}

class $TimerTableManager extends RootTableManager<
    _$AppDatabase,
    Timer,
    TimerData,
    $TimerFilterComposer,
    $TimerOrderingComposer,
    $TimerAnnotationComposer,
    $TimerCreateCompanionBuilder,
    $TimerUpdateCompanionBuilder,
    (TimerData, BaseReferences<_$AppDatabase, Timer, TimerData>),
    TimerData,
    PrefetchHooks Function()> {
  $TimerTableManager(_$AppDatabase db, Timer table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TimerFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TimerOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TimerAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> timerTemplateId = const Value.absent(),
            Value<String?> startTime = const Value.absent(),
            Value<int?> pageId = const Value.absent(),
          }) =>
              TimerCompanion(
            id: id,
            timerTemplateId: timerTemplateId,
            startTime: startTime,
            pageId: pageId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> timerTemplateId = const Value.absent(),
            Value<String?> startTime = const Value.absent(),
            Value<int?> pageId = const Value.absent(),
          }) =>
              TimerCompanion.insert(
            id: id,
            timerTemplateId: timerTemplateId,
            startTime: startTime,
            pageId: pageId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $TimerProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    Timer,
    TimerData,
    $TimerFilterComposer,
    $TimerOrderingComposer,
    $TimerAnnotationComposer,
    $TimerCreateCompanionBuilder,
    $TimerUpdateCompanionBuilder,
    (TimerData, BaseReferences<_$AppDatabase, Timer, TimerData>),
    TimerData,
    PrefetchHooks Function()>;
typedef $PageCreateCompanionBuilder = PageCompanion Function({
  Value<int> id,
  Value<String?> pageName,
  Value<String?> sectionName,
  Value<String?> fontName,
  Value<String?> bgmName,
  Value<String?> pageTypeId,
  Value<String?> hotkeyValue,
  Value<int?> flowId,
  Value<int?> pagePosition,
});
typedef $PageUpdateCompanionBuilder = PageCompanion Function({
  Value<int> id,
  Value<String?> pageName,
  Value<String?> sectionName,
  Value<String?> fontName,
  Value<String?> bgmName,
  Value<String?> pageTypeId,
  Value<String?> hotkeyValue,
  Value<int?> flowId,
  Value<int?> pagePosition,
});

class $PageFilterComposer extends Composer<_$AppDatabase, Page> {
  $PageFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pageName => $composableBuilder(
      column: $table.pageName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sectionName => $composableBuilder(
      column: $table.sectionName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fontName => $composableBuilder(
      column: $table.fontName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bgmName => $composableBuilder(
      column: $table.bgmName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pageTypeId => $composableBuilder(
      column: $table.pageTypeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hotkeyValue => $composableBuilder(
      column: $table.hotkeyValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get flowId => $composableBuilder(
      column: $table.flowId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pagePosition => $composableBuilder(
      column: $table.pagePosition, builder: (column) => ColumnFilters(column));
}

class $PageOrderingComposer extends Composer<_$AppDatabase, Page> {
  $PageOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pageName => $composableBuilder(
      column: $table.pageName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sectionName => $composableBuilder(
      column: $table.sectionName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fontName => $composableBuilder(
      column: $table.fontName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bgmName => $composableBuilder(
      column: $table.bgmName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pageTypeId => $composableBuilder(
      column: $table.pageTypeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hotkeyValue => $composableBuilder(
      column: $table.hotkeyValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get flowId => $composableBuilder(
      column: $table.flowId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pagePosition => $composableBuilder(
      column: $table.pagePosition,
      builder: (column) => ColumnOrderings(column));
}

class $PageAnnotationComposer extends Composer<_$AppDatabase, Page> {
  $PageAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pageName =>
      $composableBuilder(column: $table.pageName, builder: (column) => column);

  GeneratedColumn<String> get sectionName => $composableBuilder(
      column: $table.sectionName, builder: (column) => column);

  GeneratedColumn<String> get fontName =>
      $composableBuilder(column: $table.fontName, builder: (column) => column);

  GeneratedColumn<String> get bgmName =>
      $composableBuilder(column: $table.bgmName, builder: (column) => column);

  GeneratedColumn<String> get pageTypeId => $composableBuilder(
      column: $table.pageTypeId, builder: (column) => column);

  GeneratedColumn<String> get hotkeyValue => $composableBuilder(
      column: $table.hotkeyValue, builder: (column) => column);

  GeneratedColumn<int> get flowId =>
      $composableBuilder(column: $table.flowId, builder: (column) => column);

  GeneratedColumn<int> get pagePosition => $composableBuilder(
      column: $table.pagePosition, builder: (column) => column);
}

class $PageTableManager extends RootTableManager<
    _$AppDatabase,
    Page,
    PageData,
    $PageFilterComposer,
    $PageOrderingComposer,
    $PageAnnotationComposer,
    $PageCreateCompanionBuilder,
    $PageUpdateCompanionBuilder,
    (PageData, BaseReferences<_$AppDatabase, Page, PageData>),
    PageData,
    PrefetchHooks Function()> {
  $PageTableManager(_$AppDatabase db, Page table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PageFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PageOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PageAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> pageName = const Value.absent(),
            Value<String?> sectionName = const Value.absent(),
            Value<String?> fontName = const Value.absent(),
            Value<String?> bgmName = const Value.absent(),
            Value<String?> pageTypeId = const Value.absent(),
            Value<String?> hotkeyValue = const Value.absent(),
            Value<int?> flowId = const Value.absent(),
            Value<int?> pagePosition = const Value.absent(),
          }) =>
              PageCompanion(
            id: id,
            pageName: pageName,
            sectionName: sectionName,
            fontName: fontName,
            bgmName: bgmName,
            pageTypeId: pageTypeId,
            hotkeyValue: hotkeyValue,
            flowId: flowId,
            pagePosition: pagePosition,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> pageName = const Value.absent(),
            Value<String?> sectionName = const Value.absent(),
            Value<String?> fontName = const Value.absent(),
            Value<String?> bgmName = const Value.absent(),
            Value<String?> pageTypeId = const Value.absent(),
            Value<String?> hotkeyValue = const Value.absent(),
            Value<int?> flowId = const Value.absent(),
            Value<int?> pagePosition = const Value.absent(),
          }) =>
              PageCompanion.insert(
            id: id,
            pageName: pageName,
            sectionName: sectionName,
            fontName: fontName,
            bgmName: bgmName,
            pageTypeId: pageTypeId,
            hotkeyValue: hotkeyValue,
            flowId: flowId,
            pagePosition: pagePosition,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $PageProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    Page,
    PageData,
    $PageFilterComposer,
    $PageOrderingComposer,
    $PageAnnotationComposer,
    $PageCreateCompanionBuilder,
    $PageUpdateCompanionBuilder,
    (PageData, BaseReferences<_$AppDatabase, Page, PageData>),
    PageData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $EventTableManager get event => $EventTableManager(_db, _db.event);
  $TimerTemplateTableManager get timerTemplate =>
      $TimerTemplateTableManager(_db, _db.timerTemplate);
  $DingValueTableManager get dingValue =>
      $DingValueTableManager(_db, _db.dingValue);
  $FlowTableManager get flow => $FlowTableManager(_db, _db.flow);
  $ImagesTableManager get images => $ImagesTableManager(_db, _db.images);
  $TimerTableManager get timer => $TimerTableManager(_db, _db.timer);
  $PageTableManager get page => $PageTableManager(_db, _db.page);
}
