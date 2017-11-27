
Перем Лог;

///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт
	
	ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды, "Создание файлов поставки (cf и cfu)");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-cfu-basedir", "Каталог предыдущих версий для создания CFU (опционально)");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-update-from", "Перечень версий, через запятую, включаемых в обновление (опционально)");

	Парсер.ДобавитьКоманду(ОписаниеКоманды);

КонецПроцедуры

// Выполняет логику команды
// 
// Параметры:
//   ПараметрыКоманды - Соответствие ключей командной строки и их значений
//
Функция ВыполнитьКоманду(Знач ПараметрыКоманды) Экспорт

	РазобранныеПараметры = РазобратьПараметры(ПараметрыКоманды);
	СоздатьФайлыКонфигурацииПоставщика(ОкружениеСборки.ПолучитьКонфигуратор(), РазобранныеПараметры.КаталогВерсий, РазобранныеПараметры.ПредыдущиеВерсии);

КонецФункции

Функция СоздатьФайлыКонфигурацииПоставщика(Знач УправлениеКонфигуратором, Знач КаталогВерсий, Знач ПредыдущиеВерсии) Экспорт

	ИмяФайлаПоставки = ОбъединитьПути(УправлениеКонфигуратором.КаталогСборки(), "1cv8.cf");
	Параметры = УправлениеКонфигуратором.ПолучитьПараметрыЗапуска();
	Параметры.Добавить("/CreateDistributionFiles");
	Параметры.Добавить(СтрШаблон("-cffile ""%1""", ИмяФайлаПоставки));
	
	ФайлыПредыдущихВерсий = НайтиФайлыПредыдущихВерсий(КаталогВерсий, ПредыдущиеВерсии);
	Если ФайлыПредыдущихВерсий <> Неопределено Тогда
		ИмяФайлаОбновления = ОбъединитьПути(УправлениеКонфигуратором.КаталогСборки(), "1cv8.cfu");
		Параметры.Добавить(СтрШаблон("-cfufile ""%1""", ИмяФайлаОбновления));
		
		Для Каждого ФайлПредыдущейВерсии Из ФайлыПредыдущихВерсий Цикл

			Лог.Информация("Добавляю обновление из файла: %1", ФайлПредыдущейВерсии.ПолноеИмя);
			Параметры.Добавить(СтрШаблон("-f ""%1""", ФайлПредыдущейВерсии.ПолноеИмя));

		КонецЦикла;
		
	КонецЕсли;
	
	УправлениеКонфигуратором.ВыполнитьКоманду(Параметры);
	Лог.Отладка(УправлениеКонфигуратором.ВыводКоманды());

	Возврат Новый Структура("ИмяФайлаПоставки, ИмяФайлаОбновления", ИмяФайлаПоставки, ИмяФайлаОбновления);

КонецФункции // СоздатьФайлыКонфигурацииПоставщика()

Функция НайтиФайлыПредыдущихВерсий(Знач КаталогПредыдущихВерсий, Знач ВерсииОбновления)
	
	Если КаталогПредыдущихВерсий = Неопределено Тогда

		Возврат Неопределено;

	КонецЕсли;
	
	Каталог = Новый Файл(КаталогПредыдущихВерсий);
	Если Не Каталог.Существует() ИЛИ Каталог.ЭтоФайл() Тогда
		
		Возврат Неопределено;

	КонецЕсли;
	
	ФайлыКонфигураций = Новый Массив;
	
	Для Каждого Версия Из ВерсииОбновления Цикл

		КаталогВерсии = Новый Файл(ОбъединитьПути(КаталогПредыдущихВерсий, Версия));
		Если Не КаталогВерсии.Существует() Тогда

			Текст = СтрШаблон("Каталог версии %1 не найден", КаталогВерсии.ПолноеИмя);
			Лог.Ошибка(Текст);
			ВызватьИсключение Текст;

		КонецЕсли;
		
		ФайлыКонфигурацийВерсии = НайтиФайлы(КаталогВерсии.ПолноеИмя, "*.cf", Истина);
		Для Каждого ФайлВерсии Из ФайлыКонфигурацийВерсии Цикл

			ФайлыКонфигураций.Добавить(ФайлВерсии);

		КонецЦикла;

	КонецЦикла;
	
	Если ФайлыКонфигураций.Количество() Тогда
	
		Возврат ФайлыКонфигураций;
		
	КонецЕсли;

	Возврат Неопределено;
	
КонецФункции

Функция РазобратьПараметры(Знач ПараметрыКоманды) Экспорт

	МассивВерсий = СтрРазделить(Строка(ПараметрыКоманды["-update-from"]), ",", Истина);
	
	Результат = Новый Структура;
	Результат.Вставить("КаталогВерсий", ПараметрыКоманды["-cfu-basedir"]);
	Результат.Вставить("ПредыдущиеВерсии", МассивВерсий);

	Возврат Результат;

КонецФункции

//////////////////////////////////////////////////////////////////////////
//

Лог = Логирование.ПолучитьЛог(ПараметрыСистемы.ИмяЛогаСистемы());