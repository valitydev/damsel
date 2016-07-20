/**
 * Определения структур и сервисов для поддержания взаимодействия со
 * state processor – абстракции, реализующей шаг обработки (другими словами,
 * один переход состояния) ограниченного конечного автомата со сложным
 * состоянием, которое выражается при помощи истории как набора событий,
 * порождённых процессором.
 */

include "base.thrift"

namespace java com.rbkmoney.damsel.state_processing

exception EventNotFound {}
exception MachineNotFound {}
exception MachineFailed {}

typedef binary EventBody;
typedef list<EventBody> EventBodies;

/**
 * Произвольное событие, продукт перехода в новое состояние.
 */
struct Event {
    /**
     * Идентификатор события.
     * Монотонно возрастающее целочисленное значение, таким образом на множестве
     * событий задаётся отношение полного порядка (total order).
     */
    1: required base.EventID    id;
    2: required base.Timestamp  created_at;     /* Время происхождения события */
    3: required base.ID         source;         /* Идентификатор объекта, породившего событие */
    4: required EventBody       event_payload;  /* Описание события */
}

/**
 * Сложное состояние, выраженное в виде упорядоченного набора событий
 * процессора.
 */
typedef list<Event> History;

/**
 * Контекст автомата.
 * Основная его идея в том, что в него можно помещать некоторую ассоциированную информацию
 * (например в него можно положить свёрнутый из эвентов стейт).
 */
typedef binary Context;

/**
 * Желаемое действие, продукт перехода в новое состояние.
 *
 * Возможные действия представляют собой ограниченный язык для управления
 * прогрессом автомата, основанием для прихода сигналов или внешних вызовов,
 * которые приводят к дальнейшим переходам состояния. Отсутствие заполненных
 * полей будет интерпретировано буквально, как отсутствие желаемых действий.
 */
struct ComplexAction {
    1: optional SetTimerAction       set_timer;
    2: optional TagAction            tag;
    3: optional UpdateContextAction  update_context;
}

/**
 * Действие установки таймера ожидания на определённый отрезок времени.
 *
 * По истечению заданного отрезка времени в процессор поступит сигнал
 * `TimeoutSignal`.
 */
struct SetTimerAction {
    /** Критерий остановки таймера ожидания */
    1: required base.Timer      timer;
}

/**
 * Действие ассоциации с процессом автомата произвольного значения
 *
 * После факта успешной ассоциации к автомату можно обратиться с внешним
 * вызовом, используя указанное значение, то есть в процессор может поступить
 * вызов `processCall` с указанным `tag` в качестве `Reference`.
 *
 * Это действие в общем случае неидемпотентно, то есть ассоциация связана с
 * определённым моментом в истории, и в случае попытки использования одного и
 * того же значения ассоциации в разные моменты истории процесса автомата он
 * переходит в ошибочное состояние.
 *
 * То же самое происходит в случае попытки ассоциации одного и того значения с
 * двумя или более различными процессами автомата, все они переходят в ошибочное
 * состояние, – ситуация, требующая ручного вмешательства.
 */
struct TagAction {
    /** Значение для ассоциации */
    1: required base.Tag        tag;
}

/**
 * Действие обновления связанного с процессом автомата контекста.
 * На все последующие запросы в контексте придёт это значение, до его следующего обновления.
 */
struct UpdateContextAction {
    /** Контекст для обновления */
    1: required Context        context;
}

/**
 * Ссылка, уникально определяющая процесс автомата.
 */
union Reference {
    1: base.ID  id;   /** Основной идентификатор процесса автомата */
    2: base.Tag tag;  /** Ассоциация */
}

/**
 * Внешний вызов.
 *
 * При помощи вызовов организовано общение автомата с внешним миром и
 * получение на них ответов.
 */
typedef binary Call;

/**
 * Ответ на внешний вызов.
 */
typedef binary CallResponse;

/**
 * Набор данных для обработки внешнего вызова.
 */
struct CallArgs {
    1: required Call     call;     /** Данные вызова */
    2: required History  history;  /** История автомата */
    3: optional Context  context;  /** Текущий контекст автомата */
}

/**
 * Результат обработки внешнего вызова.
 */
struct CallResult {
    /** Список описаний событий, порождённых в результате обработки */
    1: required EventBodies events;
    /** Действие, которое необходимо выполнить после обработки */
    2: required ComplexAction action;
    /** Данные ответа */
    3: required CallResponse response;
}

/**
 * Сигнал, который может поступить в автомат.
 *
 * Сигналы, как и частный их случай в виде вызовов, приводят к прогрессу
 * автомата и эволюции его состояния, то есть нарастанию истории.
 */
union Signal {
    1: InitSignal     init;
    2: TimeoutSignal  timeout;
    3: RepairSignal   repair;
}

/**
 * Сигнал, информирующий о запуске автомата.
 */
struct InitSignal {
    /** Основной идентификатор процесса автомата */
    1: required base.ID  id;
    /** Набор данных для инициализации */
    2: required binary   arg;
}

/**
 * Сигнал, информирующий об окончании ожидания по таймеру.
 */
struct TimeoutSignal {}

/**
 * Сигнал, информирующий о необходимости восстановить работу автомата,
 * опционально скорректировать своё состояние.
 */
struct RepairSignal {
    1: optional binary  arg;
}

/**
 * Набор данных для обработки сигнала.
 */
struct SignalArgs {
    1: required Signal   signal;     /** Поступивший сигнал */
    2: required History  history;    /** История автомата */
    3: optional Context  context;    /** Текущий контекст автомата */
}

/**
 * Результат обработки сигнала.
 */
struct SignalResult {
    /** Список описаний событий, порождённых в результате обработки */
    1: required EventBodies events;
    /** Действие, которое необходимо выполнить после обработки */
    2: required ComplexAction action;
}

/**
 * Процессор переходов состояния ограниченного конечного автомата.
 *
 * В результате вызова каждого из методов сервиса должны появиться новое
 * состояние и новые действия, приводящие к дальнейшему прогрессу автомата.
 */
service Processor {

    /**
     * Обработать поступивший сигнал.
     */
    SignalResult processSignal (1: SignalArgs a) throws ()

    /**
     * Обработать внешний вызов и сформировать ответ на него.
     */
    CallResult processCall (1: CallArgs a) throws ()

}

/** Универсальная расширяемая структура с набором аргументов. */
struct Args {
    /** Неструктурированные данные. */
    1: required binary          arg;
}

/** Результат запуска процесса автомата. */
struct StartResult {
    1: required base.ID         id;
}

/**
 * Структура задает параметры для выборки событий
 *
 */
struct HistoryRange {
    /**
     * Идентификатор события, после которого следуют события,
     * входящие в описываемую выборку. Если поле не указано,
     * то в выборку попадут события с самого первого.
     *
     * Если `after` не указано, в выборку попадут события с начала истории; если
     * указано, например, `42`, то в выборку попадут события, случившиеся _после_
     * события `42`.
     */
    1: optional base.EventID after

    /**
     * Максимальная длина выборки.
     * Допустимо указывать любое значение >= 0.
     *
     * Если поле не задано, то длина выборки ничем не ограничена.
     *
     * Если в выборку попало событий _меньше_, чем значение `limit`,
     * был достигнут конец текущей истории.
     */
    2: optional i32 limit
}

/**
 * Сервис управления процессами автоматов, отвечающий за реализацию желаемых
 * действий и поддержку состояния процессоров.
 *
 * Для всех методов сервиса справедливы следующие утверждения:
 *  - если в параметре к методу передан Reference с ссылкой на машину, которой не
 *    существует, то метод выкинет исключение MachineNotFound
 *  - если в структуре HistoryRange поле after содержит несуществующий id события,
 *    то метод выкинет исключение EventNotFound
 *  - если в процессе выполнения запроса машина перешла в некорректное состояние
 *    то метод выкинет исключение MachineFailed
 */
service Automaton {

    /**
     * Запустить новый процесс автомата.
     */
    StartResult start (1: Args a) throws ();

    /**
     * Уничтожить определённый процесс автомата.
     */
    void destroy (1: Reference ref)
         throws (1: MachineNotFound ex1);

    /**
     * Попытаться перевести определённый процесс автомата из ошибочного
     * состояния в штатное и продолжить его исполнение.
     */
    void repair (1: Reference ref, 2: Args a)
         throws (1: MachineNotFound ex1, 2: MachineFailed ex2);

    /**
     * Совершить вызов и дождаться на него ответа.
     */
    CallResponse call (1: Reference ref, 2: Call c)
         throws (1: MachineNotFound ex1, 2: MachineFailed ex2);

    /**
     * Метод возвращает список событий (историю) машины ref
     *
     * Возвращаемый список событий упорядочен по моменту фиксирования его в
     * системе: в начале списка располагаются события, произошедшие
     * раньше тех, которые располагаются в конце.
     */

    History getHistory (1: Reference ref, 2: HistoryRange range)
         throws (1: MachineNotFound ex1, 2: EventNotFound ex2);
}

/** Исключение, сигнализирующее о том, что последнего события не существует. */
exception NoLastEvent {}

/**
 * Сервис получения истории событий сразу всех машин.
 */
service EventSink {
    /**
     * Метод возвращает список событий (историю) всех машин системы, включая
     * те машины, которые существовали в прошлом, но затем были удалены.
     *
     * Возвращаемый список событий упорядочен по моменту фиксирования его в
     * системе: в начале списка располагаются события, произошедшие
     * раньше тех, которые располагаются в конце.
     */
    History GetHistory (1: HistoryRange range)
         throws (1: EventNotFound ex1, 2: base.InvalidRequest ex2);

    /**
     * Получить идентификатор наиболее позднего события.
     * Если в системе нет ни одного события, то бросится исключение NoLastEvent.
     */
    base.EventID GetLastEventID ()
         throws (1: NoLastEvent ex1);
}
